import SwiftUI

struct ProfilesTabView: View {

    let myUid: String
    @StateObject private var vm = ProfilesViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            header
            searchBar

            if let err = vm.errorMessage, !err.isEmpty {
                Text(err)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.red.opacity(0.9))
                    .padding(.horizontal, 2)
            }

            VStack(spacing: 14) {

                sectionTitle("Tus amigos")

                if vm.isLoading {
                    SwiftUI.ProgressView()
                        .tint(Color.appGreen.opacity(0.95))
                        .padding(.top, 6)
                } else if vm.friendsFiltered.isEmpty {
                    emptyState("Todavía no tenés amigos.")
                } else {
                    VStack(spacing: 10) {
                        ForEach(vm.friendsFiltered) { u in
                            FriendRow(user: u) {
                                Task { await vm.remove(uid: u.uid) } // opcional: eliminar amigo
                            }
                        }
                    }
                }

                Spacer().frame(height: 6)
            }
        }
        .task { await vm.load(myUid: myUid) }
    }

    // MARK: - Header + Search

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Amigos")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))

                Text("Tus amigos")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            if vm.isLoading {
                SwiftUI.ProgressView()
                    .tint(Color.appGreen.opacity(0.95))
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.55))

            TextField("Buscar por username", text: $vm.searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundColor(.white.opacity(0.92))

            if !vm.searchText.isEmpty {
                Button { vm.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.appGreen.opacity(0.18), lineWidth: 1)
                )
        )
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .foregroundColor(.white.opacity(0.80))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
    }

    private func emptyState(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.55))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
    }
}

// MARK: - Friend row (simple)

private struct FriendRow: View {
    let user: UserProfile
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {

            ZStack {
                Circle().fill(Color.white.opacity(0.10))
                Image(systemName: "person.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.65))
            }
            .frame(width: 42, height: 42)
            .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(user.displayName)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(1)

                    LevelPill(level: user.level)
                }

                Text(user.displaySubtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer()

            Button { onRemove() } label: {
                Image(systemName: "person.badge.minus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.75))
                    .frame(width: 38, height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.appGreen.opacity(0.18), lineWidth: 1)
                )
        )
    }
}
