import SwiftUI

public struct DebugLayer: View {
    @ObservedObject var viewModel: PreviewViewModel
    
    public init(viewModel: PreviewViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack {
            // Cards bounding boxes and resize handles
            ForEach(viewModel.debugCards) { card in
                Rectangle()
                    .stroke(Color.red, lineWidth: 1)
                    .frame(width: card.rect.width, height: card.rect.height)
                    .position(x: card.rect.midX, y: card.rect.midY)
                
                Rectangle()
                    .stroke(Color.blue.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    .frame(width: card.dragSafeRect.width, height: card.dragSafeRect.height)
                    .position(x: card.dragSafeRect.midX, y: card.dragSafeRect.midY)
                
                let handles: [(ResizeHandle, CGPoint)] = [
                    (.topLeft, CGPoint(x: card.rect.minX, y: card.rect.minY)),
                    (.topRight, CGPoint(x: card.rect.maxX, y: card.rect.minY)),
                    (.bottomLeft, CGPoint(x: card.rect.minX, y: card.rect.maxY)),
                    (.bottomRight, CGPoint(x: card.rect.maxX, y: card.rect.maxY))
                ]
                
                ForEach(handles, id: \.0.rawValue) { handle, center in
                    let isNearest = card.nearestHandle == handle
                    let isActive = card.activeHandle == handle
                    
                    Circle()
                        .stroke(isActive ? Color.green : (isNearest ? Color.yellow : Color.orange.opacity(0.75)), lineWidth: 2)
                        .background(
                            Circle()
                                .fill(Color.orange.opacity(0.06))
                        )
                        .frame(width: card.handleHitRadius * 2, height: card.handleHitRadius * 2)
                        .position(center)
                        
                    Circle()
                        .fill(isActive ? Color.green : (isNearest ? Color.yellow : Color.orange))
                        .frame(width: 6, height: 6)
                        .position(center)
                }
                
                Text(verbatim: """
                CARD
                size: \(Int(card.rect.width))×\(Int(card.rect.height))
                mode: \(card.interactionModeDescription)
                hit: \(Int(card.handleHitRadius))
                nearest: \(card.nearestHandle?.rawValue ?? "none")
                dist: \(card.distanceToHandle.map { String(Int($0)) } ?? "none")
                """)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .padding(4)
                .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 4))
                .foregroundColor(.white)
                .position(x: card.rect.midX, y: card.rect.maxY + 45)
            }
            
            // Raw hand points
            ForEach(viewModel.debugHandPoints) { pt in
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 8, height: 8)
                    .position(pt.canvasPoint)
            }
            
            // Canvas Debug info
            Text(verbatim: """
            CANVAS
            view: \(Int(viewModel.canvasGeometry.viewSize.width))×\(Int(viewModel.canvasGeometry.viewSize.height))
            scene: \(Int(viewModel.sceneBounds.width))×\(Int(viewModel.sceneBounds.height))
            cameraRect: \(Int(viewModel.canvasGeometry.cameraImageRect.width))×\(Int(viewModel.canvasGeometry.cameraImageRect.height))
            mirror: \(viewModel.canvasGeometry.isMirrored ? "yes" : "no")
            """)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .padding(8)
            .background(Color.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 10))
            .foregroundColor(.white)
            .position(x: 140, y: 70)

            Text(edgeDeleteDebugText)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .padding(8)
                .background(Color.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 10))
                .foregroundColor(.white)
                .position(x: max(140, viewModel.sceneBounds.maxX - 140), y: 70)
            
            // Gesture Status
            if let gesture = viewModel.debugGesture {
                VStack(alignment: .leading) {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(verbatim: "Grab: \(gesture.isGrabActive)")
                            Text(verbatim: "Pinch: \(gesture.isPinchActive)")
                            Text(verbatim: "Pinch Base: \(gesture.pinchBaseline.map { String(format: "%.2f", $0) } ?? "nil")")
                            Text(verbatim: "Pinch Curr: \(gesture.pinchCurrent.map { String(format: "%.2f", $0) } ?? "nil")")
                            Text(verbatim: "Pinch Delta: \(gesture.pinchDelta.map { String(format: "%.2f", $0) } ?? "nil")")
                        }
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        Spacer()
                    }
                }
                .padding()
            }
            
            // Onboarding status
            if let onboarding = viewModel.debugOnboarding {
                VStack(alignment: .leading) {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(verbatim: "Step: \(onboarding.step)")
                            Text(String(format: "Scale: %.2f", onboarding.currentScale))
                            Text(verbatim: "Zoom Baseline: \(onboarding.baselineScale.map { String(format: "%.2f", $0) } ?? "nil")")
                            Text(verbatim: "Success Frames: \(onboarding.successFrames)")
                            Text(verbatim: "Met: \(onboarding.conditionMet)")
                        }
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .allowsHitTesting(false)
    }

    private var edgeDeleteDebugText: String {
        let state = viewModel.edgeDeleteState
        let sideStr = state.side.map { $0 == .left ? "left" : "right" } ?? "none"
        let layerStr = state.layerID.map { String($0.uuidString.prefix(8)) } ?? "none"
        let stateStr: String
        switch state {
        case .idle: stateStr = "idle"
        case .hovering: stateStr = "hovering"
        case .armed: stateStr = "armed"
        case .disintegrating: stateStr = "disintegrating"
        }
        return """
        EDGE DELETE
        state: \(stateStr)
        side: \(sideStr)
        layer: \(layerStr)
        zone: 96
        scene: \(Int(viewModel.sceneBounds.width))×\(Int(viewModel.sceneBounds.height))
        """
    }
}
