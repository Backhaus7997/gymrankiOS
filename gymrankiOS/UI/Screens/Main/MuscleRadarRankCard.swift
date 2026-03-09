//
//  MuscleRadarRankCard.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 05/03/2026.
//

import SwiftUI

private enum RadarAxis: Int, CaseIterable, Identifiable {
    case chest, shoulders, back, triceps, legs, biceps, core, cardio, forearms
    var id: Int { rawValue }

    var title: String {
        switch self {
        case .chest: return "Chest"
        case .shoulders: return "Shoulders"
        case .back: return "Back"
        case .triceps: return "Triceps"
        case .legs: return "Legs"
        case .biceps: return "Biceps"
        case .core: return "Core"
        case .cardio: return "Cardio"
        case .forearms: return "Forearms"
        }
    }

    var assetName: String? {
        switch self {
        case .chest:
            return "mask_front_chest"
        case .shoulders:
            return "mask_front_shoulders"
        case .back:
            return "mask_back_back"
        case .legs:
            return "mask_front_quads"
        case .biceps:
            return "mask_front_biceps"
        case .core:
            return "mask_front_abs"
        case .forearms:
            return "mask_back_forearms"
        case .triceps:
            return nil
        case .cardio:
            return nil
        }
    }

    var fallbackSystemIcon: String {
        switch self {
        case .chest:
            return "figure.strengthtraining.traditional"
        case .shoulders:
            return "figure.strengthtraining.functional"
        case .back:
            return "figure.strengthtraining.traditional"
        case .triceps:
            return "bolt.fill"
        case .legs:
            return "figure.walk"
        case .biceps:
            return "bolt.fill"
        case .core:
            return "circle.grid.cross"
        case .cardio:
            return "heart.fill"
        case .forearms:
            return "hand.raised.fill"
        }
    }
}

private struct AxisScore: Identifiable {
    let id = UUID()
    let axis: RadarAxis
    let sets: Int
    let normalized: Double
    let grade: String
}

private func grade(for sets: Int) -> String {
    switch sets {
    case 0: return "F"
    case 1...2: return "E"
    case 3...4: return "D"
    case 5...7: return "C"
    case 8...10: return "B"
    default: return "A"
    }
}

private func buildRadarScores(from stats: [MuscleSetStat]) -> [AxisScore] {
    let dict = Dictionary(uniqueKeysWithValues: stats.map { ($0.name, $0.sets) })

    func s(_ key: String) -> Int { dict[key, default: 0] }

    let chest = s("Pecho")
    let shoulders = s("Hombros")
    let back = s("Espalda") + s("Trapecios")
    let triceps = s("Tríceps")
    let biceps = s("Bíceps")
    let forearms = s("Antebrazos")
    let core = s("Abdomen")
    let legs = s("Cuádriceps") + s("Femorales") + s("Glúteos") + s("Pantorrillas")
    let cardio = 0

    let raw: [(RadarAxis, Int)] = [
        (.chest, chest),
        (.shoulders, shoulders),
        (.back, back),
        (.triceps, triceps),
        (.legs, legs),
        (.biceps, biceps),
        (.core, core),
        (.cardio, cardio),
        (.forearms, forearms)
    ]

    let maxV = max(raw.map { $0.1 }.max() ?? 1, 1)

    return raw.map { axis, sets in
        AxisScore(
            axis: axis,
            sets: sets,
            normalized: min(1.0, Double(sets) / Double(maxV)),
            grade: grade(for: sets)
        )
    }
}

struct MuscleRadarRankCard: View {

    @EnvironmentObject private var session: SessionManager
    @ObservedObject var vm: SetsPerMuscleViewModel

    private var scores: [AxisScore] { buildRadarScores(from: vm.stats) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.22))

                RadarChart(scores: scores)
                    .padding(24)
            }
            .frame(height: 360)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
        .task { await loadIfPossible() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Balance muscular")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("Esta semana")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }
            Spacer()
        }
    }

    private func loadIfPossible() async {
        let uid = session.userId
        guard !uid.isEmpty else { return }
        if vm.stats.isEmpty && !vm.isLoading {
            await vm.load(userId: uid)
        }
    }
}

private struct RadarChart: View {

    let scores: [AxisScore]
    private let rings: Int = 6

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = Double(size) * 0.32

            ZStack {
                ForEach(1...rings, id: \.self) { i in
                    polygonPath(
                        center: center,
                        radius: radius * (Double(i) / Double(rings)),
                        sides: scores.count
                    )
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                }

                ForEach(0..<scores.count, id: \.self) { i in
                    let p = point(center: center, radius: radius, index: i, total: scores.count)

                    Path { path in
                        path.move(to: center)
                        path.addLine(to: p)
                    }
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }

                dataPath(center: center, radius: radius, scores: scores)
                    .fill(Color.appGreen.opacity(0.22))

                dataPath(center: center, radius: radius, scores: scores)
                    .stroke(Color.appGreen.opacity(0.95), lineWidth: 2)

                ForEach(scores) { s in
                    let i = s.axis.rawValue
                    let labelR = radius * 1.28
                    let p = point(center: center, radius: labelR, index: i, total: scores.count)

                    VStack(spacing: 2) {
                        RadarAxisIcon(axis: s.axis)

                        Text(s.axis.title)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))

                        Text(s.grade)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .position(p)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
    }

    private func dataPath(center: CGPoint, radius: Double, scores: [AxisScore]) -> Path {
        var pts: [CGPoint] = []

        for i in 0..<scores.count {
            let r = radius * scores[i].normalized
            pts.append(point(center: center, radius: r, index: i, total: scores.count))
        }

        return Path { path in
            guard let first = pts.first else { return }
            path.move(to: first)
            for p in pts.dropFirst() {
                path.addLine(to: p)
            }
            path.closeSubpath()
        }
    }

    private func polygonPath(center: CGPoint, radius: Double, sides: Int) -> Path {
        Path { path in
            guard sides >= 3 else { return }

            let first = point(center: center, radius: radius, index: 0, total: sides)
            path.move(to: first)

            for i in 1..<sides {
                path.addLine(to: point(center: center, radius: radius, index: i, total: sides))
            }

            path.closeSubpath()
        }
    }

    private func point(center: CGPoint, radius: Double, index: Int, total: Int) -> CGPoint {
        let angle = (Double(index) / Double(total)) * (Double.pi * 2) - Double.pi / 2
        return CGPoint(
            x: center.x + CGFloat(cos(angle) * radius),
            y: center.y + CGFloat(sin(angle) * radius)
        )
    }
}

private struct RadarAxisIcon: View {
    let axis: RadarAxis

    var body: some View {
        Group {
            if let assetName = axis.assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .opacity(0.9)
            } else {
                Image(systemName: axis.fallbackSystemIcon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 22, height: 22)
            }
        }
    }
}
