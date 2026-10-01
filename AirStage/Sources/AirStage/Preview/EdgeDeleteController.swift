import Foundation
import CoreGraphics

public final class EdgeDeleteController: ObservableObject {
    public struct Configuration: Equatable {
        public var deleteZoneWidth: CGFloat = 96
        public var escapePadding: CGFloat = 32
        public var deleteDelay: TimeInterval = 1.5
        public var jitterTolerance: TimeInterval = 0.3
        public var disintegrationDuration: TimeInterval = 0.65

        public init() {}
    }

    @Published public private(set) var state: EdgeDeleteState = .idle

    public let configuration: Configuration
    private var armingTask: Task<Void, Never>?
    private var jitterTask: Task<Void, Never>?

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    deinit {
        let aTask = armingTask
        let jTask = jitterTask
        Task {
            aTask?.cancel()
            jTask?.cancel()
        }
    }

    @MainActor
    public func updateDraggedLayer(
        id: UUID,
        frame: CGRect,
        sceneBounds: CGRect,
        isAllowed: Bool,
        onDeleteReady: @escaping @MainActor (UUID, EdgeDeleteSide) -> Void
    ) {
        guard isAllowed else {
            cancel()
            return
        }

        let side = detectedSide(
            frame: frame,
            sceneBounds: sceneBounds,
            currentState: state
        )

        guard let side else {
            if state.layerID == id && state.isArmed {
                if jitterTask == nil {
                    jitterTask = Task { [weak self] in
                        guard let self else { return }
                        try? await Task.sleep(nanoseconds: UInt64(self.configuration.jitterTolerance * 1_000_000_000))
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            self.cancel()
                        }
                    }
                }
            } else {
                cancelIfTracking(id)
            }
            return
        }

        jitterTask?.cancel()
        jitterTask = nil

        switch state {
        case .idle:
            beginArming(side: side, layerID: id, onDeleteReady: onDeleteReady)

        case .arming(let currentSide, let currentID, _):
            if currentID != id || currentSide != side {
                cancel()
                beginArming(side: side, layerID: id, onDeleteReady: onDeleteReady)
            }

        case .disintegrating:
            break
        }
    }

    @MainActor
    public func cancel() {
        armingTask?.cancel()
        jitterTask?.cancel()
        armingTask = nil
        jitterTask = nil
        state = .idle
    }

    @MainActor
    public func markDisintegrating(layerID: UUID, side: EdgeDeleteSide) {
        armingTask?.cancel()
        jitterTask?.cancel()
        state = .disintegrating(side: side, layerID: layerID)
    }

    @MainActor
    public func forceArmForTesting(id: UUID, side: EdgeDeleteSide) {
        armingTask?.cancel()
        jitterTask?.cancel()
        state = .arming(side: side, layerID: id, startedAt: Date())
    }

    @MainActor
    public func forceDeleteReadyForTesting(id: UUID, side: EdgeDeleteSide, onDeleteReady: @escaping @MainActor (UUID, EdgeDeleteSide) -> Void) {
        armingTask?.cancel()
        jitterTask?.cancel()
        state = .arming(side: side, layerID: id, startedAt: Date())
        onDeleteReady(id, side)
    }

    @MainActor
    private func beginArming(
        side: EdgeDeleteSide,
        layerID: UUID,
        onDeleteReady: @escaping @MainActor (UUID, EdgeDeleteSide) -> Void
    ) {
        armingTask?.cancel()
        jitterTask?.cancel()

        state = .arming(side: side, layerID: layerID, startedAt: Date())

        armingTask = Task { [weak self] in
            guard let self else { return }

            try? await Task.sleep(nanoseconds: UInt64(configuration.deleteDelay * 1_000_000_000))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard case .arming(let side, let layerID, _) = self.state else { return }
                onDeleteReady(layerID, side)
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
