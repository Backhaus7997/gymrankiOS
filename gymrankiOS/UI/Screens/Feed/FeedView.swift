import SwiftUI

struct FeedView: View {

    @EnvironmentObject private var session: SessionManager

    let bottomInset: CGFloat

    @State private var selected: Segment = .amigos
    @StateObject private var vm = FeedViewModel()

    enum Segment: String, CaseIterable, Identifiable {
        case amigos = "Amigos"
        case publico = "Público"
        var id: String { rawValue }
    }

    private var uid: String { session.userId }

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            VStack(spacing: 12) {
                segmentedTop

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {

                        // ✅ Buscar (para ambos tabs)
                        searchSection

                        if selected == .amigos {
                            friendsContent
                        } else {
                            publicContent
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
        .task { await initialLoad() }
        .onChange(of: selected) { _ in Task { await reloadForTab() } }
        .onChange(of: uid) { _ in Task { await reloadForTab() } }
    }

    // MARK: - Search UI

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Buscar")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.92))

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
    }

    // MARK: - Friends content (same cards)

    private var friendsContent: some View {
        VStack(alignment: .leading, spacing: 12) {

            if let err = vm.errorMessageFriends, !err.isEmpty {
                Text(err)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.red.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if vm.isLoadingFriends {
                SwiftUI.ProgressView()
                    .tint(Color.appGreen.opacity(0.95))
                    .padding(.top, 6)
            }

            if !vm.isLoadingFriends && vm.friendsItemsFiltered.isEmpty {
                Text(vm.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                     ? "Todavía no tenés amigos."
                     : "No se encontraron resultados.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            } else {
                ForEach(vm.friendsItemsFiltered) { item in
                    FeedProfileCard(
                        item: item,
                        myUid: uid,
                        status: vm.relationshipStatus(with: item.profile.uid),
                        onAddFriend: {
                            Task { await vm.sendRequest(myUid: uid, to: item.profile.uid) }
                        },
                        onOpenRoutine: { routine in
                            print("open routine \(routine.id) of \(item.profile.uid)")
                        }
                    )
                }
            }
        }
    }

    // MARK: - Public content

    private var publicContent: some View {
        VStack(alignment: .leading, spacing: 12) {

            if let err = vm.errorMessagePublic, !err.isEmpty {
                Text(err)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.red.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if vm.isLoadingPublic {
                SwiftUI.ProgressView()
                    .tint(Color.appGreen.opacity(0.95))
                    .padding(.top, 6)
            }

            if !vm.isLoadingPublic && vm.publicItemsFiltered.isEmpty {
                Text(vm.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                     ? "No hay usuarios para mostrar."
                     : "No se encontraron resultados.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            } else {
                ForEach(vm.publicItemsFiltered) { item in
                    FeedProfileCard(
                        item: item,
                        myUid: uid,
                        status: vm.relationshipStatus(with: item.profile.uid),
                        onAddFriend: {
                            Task { await vm.sendRequest(myUid: uid, to: item.profile.uid) }
                        },
                        onOpenRoutine: { routine in
                            print("open routine \(routine.id) of \(item.profile.uid)")
                        }
                    )
                }
            }
        }
    }

    // MARK: - Segmented top

    private var segmentedTop: some View {
        HStack(spacing: 0) {
            ForEach(Segment.allCases) { seg in
                Button { selected = seg } label: {
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

    // MARK: - Load helpers

    private func initialLoad() async {
        await reloadForTab()
    }

    private func reloadForTab() async {
        guard !uid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if selected == .amigos {
            await vm.loadFriends(myUid: uid)
        } else {
            await vm.loadPublic(myUid: uid)
        }
    }
}
