import SwiftUI

struct MissionsView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var showCreateMissionPopup: Bool = false

    private let sidePadding: CGFloat = 16

    private let programs: [ProgramItem] = [
        .init(title: "Candito - Fuerza 6 Sem.", subtitle: "Ideal para testear 1RM y competir", tag: "PRO", frequency: "4x/sem", level: "Intermedio", imageName: "feed1"),
        .init(title: "Juggernaut - Deadlift", subtitle: "Enfocado a levantar más en 16 semanas", tag: "PRO", frequency: "4x/sem", level: "Avanzado", imageName: "feed2"),
        .init(title: "Upper Hypertrophy", subtitle: "Volumen para torso y estética", tag: "Gratis", frequency: "5x/sem", level: "Intermedio", imageName: "feed3"),
        .init(title: "Full Body Strength", subtitle: "Fuerza general y progresiva", tag: "Gratis", frequency: "3x/sem", level: "Principiante", imageName: "feed4"),
        .init(title: "Core + Estabilidad", subtitle: "Abdomen + postura + control", tag: "PRO", frequency: "3x/sem", level: "Intermedio", imageName: "feed5"),
        .init(title: "Powerbuilding 8 Sem.", subtitle: "Fuerza + hipertrofia balanceada", tag: "PRO", frequency: "4x/sem", level: "Avanzado", imageName: "feed6"),
        .init(title: "Glúteos y Pierna", subtitle: "Enfoque en lower body", tag: "Gratis", frequency: "3x/sem", level: "Principiante", imageName: "gym1"),
        .init(title: "Strong Back", subtitle: "Espalda fuerte + prevención", tag: "PRO", frequency: "3x/sem", level: "Intermedio", imageName: "gym2"),
        .init(title: "Push/Pull/Legs", subtitle: "Split clásico con progresión", tag: "Gratis", frequency: "6x/sem", level: "Avanzado", imageName: "gym3"),
        .init(title: "Hypertrophy Upper", subtitle: "Torso con buen volumen", tag: "PRO", frequency: "4x/sem", level: "Intermedio", imageName: "gym4"),
        .init(title: "Conditioning", subtitle: "Cardio + resistencia", tag: "Gratis", frequency: "3x/sem", level: "Principiante", imageName: "gym5"),
        .init(title: "Olympic Basics", subtitle: "Técnica de levantamientos", tag: "PRO", frequency: "3x/sem", level: "Intermedio", imageName: "gym6")
    ]

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            VStack(spacing: 12) {

                headerFixed
                    .padding(.horizontal, sidePadding)
                    .padding(.top, 10)

                Divider()
                    .overlay(Color.white.opacity(0.08))
                    .padding(.horizontal, sidePadding)

                missionsScroll
            }
        }
        .safeAreaInset(edge: .bottom) {
            createMissionButton
                .padding(.horizontal, sidePadding)
                .padding(.bottom, 12)
        }
        .overlay {
            if showCreateMissionPopup {
                CenterModalOverlay(isPresented: $showCreateMissionPopup) {
                    CreateMissionPopupCard(
                        onClose: { showCreateMissionPopup = false },
                        onNext: { selected in
                            print("siguiente: \(selected)")
                            showCreateMissionPopup = false
                        }
                    )
                    .padding(.horizontal, 18)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Header (no scrollea)

    private var headerFixed: some View {
        VStack(alignment: .leading, spacing: 12) {
            topBar
            headerCard
            chipsRow
            searchBar
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Text("Desafíos")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))

            Spacer()

            Button { print("menu") } label: {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Programas y rutinas")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))

            Text("Elegí un programa y empezá hoy.")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private var chipsRow: some View {
        HStack(spacing: 10) {
            Chip(text: "Oficial", isActive: true)
            Chip(text: "Comunidad", isActive: false)
            Spacer()
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.55))

            Text("Buscar programas...")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.45))

            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    // MARK: - Scroll SOLO misiones

    private var missionsScroll: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(programs) { item in
                    ProgramCard(item: item)
                }

                Spacer().frame(height: 140)
            }
            .padding(.horizontal, sidePadding)
            .padding(.top, 10)
        }
    }

    // MARK: - Bottom fixed button

    private var createMissionButton: some View {
        Button {
            showCreateMissionPopup = true
        } label: {
            Text("Crear misión")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.appGreen.opacity(0.95))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Models

private struct ProgramItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let tag: String
    let frequency: String
    let level: String
    let imageName: String?   // ✅ NUEVO (opcional)
}

// MARK: - Components (igual que antes)

private struct Chip: View {
    let text: String
    let isActive: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundColor(isActive ? Color.appGreen.opacity(0.95) : .white.opacity(0.60))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isActive ? Color.appGreen.opacity(0.10) : Color.white.opacity(0.06))
            )
            .overlay(
                Capsule().stroke(isActive ? Color.appGreen.opacity(0.35) : Color.white.opacity(0.10), lineWidth: 1)
            )
    }
}

private struct ProgramCard: View {
    let item: ProgramItem

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {

                // ✅ MISMO CUADRADO, ahora soporta imagen
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.22))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Group {
                            if let name = item.imageName {
                                Image(name)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipped()
                            } else {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white.opacity(0.35))
                            }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        Text(item.tag)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(item.tag == "PRO" ? .black : .white.opacity(0.85))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(item.tag == "PRO" ? Color.appGreen.opacity(0.90) : Color.white.opacity(0.08))
                            )
                            .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))

                        Text(item.title)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(.white.opacity(0.92))
                            .lineLimit(1)

                        Spacer()

                        Button { print("ver \(item.title)") } label: {
                            Text("Ver")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color.appGreen.opacity(0.95)))
                        }
                        .buttonStyle(.plain)
                    }

                    Text(item.subtitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(2)
                }
            }

            HStack(spacing: 12) {
                StatMiniCard(title: "Frecuencia", value: item.frequency)
                StatMiniCard(title: "Nivel", value: item.level)
            }
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
}

private struct StatMiniCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))

            Text(value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationStack {
        MissionsView()
    }
}
