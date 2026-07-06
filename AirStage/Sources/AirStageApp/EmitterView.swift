import SwiftUI
import AppKit
import QuartzCore
import AirStage

struct EmitterView: NSViewRepresentable {
    let side: EdgeDeleteSide
    let isActive: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard isActive else {
            nsView.layer?.sublayers?.removeAll(where: { $0 is CAEmitterLayer })
            return
        }

        if nsView.layer?.sublayers?.contains(where: { $0 is CAEmitterLayer }) == true {
            return
        }

        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: nsView.bounds.midX, y: nsView.bounds.midY)
        emitter.emitterShape = .rectangle
        emitter.emitterSize = CGSize(width: nsView.bounds.width, height: nsView.bounds.height)
        emitter.renderMode = .additive
        emitter.birthRate = 1

        let cell = CAEmitterCell()
        cell.birthRate = 260
        cell.lifetime = 0.75
        cell.velocity = 120
        cell.velocityRange = 80
        cell.scale = 0.018
        cell.scaleRange = 0.014
        cell.alphaSpeed = -1.2
        cell.emissionRange = .pi / 4
        cell.emissionLongitude = side == .left ? .pi : 0
        cell.contents = particleImage().cgImage(forProposedRect: nil, context: nil, hints: nil)

        emitter.emitterCells = [cell]
        nsView.layer?.addSublayer(emitter)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            emitter.birthRate = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            emitter.removeFromSuperlayer()
        }
    }

    private func particleImage() -> NSImage {
        let size = NSSize(width: 8, height: 8)
        let image = NSImage(size: size)
        image.lockFocus()

        NSColor.white.withAlphaComponent(0.8).setFill()
        NSBezierPath(ovalIn: NSRect(origin: .zero, size: size)).fill()

        image.unlockFocus()
        return image
    }
}
