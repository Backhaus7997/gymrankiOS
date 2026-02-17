//
//  HistoryView.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 10/02/2026.
//

import SwiftUI

struct WorkoutHistoryView: View {

    @Environment(\.dismiss) private var dismiss

    // Mock data (por ahora)
    private let totalWorkouts: Int = 0

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    topBar(title: "Historial de entrenamientos")

                    summaryCard

                    emptyStateCard

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - TopBar

    private func topBar(title: String) -> some View {
        HStack(spacing: 10) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Text(title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Spacer()
        }
    }

    // MARK: - Cards

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Resumen")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))

            Text("Total de entrenamientos")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))

            HStack(alignment: .lastTextBaseline) {
                Text("\(totalWorkouts)")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.appGreen.opacity(0.95))

                Spacer()

                Text("entrenamientos")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.appGreen.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private var emptyStateCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "dumbbell")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white.opacity(0.35))
                .padding(.top, 6)

            Text("Todavía no registraste entrenamientos")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
                .multilineTextAlignment(.center)

            Text("Cuando cargues uno, acá vas a ver el detalle con\nejercicios, series y pesos.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)

            Button {
                print("cargar entrenamiento")
            } label: {
                Text("Cargar entrenamiento")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .frame(width: 190, height: 44)
                    .background(Capsule().fill(Color.appGreen.opacity(0.95)))
            }
            .buttonStyle(.plain)
            .padding(.top, 6)

            Spacer(minLength: 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.appGreen.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.top, 6)
    }
}

#Preview {
    NavigationStack {
        WorkoutHistoryView()
    }
}
