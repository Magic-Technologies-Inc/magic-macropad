import AppKit
import SwiftUI

/// A horizontal scroller for the app chips backed by NSScrollView, so it handles
/// every input method: trackpad, mouse scroll wheel (vertical wheel maps to
/// horizontal), and click-and-drag panning.
struct ChipsScroller<Content: View>: NSViewRepresentable {
    var height: CGFloat
    @ViewBuilder var content: Content

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = HorizontalScrollView()
        scroll.drawsBackground = false
        scroll.hasHorizontalScroller = false
        scroll.hasVerticalScroller = false
        scroll.horizontalScrollElasticity = .allowed
        scroll.verticalScrollElasticity = .none
        scroll.contentView.postsBoundsChangedNotifications = false

        let hosting = NSHostingView(rootView: AnyView(content))
        hosting.frame = NSRect(x: 0, y: 0, width: hosting.fittingSize.width, height: height)
        scroll.documentView = hosting

        let pan = NSPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.pan(_:)))
        scroll.addGestureRecognizer(pan)
        context.coordinator.scroll = scroll
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let hosting = scroll.documentView as? NSHostingView<AnyView> else { return }
        hosting.rootView = AnyView(content)
        let width = hosting.fittingSize.width
        if abs(hosting.frame.width - width) > 0.5 || hosting.frame.height != height {
            hosting.frame = NSRect(x: 0, y: 0, width: width, height: height)
        }
    }

    final class Coordinator: NSObject {
        weak var scroll: NSScrollView?
        private var startX: CGFloat = 0

        @objc func pan(_ gesture: NSPanGestureRecognizer) {
            guard let scroll, let document = scroll.documentView else { return }
            let clip = scroll.contentView
            switch gesture.state {
            case .began:
                startX = clip.bounds.origin.x
            case .changed:
                let translation = gesture.translation(in: scroll)
                let maxX = max(0, document.frame.width - clip.bounds.width)
                let x = min(max(0, startX - translation.x), maxX)
                clip.scroll(to: NSPoint(x: x, y: clip.bounds.origin.y))
                scroll.reflectScrolledClipView(clip)
            default:
                break
            }
        }
    }
}

/// Maps vertical wheel scrolling to horizontal so a plain mouse wheel scrolls
/// the row; trackpad horizontal deltas pass through as usual.
private final class HorizontalScrollView: NSScrollView {
    override func scrollWheel(with event: NSEvent) {
        guard let document = documentView else { super.scrollWheel(with: event); return }
        let clip = contentView
        let maxX = max(0, document.frame.width - clip.bounds.width)
        guard maxX > 0 else { return }  // nothing to scroll

        // Prefer a real horizontal delta (trackpad); otherwise use vertical (wheel).
        let horizontal = event.scrollingDeltaX
        let raw = horizontal != 0 ? horizontal : event.scrollingDeltaY
        let factor: CGFloat = event.hasPreciseScrollingDeltas ? 1 : 8
        let x = min(max(0, clip.bounds.origin.x - raw * factor), maxX)
        clip.scroll(to: NSPoint(x: x, y: clip.bounds.origin.y))
        reflectScrolledClipView(clip)
    }
}
