import Foundation

public enum PresenterShelfCategory: String, CaseIterable, Identifiable, Equatable {
    case deck
    case screenshots
    case media
    case notes
    case files

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .deck: return "Deck"
        case .screenshots: return "Screenshots"
        case .media: return "Media"
        case .notes: return "Notes"
        case .files: return "Files"
        }
    }

    public var systemImage: String {
        switch self {
        case .deck: return "rectangle.on.rectangle"
        case .screenshots: return "viewfinder"
        case .media: return "play.rectangle"
        case .notes: return "doc.text"
        case .files: return "folder"
        }
    }
}

public struct PresenterShelfItem: Identifiable, Equatable {
    public enum Kind: Equatable {
        case deck
        case screenshot
        case media
        case notes
        case folder
        case file
    }

    public let id: UUID
    public var title: String
    public var subtitle: String
    public var kind: Kind
    public var category: PresenterShelfCategory
    public var fileURL: URL?
    public var thumbnailData: Data?

    public init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        kind: Kind,
        category: PresenterShelfCategory,
        fileURL: URL? = nil,
        thumbnailData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.kind = kind
        self.category = category
        self.fileURL = fileURL
        self.thumbnailData = thumbnailData
    }
}

public extension PresenterShelfItem {
    static let mockItems: [PresenterShelfItem] = [
        PresenterShelfItem(
            title: "Product Update — May 2025",
            subtitle: "Keynote Presentation · 24 MB",
            kind: .deck,
            category: .deck
        ),
        PresenterShelfItem(
            title: "Dashboard Overview",
            subtitle: "PNG Image · 2.1 MB",
            kind: .screenshot,
            category: .screenshots
        ),
        PresenterShelfItem(
            title: "Speaker Notes",
            subtitle: "PDF Document · 1.3 MB",
            kind: .notes,
            category: .notes
        ),
        PresenterShelfItem(
            title: "Brand Assets",
            subtitle: "Folder · 18 items",
            kind: .folder,
            category: .files
        ),
        PresenterShelfItem(
            title: "Product Demo",
            subtitle: "MP4 Video · 120 MB",
            kind: .media,
            category: .media
        )
    ]
}
