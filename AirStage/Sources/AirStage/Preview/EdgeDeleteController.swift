import Foundation
import CoreGraphics

public final class EdgeDeleteController: ObservableObject {
    public struct Configuration: Equatable {
        public var deleteZoneWidth: CGFloat = 96
        public var escapePadding: CGFloat = 32
        public var revealDelay: TimeInterval = 2.0
        public var deleteDelayAfterReveal: TimeInterval = 1.0
        public var disintegrationDuration: TimeInterval = 0.65

        public init() {}
    }

    @Published public private(set) var state: EdgeDeleteState = .idle

    private let configuration: Configuration
    private var revealTask: Task<Void, Never>?
    private var deleteTask: Task<Void, Never>?

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    deinit {
        // Since deinit can be called on a background thread during teardown or cleanup,
        // cancel the tasks from Task or manually. Note: tasks can be cancelled without @MainActor.
        let rTask = revealTask
        let dTask = deleteTask
        Task {
            rTask?.cancel()
            dTask?.cancel()
        }
    }

    @MainActor
    public func updateDraggedLayer(
        id: UUID,
        frame: CGRect,
        sceneBounds: CGRect,
        isOnboardingCompleted: Bool,
        isTutorialLayer: Bool,
        onDeleteReady: @escaping @MainActor (UUID, EdgeDeleteSide) -> Void
    ) {
        guard isOnboardingCompleted, !isTutorialLayer else {
            cancel()
            return
        }

        let side = detectedSide(
            frame: frame,
            sceneBounds: sceneBounds,
            currentState: state
        )

        guard let side else {
            cancelIfTracking(id)
            return
        }

        switch state {
        case .idle:
            beginHovering(side: side, layerID: id, onDeleteReady: onDeleteReady)

        case .hovering(let currentSide, let currentID, _):
            if currentID != id || currentSide != side {
                cancel()
                beginHovering(side: side, layerID: id, onDeleteReady: onDeleteReady)
            }

        case .armed(let currentSide, let currentID, _):
            if currentID != id || currentSide != side {
                cancel()
                beginHovering(side: side, layerID: id, onDeleteReady: onDeleteReady)
            }

        case .disintegrating:
            break
        }
    }

    @MainActor
    public func cancel() {
        revealTask?.cancel()
        deleteTask?.cancel()
        revealTask = nil
        deleteTask = nil
        state = .idle
    }

    @MainActor
    public func markDisintegrating(layerID: UUID, side: EdgeDeleteSide) {
        revealTask?.cancel()
        deleteTask?.cancel()
        state = .disintegrating(side: side, layerID: layerID)
    }

    // Test helpers to bypass asynchronous Task delays
    @MainActor
    public func forceArmForTesting(id: UUID, side: EdgeDeleteSide) {
        revealTask?.cancel()
        deleteTask?.cancel()
        state = .armed(side: side, layerID: id, armedAt: Date())
    }

    @MainActor
    public func forceDeleteReadyForTesting(id: UUID, side: EdgeDeleteSide, onDeleteReady: @escaping @MainActor (UUID, EdgeDeleteSide) -> Void) {
        revealTask?.cancel()
        deleteTask?.cancel()
        state = .armed(side: side, layerID: id, armedAt: Date())
        onDeleteReady(id, side)
    }

    @MainActor
    private func beginHovering(
        side: EdgeDeleteSide,
        layerID: UUID,
        onDeleteReady: @escaping @MainActor (UUID, EdgeDeleteSide) -> Void
    ) {
        revealTask?.cancel()
        deleteTask?.cancel()

        state = .hovering(side: side, layerID: layerID, enteredAt: Date())

        revealTask = Task { [weak self] in
            guard let self else { return }

            try? await Task.sleep(nanoseconds: UInt64(configuration.revealDelay * 1_000_000_000))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard case .hovering(side, layerID, _) = self.state else { return }
                self.state = .armed(side: side, layerID: layerID, armedAt: Date())
            }

            self.deleteTask = Task { [weak self] in
                guard let self else { return }

                try? await Task.sleep(nanoseconds: UInt64(configuration.deleteDelayAfterReveal * 1_000_000_000))
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    guard case .armed(side, layerID, _) = self.state else { return }
                    onDeleteReady(layerID, side)
                }
            }
        }
    }

    @MainActor
    private func cancelIfTracking(_ id: UUID) {
        if state.layerID == id {
            cancel()
        }
    }

    @MainActor
    private func detectedSide(
        frame: CGRect,
        sceneBounds: CGRect,
        currentState: EdgeDeleteState
    ) -> EdgeDeleteSide? {
        let zone = configuration.deleteZoneWidth
        let escape = configuration.escapePadding

        let leftThreshold: CGFloat
        let rightThreshold: CGFloat

        // Hysteresis:
        // when already tracking, allow a little escape padding before canceling.
        if currentState.side != nil {
            leftThreshold = zone + escape
            rightThreshold = sceneBounds.maxX - zone - escape
        } else {
            leftThreshold = zone
            rightThreshold = sceneBounds.maxX - zone
        }

        if frame.minX <= leftThreshold {
            return .left
        }

        if frame.maxX >= rightThreshold {
            return .right
        }

        return nil
    }
}
