//
//  MuscleRadarRankCard.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 05/03/2026.
//

import SwiftUI

private enum RadarAxis: Int, CaseIterable, Identifiable {
    case pecho, hombros, espalda, triceps, piernas, biceps, core, cardio, antebrazos
    var id: Int { rawValue }

    var title: String {
        switch self {
        case .pecho: return "Pecho"
        case .hombros: return "Hombros"
        case .espalda: return "Espalda"
        case .triceps: return "Tríceps"
        case .piernas: return "Piernas"
        case .biceps: return "Bíceps"
        case .core: return "Core"
        case .cardio: return "Cardio"
        case .antebrazos: return "Antebrazos"
        }
    }
}

private struct AxisScore: Identifiable {
    let id = UUID()
    let axis: RadarAxis
    let sets: Int
    let normalized: Double
}

private func buildRadarScores(from stats: [MuscleSetStat]) -> [AxisScore] {
    let dict = Dictionary(uniqueKeysWithValues: stats.map { ($0.name, $0.sets) })

    func s(_ key: String) -> Int { dict[key, default: 0] }

    let pecho = s("Pecho")
    let hombros = s("Hombros")
    let espalda = s("Espalda") + s("Trapecios")
    let triceps = s("Tríceps")
    let biceps = s("Bíceps")
    let antebrazos = s("Antebrazos")
    let core = s("Abdomen")
    let piernas = s("Cuádriceps") + s("Femorales") + s("Glúteos") + s("Pantorrillas")
    let cardio = 0

    let raw: [(RadarAxis, Int)] = [
        (.pecho, pecho),
        (.hombros, hombros),
        (.espalda, espalda),
        (.triceps, triceps),
        (.piernas, piernas),
        (.biceps, biceps),
        (.core, core),
        (.cardio, cardio),
        (.antebrazos, antebrazos)
    ]

    let maxV = max(raw.map { $0.1 }.max() ?? 1, 1)

    return raw.map { axis, sets in
        AxisScore(
            axis: axis,
            sets: sets,
            normalized: min(1.0, Double(sets) / Double(maxV))
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
            let radius = Double(size) * 0.28

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
                    let labelR = radius * 1.38
                    let p = point(center: center, radius: labelR, index: i, total: scores.count)

                    Text(s.axis.title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.80))
                        .multilineTextAlignment(.center)
                        .frame(width: 92)
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
            let r = radius * scores[i].normalized * 0.82
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
