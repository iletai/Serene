#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_YML="${PROJECT_ROOT}/project.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[BUILD]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Hàm chọn simulator có sẵn
# Ưu tiên: 1) thiết bị đang Booted, 2) thiết bị đầu tiên trong danh sách
pick_simulator() {
    if ! command -v xcrun >/dev/null 2>&1; then
        warn "Không tìm thấy xcrun. Sử dụng tên simulator mặc định."
        echo "iPhone 16 Pro"
        return 1
    fi

    local sims=$(xcrun simctl list devices available)

    # Lấy UUID nếu có thiết bị Booted
    local booted_id=$(echo "$sims" | grep "(Booted)" | grep -oE "[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}" | head -1)
    if [[ -n "$booted_id" ]]; then
        echo "id=$booted_id"
        return 0
    fi

    # Nếu không có thiết bị boot, lấy UUID thiết bị đầu tiên
    local first_id=$(echo "$sims" | grep -oE "[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}" | head -1)
    if [[ -n "$first_id" ]]; then
        echo "id=$first_id"
        return 0
    fi

    warn "Không tìm thấy simulator nào. Sử dụng tên mặc định."
    echo "name=iPhone 16 Pro"
    return 1
}

# Build project.yml với XcodeGen
build_project() {
    log "Tạo Xcode project từ ${PROJECT_YML}"
    if ! command -v xcodegen >/dev/null 2>&1; then
        error "xcodegen không được cài đặt. Cài đặt qua 'brew install xcodegen'"
        exit 1
    fi
    (cd "${PROJECT_ROOT}" && xcodegen generate)
    if [[ ! -d "${PROJECT_ROOT}/AnNien.xcodeproj" ]]; then
        error "Không thể tạo dự án AnNien.xcodeproj"
        exit 1
    fi
    log "Xcode project được tạo"
}

# Chạy xcodebuild
run_xcodebuild() {
    local scheme="${1:-AnNien-Dev}"
    local simulator_name="${2:-$(pick_simulator)}"
    local configuration="${3:-Debug-Development}"
    local action="${4:-test}"

    log "Bắt đầu build (${action}) với scheme: ${scheme}, simulator: ${simulator_name}, config: ${configuration}"

    # Xác định simulator name và id
    local sim_type="name"
    local sim_name="$simulator_name"
    if [[ "$simulator_name" =~ ^id=(.*)$ ]]; then
        sim_type="id"
        sim_name="${BASH_REMATCH[1]}"
    elif [[ "$simulator_name" =~ ^name=(.*)$ ]]; then
        sim_type="name"
        sim_name="${BASH_REMATCH[1]}"
    fi

    local destination="platform=iOS Simulator,${sim_type}=${sim_name}"

    (
        cd "${PROJECT_ROOT}"
        xcodebuild \
            -scheme ${scheme} \
            -destination "${destination}" \
            -configuration ${configuration} \
            -quiet \
            ${action}
    )

    local result=$?
    if [[ ${result} -ne 0 ]]; then
        error "Build/app thất bại với mã: ${result}"
        exit ${result}
    fi

    if [[ "${action}" == "build" ]]; then
        local target_id="${sim_name}"
        if [[ "${sim_type}" == "name" ]]; then
            target_id=$(xcrun simctl list devices available | grep -F "${sim_name}" | grep -oE "[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}" | head -1)
        fi

        log "Khởi chạy app trên simulator (id=${target_id})"
        xcrun simctl boot "${target_id}" >/dev/null 2>&1 || true
        open -a Simulator
        xcrun simctl launch "${target_id}" "com.iletai.annien.dev"
        log "App đã khởi chạy thành công trên Simulator!"
    else
        log "Build và test hoàn tất thành công"
    fi
}

# In hướng dẫn sử dụng
usage() {
    echo "Cách sử dụng: $0 [tùy chọn]"
    echo ""
    echo "Tùy chọn:"
    echo "  --run                  Build và mở app trực tiếp trên Simulator (thay vì chạy test)"
    echo "  --test-only            Chỉ chạy test (bỏ qua xcodegen generate)"
    echo "  --no-generate          Bỏ qua xcodegen generate"
    echo "  --scheme SCHEME        Scheme (mặc định: AnNien-Dev)"
    echo "  --simulator NAME       Tên simulator (mặc định: chọn simulator có sẵn)"
    echo "  --configuration CONFIG  Cấu hình Xcode (mặc định: Debug-Development)"
    echo "  --skip-clean           Bỏ qua bước clean"
    echo "  --help                 In hướng dẫn này"
    echo ""
    echo "Ví dụ:"
    echo "  $0 --run                         # Build và launch app trên simulator"
    echo "  $0 --test-only                   # Chỉ chạy test"
}

# Phân tích tham số
TEST_ONLY=false
NO_GENERATE=false
RUN_APP=false
SCHEME="AnNien-Dev"
SIMULATOR=""
CONFIGURATION="Debug-Development"
SKIP_CLEAN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --run)
            RUN_APP=true
            shift
            ;;
        --test-only)
            TEST_ONLY=true
            shift
            ;;
        --no-generate)
            NO_GENERATE=true
            shift
            ;;
        --scheme)
            SCHEME="$2"
            shift 2
            ;;
        --simulator)
            SIMULATOR="$2"
            shift 2
            ;;
        --configuration)
            CONFIGURATION="$2"
            shift 2
            ;;
        --skip-clean)
            SKIP_CLEAN=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            error "Tùy chọn không xác định: $1"
            usage
            exit 1
            ;;
    esac
done

# Đặt action target
BUILD_TARGET="test"
if [[ "${RUN_APP}" = true ]]; then
    BUILD_TARGET="build"
    # Gán biến để phân biệt action run ở hàm run_xcodebuild
    # (ta dùng biến toàn cục hoặc truyền qua tham số)
fi

# Chọn simulator cuối cùng
if [[ -z "$SIMULATOR" ]]; then
    SIMULATOR=$(pick_simulator)
fi

log "Cấu hình: scheme=${SCHEME}, simulator=${SIMULATOR}, config=${CONFIGURATION}, test_only=${TEST_ONLY}, no_generate=${NO_GENERATE}, skip_clean=${SKIP_CLEAN}"

# Build project.yml
if [[ "${NO_GENERATE}" = false && "${TEST_ONLY}" = false ]]; then
    build_project
fi

# Chạy xcodebuild
run_xcodebuild "${SCHEME}" "${SIMULATOR}" "${CONFIGURATION}" "${BUILD_TARGET}"

log "Hoàn tất."; exit 0