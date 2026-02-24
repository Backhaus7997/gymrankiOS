//
//  MuscleRecoveryRow.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 23/02/2026.
//

import SwiftUI

struct MuscleRecoveryRow: View {
    let item: MuscleRecovery

    var body: some View {
        HStack(spacing: 12) {

            Text(item.muscle)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
                .lineLimit(1)
                .frame(width: 120, alignment: .leading)

            ProgressBar(value: item.percent)

            Text("\(Int(round(item.percent * 100)))%")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(.appGreen.opacity(0.95))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.06)))
                .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
        }
    }
}

private struct ProgressBar: View {
    let value: Double // 0...1

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.06))
                    .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))

                Capsule()
                    .fill(Color.appGreen.opacity(0.85))
                    .frame(width: max(8, w * CGFloat(value)))
            }
        }
        .frame(height: 12)
    }
}
