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
                let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
                sceneStore.dragLayer(withID: layer.id, to: newPos, sceneBounds: bounds)
            }
            .onEnded { value in
                let newPos = CGPoint(
                    x: startPosition.x + value.translation.width,
                    y: startPosition.y + value.translation.height
                )
                startPosition = .zero
                let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
                sceneStore.endDrag(layerID: layer.id, center: newPos, sceneBounds: bounds)
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
        .opacity(layer.isBeingRemoved ? 0.4 : 1.0)
        .saturation(layer.isBeingRemoved ? 0.2 : 1.0)
        .gesture(dragGesture)
        .onTapGesture {
            sceneStore.selectLayer(layer.id)
        }
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
                let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
                sceneStore.dragLayer(withID: layer.id, to: newPos, sceneBounds: bounds)
            }
            .onEnded { value in
                let newPos = CGPoint(
                    x: startPosition.x + value.translation.width,
                    y: startPosition.y + value.translation.height
                )
                startPosition = .zero
                let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
                sceneStore.endDrag(layerID: layer.id, center: newPos, sceneBounds: bounds)
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
        .background(.regularMaterial)
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
        .gesture(dragGesture)
        .onTapGesture {
            sceneStore.selectLayer(layer.id)
        }
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
                let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
                sceneStore.dragLayer(withID: layer.id, to: newPos, sceneBounds: bounds)
            }
            .onEnded { value in
                let newPos = CGPoint(
                    x: startPosition.x + value.translation.width,
                    y: startPosition.y + value.translation.height
                )
                startPosition = .zero
                let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
                sceneStore.endDrag(layerID: layer.id, center: newPos, sceneBounds: bounds)
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
        .gesture(dragGesture)
        .onTapGesture {
            sceneStore.selectLayer(layer.id)
        }
    }
}

struct SelectedLayerOverlay: View {
    let layer: SceneLayer
    let sceneStore: SceneStore
    let viewModel: PreviewViewModel
    let sceneBounds: CGRect = CGRect(x: 0, y: 0, width: 640, height: 480)

    @State private var startSize: CGSize = .zero
    @State private var startPosition: CGPoint = .zero

    var body: some View {
        ZStack {
            if layer.isSelected && !layer.isBeingRemoved {
                // Dashed outline
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.blue.opacity(0.8), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                
                // Bottom-right resize handle
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                            .shadow(radius: 2)
                            .padding(-4) // position it exactly on the corner
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 1)
                                    .onChanged { value in
                                        if startSize == .zero {
                                            startSize = layer.size
                                            startPosition = layer.position
                                            sceneStore.beginResize(withID: layer.id)
                                        }
                                        let deltaW = value.translation.width
                                        let deltaH = value.translation.height
                                        let newW = startSize.width + deltaW
                                        let newH = startSize.height + deltaH

                                        let newPos = CGPoint(
                                            x: startPosition.x + deltaW / 2,
                                            y: startPosition.y + deltaH / 2
                                        )
                                        sceneStore.resizeLayer(withID: layer.id, size: CGSize(width: newW, height: newH), position: newPos, sceneBounds: sceneBounds)

                                        if layer.kind == .tutorial {
                                            let currentW = max(SceneLimits.minTutorialSize.width, newW)
                                            let scale = currentW / 150.0
                                            viewModel.handleOnboardingEvent(.tutorialItemScaled(scale: scale))
                                        }
                                    }
                                    .onEnded { value in
                                        let finalSize = sceneStore.layer(withID: layer.id)?.size ?? layer.size
                                        sceneStore.endResize(withID: layer.id, finalSize: finalSize)
                                        startSize = .zero
                                        startPosition = .zero

                                        if layer.kind == .tutorial {
                                            let scale = finalSize.width / 150.0
                                            viewModel.handleOnboardingEvent(.tutorialItemScaled(scale: scale))
                                        }
                                    }
                            )
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
                let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
                sceneStore.dragLayer(withID: layer.id, to: newPos, sceneBounds: bounds)

                if viewModel.onboardingStep == .grabTutorial {
                    let dist = sqrt(pow(newPos.x - 320, 2) + pow(newPos.y - 240, 2))
                    viewModel.handleOnboardingEvent(.tutorialItemMoved(distance: dist))
                }
            }
            .onEnded { value in
                let newPos = CGPoint(
                    x: startPosition.x + value.translation.width,
                    y: startPosition.y + value.translation.height
                )
                startPosition = .zero
                let bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
                sceneStore.endDrag(layerID: layer.id, center: newPos, sceneBounds: bounds)

                if viewModel.onboardingStep == .grabTutorial {
                    let dist = sqrt(pow(newPos.x - 320, 2) + pow(newPos.y - 240, 2))
                    viewModel.handleOnboardingEvent(.tutorialItemMoved(distance: dist))
                }
            }
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.draw.fill")
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
            SelectedLayerOverlay(layer: layer, sceneStore: sceneStore, viewModel: viewModel)
        )
        .opacity(layer.isBeingRemoved ? 0.4 : 1.0)
        .saturation(layer.isBeingRemoved ? 0.2 : 1.0)
        .gesture(dragGesture)
        .onTapGesture {
            sceneStore.selectLayer(layer.id)
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

// Virtual Camera Prompt Card
struct VirtualCameraPromptCard: View {
    let viewModel: PreviewViewModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.fill")
                .font(.system(size: 36))
                .foregroundColor(.blue)
            Text("You’ve got the moves")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(.white)
            Text("Turn on AirStage’s virtual camera to use it in video calls, screen recordings, and live streams.")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Button(action: {
                    viewModel.handleOnboardingEvent(.virtualCameraPromptDismissed)
                }) {
                    Text("Maybe later")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)

                Button(action: {
                    viewModel.handleOnboardingEvent(.virtualCameraTurnOnTapped)
                }) {
                    Text("Turn it on")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
        .frame(width: 320)
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
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                    Text(bodyText)
                        .font(.system(.caption, design: .rounded))
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
            .frame(width: 340)
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
                    .font(.system(size: 20))
                Text(successLabel)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
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
        default: return "Amazing!"
        }
    }
}

struct PreviewView: View {
    @ObservedObject var sceneStore: SceneStore
    @ObservedObject var viewModel: PreviewViewModel

    @State private var showVanishSuccess: Bool = false

    var body: some View {
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
            }

            // Onboarding Overlay Cards
            if viewModel.onboardingStep == .welcome {
                OnboardingWelcomeCard(viewModel: viewModel)
            } else if viewModel.onboardingStep == .virtualCameraPrompt {
                VirtualCameraPromptCard(viewModel: viewModel)
            } else if viewModel.onboardingStep == .grabTutorial || viewModel.onboardingStep == .zoomTutorial || viewModel.onboardingStep == .shrinkTutorial || viewModel.onboardingStep == .shrinkHold {
                OnboardingInstructionPill(step: viewModel.onboardingStep, viewModel: viewModel)
            } else if viewModel.onboardingStep == .grabSuccess || viewModel.onboardingStep == .zoomSuccess {
                OnboardingSuccessToast(step: viewModel.onboardingStep, viewModel: viewModel)
            }

            if showVanishSuccess {
                OnboardingSuccessToast(step: .vanishSuccess, viewModel: viewModel)
            }

            // Quick-Add Toolbar Overlay (only when onboarding is completed or welcome card is not blocking)
            if viewModel.isToolbarVisible && (viewModel.onboardingStep == .completed || viewModel.onboardingStep == .welcome) {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
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
                                Text("Paste")
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
        .contentShape(Rectangle())
        .onHover { hovered in
            viewModel.setHovered(hovered)
        }
        .onChange(of: viewModel.onboardingStep) { _, newStep in
            if newStep == .virtualCameraPrompt {
                showVanishSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    showVanishSuccess = false
                }
            }
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
    }
}
