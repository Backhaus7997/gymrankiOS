import SwiftUI

struct FeedProfileCard: View {

    let item: FeedProfileItem
    let myUid: String

    let status: FriendStatus?          // nil => no relación
    let onAddFriend: () -> Void
    let onOpenRoutine: (FeedRoutinePreview) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerPlaceholder
            authorRow
            routinesSection
        }
        .padding(14)
        .background(cardBg)
    }

    // MARK: - Header (placeholder)
    private var headerPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .frame(height: 180)

            LinearGradient(
                colors: [Color.black.opacity(0.35), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    // MARK: - Author row + botón
    private var authorRow: some View {
        HStack(spacing: 10) {
            avatar

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.profile.displayName)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))

                    LevelPill(level: item.profile.level)
                }

                Text(item.profile.displaySubtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            addButton
        }
    }

    // ✅ Botón AGREGAR / PENDIENTE / AMIGOS
    private var addButton: some View {
        let isMe = item.profile.uid == myUid
        if isMe { return AnyView(EmptyView()) }

        if status == .accepted {
            return AnyView(pill(text: "AMIGOS", disabled: true) {})
        }
        if status == .requested {
            return AnyView(pill(text: "PENDIENTE", disabled: true) {})
        }
        if status == .blocked {
            return AnyView(pill(text: "BLOQUEADO", disabled: true) {})
        }

        return AnyView(pill(text: "AGREGAR", disabled: false) { onAddFriend() })
    }

    private func pill(text: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            guard !disabled else { return }
            action()
        } label: {
            Text(text)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(disabled ? .white.opacity(0.55) : .black.opacity(0.90))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(disabled ? Color.white.opacity(0.10) : Color.appGreen.opacity(0.95))
                )
        }
        .buttonStyle(.plain)
    }

    private var avatar: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.10))
            Image(systemName: "person.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white.opacity(0.65))
        }
        .frame(width: 42, height: 42)
        .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
    }

    // MARK: - Routines (ahora previews)
    private var routinesSection: some View {
        VStack(spacing: 12) {
            if item.latestRoutines.isEmpty {
                Text("Todavía no hay entrenamientos para mostrar.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                let top3 = Array(item.latestRoutines.prefix(3))
                ForEach(top3, id: \.id) { r in
                    Button {
                        onOpenRoutine(r)
                    } label: {
                        routineRow(r)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func routineRow(_ r: FeedRoutinePreview) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(r.title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))

            VStack(spacing: 8) {
                ForEach(r.exercisesSummary) { ex in
                    HStack {
                        Text(ex.name)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.90))

                        Spacer()

                        Text("\(ex.reps) • \(ex.weight)")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.30)))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
                }
            }

            Text("Ver entrenamiento completo →")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(Color.appGreen.opacity(0.95))

            Text("Público • \(r.timeAgo)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.appGreen.opacity(0.18), lineWidth: 1))
    }

    private var cardBg: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.appGreen.opacity(0.18), lineWidth: 1)
            )
    }
}
