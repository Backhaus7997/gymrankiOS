import SwiftUI

struct SelectGymView: View {

    @Binding var path: NavigationPath
    @State private var query: String = ""

    private let gyms: [GymCardModel] = [
        .init(name: "Iron Temple", city: "Buenos Aires, Argentina", badge: "🔥 Alta competencia", assetName: "gym"),
        .init(name: "Titan Gym", city: "Córdoba, Argentina", badge: "🔥 Alta competencia", assetName: "gym2"),
        .init(name: "Beast Factory", city: "Rosario, Argentina", badge: "🔥 Alta competencia", assetName: "gym3"),
        .init(name: "Fuerza Sur", city: "La Plata, Argentina", badge: nil, assetName: "gym4"),
        .init(name: "Power House", city: "Mar del Plata, Argentina", badge: nil, assetName: "gym5"),
        .init(name: "Strong Nation", city: "Mendoza, Argentina", badge: "🔥 Alta competencia", assetName: "gym6")
    ]

    private var filteredGyms: [GymCardModel] {
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

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredGyms) { gym in
                            GymCard(gym: gym) {
                                path.append(AppRoute.dashboard)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 32)
                }
                .frame(maxHeight: .infinity)
            }
            .safeAreaPadding(.top, 8)
        }
    }
}

// MARK: - Model

struct GymCardModel: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let city: String
    let badge: String?
    let assetName: String
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

// MARK: - Card

private struct GymCard: View {
    let gym: GymCardModel
    let onJoin: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {

            ZStack(alignment: .topLeading) {

                // ✅ Imagen bien recortada
                Image(gym.assetName)
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

                // ✅ capa glass sutil
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                // ✅ borde
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)

                VStack(alignment: .leading, spacing: 10) {
                    if let badge = gym.badge {
                        BadgePill(text: badge)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 6) {
                        Text(gym.name)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)

                        Text(gym.city)
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
