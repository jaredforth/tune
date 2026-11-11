import SwiftUI
import AVFoundation

// Calibration knob: reference pitch for A4.
let A4 = 440.0
let names = ["C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B"]

// Pitch of a mono buffer in Hz, or nil if too quiet/unclear. Normalized autocorrelation (McLeod-style):
// take the first peak within 90% of the best, which avoids octave-down errors. Range 50-1500 Hz.
func detectPitch(_ x: [Float], rate: Double) -> Double? {
    let n = x.count
    guard sqrt(x.reduce(0) { $0 + $1 * $1 } / Float(n)) > 0.01 else { return nil }
    let lo = Int(rate / 1500), hi = min(Int(rate / 50), n / 2)
    var nsdf = [Float](repeating: 0, count: hi + 2)
    for lag in lo...hi {
        var r: Float = 0, m: Float = 0
        for i in 0..<(n - lag) { r += x[i] * x[i + lag]; m += x[i] * x[i] + x[i + lag] * x[i + lag] }
        nsdf[lag] = m > 0 ? 2 * r / m : 0
    }
    let best = nsdf.max()!
    guard best > 0.8 else { return nil }
    for lag in (lo + 1)...hi where nsdf[lag] > 0.9 * best && nsdf[lag] >= nsdf[lag - 1] && nsdf[lag] >= nsdf[lag + 1] {
        let a = nsdf[lag - 1], b = nsdf[lag], c = nsdf[lag + 1] // parabolic interpolation for sub-sample lag
        let d = a - 2 * b + c
        return rate / (Double(lag) + (d == 0 ? 0 : Double(0.5 * (a - c) / d)))
    }
    return nil
}

final class Model: ObservableObject {
    @Published var freq: Double? = nil
    private let engine = AVAudioEngine()

    // Nearest note, octave and cents off (-50...50) for the current pitch.
    var reading: (name: String, octave: Int, cents: Double)? {
        guard let f = freq else { return nil }
        let midi = 69 + 12 * log2(f / A4), n = Int(midi.rounded())
        return (names[(n % 12 + 12) % 12], n / 12 - 1, (midi - Double(n)) * 100)
    }

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
