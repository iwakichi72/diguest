import SwiftUI

struct DepthMeterView: View {
    let depth: DigDepth
    let transitionTick: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var emphasized = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("DEPTH")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(1.6)
                    .foregroundStyle(Theme.muted)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(levelText)
                        .font(.system(size: 26, weight: .regular, design: .monospaced))
                        .foregroundStyle(emphasized ? depth.currentLayer.accentColor : Theme.secondary)
                        .monospacedDigit()
                    Text("/ \(depth.currentLayer.meterLabel)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Theme.muted)
                }
            }

            DepthBar(
                progress: depth.progress,
                level: depth.level,
                color: depth.currentLayer.accentColor,
                emphasized: emphasized,
                reduceMotion: reduceMotion
            )
            .frame(width: 96, height: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(depth.currentLayer.displayName)
                    .font(.system(size: 11, design: .serif))
                    .foregroundStyle(Theme.secondary)
                Text(depth.currentLayer.subtitle)
                    .font(.system(size: 11, design: .serif))
                    .italic()
                    .foregroundStyle(Theme.muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(width: 156, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.base.opacity(0.7))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Theme.border.opacity(0.65), lineWidth: 0.5)
        }
        .onChange(of: transitionTick) { _ in
            triggerEmphasis()
        }
        .onChange(of: depth.currentLayer) { _ in
            triggerEmphasis()
        }
    }

    private var levelText: String {
        String(format: "%02d", depth.level)
    }

    private func triggerEmphasis() {
        if reduceMotion {
            emphasized = true
            return
        }
        withAnimation(.easeOut(duration: 0.32)) {
            emphasized = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.8)) {
                emphasized = false
            }
        }
    }
}

private struct DepthBar: View {
    let progress: Double
    let level: Int
    let color: Color
    let emphasized: Bool
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.border.opacity(0.7))
                Capsule()
                    .fill(color.opacity(emphasized ? 0.9 : 0.6))
                    .frame(width: proxy.size.width * CGFloat(max(0.04, min(progress, 1))))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.65), value: progress)
            }
        }
    }
}

struct CrystallizationView: View {
    let depth: DigDepth

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false
    @State private var crystallized = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("今日掘った深さ")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.secondary)
                Text("Depth \(String(format: "%02d", depth.level)) · \(depth.currentLayer.meterLabel)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(depth.currentLayer.accentColor.opacity(0.85))
            }
            .opacity(revealed ? 1 : 0)

            ShaftSilhouette(depth: depth, crystallized: crystallized, reduceMotion: reduceMotion)
                .frame(height: 132)
                .opacity(revealed ? 1 : 0)

            Text(depth.currentLayer.subtitle)
                .font(.system(size: 13, design: .serif))
                .italic()
                .foregroundStyle(Theme.muted)
                .opacity(revealed ? 1 : 0)
        }
        .frame(maxWidth: 520, alignment: .leading)
        .onAppear {
            if reduceMotion {
                revealed = true
                crystallized = true
            } else {
                withAnimation(.easeOut(duration: 0.6)) {
                    revealed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    withAnimation(.easeOut(duration: 0.9)) {
                        crystallized = true
                    }
                }
            }
        }
    }
}

private struct ShaftSilhouette: View {
    let depth: DigDepth
    let crystallized: Bool
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let shaftCenterX = w * 0.5
            let layerHeight = h / CGFloat(DigLayer.allCases.count)

            ZStack {
                ForEach(DigLayer.allCases, id: \.rawValue) { layer in
                    let idx = CGFloat(layer.rawValue)
                    let y = idx * layerHeight
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [layer.topColor, layer.bottomColor],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: w, height: layerHeight)
                        .position(x: w / 2, y: y + layerHeight / 2)
                        .opacity(layer.rawValue <= depth.currentLayer.rawValue ? 0.85 : 0.32)
                }

                Path { path in
                    path.move(to: CGPoint(x: shaftCenterX, y: 0))
                    path.addLine(to: CGPoint(x: shaftCenterX, y: h * shaftReach))
                }
                .stroke(
                    LinearGradient(
                        colors: [
                            Theme.accent.opacity(0.5),
                            depth.currentLayer.accentColor.opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 1.0, lineCap: .round)
                )
                .blur(radius: 0.4)

                Circle()
                    .fill(depth.currentLayer.accentColor.opacity(crystallized ? 0.95 : 0.0))
                    .frame(width: 7, height: 7)
                    .blur(radius: crystallized ? 0.5 : 4)
                    .shadow(color: depth.currentLayer.accentColor.opacity(crystallized ? 0.55 : 0.0), radius: 6)
                    .position(x: shaftCenterX, y: h * shaftReach)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.9), value: crystallized)

                ForEach(Array(depth.discoveries.prefix(8).enumerated()), id: \.element.id) { _, discovery in
                    let yPos = layerHeight * CGFloat(discovery.layer.rawValue) + layerHeight * CGFloat(discovery.position.y) * 0.7
                    let xOffset = (CGFloat(discovery.position.x) - 0.5) * (w * 0.6)
                    Circle()
                        .fill(discovery.layer.accentColor.opacity(0.7))
                        .frame(width: 3, height: 3)
                        .shadow(color: discovery.layer.accentColor.opacity(0.5), radius: 3)
                        .position(x: shaftCenterX + xOffset, y: yPos)
                        .opacity(crystallized ? 1 : 0)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.9), value: crystallized)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Theme.border.opacity(0.55), lineWidth: 0.5)
            }
        }
    }

    private var shaftReach: CGFloat {
        let total = CGFloat(DigLayer.allCases.count)
        let layerStart = CGFloat(depth.currentLayer.rawValue) / total
        let inLayer = CGFloat(max(0.1, min(depth.progress, 1.0))) / total
        return min(layerStart + inLayer, 1.0)
    }
}
