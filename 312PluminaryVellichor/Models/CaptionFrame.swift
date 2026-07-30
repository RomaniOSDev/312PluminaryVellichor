import Foundation

struct CaptionFrame: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var caption: String
    var imageName: String
    var symbolName: String
    var date: Date

    init(
        id: UUID = UUID(),
        title: String,
        caption: String = "",
        imageName: String,
        symbolName: String = "rectangle.on.rectangle.angled",
        date: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.caption = caption
        self.imageName = imageName
        self.symbolName = symbolName
        self.date = date
    }
}
