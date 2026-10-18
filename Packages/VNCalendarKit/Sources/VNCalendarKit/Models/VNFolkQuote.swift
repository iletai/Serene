import Foundation

public struct VNFolkQuote: Sendable, Equatable, Hashable {
    public let quote: String
    public let authorOrOrigin: String

    public init(quote: String, authorOrOrigin: String) {
        self.quote = quote
        self.authorOrOrigin = authorOrOrigin
    }
}

extension Notification.Name {
    /// Posted when `VNFolkQuotes.source` changes so cached calendar models refresh.
    public static let annienFolkQuotesDidChange = Notification.Name("annienFolkQuotesDidChange")
}

public enum VNFolkQuotes {
    public static let allQuotes: [VNFolkQuote] = [
        VNFolkQuote(quote: "Ăn quả nhớ kẻ trồng cây\nĂn khoai nhớ kẻ cho dây mà trồng.", authorOrOrigin: "Ca dao Việt Nam"),
        VNFolkQuote(quote: "Công cha như núi Thái Sơn\nNghĩa mẹ như nước trong nguồn chảy ra.", authorOrOrigin: "Ca dao Việt Nam"),
        VNFolkQuote(quote: "Thuận vợ thuận chồng, tát biển Đông cũng cạn.", authorOrOrigin: "Tục ngữ Việt Nam"),
        VNFolkQuote(quote: "Lời nói chẳng mất tiền mua\nLựa lời mà nói cho vừa lòng nhau.", authorOrOrigin: "Tục ngữ Việt Nam"),
        VNFolkQuote(quote: "Dù ai đi ngược về xuôi\nNhớ ngày Giỗ Tổ mùng mười tháng ba.", authorOrOrigin: "Ca dao Việt Nam"),
        VNFolkQuote(quote: "Bầu ơi thương lấy bí cùng\nTuy rằng khác giống nhưng chung một giàn.", authorOrOrigin: "Ca dao Việt Nam"),
        VNFolkQuote(quote: "Muốn sang thì bắc cầu Kiều\nMuốn con hay chữ thì yêu lấy thầy.", authorOrOrigin: "Ca dao Việt Nam"),
        VNFolkQuote(quote: "Uống nước nhớ nguồn, làm con phải giữ đạo hiếu.", authorOrOrigin: "Tục ngữ Việt Nam"),
        VNFolkQuote(quote: "Một cây làm chẳng nên non\nBa cây chụm lại nên hòn núi cao.", authorOrOrigin: "Ca dao Việt Nam"),
        VNFolkQuote(quote: "Nhiễu điều phủ lấy giá gương\nNgười trong một nước phải thương nhau cùng.", authorOrOrigin: "Ca dao Việt Nam"),
        VNFolkQuote(quote: "Anh em như thể tay chân\nRách lành đùm bọc dở hay đỡ đần.", authorOrOrigin: "Ca dao Việt Nam"),
        VNFolkQuote(quote: "Tấc đất tấc vàng, người ta là hoa của đất.", authorOrOrigin: "Tục ngữ Việt Nam"),
        VNFolkQuote(quote: "Chim có tổ, người có tông\nNhư cây có cội, như sông có nguồn.", authorOrOrigin: "Ca dao Việt Nam"),
        VNFolkQuote(quote: "Đi một ngày đàng, học một sàng khôn.", authorOrOrigin: "Tục ngữ Việt Nam"),
        VNFolkQuote(quote: "Có công mài sắt, có ngày nên kim.", authorOrOrigin: "Tục ngữ Việt Nam"),
        VNFolkQuote(quote: "Đói cho sạch, rách cho thơm.", authorOrOrigin: "Tục ngữ Việt Nam"),
        VNFolkQuote(quote: "Lá lành đùm lá rách, thương người như thể thương thân.", authorOrOrigin: "Tục ngữ Việt Nam"),
        VNFolkQuote(quote: "Uống trà ngắm trăng, tâm an vạn sự an.", authorOrOrigin: "Triết lý phương Đông"),
        VNFolkQuote(quote: "Xuân sinh, hạ trưởng, thu liễm, đông tàng.", authorOrOrigin: "Hoàng Đế Nội Kinh"),
        VNFolkQuote(quote: "Vạn sự tùy duyên, tâm an dạ sáng.", authorOrOrigin: "Cổ đức danh ngôn"),
        VNFolkQuote(quote: "Cơm cha áo mẹ chữ thầy\nGắng công mà học có ngày thành danh.", authorOrOrigin: "Ca dao Việt Nam"),
        VNFolkQuote(quote: "Giữ gìn gia phong nếp nhà\nCội nguồn tiên tổ sáng soi muôn đời.", authorOrOrigin: "Văn hóa truyền thống"),
        VNFolkQuote(
            quote: "Trời có bốn mùa: Xuân Hạ Thu Đông\nNgười có bốn đức: Cần Kiệm Liêm Chính.",
            authorOrOrigin: "Cổ ngữ phương Đông"
        ),
        VNFolkQuote(quote: "Ngọc bất trác, bất thành khí\nNhân bất học, bất tri đạo.", authorOrOrigin: "Tam Tự Kinh"),
        VNFolkQuote(quote: "Gần mực thì đen, gần đèn thì rạng.", authorOrOrigin: "Tục ngữ Việt Nam"),
        VNFolkQuote(quote: "Khéo ăn thì no, khéo co thì ấm.", authorOrOrigin: "Tục ngữ Việt Nam"),
        VNFolkQuote(quote: "Một nụ cười bằng mười thang thuốc bổ.", authorOrOrigin: "Tục ngữ Việt Nam"),
        VNFolkQuote(quote: "Nuôi lợn ăn cơm nằm, nuôi tằm ăn cơm đứng.", authorOrOrigin: "Tục ngữ Việt Nam"),
        VNFolkQuote(quote: "Đất lành chim đậu, phúc trạch lưu trường.", authorOrOrigin: "Tục ngữ Việt Nam"),
        VNFolkQuote(quote: "Nhất nghệ tinh, nhất thân vinh.", authorOrOrigin: "Tục ngữ Việt Nam")
    ]

    // ponytail: single static injection point (app composition root sets it once per sync);
    // move to a DI'd store if a second source or per-scene state ever appears.
    // nonisolated(unsafe) because StrictConcurrency forbids mutable global state;
    // writes happen on @MainActor (AppContainer), reads are index reads (safe in practice).
    public nonisolated(unsafe) static var source: [VNFolkQuote] = allQuotes {
        didSet {
            VNMonthLunarCache.shared.removeAll()
            NotificationCenter.default.post(name: .annienFolkQuotesDidChange, object: nil)
        }
    }

    public static func quote(for dateKey: DateKey) -> VNFolkQuote {
        let list = source.isEmpty ? allQuotes : source
        let index = abs(dateKey.rawValue) % list.count
        return list[index]
    }
}
