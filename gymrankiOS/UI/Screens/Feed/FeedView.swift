import SwiftUI

// MARK: - Feed

struct FeedView: View {

    let bottomInset: CGFloat

    @State private var selected: Segment = .publico

    enum Segment: String, CaseIterable, Identifiable {
        case amigos = "Amigos"
        case publico = "Público"
        var id: String { rawValue }
    }

    private var items: [FeedPost] {
        switch selected {
        case .amigos: return FeedPost.mockFriends
        case .publico: return FeedPost.mockPublic
        }
    }

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            VStack(spacing: 12) {
                segmentedTop

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(items) { post in
                            FeedPostCard(post: post)
                        }

                        Spacer().frame(height: bottomInset + 90)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .padding(.top, 8)
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Segmented (arriba)

    private var segmentedTop: some View {
        HStack(spacing: 0) {
            ForEach(Segment.allCases) { seg in
                Button {
                    selected = seg
                } label: {
                    VStack(spacing: 10) {
                        Text(seg.rawValue)
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(selected == seg ? .white.opacity(0.95) : .white.opacity(0.55))
                            .frame(maxWidth: .infinity)

                        Rectangle()
                            .fill(selected == seg ? Color.appGreen : Color.clear)
                            .frame(height: 2)
                            .padding(.horizontal, 38)
                    }
                    .padding(.top, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Card

private struct FeedPostCard: View {
    let post: FeedPost

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Imagen header
            ZStack(alignment: .topLeading) {
                Image(post.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipped()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.55),
                        Color.black.opacity(0.12),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            // Autor + nivel + escudo
            HStack(spacing: 10) {
                avatar

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(post.username)
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(.white.opacity(0.92))

                        LevelPill(level: post.level)
                    }

                    Text(post.subtitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                Image(systemName: "shield")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.45))
            }

            // Título
            Text(post.title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
                .padding(.top, 2)

            // Lista ejercicios
            VStack(spacing: 8) {
                ForEach(post.exercises) { ex in
                    ExerciseRow(ex: ex)
                }
            }

            // CTA
            Button {
                print("ver entrenamiento completo \(post.username)")
            } label: {
                Text("Ver entrenamiento completo →")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.appGreen.opacity(0.95))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            // Meta
            Text("\(post.visibility)  •  \(post.timeAgo)")
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

    private var avatar: some View {
        Group {
            if let ui = UIImage(named: post.avatarName) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                // fallback si falta el asset
                ZStack {
                    Circle().fill(Color.white.opacity(0.10))
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.65))
                }
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

private struct LevelPill: View {
    let level: Int

    var body: some View {
        Text("Nivel \(level)")
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundColor(Color.appGreen.opacity(0.95))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.appGreen.opacity(0.10))
            )
            .overlay(
                Capsule().stroke(Color.appGreen.opacity(0.35), lineWidth: 1)
            )
    }
}

private struct ExerciseRow: View {
    let ex: FeedExercise

    var body: some View {
        HStack {
            Text(ex.name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.90))

            Spacer()

            Text("\(ex.reps) · \(ex.weight)")
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

// MARK: - Models

private struct FeedPost: Identifiable {
    let id = UUID()
    let imageName: String
    let avatarName: String
    let username: String
    let level: Int
    let subtitle: String
    let title: String
    let exercises: [FeedExercise]
    let visibility: String
    let timeAgo: String

    static let mockFriends: [FeedPost] = [
        .init(
            imageName: "feed1",
            avatarName: "avatar1",
            username: "lucho.power",
            level: 27,
            subtitle: "Entrena con vos",
            title: "Piernas pesado",
            exercises: [
                .init(name: "Sentadilla trasera", reps: "5", weight: "140 kg"),
                .init(name: "Prensa", reps: "12", weight: "240 kg"),
                .init(name: "Curl femoral", reps: "12", weight: "50 kg")
            ],
            visibility: "Amigos",
            timeAgo: "Hace 20 min"
        ),
        .init(
            imageName: "feed2",
            avatarName: "avatar2",
            username: "maria.fit",
            level: 19,
            subtitle: "Constante",
            title: "Upper rápido",
            exercises: [
                .init(name: "Press banca", reps: "8", weight: "45 kg"),
                .init(name: "Remo con manc.", reps: "10", weight: "20 kg"),
                .init(name: "Elevaciones laterales", reps: "15", weight: "7.5 kg")
            ],
            visibility: "Amigos",
            timeAgo: "Hace 1 h"
        ),
        .init(
            imageName: "feed3",
            avatarName: "avatar3",
            username: "tomi.hybrid",
            level: 33,
            subtitle: "Metas claras",
            title: "Full body + cardio",
            exercises: [
                .init(name: "Peso muerto", reps: "5", weight: "160 kg"),
                .init(name: "Dominadas", reps: "10", weight: "BW"),
                .init(name: "Cinta", reps: "20 min", weight: "—")
            ],
            visibility: "Amigos",
            timeAgo: "Hace 4 h"
        )
    ]

    static let mockPublic: [FeedPost] = [
        .init(
            imageName: "feed4",
            avatarName: "avatar4",
            username: "agus.strength",
            level: 41,
            subtitle: "Primeros pasos",
            title: "Piernas pesado",
            exercises: [
                .init(name: "Sentadilla trasera", reps: "5", weight: "160 kg"),
                .init(name: "Prensa", reps: "10", weight: "280 kg"),
                .init(name: "Curl femoral", reps: "12", weight: "55 kg")
            ],
            visibility: "Público",
            timeAgo: "Hace 3 h"
        ),
        .init(
            imageName: "feed5",
            avatarName: "avatar5",
            username: "vale.runner",
            level: 18,
            subtitle: "Primeros pasos",
            title: "Espalda + bíceps",
            exercises: [
                .init(name: "Remo con barra", reps: "8", weight: "60 kg"),
                .init(name: "Jalón al pecho", reps: "12", weight: "45 kg"),
                .init(name: "Curl bíceps", reps: "12", weight: "12 kg")
            ],
            visibility: "Público",
            timeAgo: "Hace 6 h"
        ),
        .init(
            imageName: "feed6",
            avatarName: "avatar6",
            username: "sofi.lifts",
            level: 24,
            subtitle: "En progreso",
            title: "Pecho + tríceps",
            exercises: [
                .init(name: "Press inclinado", reps: "10", weight: "40 kg"),
                .init(name: "Fondos", reps: "12", weight: "BW"),
                .init(name: "Extensión tríceps", reps: "15", weight: "20 kg")
            ],
            visibility: "Público",
            timeAgo: "Hace 10 h"
        )
    ]
}

private struct FeedExercise: Identifiable {
    let id = UUID()
    let name: String
    let reps: String
    let weight: String
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FeedView(bottomInset: 96)
    }
}
