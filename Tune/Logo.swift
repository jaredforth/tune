import SwiftUI

// A tuning fork: U-shaped tines on a stem.
struct Logo: View {
    var size: CGFloat
    var body: some View {
        let w = size * 0.09
        Path { p in
            p.move(to: CGPoint(x: size * 0.3, y: 0))
            p.addLine(to: CGPoint(x: size * 0.3, y: size * 0.5))
            p.addArc(center: CGPoint(x: size * 0.5, y: size * 0.5), radius: size * 0.2, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
            p.addLine(to: CGPoint(x: size * 0.7, y: 0))
            p.move(to: CGPoint(x: size * 0.5, y: size * 0.7))
            p.addLine(to: CGPoint(x: size * 0.5, y: size))
        }
        .stroke(style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}
