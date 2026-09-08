import AppKit

/// A distinctive menu-bar glyph shaped like the K1: three stacked keys inside a
/// rounded body. Rendered as a template image so macOS tints it for the menu
/// bar's light/dark appearance and the active/selection state.
enum MenuBarIcon {
    static func image(connected: Bool) -> NSImage {
        let size = NSSize(width: 15, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            // Device body outline.
            let body = NSBezierPath(roundedRect: rect.insetBy(dx: 0.75, dy: 0.75),
                                    xRadius: 3.5, yRadius: 3.5)
            body.lineWidth = 1.2
            NSColor.black.setStroke()
            body.stroke()

            // Three keys stacked vertically.
            let keyWidth: CGFloat = 7
            let keyHeight: CGFloat = 3.2
            let x = (rect.width - keyWidth) / 2
            let ys: [CGFloat] = [rect.height - 5.4, rect.height - 9.4, rect.height - 13.4]
            for y in ys {
                let key = NSBezierPath(roundedRect: NSRect(x: x, y: y, width: keyWidth, height: keyHeight),
                                       xRadius: 1.1, yRadius: 1.1)
                if connected {
                    // Solid keys signal a live connection.
                    NSColor.black.setFill()
                    key.fill()
                } else {
                    // Hollow keys when nothing is attached.
                    key.lineWidth = 1
                    NSColor.black.setStroke()
                    key.stroke()
                }
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
