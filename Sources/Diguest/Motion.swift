import SwiftUI

enum MotionToken {
    static let fast = 0.10
    static let base = 0.22
    static let slow = 0.38
    static let page = 0.34
    static let scroll = 0.36
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
        blur: Double = 3,
        scale: Double = 0.988
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
                .stroke(Theme.accent.opacity(isActive ? opacity(for: phase) : 0), lineWidth: 1.25)
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
        reduceMotion ? 0.3 : max(0, 0.42 * (1.0 - phase))
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
                let segment = max(width * 0.24, 96)
                let travel = width + segment
                let phase = reduceMotion ? 0.5 : context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.45) / 1.45
                Rectangle()
                    .fill(Theme.accent.opacity(reduceMotion ? 0.24 : 0.46))
                    .frame(width: reduceMotion ? width : segment, height: 2)
                    .offset(x: reduceMotion ? 0 : -segment + (travel * phase))
            }
        }
        .frame(height: 2)
        .clipped()
    }
}

struct PaperAssemblyView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var assembled = false

    private let rows: [PaperAssemblyRow] = [
        PaperAssemblyRow(width: 0.34, height: 12, role: .heading),
        PaperAssemblyRow(width: 0.86, height: 7, role: .body),
        PaperAssemblyRow(width: 0.72, height: 7, role: .body),
        PaperAssemblyRow(width: 0.94, height: 7, role: .body),
        PaperAssemblyRow(width: 0.48, height: 7, role: .body),
        PaperAssemblyRow(width: 0.22, height: 5, role: .rule),
        PaperAssemblyRow(width: 0.62, height: 9, role: .subheading),
        PaperAssemblyRow(width: 0.90, height: 7, role: .body),
        PaperAssemblyRow(width: 0.78, height: 7, role: .body),
        PaperAssemblyRow(width: 0.56, height: 7, role: .body)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 14) {
                Text("Markdownに組み上げています")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.secondary)
                    .quietReveal(duration: MotionToken.base, blur: 1.5)

                MarkdownGenerationTrace()
                    .frame(width: 180)
                    .opacity(assembled ? 1 : 0)
            }

            VStack(alignment: .leading, spacing: 11) {
                ForEach(rows.indices, id: \.self) { index in
                    PaperAssemblyLine(
                        row: rows[index],
                        index: index,
                        assembled: assembled
                    )
                }
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: 520, alignment: .leading)
        .padding(.vertical, 4)
        .onAppear {
            if reduceMotion {
                assembled = true
            } else {
                withAnimation(MotionToken.soft(0.44)) {
                    assembled = true
                }
            }
        }
    }
}

private struct PaperAssemblyLine: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let row: PaperAssemblyRow
    let index: Int
    let assembled: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(fill)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: row.height)
            .scaleEffect(x: assembled ? row.width : 0.02, y: 1, anchor: .leading)
            .opacity(assembled ? opacity : 0)
            .offset(y: assembled || reduceMotion ? 0 : 9)
            .blur(radius: assembled || reduceMotion ? 0 : 3.5)
            .animation(animation, value: assembled)
    }

    private var animation: Animation? {
        guard !reduceMotion else { return nil }
        return MotionToken.soft(0.34 + Double(index) * 0.015)
            .delay(Double(index) * 0.055)
    }

    private var fill: Color {
        switch row.role {
        case .heading:
            return Theme.accent.opacity(0.44)
        case .subheading:
            return Theme.text.opacity(0.3)
        case .body:
            return Theme.border.opacity(0.95)
        case .rule:
            return Theme.muted.opacity(0.85)
        }
    }

    private var opacity: Double {
        switch row.role {
        case .heading:
            return 0.95
        case .subheading:
            return 0.82
        case .body:
            return 0.78
        case .rule:
            return 0.56
        }
    }

    private var cornerRadius: CGFloat {
        row.role == .rule ? 1 : 2
    }
}

private struct PaperAssemblyRow {
    let width: CGFloat
    let height: CGFloat
    let role: PaperAssemblyRole
}

private enum PaperAssemblyRole {
    case heading
    case subheading
    case body
    case rule
}
