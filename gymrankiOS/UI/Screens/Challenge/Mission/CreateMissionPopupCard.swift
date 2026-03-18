//
//  CreateMissionPopupCard.swift
//  gymrankiOS
//

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

// MARK: - Draft model (lo que sale del wizard)

struct MissionDraft: Hashable {
    let durationDays: Int
    let focus: CreateMissionPopupCard.Focus

    let goalWorkouts: Int
    let points: Int

    let title: String
    let subtitle: String
    let level: String
    let tags: [String]
}

// MARK: - Create Mission Popup (Wizard)

struct CreateMissionPopupCard: View {

    private enum Step: Int, CaseIterable {
        case duration, focus, details, summary
    }

    enum Duration: String, CaseIterable, Identifiable {
        case d14 = "14 DÍAS"
        case d21 = "21 DÍAS"
        case d28 = "28 DÍAS"
        var id: String { rawValue }

        var days: Int {
            switch self {
            case .d14: return 14
            case .d21: return 21
            case .d28: return 28
            }
        }

        // ✅ dificultad derivada por duración (cambiable)
        var levelLabel: String {
            switch self {
            case .d14: return "Fácil"
            case .d21: return "Intermedio"
            case .d28: return "Difícil"
            }
        }

        // ✅ puntos fijos por duración
        var points: Int {
            switch self {
            case .d14: return 250
            case .d21: return 350
            case .d28: return 500
            }
        }

        var icon: String {
            switch self {
            case .d14: return "calendar"
            case .d21: return "calendar.badge.clock"
            case .d28: return "calendar.badge.exclamationmark"
            }
        }

        var subtitle: String {
            switch self {
            case .d14: return "\(levelLabel) • \(points) pts"
            case .d21: return "\(levelLabel) • \(points) pts"
            case .d28: return "\(levelLabel) • \(points) pts"
            }
        }

        var detail: String {
            switch self {
            case .d14: return "Misión corta y accesible"
            case .d21: return "Misión más exigente"
            case .d28: return "Misión larga (alta recompensa)"
            }
        }
    }

    enum Focus: String, CaseIterable, Identifiable {
        case upper = "TREN SUPERIOR"
        case lower = "TREN INFERIOR"
        case cardio = "CARDIO"
        case mobility = "MOVILIDAD"
        var id: String { rawValue }

        var icon: String {
            switch self {
            case .upper: return "figure.boxing"
            case .lower: return "figure.run"
            case .cardio: return "waveform.path.ecg"
            case .mobility: return "figure.cooldown"
            }
        }

        var detail: String {
            switch self {
            case .upper: return "Brazos, pecho,\nespalda"
            case .lower: return "Piernas y\nglúteos"
            case .cardio: return "Corazón y\nresistencia"
            case .mobility: return "Flexibilidad\ny movilidad"
            }
        }

        var chipLabel: String {
            switch self {
            case .upper: return "Superior"
            case .lower: return "Inferior"
            case .cardio: return "Cardio"
            case .mobility: return "Movilidad"
            }
        }

        var tag: String {
            switch self {
            case .upper: return "upper"
            case .lower: return "lower"
            case .cardio: return "cardio"
            case .mobility: return "mobility"
            }
        }
    }

    // callbacks
    let onClose: () -> Void
    let onNext: (MissionDraft) -> Void

    // state
    @State private var step: Step = .duration
    @State private var selectedDuration: Duration = .d14
    @State private var selectedFocus: Focus = .lower

    // inputs
    @State private var titleInput: String = ""
    @State private var subtitleInput: String = ""

    var body: some View {
        VStack(spacing: 14) {
            header

            ZStack {
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
        case .duration: return "calendar"
        case .focus: return "scope"
        case .details: return "text.quote"
        case .summary: return "trophy.fill"
        }
    }

    private var headerTitle: String {
        switch step {
        case .duration: return "Crear misión"
        case .focus: return "Elegir enfoque"
        case .details: return "Detalles"
        case .summary: return "Resumen"
        }
    }

    private var headerSubtitle: String {
        switch step {
        case .duration: return "La dificultad y puntos dependen de la duración"
        case .focus: return "¿Qué querés priorizar?"
        case .details: return "Poné un nombre y descripción"
        case .summary: return "Confirmá tu misión"
        }
    }

    // MARK: Steps

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .duration: durationStep
        case .focus: focusStep
        case .details: detailsStep
        case .summary: summaryStep
        }
    }

    private var durationStep: some View {
        VStack(spacing: 12) {
            ForEach(Duration.allCases) { d in
                Button {
                    selectedDuration = d
                } label: {
                    DurationRowCard(duration: d, isSelected: selectedDuration == d)
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

    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: 12) {

            fieldLabel("Nombre de la misión")
            TextField("Ej: Cardio post-entreno", text: $titleInput)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.10), lineWidth: 1))
                )

            fieldLabel("Descripción")
            TextField("Ej: Completá X entrenos en Y días", text: $subtitleInput, axis: .vertical)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(3, reservesSpace: true)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.10), lineWidth: 1))
                )

            if !detailsValid {
                Text("Completá nombre y descripción para continuar.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))
                    .padding(.top, 2)
            }
        }
        .padding(.top, 2)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundColor(.white.opacity(0.70))
    }

    private var summaryStep: some View {
        let goal = goalWorkoutsFor(duration: selectedDuration)

        let cleanTitle = titleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSubtitle = subtitleInput.trimmingCharacters(in: .whitespacesAndNewlines)

        return VStack(spacing: 12) {
            Text(cleanTitle.isEmpty ? "Tu misión" : cleanTitle)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)

            Text(cleanSubtitle.isEmpty ? "Agregá una descripción" : cleanSubtitle)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 6)

            HStack(spacing: 10) {
                Chip(text: selectedDuration.rawValue)
                Chip(text: selectedDuration.levelLabel)
                Chip(text: selectedFocus.chipLabel)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 12) {
                InfoCard(
                    icon: "target",
                    title: "Objetivo",
                    value: "\(goal) semanas"
                )
                InfoCard(
                    icon: "star.fill",
                    title: "Recompensa",
                    value: "\(selectedDuration.points) pts",
                    valueIsGreen: true
                )
            }
        }
        .padding(.top, 2)
        .frame(maxWidth: .infinity)
        .frame(height: 220, alignment: .top)
    }

    // MARK: Footer

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
                    .opacity(primaryEnabled ? 1.0 : 0.55)
            }
            .buttonStyle(.plain)
            .disabled(!primaryEnabled)

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
        step == .summary ? "CREAR MISIÓN" : "Siguiente"
    }

    private var secondaryTitle: String {
        step == .duration ? "Cancelar" : "Volver"
    }

    private var detailsValid: Bool {
        !titleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !subtitleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var primaryEnabled: Bool {
        switch step {
        case .details, .summary:
            return detailsValid
        default:
            return true
        }
    }

    private func primaryAction() {
        switch step {
        case .duration:
            withAnimation { step = .focus }
        case .focus:
            withAnimation { step = .details }
        case .details:
            withAnimation { step = .summary }
        case .summary:
            let goal = goalWorkoutsFor(duration: selectedDuration)

            let cleanTitle = titleInput.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanSubtitle = subtitleInput.trimmingCharacters(in: .whitespacesAndNewlines)

            let draft = MissionDraft(
                durationDays: selectedDuration.days,
                focus: selectedFocus,
                goalWorkouts: goal,
                points: selectedDuration.points,
                title: cleanTitle,
                subtitle: cleanSubtitle,
                level: selectedDuration.levelLabel,
                tags: ["mission", "custom", selectedFocus.tag, "d\(selectedDuration.days)"]
            )
            onNext(draft)
        }
    }

    private func secondaryAction() {
        switch step {
        case .duration:
            onClose()
        case .focus:
            withAnimation { step = .duration }
        case .details:
            withAnimation { step = .focus }
        case .summary:
            withAnimation { step = .details }
        }
    }

    // MARK: Goals (por duración)

    private func goalWorkoutsFor(duration: Duration) -> Int {
        switch duration {
        case .d14: return 2
        case .d21: return 3
        case .d28: return 4
        }
    }
}

// MARK: - Cards

private struct DurationRowCard: View {
    let duration: CreateMissionPopupCard.Duration
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.appGreen.opacity(0.18) : Color.white.opacity(0.06))
                    .frame(width: 44, height: 44)

                Image(systemName: duration.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? Color.appGreen.opacity(0.95) : .white.opacity(0.70))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(duration.rawValue)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))

                Text(duration.subtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.70))

                Text(duration.detail)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? Color.appGreen.opacity(0.95) : .white.opacity(0.25))
        }
        .padding(14)
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
                    .overlay(Capsule().stroke(Color.appGreen.opacity(0.28), lineWidth: 1))
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
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
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
