import Foundation
import SwiftUI

struct DigDepth: Equatable {
    var level: Int
    var progress: Double
    var currentLayer: DigLayer
    var discoveries: [DigDiscovery]

    static let initial = DigDepth(
        level: 0,
        progress: 0,
        currentLayer: .surface,
        discoveries: []
    )
}

enum DigLayer: Int, CaseIterable, Equatable {
    case surface
    case softSoil
    case roots
    case sediment
    case stone
    case crystal
    case deepCore

    static func layer(forLevel level: Int) -> DigLayer {
        switch level {
        case ..<1: return .surface
        case 1...2: return .softSoil
        case 3...4: return .roots
        case 5...7: return .sediment
        case 8...10: return .stone
        case 11...14: return .crystal
        default: return .deepCore
        }
    }

    var levelRange: ClosedRange<Int> {
        switch self {
        case .surface: return 0...0
        case .softSoil: return 1...2
        case .roots: return 3...4
        case .sediment: return 5...7
        case .stone: return 8...10
        case .crystal: return 11...14
        case .deepCore: return 15...99
        }
    }

    var displayName: String {
        switch self {
        case .surface: return "地表"
        case .softSoil: return "柔らかい土"
        case .roots: return "根の層"
        case .sediment: return "堆積層"
        case .stone: return "岩盤"
        case .crystal: return "結晶層"
        case .deepCore: return "深層"
        }
    }

    var meterLabel: String {
        switch self {
        case .surface: return "Surface"
        case .softSoil: return "Soft Soil"
        case .roots: return "Roots"
        case .sediment: return "Sediment"
        case .stone: return "Stone"
        case .crystal: return "Crystal"
        case .deepCore: return "Deep Core"
        }
    }

    var subtitle: String {
        switch self {
        case .surface: return "まだ問いの入口"
        case .softSoil: return "違和感を掘り始めています"
        case .roots: return "問いが根に触れはじめています"
        case .sediment: return "思考の堆積が見え始めています"
        case .stone: return "詰まりや抵抗に触れています"
        case .crystal: return "言葉になりかけています"
        case .deepCore: return "核心の手前にいます"
        }
    }

    var particleDensity: Double {
        switch self {
        case .surface: return 0.25
        case .softSoil: return 0.55
        case .roots: return 0.65
        case .sediment: return 0.55
        case .stone: return 0.40
        case .crystal: return 0.70
        case .deepCore: return 0.85
        }
    }

    var shakeStrength: Double {
        switch self {
        case .surface: return 0.4
        case .softSoil: return 0.7
        case .roots: return 0.9
        case .sediment: return 0.8
        case .stone: return 1.1
        case .crystal: return 0.7
        case .deepCore: return 1.2
        }
    }

    var topColor: Color {
        switch self {
        case .surface: return Color(red: 0.118, green: 0.106, blue: 0.082)
        case .softSoil: return Color(red: 0.135, green: 0.110, blue: 0.078)
        case .roots: return Color(red: 0.122, green: 0.094, blue: 0.071)
        case .sediment: return Color(red: 0.105, green: 0.088, blue: 0.078)
        case .stone: return Color(red: 0.078, green: 0.078, blue: 0.082)
        case .crystal: return Color(red: 0.075, green: 0.075, blue: 0.094)
        case .deepCore: return Color(red: 0.055, green: 0.047, blue: 0.055)
        }
    }

    var bottomColor: Color {
        switch self {
        case .surface: return Color(red: 0.082, green: 0.075, blue: 0.055)
        case .softSoil: return Color(red: 0.094, green: 0.071, blue: 0.047)
        case .roots: return Color(red: 0.082, green: 0.055, blue: 0.039)
        case .sediment: return Color(red: 0.071, green: 0.063, blue: 0.055)
        case .stone: return Color(red: 0.055, green: 0.055, blue: 0.063)
        case .crystal: return Color(red: 0.055, green: 0.055, blue: 0.080)
        case .deepCore: return Color(red: 0.027, green: 0.024, blue: 0.027)
        }
    }

    var accentColor: Color {
        switch self {
        case .surface: return Color(red: 0.510, green: 0.420, blue: 0.310)
        case .softSoil: return Color(red: 0.580, green: 0.435, blue: 0.290)
        case .roots: return Color(red: 0.635, green: 0.380, blue: 0.255)
        case .sediment: return Color(red: 0.545, green: 0.482, blue: 0.388)
        case .stone: return Color(red: 0.510, green: 0.525, blue: 0.560)
        case .crystal: return Color(red: 0.580, green: 0.690, blue: 0.745)
        case .deepCore: return Color(red: 0.812, green: 0.643, blue: 0.420)
        }
    }
}

struct DigDiscovery: Identifiable, Equatable {
    let id: UUID
    let level: Int
    let layer: DigLayer
    let kind: DigDiscoveryKind
    let position: CGPoint
    let seed: Double

    init(
        id: UUID = UUID(),
        level: Int,
        layer: DigLayer,
        kind: DigDiscoveryKind,
        position: CGPoint,
        seed: Double
    ) {
        self.id = id
        self.level = level
        self.layer = layer
        self.kind = kind
        self.position = position
        self.seed = seed
    }
}

enum DigDiscoveryKind: String, Equatable, CaseIterable {
    case spark
    case vein
    case pebble
    case crystal

    static func suggested(for layer: DigLayer) -> DigDiscoveryKind {
        switch layer {
        case .surface, .softSoil: return .spark
        case .roots, .sediment: return .vein
        case .stone: return .pebble
        case .crystal: return .crystal
        case .deepCore: return .crystal
        }
    }
}

enum DigAnimationIntensity: String, Codable, Equatable, CaseIterable {
    case minimal
    case normal
    case rich

    var multiplier: Double {
        switch self {
        case .minimal: return 0.4
        case .normal: return 1.0
        case .rich: return 1.45
        }
    }

    var label: String {
        switch self {
        case .minimal: return "minimal"
        case .normal: return "normal"
        case .rich: return "rich"
        }
    }
}

enum DigQuestionDetector {
    static let markers: [String] = [
        "?", "？", "なぜ", "どうして", "何が", "どんな", "どこに", "いつ", "本当に"
    ]

    static func containsQuestion(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        for marker in markers where text.contains(marker) {
            return true
        }
        return false
    }
}

enum DigDepthEngine {
    static let discoveryStep = 3

    static func progress(forLevel level: Int) -> Double {
        let layer = DigLayer.layer(forLevel: level)
        let span = max(layer.levelRange.upperBound - layer.levelRange.lowerBound + 1, 1)
        let local = level - layer.levelRange.lowerBound + 1
        return min(max(Double(local) / Double(span), 0), 1)
    }

    static func advance(
        from current: DigDepth,
        by amount: Int,
        canvasSeed: Double
    ) -> DigDepth {
        let newLevel = min(current.level + max(amount, 1), 99)
        let layer = DigLayer.layer(forLevel: newLevel)
        var discoveries = current.discoveries

        let crossedLayer = DigLayer.layer(forLevel: current.level) != layer && current.level > 0
        let crossedDiscoveryStep = (current.level / discoveryStep) != (newLevel / discoveryStep) && newLevel > 0

        if crossedLayer || crossedDiscoveryStep {
            let kind = DigDiscoveryKind.suggested(for: layer)
            let seed = canvasSeed.truncatingRemainder(dividingBy: 1.0)
            let x = 0.18 + (seed * 0.64)
            let y = 0.12 + ((1.0 - seed).truncatingRemainder(dividingBy: 1.0)) * 0.74
            let discovery = DigDiscovery(
                level: newLevel,
                layer: layer,
                kind: kind,
                position: CGPoint(x: x, y: y),
                seed: seed
            )
            discoveries.append(discovery)
            if discoveries.count > 24 {
                discoveries.removeFirst(discoveries.count - 24)
            }
        }

        return DigDepth(
            level: newLevel,
            progress: progress(forLevel: newLevel),
            currentLayer: layer,
            discoveries: discoveries
        )
    }
}
