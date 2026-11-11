import Foundation

// Calibration knob: reference pitch for A4.
let A4 = 440.0
let names = ["C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B"]

// Nearest note, octave and cents off (-50...50) for a frequency.
func note(_ f: Double) -> (name: String, octave: Int, cents: Double) {
    let midi = 69 + 12 * log2(f / A4), n = Int(midi.rounded())
    return (names[(n % 12 + 12) % 12], n / 12 - 1, (midi - Double(n)) * 100)
}

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
