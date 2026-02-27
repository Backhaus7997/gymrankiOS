import SwiftUI

struct FeedView: View {

    @EnvironmentObject private var session: SessionManager

    let bottomInset: CGFloat

    @State private var selected: Segment = .publico
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
                    VStack(spacing: 14) {

                        if selected == .amigos {
                            // ✅ Tab de amigos (ya lo tenés funcionando)
                            ProfilesTabView(myUid: uid)

                        } else {
                            // ✅ Público

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

                            ForEach(vm.publicItems) { item in
                                FeedProfileCard(
                                    item: item,
                                    myUid: uid,
                                    status: vm.relationshipStatus(with: item.profile.uid),
                                    onAddFriend: {
                                        Task { await vm.sendRequest(myUid: uid, to: item.profile.uid) }
                                    },
                                    onOpenRoutine: { routinePreview in
                                        print("open routine \(routinePreview.id) of \(item.profile.uid)")
                                    }
                                )
                            }
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
        .task {
            if selected == .publico {
                await vm.loadPublic(myUid: uid)
            }
        }
        .onChange(of: selected) { newValue in
            if newValue == .publico {
                Task { await vm.loadPublic(myUid: uid) }
            }
        }
        .onChange(of: uid) { _ in
            // si cambia sesión, refrescamos el público
            if selected == .publico {
                Task { await vm.loadPublic(myUid: uid) }
            }
        }
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
