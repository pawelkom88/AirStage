import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// LSUIElement = YES in Info.plist keeps AirStage out of the Dock.
// For now, set the activation policy here for the package-based build.
app.setActivationPolicy(.accessory)
app.run()
