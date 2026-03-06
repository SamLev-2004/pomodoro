import AppKit

enum MenuBarIcon {
    static func render(progress: CGFloat, phase: SessionPhase) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: true) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

            // --- Tomato body (circle) ---
            let bodyCenter = CGPoint(x: 9, y: 10.5)
            let bodyRadius: CGFloat = 6.0
            let bodyRect = CGRect(
                x: bodyCenter.x - bodyRadius,
                y: bodyCenter.y - bodyRadius,
                width: bodyRadius * 2,
                height: bodyRadius * 2
            )

            // Fill from bottom to top based on progress
            if progress > 0.005 {
                ctx.saveGState()
                ctx.addEllipse(in: bodyRect)
                ctx.clip()

                ctx.setFillColor(phase.fillCGColor)

                let fillHeight = bodyRect.height * CGFloat(progress)
                let fillRect = CGRect(
                    x: bodyRect.minX,
                    y: bodyRect.maxY - fillHeight,
                    width: bodyRect.width,
                    height: fillHeight
                )
                ctx.fill(fillRect)
                ctx.restoreGState()
            }

            // Outline
            ctx.setStrokeColor(NSColor.labelColor.withAlphaComponent(0.55).cgColor)
            ctx.setLineWidth(1.0)
            ctx.addEllipse(in: bodyRect)
            ctx.strokePath()

            // --- Stem ---
            let stemColor = CGColor(red: 0.30, green: 0.62, blue: 0.30, alpha: 1.0)
            ctx.setStrokeColor(stemColor)
            ctx.setLineWidth(1.5)
            ctx.setLineCap(.round)
            ctx.move(to: CGPoint(x: 9, y: 4.5))
            ctx.addLine(to: CGPoint(x: 9, y: 2.0))
            ctx.strokePath()

            // --- Leaf (small curve to the right) ---
            ctx.setFillColor(stemColor)
            let leaf = CGMutablePath()
            leaf.move(to: CGPoint(x: 9.5, y: 3.8))
            leaf.addQuadCurve(to: CGPoint(x: 13.5, y: 1.8), control: CGPoint(x: 12.5, y: 4.0))
            leaf.addQuadCurve(to: CGPoint(x: 9.5, y: 3.8), control: CGPoint(x: 11.5, y: 1.5))
            ctx.addPath(leaf)
            ctx.fillPath()

            return true
        }
        image.isTemplate = false
        return image
    }
}
