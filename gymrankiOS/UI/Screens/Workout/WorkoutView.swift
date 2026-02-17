//
//  WorkoutView.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 06/02/2026.
//

import SwiftUI

struct WorkoutView: View {

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            VStack(spacing: 14) {
                WorkoutTopBar()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        QuickActionsGrid()

                        RecoveryCard()

                        MyRoutinesCard()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

// MARK: - Top bar

private struct WorkoutTopBar: View {
    var body: some View {
        HStack {
            Text("Entrenar")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Button {
                print("menu")
            } label: {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }
}

// MARK: - Grid

private struct QuickActionsGrid: View {

    private let items: [QuickActionItem] = [
        .init(title: "Explorar", icon: "magnifyingglass"),
        .init(title: "Coach IA", icon: "sparkles"),
        .init(title: "Historial", icon: "arrow.counterclockwise"),
        .init(title: "Progreso", icon: "chart.bar.fill")
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(items) { item in
                QuickActionCard(item: item)
            }
        }
    }
}

private struct QuickActionItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
}

private struct QuickActionCard: View {
    let item: QuickActionItem

    var body: some View {
        HStack(spacing: 12) {

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.appGreen.opacity(0.18))
                    .frame(width: 42, height: 42)

                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.appGreen.opacity(0.95))
            }

            Text(item.title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.92))

            Spacer()
        }
        .padding(14)
        .frame(height: 78)
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

// MARK: - Recovery

private struct RecoveryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Recuperación muscular")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))

                Spacer()

                Button("Detalles") { print("detalles") }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.appGreen)
                    .buttonStyle(.plain)
            }

            HStack(spacing: 14) {
                RecoverySmallCard(title: "Abductores", percent: "100%")
                RecoverySmallCard(title: "Abdominales", percent: "100%")
            }
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
}

private struct RecoverySmallCard: View {
    let title: String
    let percent: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("💪")
                .font(.system(size: 28))

            Spacer()

            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.92))

            Text(percent)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Color.appGreen.opacity(0.95))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.black.opacity(0.35)))
                .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(height: 150)
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

// MARK: - My routines

private struct MyRoutinesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack {
                Text("Mis rutinas (0/1)")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Button {
                    print("add routine")
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.appGreen))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            HStack(spacing: 12) {
                Text("📝")
                    .font(.system(size: 22))

                Text("Creá tu primera rutina")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 260)
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
    WorkoutView()
}
