import AppKit
import Combine
import SwiftUI

@MainActor
public final class PreviewFullscreenController: ObservableObject {
    @Published public private(set) var isFullscreen: Bool = false
    
    private weak var window: NSWindow?
    private var originalFrame: NSRect?
    private var originalStyleMask: NSWindow.StyleMask?
    
    public init() {}
    
    public func attach(to window: NSWindow) {
        self.window = window
    }
    
    public func toggleFullscreen() {
        guard let window = window else { return }
        
        if isFullscreen {
            exitFullscreen(window: window)
        } else {
            enterFullscreen(window: window)
        }
    }
    
    private func enterFullscreen(window: NSWindow) {
        guard let screen = window.screen else { return }
        
        originalFrame = window.frame
        originalStyleMask = window.styleMask
        
        // Use visibleFrame instead of frame to avoid covering the menu bar/dock
        let targetFrame = screen.visibleFrame
        
        // Remove title bar and make borderless for "presentation" feel, but keep resizing if wanted, though fullscreen shouldn't resize.
        window.styleMask = [.borderless, .resizable]
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(targetFrame, display: true)
        }, completionHandler: {
            Task { @MainActor in
                self.isFullscreen = true
            }
        })
    }
    
    private func exitFullscreen(window: NSWindow) {
        guard let targetFrame = originalFrame, let originalStyleMask = originalStyleMask else { return }
        
        window.styleMask = originalStyleMask
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(targetFrame, display: true)
        }, completionHandler: {
            Task { @MainActor in
                self.isFullscreen = false
            }
        })
    }
}
