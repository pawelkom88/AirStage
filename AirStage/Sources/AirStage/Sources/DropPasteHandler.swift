import Foundation
import AppKit
import UniformTypeIdentifiers
import OSLog

public final class DropPasteHandler {
    private let importer: ImageImporter

    public init(importer: ImageImporter) {
        self.importer = importer
    }

    public func handleDrop(providers: [NSItemProvider], completion: @escaping (Result<UUID, ImageImportError>) -> Void) -> Bool {
        guard let provider = providers.first else { return false }
        
        // 1. Check if provider can load a file URL
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let url = item as? URL {
                    let result = self.importer.importImage(from: url)
                    completion(result)
                } else if let data = item as? Data,
                          let urlString = String(data: data, encoding: .utf8),
                          let url = URL(string: urlString) {
                    let result = self.importer.importImage(from: url)
                    completion(result)
                } else {
                    completion(.failure(.other("Failed to read drop data")))
                }
            }
            return true
        }
        
        // 2. Check if provider can load raw image data
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                guard let data = data else {
                    completion(.failure(.other("Failed to read dropped image data")))
                    return
                }
                
                // Write data to temporary file
                let tempDir = FileManager.default.temporaryDirectory
                let fileURL = tempDir.appendingPathComponent("dropped_image_\(UUID().uuidString).png")
                do {
                    try data.write(to: fileURL)
                    let result = self.importer.importImage(from: fileURL)
                    completion(result)
                } catch {
                    completion(.failure(.other("Failed to save dropped image data")))
                }
            }
            return true
        }
        
        return false
    }

    public func handlePaste(completion: @escaping (Result<UUID, ImageImportError>) -> Void) -> Bool {
        let pb = NSPasteboard.general
        // 1. Check for file URL
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let firstUrl = urls.first {
            let result = importer.importImage(from: firstUrl)
            completion(result)
            if case .success = result { return true }
            return false
        }
        
        // 2. Check for raw image data
        if pb.canReadItem(withDataConformingToTypes: [UTType.image.identifier]) {
            if let image = NSImage(pasteboard: pb) {
                let tempDir = FileManager.default.temporaryDirectory
                let fileURL = tempDir.appendingPathComponent("pasted_image_\(UUID().uuidString).png")
                if let tiff = image.tiffRepresentation,
                   let rep = NSBitmapImageRep(data: tiff),
                   let pngData = rep.representation(using: .png, properties: [:]) {
                    do {
                        try pngData.write(to: fileURL)
                        let result = importer.importImage(from: fileURL)
                        completion(result)
                        if case .success = result { return true }
                        return false
                    } catch {
                        AppLog.sources.error("Failed to write pasted image data: \(error.localizedDescription)")
                    }
                }
            }
        }
        return false
    }
}
