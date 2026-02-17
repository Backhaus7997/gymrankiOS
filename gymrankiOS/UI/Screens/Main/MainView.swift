//
//  MainView.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 17/02/2026.
//

import SwiftUI

struct MainView: View {

    let onGoToWorkout: () -> Void
    let onGoToRanking: () -> Void

    private let sideMargin: CGFloat = 12

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            GeometryReader { geo in
                let contentWidth = max(0, geo.size.width - (sideMargin * 2))

                VStack(spacing: 14) {

                    TopBar()
                        .frame(width: contentWidth, alignment: .center)
                        .padding(.top, 10)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            HomeQuickActionsRow(
                                onLoadWorkout: onGoToWorkout,
                                onViewRanking: onGoToRanking
                            )

                            WeeklyMusclesCard()

                            TrainingCalendarCard(maxWidth: contentWidth)

                            SetsPerMuscleCard()
                        }
                        .frame(width: contentWidth, alignment: .center)
                        .padding(.bottom, 120)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }
}

// MARK: - Top bar

private struct TopBar: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Hola 👋")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Button {
                    print("notifications")
                } label: {
                    Image(systemName: "bell")
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white.opacity(0.06)))
                        .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button {
                    print("profile")
                } label: {
                    Text("A")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white.opacity(0.06)))
                        .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Text("Atleta")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
        }
    }
}

// MARK: - Quick actions row

private struct HomeQuickActionsRow: View {
    let onLoadWorkout: () -> Void
    let onViewRanking: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            HomeQuickCard(
                title: "Cargar entreno",
                subtitle: "Registrá tu sesión",
                icon: "figure.strengthtraining.traditional",
                onTap: onLoadWorkout
            )

            HomeQuickCard(
                title: "Ver ranking",
                subtitle: "Tu posición y top",
                icon: "chart.line.uptrend.xyaxis",
                onTap: onViewRanking
            )
        }
        .padding(.top, 2)
    }
}

private struct HomeQuickCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.appGreen.opacity(0.16))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.appGreen.opacity(0.95))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .frame(height: 78)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.appGreen.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Weekly muscles

private struct WeeklyMusclesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Músculos entrenados esta semana")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text("Basado en entrenamientos cargados")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                Image(systemName: "gearshape")
                    .foregroundColor(.white.opacity(0.55))
            }

            // ✅ Intensidad (como en tu imagen)
            HStack(spacing: 10) {
                Text("Intensidad")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))

                IntensityDot(label: "1x", opacity: 0.35)
                IntensityDot(label: "2x", opacity: 0.60)
                IntensityDot(label: "3x+", opacity: 0.95)

                Spacer()
            }
            .padding(.top, 2)

            HStack(spacing: 14) {
                MuscleImageCard(title: "Frente", imageName: "bodyfront")
                MuscleImageCard(title: "Espalda", imageName: "bodyback")
            }

            Text("* Basado en entrenamientos completados")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
                .padding(.top, 2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appGreen.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private func IntensityDot(label: String, opacity: Double) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.appGreen.opacity(opacity))
                .frame(width: 6, height: 6)

            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.65))
        }
    }
}

private struct MuscleImageCard: View {
    let title: String
    let imageName: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.65))

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 1)
                        .padding(.vertical, 10)
                        .opacity(0.95)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
                .frame(height: 280)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Calendar

private struct TrainingCalendarCard: View {

    let maxWidth: CGFloat
    private let widthFactor: CGFloat = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Calendario de entrenamientos")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            // ✅ izquierda 0/7 + derecha 0%
            HStack {
                Text("Objetivo semanal: 0/7")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))

                Spacer()

                Text("0%")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            HStack(spacing: 14) {
                DayPill("L", isActive: true)
                DayPill("M")
                DayPill("M")
                DayPill("J")
                DayPill("V")
                DayPill("S")
                DayPill("D")
            }
            .padding(.top, 4)
        }
        .padding(14)
        .frame(width: maxWidth * widthFactor, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func DayPill(_ text: String, isActive: Bool = false) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 12)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isActive ? Color.white.opacity(0.10) : Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
    }
}

// MARK: - Sets per muscle

private struct SetsPerMuscleCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sets por músculo")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text("Esta semana")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                Image(systemName: "bell")
                    .foregroundColor(.white.opacity(0.55))
            }

            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.25))
                .frame(height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    MainView(
        onGoToWorkout: {},
        onGoToRanking: {}
    )
}
