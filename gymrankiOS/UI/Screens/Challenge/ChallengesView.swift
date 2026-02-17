import SwiftUI

struct ChallengesView: View {

    @State private var selected: Segment = .pending
    @State private var route: Route? = nil
    @State private var showEquipmentSheet = false
    @State private var showDestinyBetPopup = false

    private let sidePadding: CGFloat = 16

    enum Segment: String, CaseIterable, Identifiable {
        case pending = "Pendientes"
        case progress = "Progreso"
        case activity = "Actividad"
        var id: String { rawValue }

        var icon: String {
            switch self {
            case .pending: return "checkmark.circle"
            case .progress: return "chart.bar"
            case .activity: return "waveform.path.ecg"
            }
        }
    }

    enum Route: Hashable, Identifiable {
        case discover
        case missions
        var id: String { String(describing: self) }
    }

    private let items: [QuickCard] = [
        .init(title: "Descubrir", subtitle: "Nuevos desafíos", icon: "magnifyingglass"),
        .init(title: "Misiones", subtitle: "Crear y gestionar", icon: "checklist"),
        .init(title: "Apuestas", subtitle: "Rueda y dados", icon: "die.face.5"),
        .init(title: "Equipamiento", subtitle: "Tus ítems y stats", icon: "wrench.and.screwdriver")
    ]

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    topBar

                    quickActionsGrid

                    Text("Vista:")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.top, 4)

                    segmented

                    emptyStateCard

                    Spacer(minLength: 110)
                }
                .padding(.horizontal, sidePadding)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            if showDestinyBetPopup {
                CenterModalOverlay(isPresented: $showDestinyBetPopup) {
                    DestinyBetFlowPopup(onClose: { showDestinyBetPopup = false })
                        .padding(.horizontal, 18)
                }
                .zIndex(50)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(item: $route) { r in
            switch r {
            case .discover:
                ChallengesDiscoverView()
            case .missions:
                MissionsView()
            }
        }
        .sheet(isPresented: $showEquipmentSheet) {
            EquipmentView { selectedItems in
                print("Equipamiento elegido:", selectedItems)
            }
            .presentationDetents([.fraction(0.70), .large])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(22)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Text("Desafíos")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Button {
                print("menu")
            } label: {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 6)
    }

    // MARK: - Grid

    private var quickActionsGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(items) { item in
                Button {
                    handleQuickTap(item.title)
                } label: {
                    QuickCardView(item: item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func handleQuickTap(_ title: String) {
        switch title {
        case "Descubrir":
            route = .discover
        case "Misiones":
            route = .missions
        case "Equipamiento":
            showEquipmentSheet = true
        case "Apuestas":
            showDestinyBetPopup = true
        default:
            print("tap \(title)")
        }
    }

    // MARK: - Segmented

    private var segmented: some View {
        HStack(spacing: 10) {
            ForEach(Segment.allCases) { seg in
                Button {
                    selected = seg
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: seg.icon)
                            .font(.system(size: 13, weight: .bold))

                        Text(seg.rawValue)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .lineLimit(1)
                    }
                    .foregroundColor(selected == seg ? Color.appGreen : .white.opacity(0.55))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(selected == seg ? Color.appGreen.opacity(0.12) : Color.white.opacity(0.06))
                    )
                    .overlay(
                        Capsule()
                            .stroke(selected == seg ? Color.appGreen.opacity(0.35) : Color.white.opacity(0.10), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 2)
    }

    // MARK: - Empty state

    private var emptyStateCard: some View {
        VStack(spacing: 14) {

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.25))
                .frame(height: 210)
                .overlay(
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 54, weight: .bold))
                        .foregroundColor(.white.opacity(0.30))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
                .padding(.top, 6)

            VStack(spacing: 6) {
                Text("No hay desafíos activos")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))

                Text("Creá un desafío para mejorar tu nivel")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            Capsule()
                .fill(Color.appGreen.opacity(0.50))
                .frame(width: 70, height: 4)
                .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.appGreen.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.appGreen.opacity(0.22), lineWidth: 1)
                )
        )
        .padding(.top, 6)
    }
}

// MARK: - Models

private struct QuickCard: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
}

// MARK: - Quick Card View

private struct QuickCardView: View {
    let item: QuickCard

    var body: some View {
        HStack(spacing: 12) {

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.appGreen.opacity(0.18))
                    .frame(width: 44, height: 44)

                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.appGreen.opacity(0.95))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.82)
                    .allowsTightening(true)
                    .textCase(nil)

                Text(item.subtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color.appGreen.opacity(0.55))
                .frame(width: 3, height: 18)
        }
        .padding(14)
        .frame(height: 92)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.appGreen.opacity(0.20), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationStack {
        ChallengesView()
    }
}
