// Run with ./test.sh. Checks pitch detection and note naming; exits non-zero on failure.
import Foundation

func tone(_ f: Double, rate: Double = 48000) -> [Float] {
    (0..<4096).map { Float(0.3 * (sin(2 * .pi * f * Double($0) / rate) + 0.5 * sin(4 * .pi * f * Double($0) / rate))) }
}
func check(_ ok: Bool, _ msg: String) { if !ok { print("FAIL:", msg); exit(1) } }

for f in [82.41, 110, 220, 329.63, 440, 1000] {
    let d = detectPitch(tone(f), rate: 48000)
    check(d != nil && abs(d! / f - 1) < 0.003, "pitch \(f) -> \(String(describing: d))")
}
check(detectPitch(tone(440, rate: 44100), rate: 44100).map { abs($0 / 440 - 1) < 0.003 } ?? false, "44.1k rate")
check(detectPitch([Float](repeating: 0, count: 4096), rate: 48000) == nil, "silence")
check(detectPitch(tone(440).map { $0 * 0.01 }, rate: 48000) == nil, "too quiet")

var n = note(440); check(n.name == "A" && n.octave == 4 && abs(n.cents) < 1e-9, "A4")
n = note(261.63); check(n.name == "C" && n.octave == 4 && abs(n.cents) < 1, "C4")
n = note(440 * pow(2, 20.0 / 1200)); check(n.name == "A" && abs(n.cents - 20) < 1e-6, "A4 +20c")
n = note(440 * pow(2, -30.0 / 1200)); check(n.name == "A" && abs(n.cents + 30) < 1e-6, "A4 -30c")
n = note(27.5); check(n.name == "A" && n.octave == 0, "A0 (octave math)")
print("ok")
