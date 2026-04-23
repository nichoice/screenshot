import CoreGraphics
import Foundation

struct CaptureSelection: Equatable {
    let start: CGPoint
    let end: CGPoint

    var normalizedRect: CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }
}

enum CaptureSelectionHandle: CaseIterable {
    case topLeading
    case top
    case topTrailing
    case leading
    case trailing
    case bottomLeading
    case bottom
    case bottomTrailing
}

enum CaptureOverlayInteractionAction: Equatable {
    case selectionUpdated(CGRect)
    case selectionConfirmed
}

struct CaptureOverlayInteractionState {
    var availableRect: CGRect = .infinite
    var stagedSelectionRect: CGRect?
    var hoveredWindowRect: CGRect?

    private var activeDrag: ActiveDrag?
    private var liveSelectionRect: CGRect?
    private let dragThreshold: CGFloat = 4
    private let minimumSelectionSize: CGFloat = 48

    private enum ActiveDrag {
        case definingSelection(start: CGPoint)
        case resizingSelection(handle: CaptureSelectionHandle, initialRect: CGRect, initialPoint: CGPoint)
        case movingSelection(initialRect: CGRect, initialPoint: CGPoint)
    }

    var selectionRect: CGRect? {
        liveSelectionRect ?? stagedSelectionRect
    }

    mutating func handleMouseDown(at point: CGPoint) {
        liveSelectionRect = nil
        if let stagedSelectionRect,
           let handle = selectionHandle(containing: point, in: stagedSelectionRect) {
            activeDrag = .resizingSelection(handle: handle, initialRect: stagedSelectionRect, initialPoint: point)
        } else if let stagedSelectionRect, stagedSelectionRect.contains(point) {
            activeDrag = .movingSelection(initialRect: stagedSelectionRect, initialPoint: point)
        } else {
            activeDrag = .definingSelection(start: point)
        }
    }

    mutating func handleMouseDragged(to point: CGPoint) -> [CaptureOverlayInteractionAction] {
        switch activeDrag {
        case let .definingSelection(start):
            guard hasExceededDragThreshold(from: start, to: point) else {
                return []
            }

            let rect = CaptureSelection(start: start, end: point).normalizedRect
            guard rect.width >= 1 || rect.height >= 1 else {
                return []
            }

            liveSelectionRect = rect
            return [.selectionUpdated(rect)]
        case let .resizingSelection(handle, initialRect, initialPoint):
            guard hasExceededDragThreshold(from: initialPoint, to: point) else {
                return []
            }

            let rect = resizedRect(
                from: initialRect,
                using: handle,
                translation: CGSize(width: point.x - initialPoint.x, height: point.y - initialPoint.y)
            )
            liveSelectionRect = rect
            return [.selectionUpdated(rect)]
        case let .movingSelection(initialRect, initialPoint):
            guard hasExceededDragThreshold(from: initialPoint, to: point) else {
                return []
            }

            let rect = clampedRect(
                initialRect.offsetBy(
                    dx: point.x - initialPoint.x,
                    dy: point.y - initialPoint.y
                )
            )
            liveSelectionRect = rect
            return [.selectionUpdated(rect)]
        case .none:
            return []
        }
    }

    mutating func handleMouseUp(at point: CGPoint) -> [CaptureOverlayInteractionAction] {
        defer {
            activeDrag = nil
            liveSelectionRect = nil
        }

        switch activeDrag {
        case .movingSelection:
            if let liveSelectionRect {
                stagedSelectionRect = liveSelectionRect
                return [.selectionUpdated(liveSelectionRect)]
            }

            if let stagedSelectionRect, stagedSelectionRect.contains(point) {
                return [.selectionConfirmed]
            }
        case .resizingSelection:
            if let liveSelectionRect {
                stagedSelectionRect = liveSelectionRect
                return [.selectionUpdated(liveSelectionRect)]
            }
        case .definingSelection:
            if let liveSelectionRect {
                stagedSelectionRect = liveSelectionRect
                return [.selectionUpdated(liveSelectionRect), .selectionConfirmed]
            }

            if let hoveredWindowRect, hoveredWindowRect.contains(point) {
                stagedSelectionRect = hoveredWindowRect
                return [.selectionUpdated(hoveredWindowRect), .selectionConfirmed]
            }
        case .none:
            break
        }

        return []
    }

    mutating func cancel() {
        activeDrag = nil
        liveSelectionRect = nil
        stagedSelectionRect = nil
        hoveredWindowRect = nil
    }

    private func hasExceededDragThreshold(from start: CGPoint, to end: CGPoint) -> Bool {
        hypot(end.x - start.x, end.y - start.y) >= dragThreshold
    }

    private func clampedRect(_ rect: CGRect) -> CGRect {
        guard !availableRect.isInfinite,
              !availableRect.isNull,
              !availableRect.isEmpty else {
            return rect
        }

        let clampedX = min(max(availableRect.minX, rect.minX), availableRect.maxX - rect.width)
        let clampedY = min(max(availableRect.minY, rect.minY), availableRect.maxY - rect.height)
        return CGRect(x: clampedX, y: clampedY, width: rect.width, height: rect.height)
    }

    private func resizedRect(from initialRect: CGRect, using handle: CaptureSelectionHandle, translation: CGSize) -> CGRect {
        var minX = initialRect.minX
        var maxX = initialRect.maxX
        var minY = initialRect.minY
        var maxY = initialRect.maxY

        switch handle {
        case .topLeading:
            minX += translation.width
            maxY += translation.height
        case .top:
            maxY += translation.height
        case .topTrailing:
            maxX += translation.width
            maxY += translation.height
        case .leading:
            minX += translation.width
        case .trailing:
            maxX += translation.width
        case .bottomLeading:
            minX += translation.width
            minY += translation.height
        case .bottom:
            minY += translation.height
        case .bottomTrailing:
            maxX += translation.width
            minY += translation.height
        }

        if maxX - minX < minimumSelectionSize {
            switch handle {
            case .topLeading, .leading, .bottomLeading:
                minX = maxX - minimumSelectionSize
            default:
                maxX = minX + minimumSelectionSize
            }
        }

        if maxY - minY < minimumSelectionSize {
            switch handle {
            case .bottomLeading, .bottom, .bottomTrailing:
                minY = maxY - minimumSelectionSize
            default:
                maxY = minY + minimumSelectionSize
            }
        }

        minX = max(availableRect.minX, minX)
        minY = max(availableRect.minY, minY)
        maxX = min(availableRect.maxX, maxX)
        maxY = min(availableRect.maxY, maxY)

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    func handleFrame(for handle: CaptureSelectionHandle, selectionRect: CGRect) -> CGRect {
        let point: CGPoint
        switch handle {
        case .topLeading:
            point = CGPoint(x: selectionRect.minX, y: selectionRect.maxY)
        case .top:
            point = CGPoint(x: selectionRect.midX, y: selectionRect.maxY)
        case .topTrailing:
            point = CGPoint(x: selectionRect.maxX, y: selectionRect.maxY)
        case .leading:
            point = CGPoint(x: selectionRect.minX, y: selectionRect.midY)
        case .trailing:
            point = CGPoint(x: selectionRect.maxX, y: selectionRect.midY)
        case .bottomLeading:
            point = CGPoint(x: selectionRect.minX, y: selectionRect.minY)
        case .bottom:
            point = CGPoint(x: selectionRect.midX, y: selectionRect.minY)
        case .bottomTrailing:
            point = CGPoint(x: selectionRect.maxX, y: selectionRect.minY)
        }

        return CGRect(x: point.x - 8, y: point.y - 8, width: 16, height: 16)
    }

    private func selectionHandle(containing point: CGPoint, in selectionRect: CGRect) -> CaptureSelectionHandle? {
        CaptureSelectionHandle.allCases.first {
            handleFrame(for: $0, selectionRect: selectionRect).insetBy(dx: -4, dy: -4).contains(point)
        }
    }
}

enum CaptureCoordinateConverter {
    static func localPointToGlobal(_ point: CGPoint, screenFrame: CGRect) -> CGPoint {
        CGPoint(x: screenFrame.minX + point.x, y: screenFrame.minY + point.y)
    }

    static func localAppKitRectToDisplay(_ rect: CGRect, containerHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.minX,
            y: containerHeight - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    static func localDisplayRectToAppKit(_ rect: CGRect, containerHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.minX,
            y: containerHeight - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    static func globalRectToLocal(_ rect: CGRect, screenFrame: CGRect) -> CGRect {
        rect.offsetBy(dx: -screenFrame.minX, dy: -screenFrame.minY)
    }

    static func appKitPointToCGWindowPoint(_ point: CGPoint, screenFrame: CGRect) -> CGPoint {
        CGPoint(x: point.x, y: screenFrame.maxY - point.y)
    }

    static func cgWindowRectToAppKitRect(_ rect: CGRect, screenFrame: CGRect) -> CGRect {
        CGRect(
            x: rect.minX,
            y: screenFrame.maxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    static func appKitRectToCGWindowRect(_ rect: CGRect, screenFrame: CGRect) -> CGRect {
        CGRect(
            x: rect.minX,
            y: screenFrame.maxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }
}
