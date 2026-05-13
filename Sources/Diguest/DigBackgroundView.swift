import SwiftUI

struct DigBackgroundView: View {
    let depth: DigDepth
    let pulseTick: Int
    let transitionTick: Int
    let transitionStrength: Double
    let enabled: Bool
    let intensity: DigAnimationIntensity

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            StratumGradient(layer: depth.currentLayer)
                .animation(.easeInOut(duration: 1.1), value: depth.currentLayer)

            if enabled {
                StratumLines(layer: depth.currentLayer, level: depth.level, reduceMotion: reduceMotion)
                    .opacity(reduceMotion ? 0.35 : 0.5)
                    .animation(.easeInOut(duration: 1.1), value: depth.currentLayer)

                ShaftGlow(layer: depth.currentLayer, level: depth.level)
                    .animation(.easeInOut(duration: 1.1), value: depth.currentLayer)
                    .animation(.easeInOut(duration: 0.9), value: depth.level)

                if !reduceMotion {
                    DustParticleField(
                        layer: depth.currentLayer,
                        intensity: intensity,
                        pulseTick: pulseTick
                    )
                    .allowsHitTesting(false)
                }

                DiscoveryLayer(
                    discoveries: depth.discoveries,
                    reduceMotion: reduceMotion,
                    intensity: intensity
                )
                .allowsHitTesting(false)

                DigTransitionOverlay(
                    transitionTick: transitionTick,
                    strength: transitionStrength,
                    reduceMotion: reduceMotion,
                    intensity: intensity
                )
                .allowsHitTesting(false)
            }
        }
        .clipped()
    }
}

private struct StratumGradient: View {
    let layer: DigLayer

    var body: some View {
        ZStack {
            Theme.surface
            LinearGradient(
                stops: [
                    .init(color: layer.topColor, location: 0.0),
                    .init(color: layer.topColor.opacity(0.92), location: 0.34),
                    .init(color: layer.bottomColor.opacity(0.96), location: 0.78),
                    .init(color: layer.bottomColor, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .id("strata-\(layer.rawValue)")
            .transition(.opacity)
        }
    }
}

private struct StratumLines: View {
    let layer: DigLayer
    let level: Int
    let reduceMotion: Bool

    var body: some View {
        Canvas { context, size in
            let layerIndex = Double(layer.rawValue)
            let baseSpacing = max(size.height / 9.5, 38)
            let drift = reduceMotion ? 0 : (Double(level % 6) * 4)
            let baseColor = layer.accentColor.opacity(0.07)

            for index in 0..<11 {
                let normalized = Double(index) / 10.0
                let y = (CGFloat(normalized) * size.height) - CGFloat(drift).truncatingRemainder(dividingBy: baseSpacing)
                let waveOffset = sin((normalized + layerIndex * 0.13) * 6.28) * 6
                let path = Path { p in
                    p.move(to: CGPoint(x: -6, y: y + waveOffset))
                    p.addCurve(
                        to: CGPoint(x: size.width + 6, y: y - waveOffset),
                        control1: CGPoint(x: size.width * 0.33, y: y + waveOffset * 1.8),
                        control2: CGPoint(x: size.width * 0.66, y: y - waveOffset * 1.8)
                    )
                }
                let alpha = 0.18 + (1.0 - normalized) * 0.22
                context.stroke(
                    path,
                    with: .color(baseColor.opacity(alpha)),
                    style: StrokeStyle(lineWidth: 0.8 + CGFloat(index % 3) * 0.15, lineCap: .round)
                )
            }

            let veinCount = layer.rawValue + 1
            for i in 0..<veinCount {
                let seed = Double(i) * 0.37 + layerIndex * 0.21
                let x = (seed.truncatingRemainder(dividingBy: 0.94) + 0.03) * size.width
                let topY = (seed * 1.7).truncatingRemainder(dividingBy: 0.6) * size.height
                let height = size.height * (0.22 + (seed * 0.41).truncatingRemainder(dividingBy: 0.42))
                let path = Path { p in
                    p.move(to: CGPoint(x: x, y: topY))
                    p.addLine(to: CGPoint(x: x + 0.4, y: topY + height))
                }
                context.stroke(
                    path,
                    with: .color(layer.accentColor.opacity(0.06)),
                    style: StrokeStyle(lineWidth: 0.6, lineCap: .round)
                )
            }
        }
        .blendMode(.plusLighter)
        .opacity(0.62)
    }
}

private struct ShaftGlow: View {
    let layer: DigLayer
    let level: Int

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let shaftWidth = max(width * 0.18, 220)

            ZStack {
                RadialGradient(
                    colors: [
                        layer.accentColor.opacity(0.10),
                        layer.accentColor.opacity(0.04),
                        .clear
                    ],
                    center: .init(x: 0.5, y: 0.0),
                    startRadius: 0,
                    endRadius: shaftWidth * 1.4
                )
                .frame(width: width, height: height)
                .opacity(0.85)

                LinearGradient(
                    stops: [
                        .init(color: layer.bottomColor.opacity(0.0), location: 0),
                        .init(color: layer.bottomColor.opacity(0.18), location: 0.5),
                        .init(color: layer.bottomColor.opacity(0.42), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: shaftWidth)
                .blur(radius: 50)
                .opacity(0.6 + min(Double(level), 12) / 36.0)
            }
        }
        .blendMode(.plusLighter)
    }
}

private struct DustParticleField: View {
    let layer: DigLayer
    let intensity: DigAnimationIntensity
    let pulseTick: Int

    @State private var pulseAt: Date = .distantPast

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
            Canvas { gfx, size in
                let time = context.date.timeIntervalSinceReferenceDate
                let pulseAge = max(0, context.date.timeIntervalSince(pulseAt))
                let pulseBoost = pulseAge < 1.2 ? (1.0 - pulseAge / 1.2) : 0

                let totalCount = particleCount
                for i in 0..<totalCount {
                    let seed = Double(i) * 0.6180339887
                    let lifetime = 6.0 + (seed.truncatingRemainder(dividingBy: 1.0)) * 6.0
                    let phase = ((time + seed * 9.0) / lifetime).truncatingRemainder(dividingBy: 1.0)

                    let baseX = (seed * 1.61803).truncatingRemainder(dividingBy: 1.0)
                    let sway = sin((time * 0.4) + seed * 6.28) * 0.018
                    let x = (baseX + sway) * size.width

                    let y = (1.0 - phase) * size.height

                    let baseAlpha = 0.05 + (seed.truncatingRemainder(dividingBy: 0.4)) * 0.18
                    let fadeIn = min(phase * 4, 1)
                    let fadeOut = min((1 - phase) * 2.4, 1)
                    let alpha = baseAlpha * fadeIn * fadeOut * (0.7 + pulseBoost * 0.8)

                    let r = 0.5 + (seed.truncatingRemainder(dividingBy: 0.6)) * 1.6
                    let rect = CGRect(x: x - r / 2, y: y - r / 2, width: r, height: r)
                    gfx.fill(Path(ellipseIn: rect), with: .color(layer.accentColor.opacity(alpha)))
                }
            }
        }
        .onChange(of: pulseTick) { _ in
            pulseAt = Date()
        }
    }

    private var particleCount: Int {
        let base = max(8, Int(60.0 * layer.particleDensity * intensity.multiplier))
        return min(base, 110)
    }
}

private struct DiscoveryLayer: View {
    let discoveries: [DigDiscovery]
    let reduceMotion: Bool
    let intensity: DigAnimationIntensity

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(discoveries) { discovery in
                    DiscoverySparkView(
                        discovery: discovery,
                        reduceMotion: reduceMotion,
                        intensity: intensity
                    )
                    .position(
                        x: discovery.position.x * proxy.size.width,
                        y: discovery.position.y * proxy.size.height
                    )
                }
            }
        }
        .blendMode(.plusLighter)
    }
}

struct DiscoverySparkView: View {
    let discovery: DigDiscovery
    let reduceMotion: Bool
    let intensity: DigAnimationIntensity

    @State private var appeared = false

    var body: some View {
        let color = discovery.layer.accentColor
        let scale = intensity.multiplier
        let coreSize = 6 * scale

        ZStack {
            Circle()
                .fill(color.opacity(0.10))
                .frame(width: 26 * scale, height: 26 * scale)
                .blur(radius: 8)

            coreShape(size: coreSize, color: color)
                .shadow(color: color.opacity(0.5), radius: 4)

            Circle()
                .stroke(color.opacity(0.18), lineWidth: 0.6)
                .frame(width: 14 * scale, height: 14 * scale)
        }
        .opacity(appeared ? 0.82 : 0)
        .scaleEffect(appeared ? 1 : 0.6)
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.easeOut(duration: 0.9)) {
                    appeared = true
                }
            }
        }
    }

    @ViewBuilder
    private func coreShape(size: CGFloat, color: Color) -> some View {
        switch discovery.kind {
        case .spark:
            Circle().fill(color.opacity(0.55)).frame(width: size, height: size)
        case .vein:
            Capsule().fill(color.opacity(0.55)).frame(width: size, height: size * 0.45)
        case .pebble:
            RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.55)).frame(width: size, height: size * 0.7)
        case .crystal:
            Diamond().fill(color.opacity(0.7)).frame(width: size, height: size * 1.2)
        }
    }
}

private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

private struct DigTransitionOverlay: View {
    let transitionTick: Int
    let strength: Double
    let reduceMotion: Bool
    let intensity: DigAnimationIntensity

    @State private var triggeredAt: Date = .distantPast

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let age = context.date.timeIntervalSince(triggeredAt)
            let duration = 0.9
            let raw = age < duration ? max(0, 1.0 - age / duration) : 0
            let progress = pow(raw, 1.4)
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.0),
                                Color.black.opacity(0.18 * progress * strength)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                if progress > 0 && !reduceMotion {
                    DustBurst(
                        progress: 1.0 - raw,
                        strength: strength * intensity.multiplier
                    )
                }
            }
        }
        .onChange(of: transitionTick) { _ in
            triggeredAt = Date()
        }
    }
}

private struct DustBurst: View {
    let progress: Double
    let strength: Double

    var body: some View {
        Canvas { gfx, size in
            let count = max(16, Int(50 * strength))
            for i in 0..<count {
                let seed = Double(i) * 0.6180339
                let baseX = (seed * 1.7).truncatingRemainder(dividingBy: 1.0)
                let drift = sin(seed * 6.28 + progress * 3.0) * 0.04
                let x = (baseX + drift) * size.width
                let rise = progress * (0.32 + (seed.truncatingRemainder(dividingBy: 0.5)))
                let y = size.height * (1.0 - rise)
                let alpha = (1.0 - progress) * 0.32 * (0.5 + seed.truncatingRemainder(dividingBy: 0.6))
                let r = 1.0 + (seed.truncatingRemainder(dividingBy: 0.8)) * 2.0
                let rect = CGRect(x: x - r / 2, y: y - r / 2, width: r, height: r)
                gfx.fill(
                    Path(ellipseIn: rect),
                    with: .color(Color(red: 0.78, green: 0.62, blue: 0.42).opacity(alpha))
                )
            }
        }
    }
}

struct DigSinkModifier: ViewModifier {
    let tick: Int
    let strength: Double
    let reduceMotion: Bool

    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onChange(of: tick) { _ in
                guard !reduceMotion else { return }
                let drop = CGFloat(6.0 * strength)
                withAnimation(.easeOut(duration: 0.18)) {
                    offset = drop
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.55)) {
                        offset = 0
                    }
                }
            }
    }
}

extension View {
    func digSink(tick: Int, strength: Double, reduceMotion: Bool) -> some View {
        modifier(DigSinkModifier(tick: tick, strength: strength, reduceMotion: reduceMotion))
    }
}
