import Foundation

public enum CompassDirection: String, Sendable, Codable, CaseIterable {
    case east = "Chính Đông"
    case west = "Chính Tây"
    case south = "Chính Nam"
    case north = "Chính Bắc"
    case southEast = "Đông Nam"
    case northEast = "Đông Bắc"
    case southWest = "Tây Nam"
    case northWest = "Tây Bắc"
}

public enum HeavenlyStem: Int, Sendable, Codable, CaseIterable {
    case giap = 0
    case at = 1
    case binh = 2
    case dinh = 3
    case mau = 4
    case ky = 5
    case canh = 6
    case tan = 7
    case nham = 8
    case quy = 9

    public var vietnameseName: String {
        switch self {
        case .giap: return "Giáp"
        case .at: return "Ất"
        case .binh: return "Bính"
        case .dinh: return "Đinh"
        case .mau: return "Mậu"
        case .ky: return "Kỷ"
        case .canh: return "Canh"
        case .tan: return "Tân"
        case .nham: return "Nhâm"
        case .quy: return "Quý"
        }
    }

    /// Hướng Hỷ Thần xuất hành theo Can Ngày
    public var joyGodDirection: CompassDirection {
        switch self {
        case .giap, .ky: return .northEast
        case .at, .canh: return .northWest
        case .binh, .tan: return .southWest
        case .dinh, .nham: return .south
        case .mau, .quy: return .southEast
        }
    }

    /// Hướng Tài Thần xuất hành theo Can Ngày
    public var wealthGodDirection: CompassDirection {
        switch self {
        case .giap, .at: return .southEast
        case .binh, .dinh: return .east
        case .mau: return .north
        case .ky: return .south
        case .canh, .tan: return .west
        case .nham: return .south
        case .quy: return .north
        }
    }
}

public enum EarthlyBranch: Int, Sendable, Codable, CaseIterable {
    case ty = 0
    case suu = 1
    case dan = 2
    case mao = 3
    case thin = 4
    // swiftlint:disable:next identifier_name
    case ty_snake = 5
    case ngo = 6
    case mui = 7
    case than = 8
    case dau = 9
    case tuat = 10
    case hoi = 11

    public var vietnameseName: String {
        switch self {
        case .ty: return "Tý"
        case .suu: return "Sửu"
        case .dan: return "Dần"
        case .mao: return "Mão"
        case .thin: return "Thìn"
        case .ty_snake: return "Tỵ"
        case .ngo: return "Ngọ"
        case .mui: return "Mùi"
        case .than: return "Thân"
        case .dau: return "Dậu"
        case .tuat: return "Tuất"
        case .hoi: return "Hợi"
        }
    }

    public var timeRange: String {
        switch self {
        case .ty: return "23-01"
        case .suu: return "01-03"
        case .dan: return "03-05"
        case .mao: return "05-07"
        case .thin: return "07-09"
        case .ty_snake: return "09-11"
        case .ngo: return "11-13"
        case .mui: return "13-15"
        case .than: return "15-17"
        case .dau: return "17-19"
        case .tuat: return "19-21"
        case .hoi: return "21-23"
        }
    }

    /// Tính 6 Giờ Hoàng Đạo trong ngày theo Địa Chi của Ngày (Quy tắc Lịch Vạn Niên GS. Hồ Ngọc Đức)
    public static func auspiciousHours(for dayBranch: EarthlyBranch) -> [EarthlyBranch] {
        switch dayBranch {
        case .ty, .ngo:
            return [.ty, .suu, .mao, .ngo, .than, .dau]
        case .suu, .mui:
            return [.dan, .mao, .ty_snake, .than, .tuat, .hoi]
        case .dan, .than:
            return [.ty, .suu, .thin, .ty_snake, .mui, .tuat]
        case .mao, .dau:
            return [.ty, .dan, .mao, .ngo, .mui, .dau]
        case .thin, .tuat:
            return [.dan, .thin, .ty_snake, .than, .dau, .hoi]
        case .ty_snake, .hoi:
            return [.suu, .thin, .ngo, .mui, .tuat, .hoi]
        }
    }
}

public struct CanChiPair: Hashable, Sendable, Codable, CustomStringConvertible {
    public let stem: HeavenlyStem
    public let branch: EarthlyBranch

    public init(stem: HeavenlyStem, branch: EarthlyBranch) {
        self.stem = stem
        self.branch = branch
    }

    public var description: String {
        "\(stem.vietnameseName) \(branch.vietnameseName)"
    }

    /// Tính Can Chi Năm cho một năm Dương Lịch
    public static func year(for solarYear: Int) -> CanChiPair {
        let stemIndex = (solarYear + 6) % 10
        let branchIndex = (solarYear + 8) % 12
        let stem = HeavenlyStem(rawValue: (stemIndex + 10) % 10) ?? .giap
        let branch = EarthlyBranch(rawValue: (branchIndex + 12) % 12) ?? .ty
        return CanChiPair(stem: stem, branch: branch)
    }

    /// Tính Can Chi Tháng theo Tháng Âm lịch và Can của Năm
    public static func month(forLunarMonth month: Int, yearStem: HeavenlyStem) -> CanChiPair {
        let stemIndex = (yearStem.rawValue * 2 + month + 1) % 10
        let stem = HeavenlyStem(rawValue: stemIndex) ?? .giap
        let branchIndex = (month + 1) % 12
        let branch = EarthlyBranch(rawValue: branchIndex) ?? .dan
        return CanChiPair(stem: stem, branch: branch)
    }
}

public struct FullCanChi: Hashable, Sendable, Codable {
    public let year: CanChiPair
    public let month: CanChiPair
    public let day: CanChiPair
    public let hour: CanChiPair

    public init(year: CanChiPair, month: CanChiPair, day: CanChiPair, hour: CanChiPair) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
    }
}

// MARK: - 12 Trực (Thập Nhị Kiến Trừ)
public enum LunarOfficer: Int, Sendable, Codable, CaseIterable {
    case kien = 0
    case tru = 1
    case man = 2
    case binh = 3
    case dinh = 4
    case chap = 5
    case pha = 6
    case nguy = 7
    case thanh = 8
    case thau = 9
    case khai = 10
    case be = 11

    public var name: String {
        switch self {
        case .kien: return "Kiến"
        case .tru: return "Trừ"
        case .man: return "Mãn"
        case .binh: return "Bình"
        case .dinh: return "Định"
        case .chap: return "Chấp"
        case .pha: return "Phá"
        case .nguy: return "Nguy"
        case .thanh: return "Thành"
        case .thau: return "Thâu"
        case .khai: return "Khai"
        case .be: return "Bế"
        }
    }

    public var title: String {
        "Trực \(name)"
    }

    public var summary: String {
        switch self {
        case .kien: return "Khởi công, xuất hành, giá thú cát lợi"
        case .tru: return "Cúng tế, tẩy trần, giải trừ tốt lành"
        case .man: return "Khai trương, mở kho, cầu tài đắc lợi"
        case .binh: return "Mọi sự bình hòa, hội họp, an gia"
        case .dinh: return "Ký kết, giao dịch, cầu an hanh thông"
        case .chap: return "Đặt nền móng, xây cất, tu bổ tốt"
        case .pha: return "Kiêng việc lớn, chỉ nên phá dỡ, sửa sang"
        case .nguy: return "Hành sự cẩn trọng, tránh việc mạo hiểm"
        case .thanh: return "Khai trương, hôn lễ, nhập trạch đại cát"
        case .thau: return "Thu nợ, tích lũy, gặt hái thành tựu"
        case .khai: return "Trăm sự khởi sắc, vạn sự hanh thông"
        case .be: return "Kiêng việc khai mở, tốt cho an táng"
        }
    }

    /// Các việc nên làm theo 12 Trực
    public var suitableActivities: [String] {
        switch self {
        case .kien: return ["Khởi công", "Xuất hành", "Giá thú", "Tế tự"]
        case .tru: return ["Cúng tế", "Tẩy trần", "Chữa bệnh", "Giải trừ"]
        case .man: return ["Khai trương", "Mở kho", "Cầu tài", "Giao dịch"]
        case .binh: return ["Hội họp", "Tu sửa", "An gia", "Lắp đặt"]
        case .dinh: return ["Ký kết hợp đồng", "Cầu an", "Nhập học", "Hôn lễ"]
        case .chap: return ["Đặt nền móng", "Xây cất", "Tu bổ", "Cầu phúc"]
        case .pha: return ["Phá dỡ nhà", "Chữa bệnh", "Dọn dẹp", "Trừ hại"]
        case .nguy: return ["Cúng tế", "An vị", "Làm việc thiện", "Cầu an"]
        case .thanh: return ["Khai trương", "Cưới hỏi", "Nhập trạch", "Ký kết"]
        case .thau: return ["Thu nợ", "Thu hoạch", "Cất giữ tài sản", "Nhận chức"]
        case .khai: return ["Khởi công", "Khai trương", "Cưới hỏi", "Giao dịch"]
        case .be: return ["Đắp đập", "An táng", "Cất giữ của cải", "Phòng thủ"]
        }
    }

    /// Các việc kiêng cữ theo 12 Trực
    public var tabooActivities: [String] {
        switch self {
        case .kien: return ["Đào đất", "Chôn cất", "Phá dỡ"]
        case .tru: return ["Xuất hành xa", "Giá thú", "Động thổ"]
        case .man: return ["Chôn cất", "Kiện tụng", "Cho vay"]
        case .binh: return ["Động thổ", "Xuất hành xa", "Khai trương"]
        case .dinh: return ["Kiện tụng", "Tranh chấp", "Xuất quân"]
        case .chap: return ["Mở kho", "Xuất tiền của lớn", "Xuất hành"]
        case .pha: return ["Giá thú", "Khai trương", "Ký hợp đồng"]
        case .nguy: return ["Đi thuyền bè", "Leo cao", "Mạo hiểm"]
        case .thanh: return ["Kiện cáo", "Tranh chấp", "Tranh quyền"]
        case .thau: return ["Xuất tiền lớn", "Chôn cất", "Động thổ"]
        case .khai: return ["Động thổ", "Chôn cất", "Việc tang ma"]
        case .be: return ["Khai trương", "Xuất hành", "Cưới hỏi"]
        }
    }

    public static func officer(monthBranch: EarthlyBranch, dayBranch: EarthlyBranch) -> LunarOfficer {
        let diff = (dayBranch.rawValue - monthBranch.rawValue + 12) % 12
        return LunarOfficer(rawValue: diff) ?? .kien
    }
}

// MARK: - 12 Thần Hoàng Đạo / Hắc Đạo
public enum ZodiacStar: Int, Sendable, Codable, CaseIterable {
    case thanhLong = 0
    case minhDuong = 1
    case thienHinh = 2
    case chuTuoc = 3
    case kimQuy = 4
    case kimDuong = 5
    case bachHo = 6
    case ngocDuong = 7
    case thienLao = 8
    case huyenVu = 9
    case tuMenh = 10
    case cauTran = 11

    public var isAuspicious: Bool {
        switch self {
        case .thanhLong, .minhDuong, .kimQuy, .kimDuong, .ngocDuong, .tuMenh:
            return true
        default:
            return false
        }
    }

    public var vietnameseName: String {
        switch self {
        case .thanhLong: return "Thanh Long"
        case .minhDuong: return "Minh Đường"
        case .thienHinh: return "Thiên Hình"
        case .chuTuoc: return "Chu Tước"
        case .kimQuy: return "Kim Quỹ"
        case .kimDuong: return "Kim Đường"
        case .bachHo: return "Bạch Hổ"
        case .ngocDuong: return "Ngọc Đường"
        case .thienLao: return "Thiên Lao"
        case .huyenVu: return "Huyền Vũ"
        case .tuMenh: return "Tư Mệnh"
        case .cauTran: return "Câu Trận"
        }
    }

    public var fullTitle: String {
        "\(vietnameseName) \(isAuspicious ? "Hoàng Đạo" : "Hắc Đạo")"
    }

    public static func star(monthBranch: EarthlyBranch, dayBranch: EarthlyBranch) -> ZodiacStar {
        let base: EarthlyBranch
        switch monthBranch {
        case .dan, .than: base = .ty
        case .mao, .dau: base = .dan
        case .thin, .tuat: base = .thin
        case .ty_snake, .hoi: base = .ngo
        case .ty, .ngo: base = .than
        case .suu, .mui: base = .tuat
        }
        let offset = (dayBranch.rawValue - base.rawValue + 12) % 12
        return ZodiacStar(rawValue: offset) ?? .thanhLong
    }
}
