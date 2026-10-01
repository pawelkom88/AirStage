import Foundation
import CoreGraphics

public struct SceneLayer: Identifiable, Equatable {
    public enum Kind: String, Equatable {
        case note
        case image
        case windowCapture
        case tutorial
        case shelfItem
    }

    public let id: UUID
    public var kind: Kind
    public var title: String
    public var subtitle: String
    public var position: CGPoint
    public var size: CGSize
    public var scale: CGFloat
    public var rotationDegrees: CGFloat
    public var zIndex: Int
    public var isSelected: Bool
    public var isBeingRemoved: Bool
    public var imageURL: URL?

    public init(
        id: UUID = UUID(),
        kind: Kind,
        title: String,
        subtitle: String = "",
        position: CGPoint = .zero,
        size: CGSize = .zero,
        scale: CGFloat = 1.0,
        rotationDegrees: CGFloat = 0.0,
        zIndex: Int = 0,
        isSelected: Bool = false,
        isBeingRemoved: Bool = false,
        imageURL: URL? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.position = position
        self.size = size
        self.scale = scale
        self.rotationDegrees = rotationDegrees
        self.zIndex = zIndex
        self.isSelected = isSelected
        self.isBeingRemoved = isBeingRemoved
        self.imageURL = imageURL
    }

    public var displayTitle: String {
        if title.isEmpty {
            return "Empty Note"
        }
        return title
    }
}
