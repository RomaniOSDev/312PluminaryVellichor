import Foundation

struct ThemeSample: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var detail: String
    var imageName: String
    var symbolName: String
    var isFavorite: Bool
    var exploreCount: Int

    init(
        id: String,
        name: String,
        detail: String,
        imageName: String,
        symbolName: String,
        isFavorite: Bool = false,
        exploreCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.imageName = imageName
        self.symbolName = symbolName
        self.isFavorite = isFavorite
        self.exploreCount = exploreCount
    }
}
