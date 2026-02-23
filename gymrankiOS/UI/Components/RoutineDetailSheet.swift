//
//  RoutineDetailSheet.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 20/02/2026.
//

import SwiftUI

struct RoutineDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let routine: WorkoutRoutine
    let onClose: (() -> Void)?

    init(routine: WorkoutRoutine, onClose: (() -> Void)? = nil) {
        self.routine = routine
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            // ✅ Fondo oscuro para que se lea
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture { close() }

            // ✅ Modal centrado
            VStack(spacing: 12) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        infoCard

                        VStack(spacing: 10) {
                            ForEach(routine.exercises) { ex in
                                exerciseRow(ex)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }
            }
            .frame(maxWidth: 560)
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(
                // ✅ Fondo del modal MUCHO menos transparente
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.black.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.55), radius: 24, x: 0, y: 14)
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Detalles")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Button { close() } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.10)))
                    .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
    }

    // MARK: - Info

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(routine.title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))

            if let desc = routine.description,
               !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(desc)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.70))
            }

            HStack(spacing: 10) {
                chip("\(routine.exercises.count) ej.")
                if let created = routine.createdAt {
                    chip(created.formatted(date: .abbreviated, time: .omitted))
                }
            }
            .padding(.top, 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.08)) // ✅ más sólido
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    // MARK: - Exercise row

    private func exerciseRow(_ ex: RoutineExercise) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(ex.name)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))

                Text(ex.usesBodyweight ? "Peso corporal" : "Peso: \(ex.weightKg ?? 0) kg")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
            }

            Spacer()

            Text("\(ex.sets)x\(ex.reps)")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(Color.appGreen.opacity(0.95))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08)) // ✅ más sólido
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    // MARK: - Chip

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundColor(Color.appGreen.opacity(0.95))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.black.opacity(0.55))) // ✅ más legible
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
    }

    // MARK: - Close

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}
