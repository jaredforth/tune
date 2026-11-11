import SwiftUI
import AVFoundation

final class Model: ObservableObject {
    @Published var freq: Double? = nil
    private let engine = AVAudioEngine()

    var reading: (name: String, octave: Int, cents: Double)? { freq.map(note) }

    func listen() {
        AVCaptureDevice.requestAccess(for: .audio) { [self] ok in
            guard ok else { return }
            let input = engine.inputNode, fmt = input.outputFormat(forBus: 0), rate = fmt.sampleRate
            input.installTap(onBus: 0, bufferSize: 4096, format: fmt) { [weak self] buf, _ in
                let x = Array(UnsafeBufferPointer(start: buf.floatChannelData![0], count: Int(buf.frameLength)))
                let f = detectPitch(x, rate: rate)
                DispatchQueue.main.async { self?.freq = f }
            }
            try? engine.start()
        }
    }
}

struct TunerView: View {
    @ObservedObject var model: Model

    var body: some View {
        let r = model.reading
        let inTune = r.map { abs($0.cents) < 5 } ?? false
        let tint: Color = inTune ? .green : .orange
        VStack(spacing: 28) {
            Text(r.map { "\($0.name)\($0.octave)" } ?? "–")
                .font(.system(size: 140, weight: .semibold, design: .rounded))
                .foregroundColor(r == nil ? .secondary : tint)
            // Cents meter: -50...+50, needle sits at the center when in tune.
            GeometryReader { g in
                ZStack {
                    Capsule().fill(Color.gray.opacity(0.35)).frame(height: 6)
                    Rectangle().fill(Color.secondary).frame(width: 2, height: 26)
                    if let r = r {
                        Capsule().fill(tint).frame(width: 8, height: 46)
                            .offset(x: g.size.width / 2 * r.cents / 50)
                            .animation(.easeOut(duration: 0.1), value: r.cents)
                    }
                }
                .frame(width: g.size.width, height: g.size.height)
            }
            .frame(height: 50)
            Text(r.map { String(format: "%+.0f¢  ·  %.1f Hz", $0.cents, model.freq!) } ?? "Play a note")
                .font(.system(size: 22, weight: .medium).monospacedDigit()).foregroundColor(.secondary)
        }
        .padding(48)
    }
}

@main
struct TuneApp: App {
    // ObservableObject, not @State: the @State macro needs Xcode's plugin, absent with Command Line Tools only.
    @StateObject private var model = Model()

    var body: some Scene {
        WindowGroup {
            TunerView(model: model).frame(minWidth: 480, minHeight: 420).onAppear { model.listen() }
        }
    }
}
