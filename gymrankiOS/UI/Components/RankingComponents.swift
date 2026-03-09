//
//  RankingComponents.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 05/03/2026.
//

import SwiftUI

struct PodiumItemView: View {
    let rank: Int
    let name: String
    let points: Int

    private var isWinner: Bool { rank == 1 }

    private var medalColor: Color {
        switch rank {
        case 1: return Color.yellow.opacity(0.95)
        case 2: return Color.white.opacity(0.85)
        default: return Color.orange.opacity(0.85)
        }
    }

    private var ringColor: Color {
        switch rank {
        case 1: return Color.appGreen.opacity(0.90)
        case 2: return Color.white.opacity(0.20)
        default: return Color.white.opacity(0.18)
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: isWinner ? 96 : 76, height: isWinner ? 96 : 76)

                Circle()
                    .stroke(ringColor, lineWidth: isWinner ? 2 : 1)
                    .frame(width: isWinner ? 108 : 76, height: isWinner ? 108 : 76)

                Image(systemName: "medal.fill")
                    .font(.system(size: isWinner ? 34 : 28, weight: .semibold))
                    .foregroundColor(medalColor)
            }

            Text("#\(rank)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(isWinner ? Color.appGreen.opacity(0.95) : .white.opacity(0.65))

            VStack(spacing: 4) {
                Text(name)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)

                Text("\(points) pts")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }
        }
    }
}

// ✅ Ranking row
struct RankingRowView: View {
    let row: RankingRow

    var body: some View {
        HStack(spacing: 12) {

            Text("#\(row.rank)")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.65))
                .frame(width: 34, alignment: .leading)

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 34, height: 34)

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(row.name)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))

                Text(row.role)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.50))
            }

            Spacer()

            Text("\(row.points) pts")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}
