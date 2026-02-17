import SwiftUI

/// Fondo oscuro + card centrada (popup real, no sheet)
struct CenterModalOverlay<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content

    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            content
                .transition(.scale.combined(with: .opacity))
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.85), value: isPresented)
    }
}

// MARK: - Create Mission Popup (Wizard)

struct CreateMissionPopupCard: View {

    // MARK: Steps
    private enum Step: Int, CaseIterable {
        case type, difficulty, focus, summary
    }

    // MARK: Models
    enum MissionType: String, CaseIterable, Identifiable {
        case daily = "DIARIA"
        case short = "CORTA"
        var id: String { rawValue }

        var icon: String {
            switch self {
            case .daily: return "clock"
            case .short: return "bolt.fill"
            }
        }

        var subtitle: String {
            switch self {
            case .daily: return "24 horas"
            case .short: return "Sprint 3 horas"
            }
        }

        var detail: String {
            switch self {
            case .daily: return "Constancia"
            case .short: return "Intensidad rápida"
            }
        }

        var timeLimitLabel: String {
            switch self {
            case .daily: return "24 horas"
            case .short: return "3 horas"
            }
        }
    }

    enum Difficulty: String, CaseIterable, Identifiable {
        case easy = "FÁCIL"
        case medium = "MEDIA"
        case hard = "DIFÍCIL"
        case extreme = "EXTREMA"
        var id: String { rawValue }

        var icon: String {
            switch self {
            case .easy: return "leaf.fill"
            case .medium: return "pencil"
            case .hard: return "flame.fill"
            case .extreme: return "flame.circle.fill"
            }
        }

        var eloMultiplier: String {
            switch self {
            case .easy: return "1.0x ELO"
            case .medium: return "1.5x ELO"
            case .hard: return "2.0x ELO"
            case .extreme: return "3.0x ELO"
            }
        }

        /// “Hasta +X ELO” (mock)
        var maxEloReward: Int {
            switch self {
            case .easy: return 4
            case .medium: return 6
            case .hard: return 8
            case .extreme: return 12
            }
        }
    }

    enum Focus: String, CaseIterable, Identifiable {
        case upper = "TREN SUPERIOR"
        case lower = "TREN INFERIOR"
        case abs = "ABDOMEN"
        case cardio = "CARDIO"
        var id: String { rawValue }

        var icon: String {
            switch self {
            case .upper: return "figure.boxing"
            case .lower: return "figure.run"
            case .abs: return "flame.fill"
            case .cardio: return "waveform.path.ecg"
            }
        }

        var detail: String {
            switch self {
            case .upper: return "Brazos, pecho,\nespalda"
            case .lower: return "Piernas y\nglúteos"
            case .abs: return "Core y\nabdominales"
            case .cardio: return "Corazón y\npulmones"
            }
        }

        var chipLabel: String {
            switch self {
            case .upper: return "Superior"
            case .lower: return "Inferior"
            case .abs: return "Abdomen"
            case .cardio: return "Cardio"
            }
        }
    }

    // MARK: External callbacks
    let onClose: () -> Void

    /// Se llama al final (Aceptar misión). Mantengo el mismo tipo (String) para que no te rompa el caller.
    /// Ejemplo: "DIARIA|FÁCIL|TREN INFERIOR"
    let onNext: (String) -> Void

    // MARK: State
    @State private var step: Step = .type

    @State private var selectedType: MissionType = .daily
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var selectedFocus: Focus = .lower

    var body: some View {
        VStack(spacing: 14) {
            header

            ZStack {
                // contenido cambia pero el contenedor queda igual
                stepContent
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.88), value: step)

            footerButtons
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.appGreen.opacity(0.18), lineWidth: 1)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.appGreen.opacity(0.18))
                    .frame(width: 44, height: 44)

                Image(systemName: headerIcon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.appGreen.opacity(0.95))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(headerTitle)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))

                Text(headerSubtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            Button { onClose() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var headerIcon: String {
        switch step {
        case .type: return "trophy.fill"
        case .difficulty: return "slider.horizontal.3"
        case .focus: return "scope"
        case .summary: return "trophy.fill"
        }
    }

    private var headerTitle: String {
        switch step {
        case .type: return "Crear misión"
        case .difficulty: return "Seleccionar dificultad"
        case .focus: return "Elegir enfoque"
        case .summary: return "Resumen de misión"
        }
    }

    private var headerSubtitle: String {
        switch step {
        case .type: return "Elegí el tipo de misión"
        case .difficulty: return "¿Qué tan desafiante querés que sea?"
        case .focus: return "¿Qué grupo muscular querés trabajar?"
        case .summary: return "Tu misión te espera"
        }
    }

    // MARK: Content per step

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .type:
            missionTypeStep
        case .difficulty:
            difficultyStep
        case .focus:
            focusStep
        case .summary:
            summaryStep
        }
    }

    private var missionTypeStep: some View {
        HStack(spacing: 12) {
            ForEach(MissionType.allCases) { type in
                Button {
                    selectedType = type
                } label: {
                    MissionTypeCard(type: type, isSelected: selectedType == type)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 2)
    }

    private var difficultyStep: some View {
        let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: cols, spacing: 12) {
            ForEach(Difficulty.allCases) { d in
                Button {
                    selectedDifficulty = d
                } label: {
                    SelectCard(
                        title: d.rawValue,
                        subtitle: d.eloMultiplier,
                        icon: d.icon,
                        isSelected: selectedDifficulty == d
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 2)
    }

    private var focusStep: some View {
        let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: cols, spacing: 12) {
            ForEach(Focus.allCases) { f in
                Button {
                    selectedFocus = f
                } label: {
                    SelectCard(
                        title: f.rawValue,
                        subtitle: f.detail,
                        icon: f.icon,
                        isSelected: selectedFocus == f,
                        multilineSubtitle: true
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 2)
    }

    private var summaryStep: some View {
        VStack(spacing: 12) {

            Text("\(selectedType == .daily ? "Diaria" : "Corta") \(selectedDifficultyLabel) • \(selectedFocus.chipLabel)")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)

            HStack(spacing: 10) {
                Chip(text: selectedDifficultyChip)
                Chip(text: selectedTypeChip)
                Chip(text: selectedFocus.chipLabel)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 2)

            HStack(spacing: 12) {
                InfoCard(
                    icon: "clock",
                    title: "Límite de tiempo",
                    value: selectedType.timeLimitLabel
                )
                InfoCard(
                    icon: "star.fill",
                    title: "Ganancia",
                    value: "Hasta +\(selectedDifficulty.maxEloReward) ELO",
                    valueIsGreen: true
                )
            }
        }
        .padding(.top, 2)
        .frame(maxWidth: .infinity)
        .frame(height: 180, alignment: .top)
    }


    private var selectedDifficultyLabel: String {
        switch selectedDifficulty {
        case .easy: return "Easy"
        case .medium: return "Media"
        case .hard: return "Difícil"
        case .extreme: return "Extrema"
        }
    }

    private var selectedDifficultyChip: String {
        switch selectedDifficulty {
        case .easy: return "Easy"
        case .medium: return "Media"
        case .hard: return "Hard"
        case .extreme: return "Extrema"
        }
    }

    private var selectedTypeChip: String {
        switch selectedType {
        case .daily: return "Diaria"
        case .short: return "Corta"
        }
    }

    // MARK: Footer buttons

    private var footerButtons: some View {
        VStack(spacing: 10) {
            Button {
                primaryAction()
            } label: {
                Text(primaryTitle)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.appGreen.opacity(0.95))
                    )
            }
            .buttonStyle(.plain)

            Button {
                secondaryAction()
            } label: {
                Text(secondaryTitle)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.90))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, step == .summary ? 2 : 0)
    }

    private var primaryTitle: String {
        switch step {
        case .summary: return "ACEPTAR MISIÓN"
        default: return "Siguiente"
        }
    }

    private var secondaryTitle: String {
        switch step {
        case .type: return "Cancelar"
        default: return "Volver"
        }
    }

    private func primaryAction() {
        switch step {
        case .type:
            withAnimation { step = .difficulty }
        case .difficulty:
            withAnimation { step = .focus }
        case .focus:
            withAnimation { step = .summary }
        case .summary:
            // Emitimos un string para no romper tu caller actual
            let payload = "\(selectedType.rawValue)|\(selectedDifficulty.rawValue)|\(selectedFocus.rawValue)"
            onNext(payload)
        }
    }

    private func secondaryAction() {
        switch step {
        case .type:
            onClose()
        case .difficulty:
            withAnimation { step = .type }
        case .focus:
            withAnimation { step = .difficulty }
        case .summary:
            withAnimation { step = .focus }
        }
    }
}

// MARK: - Reusable cards (same style)

private struct MissionTypeCard: View {
    let type: CreateMissionPopupCard.MissionType
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? Color.appGreen.opacity(0.18) : Color.white.opacity(0.06))
                        .frame(width: 44, height: 44)

                    Image(systemName: type.icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSelected ? Color.appGreen.opacity(0.95) : .white.opacity(0.70))
                }

                Spacer()
            }

            Text(type.rawValue)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.92))

            Text(type.subtitle)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.70))

            Text(type.detail)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isSelected ? Color.appGreen.opacity(0.10) : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(isSelected ? Color.appGreen.opacity(0.35) : Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

private struct SelectCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    var multilineSubtitle: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? Color.appGreen.opacity(0.18) : Color.white.opacity(0.06))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSelected ? Color.appGreen.opacity(0.95) : .white.opacity(0.70))
                }

                Spacer()
            }

            Text(title)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
                .lineLimit(1)

            Text(subtitle)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.60))
                .lineLimit(multilineSubtitle ? 2 : 1)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(height: 132)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isSelected ? Color.appGreen.opacity(0.10) : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(isSelected ? Color.appGreen.opacity(0.35) : Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

private struct Chip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundColor(.white.opacity(0.90))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.appGreen.opacity(0.14))
                    .overlay(
                        Capsule()
                            .stroke(Color.appGreen.opacity(0.28), lineWidth: 1)
                    )
            )
    }
}

private struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    var valueIsGreen: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(valueIsGreen ? Color.appGreen.opacity(0.95) : .white.opacity(0.75))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))

                Text(value)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(valueIsGreen ? Color.appGreen.opacity(0.95) : .white.opacity(0.92))
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppBackground().ignoresSafeArea()
        CenterModalOverlay(isPresented: .constant(true)) {
            CreateMissionPopupCard(
                onClose: {},
                onNext: { payload in
                    print("MISSION:", payload)
                }
            )
            .padding(.horizontal, 18)
        }
    }
}
