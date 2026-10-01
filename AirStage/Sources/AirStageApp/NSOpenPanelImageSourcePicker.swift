import AppKit
import AirStage
import UniformTypeIdentifiers

public final class NSOpenPanelImageSourcePicker: ImageSourcePicker {
    public init() {}

    public func pickImage(completion: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        panel.level = .floating

        panel.begin { response in
            if response == .OK {
                completion(panel.url)
            } else {
                completion(nil)
            }
        }
    }
}
