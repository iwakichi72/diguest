import SwiftUI

enum MotionToken {
    static let fast = 0.10
    static let base = 0.15
    static let slow = 0.20
    static let page = 0.20
    static let scroll = 0.30
    static let pulse = 1.35

    static func soft(_ duration: Double) -> Animation {
        .timingCurve(0.22, 0.0, 0.18, 1.0, duration: duration)
    }

    static func animation(_ duration: Double, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : soft(duration)
    }
}

private struct QuietRevealModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    let delay: Double
    let duration: Double
    let blur: Double
    let scale: Double

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .blur(radius: reduceMotion ? 0 : (appeared ? 0 : blur))
            .scaleEffect(reduceMotion ? 1 : (appeared ? 1 : scale), anchor: .center)
            .onAppear {
                guard !appeared else { return }
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(MotionToken.soft(duration).delay(delay)) {
                        appeared = true
                    }
                }
            }
    }
}

private struct QuietRuleRevealModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    let delay: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(x: appeared ? 1 : 0.02, y: 1, anchor: .leading)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                guard !appeared else { return }
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(MotionToken.soft(MotionToken.slow).delay(delay)) {
                        appeared = true
                    }
                }
            }
    }
}

extension View {
    func quietReveal(
        delay: Double = 0,
        duration: Double = MotionToken.slow,
        blur: Double = 2,
        scale: Double = 0.998
    ) -> some View {
        modifier(QuietRevealModifier(delay: delay, duration: duration, blur: blur, scale: scale))
    }

    func quietRuleReveal(delay: Double = 0) -> some View {
        modifier(QuietRuleRevealModifier(delay: delay))
    }
}

struct ListeningPulse: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isActive: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive || reduceMotion)) { context in
            let phase = pulsePhase(at: context.date)
            Circle()
                .stroke(Theme.accent.opacity(isActive ? opacity(for: phase) : 0), lineWidth: 1)
                .scaleEffect(isActive ? scale(for: phase) : 1)
        }
        .opacity(isActive ? 1 : 0)
    }

    private func pulsePhase(at date: Date) -> Double {
        guard !reduceMotion else { return 0 }
        return date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: MotionToken.pulse) / MotionToken.pulse
    }

    private func scale(for phase: Double) -> Double {
        reduceMotion ? 1.18 : 1.0 + (phase * 0.72)
    }

    private func opacity(for phase: Double) -> Double {
        reduceMotion ? 0.26 : max(0, 0.34 * (1.0 - phase))
    }
}

struct StreamingCursor: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.2, paused: reduceMotion)) { context in
            let isVisible = reduceMotion || Int(context.date.timeIntervalSinceReferenceDate / 0.55) % 2 == 0
            Rectangle()
                .fill(Theme.muted)
                .frame(width: 2, height: 20)
                .opacity(isVisible ? 0.9 : 0.12)
        }
        .frame(width: 8, height: 22, alignment: .leading)
    }
}

struct MarkdownGenerationTrace: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
                let width = proxy.size.width
                let segment = max(width * 0.18, 80)
                let travel = width + segment
                let phase = reduceMotion ? 0.5 : context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.8) / 1.8
                Rectangle()
                    .fill(Theme.accent.opacity(reduceMotion ? 0.22 : 0.32))
                    .frame(width: reduceMotion ? width : segment, height: 1)
                    .offset(x: reduceMotion ? 0 : -segment + (travel * phase))
            }
        }
        .frame(height: 1)
        .clipped()
    }
}
