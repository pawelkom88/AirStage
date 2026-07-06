import SwiftUI
import AirStage
import UniformTypeIdentifiers

struct StickyNoteView: View {
    let layer: SceneLayer
    let sceneStore: SceneStore
    let viewModel: PreviewViewModel

    @State private var startPosition: CGPoint = .zero

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                sceneStore.selectLayer(layer.id)
                if startPosition == .zero {
                    startPosition = layer.position
                }
                let newPos = CGPoint(
                    x: startPosition.x + value.translation.width,
                    y: startPosition.y + value.translation.height
                )
                let bounds = viewModel.sceneBounds
                sceneStore.dragLayer(withID: layer.id, to: newPos, sceneBounds: bounds)
                if let updated = sceneStore.layer(withID: layer.id) {
                    viewModel.updateEdgeDeleteForDraggedLayer(updated)
                }
            }
            .onEnded { value in
                let newPos = CGPoint(
                    x: startPosition.x + value.translation.width,
                    y: startPosition.y + value.translation.height
                )
                startPosition = .zero
                let bounds = viewModel.sceneBounds
                sceneStore.endDrag(layerID: layer.id, center: newPos, sceneBounds: bounds)
                viewModel.cancelEdgeDeleteIfNeeded()
            }
    }

    var body: some View {
        VStack {
            if layer.isSelected {
                TextField("Write something...", text: Binding(
                    get: { layer.title },
                    set: { sceneStore.updateNoteText(layerID: layer.id, text: $0) }
                ), axis: .vertical)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.black.opacity(0.85))
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .padding(12)
            } else {
                Text(layer.title.isEmpty ? "Write something..." : layer.title)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(layer.title.isEmpty ? .black.opacity(0.4) : .black.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(12)
            }
        }
        .frame(width: layer.size.width, height: layer.size.height)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 254/255, green: 224/255, blue: 125/255))
                .opacity(0.9)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(layer.isSelected ? Color.blue.opacity(0.6) : Color.black.opacity(0.1), lineWidth: layer.isSelected ? 2 : 1)
        )
        .overlay(
            SelectedLayerOverlay(layer: layer, sceneStore: sceneStore, viewModel: viewModel)
        )
        .overlay(
            Group {
                if layer.isBeingRemoved {
                    Text("Release to remove")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(6)
                }
            }
        )
        .overlay(
            Group {
                if viewModel.vanishHoldingLayerIDs.contains(layer.id) {
                    ProgressCircleOverlay(duration: OnboardingThresholds.vanishHoldDuration)
                }
            }
        )
        .opacity(layer.isBeingRemoved ? 0.4 : 1.0)
        .saturation(layer.isBeingRemoved ? 0.2 : 1.0)
        .gesture(dragGesture)
        .onTapGesture {
            sceneStore.selectLayer(layer.id)
        }
        .disintegrationEffect(isDeleted: viewModel.disintegratedLayerIDs.contains(layer.id), targetOffset: viewModel.disintegrationTargetOffset(for: layer))
    }
}

struct ImageCardView: View {
    let layer: SceneLayer
    let sceneStore: SceneStore
    let viewModel: PreviewViewModel

    @State private var startPosition: CGPoint = .zero

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                sceneStore.selectLayer(layer.id)
                if startPosition == .zero {
                    startPosition = layer.position
                }
                let newPos = CGPoint(
                    x: startPosition.x + value.translation.width,
                    y: startPosition.y + value.translation.height
                )
                let bounds = viewModel.sceneBounds
                sceneStore.dragLayer(withID: layer.id, to: newPos, sceneBounds: bounds)
                if let updated = sceneStore.layer(withID: layer.id) {
                    viewModel.updateEdgeDeleteForDraggedLayer(updated)
                }
            }
            .onEnded { value in
                let newPos = CGPoint(
                    x: startPosition.x + value.translation.width,
                    y: startPosition.y + value.translation.height
                )
                startPosition = .zero
                let bounds = viewModel.sceneBounds
                sceneStore.endDrag(layerID: layer.id, center: newPos, sceneBounds: bounds)
                viewModel.cancelEdgeDeleteIfNeeded()
            }
    }

    var body: some View {
        Group {
            if let imageURL = layer.imageURL,
               let nsImage = NSImage(contentsOf: imageURL) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.6))
                    Text(layer.title)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 8)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.3))
            }
        }
        .frame(width: layer.size.width, height: layer.size.height)
        .background(
            layer.imageURL != nil ? AnyView(Color.clear) : AnyView(Rectangle().fill(.regularMaterial))
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(layer.isSelected ? Color.blue.opacity(0.6) : (layer.imageURL != nil ? Color.clear : Color.black.opacity(0.1)), lineWidth: layer.isSelected ? 2 : 1)
        )
        .overlay(
            SelectedLayerOverlay(layer: layer, sceneStore: sceneStore, viewModel: viewModel)
        )
        .overlay(
            Group {
                if layer.isBeingRemoved {
                    Text("Release to remove")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(6)
                }
            }
        )
        .overlay(
            Group {
                if viewModel.vanishHoldingLayerIDs.contains(layer.id) {
                    ProgressCircleOverlay(duration: OnboardingThresholds.vanishHoldDuration)
                }
            }
        )
        .opacity(layer.isBeingRemoved ? 0.4 : 1.0)
        .saturation(layer.isBeingRemoved ? 0.2 : 1.0)
        .gesture(dragGesture)
        .onTapGesture {
            sceneStore.selectLayer(layer.id)
        }
        .disintegrationEffect(isDeleted: viewModel.disintegratedLayerIDs.contains(layer.id), targetOffset: viewModel.disintegrationTargetOffset(for: layer))
    }
}

struct DefaultCardView: View {
    let layer: SceneLayer
    let sceneStore: SceneStore
    let viewModel: PreviewViewModel

    @State private var startPosition: CGPoint = .zero

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                sceneStore.selectLayer(layer.id)
                if startPosition == .zero {
                    startPosition = layer.position
                }
                let newPos = CGPoint(
                    x: startPosition.x + value.translation.width,
                    y: startPosition.y + value.translation.height
                )
                let bounds = viewModel.sceneBounds
                sceneStore.dragLayer(withID: layer.id, to: newPos, sceneBounds: bounds)
                if let updated = sceneStore.layer(withID: layer.id) {
                    viewModel.updateEdgeDeleteForDraggedLayer(updated)
                }
            }
            .onEnded { value in
                let newPos = CGPoint(
                    x: startPosition.x + value.translation.width,
                    y: startPosition.y + value.translation.height
                )
                startPosition = .zero
                let bounds = viewModel.sceneBounds
                sceneStore.endDrag(layerID: layer.id, center: newPos, sceneBounds: bounds)
                viewModel.cancelEdgeDeleteIfNeeded()
            }
    }

    var body: some View {
        VStack {
            Text(layer.title)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.white)
                .padding(8)
                .multilineTextAlignment(.center)
        }
        .frame(width: layer.size.width > 0 ? layer.size.width : 150,
               height: layer.size.height > 0 ? layer.size.height : 120)
        .background(Color.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(layer.isSelected ? Color.blue.opacity(0.6) : Color.black.opacity(0.1), lineWidth: layer.isSelected ? 2 : 1)
        )
        .overlay(
            SelectedLayerOverlay(layer: layer, sceneStore: sceneStore, viewModel: viewModel)
        )
        .overlay(
            Group {
                if layer.isBeingRemoved {
                    Text("Release to remove")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(6)
                }
            }
        )
        .opacity(layer.isBeingRemoved ? 0.4 : 1.0)
        .saturation(layer.isBeingRemoved ? 0.2 : 1.0)
        .overlay(
            Group {
                if viewModel.vanishHoldingLayerIDs.contains(layer.id) {
                    ProgressCircleOverlay(duration: OnboardingThresholds.vanishHoldDuration)
                }
            }
        )
        .gesture(dragGesture)
        .onTapGesture {
            sceneStore.selectLayer(layer.id)
        }
        .disintegrationEffect(isDeleted: viewModel.disintegratedLayerIDs.contains(layer.id), targetOffset: viewModel.disintegrationTargetOffset(for: layer))
    }
}

struct SelectedLayerOverlay: View {
    let layer: SceneLayer
    let sceneStore: SceneStore
    let viewModel: PreviewViewModel
    private var sceneBounds: CGRect {
        viewModel.sceneBounds
    }

    @State private var startSize: CGSize = .zero
    @State private var startPosition: CGPoint = .zero

    private func resizeTutorialSquare(
        handle: ResizeHandle,
        translation: CGSize
    ) {
        let signs = handle.signs
        let projectedDelta = ((translation.width * signs.x) + (translation.height * signs.y)) / 2.0
        let startSide = max(startSize.width, startSize.height)
        let unclampedSide = startSide + projectedDelta
        let side = max(SceneLimits.minTutorialSize.width, unclampedSide)

        let appliedDelta = side - startSide

        let newPosition = CGPoint(
            x: startPosition.x + (appliedDelta * signs.x / 2.0),
            y: startPosition.y + (appliedDelta * signs.y / 2.0)
        )

        sceneStore.resizeLayer(
            withID: layer.id,
            size: CGSize(width: side, height: side),
            position: newPosition,
            sceneBounds: sceneBounds
        )

        let scale = side / 150.0
        viewModel.handleOnboardingEvent(.observe(grabbing: false, scale: scale))
    }

    var body: some View {
        ZStack {
            if (layer.isSelected || layer.kind == .tutorial) && !layer.isBeingRemoved {
                // Dashed outline
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.blue.opacity(0.8), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                
                let isGrabStep = viewModel.onboardingStep == .grabTutorial || viewModel.onboardingStep == .grabSuccess
                if layer.kind != .tutorial || !isGrabStep {
                    // Top-left resize handle
                    VStack {
                        HStack {
                            ZStack {
                                Color.clear
                                    .frame(width: 72, height: 72)
                                    .contentShape(Rectangle())
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 14, height: 14)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                    .shadow(radius: 2)
                            }
                            .frame(width: 72, height: 72)
                            .padding(-33) // position it exactly on the corner
                            .gesture(
                                    DragGesture(minimumDistance: 1)
                                        .onChanged { value in
                                            if startSize == .zero {
                                                startSize = layer.size
                                                startPosition = layer.position
                                                sceneStore.beginResize(withID: layer.id)
                                            }

                                            if layer.kind == .tutorial {
                                                resizeTutorialSquare(
                                                    handle: .topLeft,
                                                    translation: value.translation
                                                )
                                            } else {
                                                let deltaW = -value.translation.width
                                                let deltaH = -value.translation.height
                                                let newW = startSize.width + deltaW
                                                let newH = startSize.height + deltaH

                                                let newPos = CGPoint(
                                                    x: startPosition.x - deltaW / 2,
                                                    y: startPosition.y - deltaH / 2
                                                )
                                                sceneStore.resizeLayer(withID: layer.id, size: CGSize(width: newW, height: newH), position: newPos, sceneBounds: sceneBounds)
                                            }
                                        }
                                        .onEnded { value in
                                            let finalSize = sceneStore.layer(withID: layer.id)?.size ?? layer.size
                                            sceneStore.endResize(withID: layer.id, finalSize: finalSize)
                                            startSize = .zero
                                            startPosition = .zero

                                            if layer.kind == .tutorial {
                                                let scale = finalSize.width / 150.0
                                                viewModel.handleOnboardingEvent(.observe(grabbing: false, scale: scale))
                                            }
                                        }
                                )
                            Spacer()
                        }
                        Spacer()
                    }

                    // Bottom-right resize handle
                    VStack {
                        Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            Color.clear
                                .frame(width: 72, height: 72)
                                .contentShape(Rectangle())
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 14, height: 14)
                                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                .shadow(radius: 2)
                        }
                        .frame(width: 72, height: 72)
                        .padding(-33) // position it exactly on the corner
                        .gesture(
                                DragGesture(minimumDistance: 1)
                                    .onChanged { value in
                                        if startSize == .zero {
                                            startSize = layer.size
                                            startPosition = layer.position
                                            sceneStore.beginResize(withID: layer.id)
                                        }

                                        if layer.kind == .tutorial {
                                            resizeTutorialSquare(
                                                handle: .bottomRight,
                                                translation: value.translation
                                            )
                                        } else {
                                            let deltaW = value.translation.width
                                            let deltaH = value.translation.height
                                            let newW = startSize.width + deltaW
                                            let newH = startSize.height + deltaH

                                            let newPos = CGPoint(
                                                x: startPosition.x + deltaW / 2,
                                                y: startPosition.y + deltaH / 2
                                            )
                                            sceneStore.resizeLayer(withID: layer.id, size: CGSize(width: newW, height: newH), position: newPos, sceneBounds: sceneBounds)
                                        }
                                    }
                                    .onEnded { value in
                                        let finalSize = sceneStore.layer(withID: layer.id)?.size ?? layer.size
                                        sceneStore.endResize(withID: layer.id, finalSize: finalSize)
                                        startSize = .zero
                                        startPosition = .zero

                                        if layer.kind == .tutorial {
                                            let scale = finalSize.width / 150.0
                                            viewModel.handleOnboardingEvent(.observe(grabbing: false, scale: scale))
                                        }
                                    }
                            )
                    }
                }
                }
            }
        }
    }
}

struct TutorialSceneCardView: View {
    let layer: SceneLayer
    let sceneStore: SceneStore
    let viewModel: PreviewViewModel

    @State private var startPosition: CGPoint = .zero
    @State private var snapEffect: Bool = false

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                sceneStore.selectLayer(layer.id)
                if startPosition == .zero {
                    startPosition = layer.position
                }
                let newPos = CGPoint(
                    x: startPosition.x + value.translation.width,
                    y: startPosition.y + value.translation.height
                )
                let bounds = viewModel.sceneBounds
                sceneStore.dragLayer(withID: layer.id, to: newPos, sceneBounds: bounds)

                if viewModel.onboardingStep == .grabTutorial {
                    let scale = layer.size.width / 150.0
                    viewModel.handleOnboardingEvent(.observe(grabbing: true, scale: scale))
                }
            }
            .onEnded { value in
                let newPos = CGPoint(
                    x: startPosition.x + value.translation.width,
                    y: startPosition.y + value.translation.height
                )
                startPosition = .zero
                let bounds = viewModel.sceneBounds
                sceneStore.endDrag(layerID: layer.id, center: newPos, sceneBounds: bounds)

                if viewModel.onboardingStep == .grabTutorial {
                    let scale = layer.size.width / 150.0
                    viewModel.handleOnboardingEvent(.observe(grabbing: true, scale: scale))
                    viewModel.handleOnboardingEvent(.observe(grabbing: false, scale: scale))
                }
            }
    }

    private var tutorialIcon: String {
        switch viewModel.onboardingStep {
        case .grabTutorial, .grabSuccess: return "hand.draw.fill"
        case .zoomTutorial, .zoomSuccess: return "arrow.up.backward.and.arrow.down.forward"
        case .shrinkTutorial, .shrinkHold: return "arrow.down.right.and.arrow.up.left"
        default: return "hand.draw.fill"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: tutorialIcon)
                .font(.system(size: 32))
                .foregroundColor(.white)
            Text(layer.title)
                .font(.system(.body, design: .rounded).weight(.bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(width: layer.size.width, height: layer.size.height)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(gradient: Gradient(colors: [Color.pink, Color.pink.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(layer.isSelected ? Color.blue.opacity(0.8) : Color.white.opacity(0.4), lineWidth: 2)
        )
        .overlay(
            Group {
                if viewModel.onboardingStep == .shrinkHold {
                    ProgressCircleOverlay(duration: OnboardingThresholds.vanishHoldDuration)
                }
            }
        )
        .overlay(
            SelectedLayerOverlay(layer: layer, sceneStore: sceneStore, viewModel: viewModel)
        )
        .opacity(layer.isBeingRemoved ? 0.4 : 1.0)
        .saturation(layer.isBeingRemoved ? 0.2 : 1.0)
        .gesture(dragGesture)
        .onTapGesture {
            sceneStore.selectLayer(layer.id)
        }
        .disintegrationEffect(isDeleted: snapEffect, targetOffset: viewModel.disintegrationTargetOffset(for: layer))
        .onChange(of: viewModel.onboardingStep) { _, newStep in
            if newStep == .virtualCameraPrompt {
                snapEffect = true
            }
        }
    }
}

// Onboarding Welcome Card
struct OnboardingWelcomeCard: View {
    let viewModel: PreviewViewModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundColor(.yellow)
            Text("Welcome to AirStage")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(.white)
            Text("Screen sharing you can touch.\nLet’s teach your hands a few tricks.")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
            Button(action: {
                viewModel.handleOnboardingEvent(.showMeTapped)
            }) {
                Text("Show me")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(20)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
        .frame(width: 320)
    }
}

struct VirtualCameraPromptCard: View {
    let viewModel: PreviewViewModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.badge.checkmark")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.green)

            Text("You’re ready")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(.white)

            Text("AirStage can now appear as a camera source in calls, recordings, and live streams. Turn it on when you’re ready.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button("Not now") {
                    viewModel.handleOnboardingEvent(.virtualCameraPromptDismissed)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.14))
                .foregroundStyle(.white)
                .clipShape(Capsule())

                Button("Turn on AirStage") {
                    viewModel.handleOnboardingEvent(.virtualCameraTurnOnTapped)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white)
                .foregroundStyle(.black)
                .clipShape(Capsule())
            }
        }
        .padding(24)
        .frame(width: 360)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(radius: 18)
    }
}

// Onboarding Instruction Pill
struct OnboardingInstructionPill: View {
    let step: OnboardingStep
    let viewModel: PreviewViewModel

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                    Text(bodyText)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                Button(action: {
                    viewModel.handleOnboardingEvent(.skipTapped)
                }) {
                    Text("Skip")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(radius: 8)
            .frame(width: 360)
            .padding(.bottom, 20)
        }
    }

    private var title: String {
        switch step {
        case .grabTutorial: return "Grab it"
        case .zoomTutorial: return "Zoom it"
        case .shrinkTutorial, .shrinkHold: return "Make it vanish"
        default: return ""
        }
    }

    private var bodyText: String {
        switch step {
        case .grabTutorial: return "Drag the card and move it around."
        case .zoomTutorial: return "Drag a corner handle to make it bigger."
        case .shrinkTutorial, .shrinkHold: return "Shrink it very small and hold, or drag it outside."
        default: return ""
        }
    }
}

// Onboarding Success Toast
struct OnboardingSuccessToast: View {
    let step: OnboardingStep
    let viewModel: PreviewViewModel

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 24))
                Text(successLabel)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                Spacer()
                if step != .vanishSuccess {
                    Button(action: {
                        viewModel.handleOnboardingEvent(.continueTapped)
                    }) {
                        Text("Continue")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(radius: 8)
            .frame(width: 260)
            .padding(.bottom, 20)
        }
    }

    private var successLabel: String {
        switch step {
        case .grabSuccess: return "Nice!"
        case .zoomSuccess: return "Well done!"
        case .vanishSuccess: return "You’re ready"
        default: return "Amazing!"
        }
    }
}

struct PreviewView: View {
    @ObservedObject var sceneStore: SceneStore
    @ObservedObject var viewModel: PreviewViewModel

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.clear

            // Render all layers
            ForEach(sceneStore.layers) { layer in
                switch layer.kind {
                case .note:
                    StickyNoteView(layer: layer, sceneStore: sceneStore, viewModel: viewModel)
                        .position(layer.position)
                case .image:
                    ImageCardView(layer: layer, sceneStore: sceneStore, viewModel: viewModel)
                        .position(layer.position)
                case .tutorial:
                    TutorialSceneCardView(layer: layer, sceneStore: sceneStore, viewModel: viewModel)
                        .position(layer.position)
                default:
                    DefaultCardView(layer: layer, sceneStore: sceneStore, viewModel: viewModel)
                        .position(layer.position)
                }

                if viewModel.disintegratedLayerIDs.contains(layer.id) {
                    let side = viewModel.edgeDeleteState.side ?? .left
                    EmitterView(side: side, isActive: true)
                        .frame(width: layer.size.width, height: layer.size.height)
                        .position(layer.position)
                        .allowsHitTesting(false)
                }
            }

            // Onboarding Overlay Cards
            if viewModel.onboardingStep == .welcome {
                OnboardingWelcomeCard(viewModel: viewModel)
            } else if viewModel.onboardingStep == .virtualCameraPrompt {
                VirtualCameraPromptCard(viewModel: viewModel)
            } else if viewModel.onboardingStep == .grabTutorial || viewModel.onboardingStep == .zoomTutorial || viewModel.onboardingStep == .shrinkTutorial || viewModel.onboardingStep == .shrinkHold {
                OnboardingInstructionPill(step: viewModel.onboardingStep, viewModel: viewModel)
            } else if viewModel.onboardingStep == .grabSuccess || viewModel.onboardingStep == .zoomSuccess || viewModel.onboardingStep == .vanishSuccess {
                OnboardingSuccessToast(step: viewModel.onboardingStep, viewModel: viewModel)
            }

            if let side = viewModel.edgeDeleteState.side, let frame = viewModel.draggedCardFrame {
                if #available(macOS 26, iOS 26, *) {
                    EdgeDeleteBadge(side: side, state: viewModel.edgeDeleteState)
                        .position(EdgeDeleteState.badgePosition(side: side, cardFrame: frame, sceneBounds: viewModel.sceneBounds))
                        .zIndex(850)
                } else {
                    EdgeDeleteZoneView(
                        side: side,
                        state: viewModel.edgeDeleteState
                    )
                    .position(edgeDeleteZonePosition(side: side, sceneBounds: viewModel.sceneBounds))
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(850)
                }
            }

            if viewModel.isDebugOverlayVisible {
                DebugLayer(viewModel: viewModel)
                    .allowsHitTesting(false)
                    .zIndex(900)
            }
            
            // Invisible toggle for debug overlay
            Button("") {
                viewModel.toggleDebugOverlay()
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
            .opacity(0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            // Visible debug toggle in dev/debug mode
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.toggleDebugOverlay()
                    }) {
                        Image(systemName: viewModel.isDebugOverlayVisible ? "ladybug.fill" : "ladybug")
                            .foregroundColor(viewModel.isDebugOverlayVisible ? .green : .white.opacity(0.7))
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(viewModel.isDebugOverlayVisible ? "Hide debug coordinates" : "Show debug coordinates")
                    .help(viewModel.isDebugOverlayVisible ? "Hide debug coordinates" : "Show debug coordinates")
                    .padding()
                }
                Spacer()
            }
            .zIndex(1000)

            // Presenter Shelf Overlay
            if viewModel.presenterShelfStore.isVisible {
                PresenterShelfView(
                    store: viewModel.presenterShelfStore,
                    onPresent: { viewModel.presentSelectedShelfItem() },
                    onClose: { viewModel.hidePresenterShelf() }
                )
                .zIndex(950)
            }
            
            // Invisible toggle for Presenter Shelf
            Button("") {
                viewModel.togglePresenterShelf()
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
            .opacity(0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            // Quick-Add Toolbar Overlay (only when onboarding is completed or welcome card is not blocking)
            if viewModel.shouldShowQuickAddToolbar {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: { viewModel.togglePresenterShelf() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "rectangle.stack")
                                Text("Shelf")
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(6)
                        
                        Button(action: { viewModel.quickAddNote() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Note")
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(6)

                        Button(action: { viewModel.quickAddImage() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Image")
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(6)

                        Button(action: { viewModel.quickAddWindow() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Window")
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(6)

                        Button(action: { viewModel.quickAddPaste() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.clipboard")
                                Text("Paste from clipboard")
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(6)

                        Divider()
                            .frame(height: 16)
                            .background(Color.white.opacity(0.3))

                        Button(action: { viewModel.quickAddClear() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text("Clear")
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.7))
                        .cornerRadius(6)
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .padding(.bottom, 20)
                }
            }

            // Error Message Toast
            if let errorMsg = viewModel.toolbarErrorMessage {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        Text(errorMsg)
                            .foregroundColor(.white)
                    }
                    .font(.system(.footnote, design: .rounded).weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if viewModel.toolbarErrorMessage == errorMsg {
                            viewModel.toolbarErrorMessage = nil
                        }
                    }
                }
            }
        }
        .animation(.smooth(duration: 0.38), value: viewModel.presenterShelfStore.isVisible)
        .contentShape(Rectangle())
        .onHover { hovered in
            viewModel.setHovered(hovered)
        }

        .onDrop(of: [.fileURL, .image], isTargeted: nil) { providers in
            let importer = ImageImporter(store: sceneStore)
            let handler = DropPasteHandler(importer: importer)
            return handler.handleDrop(providers: providers) { result in
                if case .failure(let error) = result {
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = "Cannot Import Image"
                        alert.informativeText = error.errorDescription ?? "An unknown error occurred."
                        alert.alertStyle = .warning
                        alert.runModal()
                    }
                }
            }
        }
        .onAppear {
            viewModel.updateCanvasSize(proxy.size)
        }
        .onChange(of: proxy.size) { _, newSize in
            viewModel.updateCanvasSize(newSize)
        }
        }
    }

    private func edgeDeleteZonePosition(side: EdgeDeleteSide, sceneBounds: CGRect) -> CGPoint {
        let y = sceneBounds.midY
        switch side {
        case .left:
            return CGPoint(x: sceneBounds.minX + 48, y: y)
        case .right:
            return CGPoint(x: sceneBounds.maxX - 48, y: y)
        }
    }
}

@available(macOS 26, iOS 26, *)
struct EdgeDeleteBadge: View {
    let side: EdgeDeleteSide
    let state: EdgeDeleteState
    @Namespace private var glassNamespace

    private var isArmed: Bool {
        if case .armed = state { return true }
        if case .disintegrating = state { return true }
        return false
    }

    private var isVisible: Bool {
        state != .idle
    }

    @State private var pulse = false

    var body: some View {
        GlassEffectContainer(spacing: 16) {
            Image(systemName: isArmed ? "trash.fill" : "trash")
                .font(.system(size: isArmed ? 26 : 22, weight: .semibold))
                .foregroundStyle(.white)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: isArmed)
                .frame(width: isArmed ? 104 : 88, height: isArmed ? 104 : 88)
                .glassEffect(
                    isArmed
                        ? .regular.tint(.red.opacity(0.32)).interactive()
                        : .regular.interactive(),
                    in: Circle()
                )
                .glassEffectID("edgeDeleteBadge", in: glassNamespace)
        }
        .scaleEffect(isVisible ? 1.0 : 0.6)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.42, dampingFraction: 0.74), value: isArmed)
        .animation(.spring(response: 0.38, dampingFraction: 0.8), value: isVisible)
        .scaleEffect(state.isHoveringOnly ? (pulse ? 1.0 : 0.94) : 1.0)
        .animation(
            state.isHoveringOnly
                ? .easeInOut(duration: 1.3).repeatForever(autoreverses: true)
                : .default,
            value: pulse
        )
        .onAppear { pulse = true }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// Progress Circle Overlay for Shrink-to-Vanish
struct ProgressCircleOverlay: View {
    let duration: TimeInterval
    @State private var progress: CGFloat = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: progress)
            .stroke(Color.white, lineWidth: 6)
            .frame(width: 60, height: 60)
            .rotationEffect(.degrees(-90))
            .animation(.linear(duration: duration), value: progress)
            .onAppear {
                progress = 1.0
            }
    }
}
