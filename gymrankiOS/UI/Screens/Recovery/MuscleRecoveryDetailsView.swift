//
//  MuscleRecoveryDetailsView.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 23/02/2026.
//

import SwiftUI

struct MuscleRecoveryDetailsView: View {
    let schedule: MuscleRecoveryEngine.Schedule

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {

                    Text("Recuperación muscular")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 6)

                    let all = MuscleRecoveryEngine.computeAll(schedule: schedule)

                    if all.isEmpty {
                        Text("No hay músculos en la rutina.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.60))
                            .padding(.top, 10)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(all) { it in
                                MuscleRecoveryRow(item: it)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.10), lineWidth: 1))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 120)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
