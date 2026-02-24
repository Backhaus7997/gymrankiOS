//
//  MuscleRecoveryHomeCard.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 23/02/2026.
//

import SwiftUI

struct MuscleRecoveryHomeCard: View {
    let schedule: MuscleRecoveryEngine.Schedule
    let onTapDetails: () -> Void

    private let topCount = 4

    var body: some View {
        let items = MuscleRecoveryEngine.top(schedule: schedule, limit: topCount)

        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Recuperación muscular")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))

                Spacer()

                Button(action: onTapDetails) {
                    Text("Detalles")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(.appGreen.opacity(0.95))
                }
                .buttonStyle(.plain)
            }

            if items.isEmpty {
                Text("Cargá una rutina para ver la recuperación por músculo.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            } else {
                VStack(spacing: 10) {
                    ForEach(items) { it in
                        MuscleRecoveryRow(item: it)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}
