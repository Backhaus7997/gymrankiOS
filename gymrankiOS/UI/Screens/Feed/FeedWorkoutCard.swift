//
//  FeedWorkoutCard.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 26/02/2026.
//

import SwiftUI

struct FeedWorkoutCard: View {
    let item: FeedWorkoutItem
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            headerImage
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            // Autor + nivel + escudo
            HStack(spacing: 10) {
                avatar

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(item.authorUsername)
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(.white.opacity(0.92))
                            .lineLimit(1)

                        LevelPill(level: item.authorLevel)
                    }

                    Text(item.authorSubtitle ?? "En progreso")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "shield")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.45))
            }

            // Título
            Text(item.title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
                .padding(.top, 2)

            // Lista ejercicios (hasta 3)
            if !item.exercisesSummary.isEmpty {
                VStack(spacing: 8) {
                    ForEach(item.exercisesSummary) { ex in
                        ExerciseRow2(name: ex.name, reps: ex.reps, weight: ex.weight)
                    }
                }
            }

            // CTA
            Button(action: onOpen) {
                Text("Ver entrenamiento completo →")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.appGreen.opacity(0.95))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            // Meta
            Text("\(item.visibilityLabel)  •  \(item.timeAgo)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
                .padding(.top, 2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.appGreen.opacity(0.18), lineWidth: 1)
                )
        )
    }

    // MARK: - Header (como mock)

    private var headerImage: some View {
        ZStack(alignment: .topLeading) {
            if let ui = UIImage(named: "feed_header") {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            }

            LinearGradient(
                colors: [Color.black.opacity(0.55), Color.black.opacity(0.12), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
        }
    }

    // MARK: - Avatar real

    private var avatar: some View {
        Group {
            if let urlStr = item.authorAvatarUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    case .empty:
                        fallbackAvatar.opacity(0.65)
                    case .failure:
                        fallbackAvatar
                    @unknown default:
                        fallbackAvatar
                    }
                }
            } else {
                fallbackAvatar
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
    }

    private var fallbackAvatar: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.10))
            Image(systemName: "person.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white.opacity(0.65))
        }
    }
}

// MARK: - Subviews

private struct ExerciseRow2: View {
    let name: String
    let reps: String
    let weight: String

    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.90))
                .lineLimit(2)

            Spacer()

            Text("\(reps) · \(weight)")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.65))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.30))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
