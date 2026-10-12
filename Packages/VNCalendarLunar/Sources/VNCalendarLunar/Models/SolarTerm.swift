import Foundation

public enum SolarTerm: Int, Sendable, Codable, CaseIterable {
    case xuanPhan = 0      // 0° (Trung khí)
    case thanhMinh = 1     // 15° (Tiết khí)
    case cocVu = 2         // 30° (Trung khí)
    case lapHa = 3         // 45° (Tiết khí)
    case tieuMan = 4       // 60° (Trung khí)
    case mangChung = 5     // 75° (Tiết khí)
    case haChi = 6         // 90° (Trung khí)
    case tieuThu = 7       // 105° (Tiết khí)
    case daiThu = 8        // 120° (Trung khí)
    case lapThu = 9        // 135° (Tiết khí)
    case xuThu = 10        // 150° (Trung khí)
    case bachLo = 11       // 165° (Tiết khí)
    case thuPhan = 12      // 180° (Trung khí)
    case hanLo = 13        // 195° (Tiết khí)
    case suongGiang = 14   // 210° (Trung khí)
    case lapDong = 15      // 225° (Tiết khí)
    case tieuTuyet = 16    // 240° (Trung khí)
    case daiTuyet = 17     // 255° (Tiết khí)
    case dongChi = 18      // 270° (Trung khí - Mốc Tháng 11)
    case tieuHan = 19      // 285° (Tiết khí)
    case daiHan = 20       // 300° (Trung khí)
    case lapXuan = 21      // 315° (Tiết khí)
    case vuThuy = 22       // 330° (Trung khí)
    case kinhTrap = 23     // 345° (Tiết khí)

    public var isMajorTerm: Bool {
        rawValue % 2 == 0
    }

    public var vietnameseName: String {
        switch self {
        case .xuanPhan: return "Xuân Phân"
        case .thanhMinh: return "Thanh Minh"
        case .cocVu: return "Cốc Vũ"
        case .lapHa: return "Lập Hạ"
        case .tieuMan: return "Tiểu Mãn"
        case .mangChung: return "Mang Chủng"
        case .haChi: return "Hạ Chí"
        case .tieuThu: return "Tiểu Thử"
        case .daiThu: return "Đại Thử"
        case .lapThu: return "Lập Thu"
        case .xuThu: return "Xử Thử"
        case .bachLo: return "Bạch Lộ"
        case .thuPhan: return "Thu Phân"
        case .hanLo: return "Hàn Lộ"
        case .suongGiang: return "Sương Giáng"
        case .lapDong: return "Lập Đông"
        case .tieuTuyet: return "Tiểu Tuyết"
        case .daiTuyet: return "Đại Tuyết"
        case .dongChi: return "Đông Chí"
        case .tieuHan: return "Tiểu Hàn"
        case .daiHan: return "Đại Hàn"
        case .lapXuan: return "Lập Xuân"
        case .vuThuy: return "Vũ Thủy"
        case .kinhTrap: return "Kinh Trập"
        }
    }
}
