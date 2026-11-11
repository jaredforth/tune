// Usage: screenshot <out.png>. Renders the main view offscreen (A4, a bit sharp) for the README.
import SwiftUI
import AppKit

MainActor.assumeIsolated {
    let m = Model()
    m.freq = 444
    let v = TunerView(model: m).frame(width: 480, height: 420).background(Color(white: 0.12)).environment(\.colorScheme, .dark)
    let r = ImageRenderer(content: v)
    r.scale = 2
    try! NSBitmapImageRep(cgImage: r.cgImage!).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
    exit(0)
}
