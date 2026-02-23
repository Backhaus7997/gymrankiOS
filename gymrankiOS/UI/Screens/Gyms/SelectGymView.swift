import SwiftUI
import FirebaseAuth

struct SelectGymView: View {

    @Binding var path: NavigationPath
    @State private var query: String = ""

    @State private var gyms: [Gym] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    private var filteredGyms: [Gym] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return gyms }
        return gyms.filter {
            $0.name.lowercased().contains(q) || $0.city.lowercased().contains(q)
        }
    }

    var body: some View {
        ZStack {
            SelectGymBackground()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                VStack(alignment: .leading, spacing: 6) {
                    Text("Elegí tu gimnasio")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text("Seleccioná el gym donde entrenás")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)

                Spacer().frame(height: 14)

                SearchBar(text: $query)
                    .padding(.horizontal, 18)

                Spacer().frame(height: 16)

                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {

                            GymCardGeneric(
                                title: "Mi gimnasio no esta",
                                subtitle: "Continuá sin vincular",
                                badge: "⭐ Opción manual",
                                assetName: "gym"
                            ) {
                                path.append(AppRoute.dashboard)
                            }

                            ForEach(filteredGyms) { gym in
                                GymCardLive(gym: gym) {
                                    Task { await joinGym(gym) }
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 32)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .safeAreaPadding(.top, 8)
        }
        .task { await loadGyms() }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Ocurrió un error.")
        }
    }

    // MARK: - Data

    private func loadGyms() async {
        isLoading = true
        defer { isLoading = false }

        do {
            gyms = try await GymRepository.shared.fetchActiveGyms()
        } catch {
            errorMessage = (error as NSError).localizedDescription
            showErrorAlert = true
        }
    }

    private func joinGym(_ gym: Gym) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "No hay sesión activa. Volvé a iniciar sesión."
            showErrorAlert = true
            return
        }

        do {
            try await UserRepository.shared.setGym(uid: uid, gymId: gym.id, gymNameCache: gym.name)
            path.append(AppRoute.dashboard)
        } catch {
            errorMessage = (error as NSError).localizedDescription
            showErrorAlert = true
        }
    }
}

// MARK: - Background

private struct SelectGymBackground: View {
    var body: some View {
        ZStack {
            Color.black

            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.05),
                    Color.clear
                ]),
                center: .top,
                startRadius: 30,
                endRadius: 550
            )

            RadialGradient(
                gradient: Gradient(colors: [
                    Color.appGreen.opacity(0.12),
                    Color.clear
                ]),
                center: .center,
                startRadius: 60,
                endRadius: 480
            )
        }
    }
}

// MARK: - Search

private struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.45))

            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text("Buscar por nombre o ciudad…")
                        .foregroundColor(.white.opacity(0.35))
                }
                .foregroundColor(.white)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

// MARK: - Cards (Live from Firestore)

private struct GymCardLive: View {
    let gym: Gym
    let onJoin: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack(alignment: .topLeading) {
                // Usamos una imagen genérica (podés mapear por city o id después)
                Image("gym")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.10),
                                Color.black.opacity(0.75)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)

                VStack(alignment: .leading, spacing: 10) {
                    // badge opcional (si después lo querés en Firestore)
                    BadgePill(text: "🔥 Alta competencia")

                    Spacer()

                    VStack(alignment: .leading, spacing: 6) {
                        Text(gym.name)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)

                        Text("\(gym.city), Argentina")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }
                .padding(16)
            }
            .frame(height: 150)

            JoinButton(title: "Unirme", action: onJoin)
                .padding(16)
        }
    }
}

// MARK: - Generic card (fallback first option)

private struct GymCardGeneric: View {
    let title: String
    let subtitle: String
    let badge: String?
    let assetName: String
    let onJoin: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack(alignment: .topLeading) {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.10),
                                Color.black.opacity(0.75)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)

                VStack(alignment: .leading, spacing: 10) {
                    if let badge {
                        BadgePill(text: badge)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)

                        Text(subtitle)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }
                .padding(16)
            }
            .frame(height: 150)

            JoinButton(title: "Continuar", action: onJoin)
                .padding(16)
        }
    }
}

private struct BadgePill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(Color.black.opacity(0.40))
            )
            .overlay(
                Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }
}

private struct JoinButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, 18)
                .frame(height: 34)
                .background(Capsule().fill(Color.appGreen.opacity(0.90)))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SelectGymView(path: .constant(NavigationPath()))
}
