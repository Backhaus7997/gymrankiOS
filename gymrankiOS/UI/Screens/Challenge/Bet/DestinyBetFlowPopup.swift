import SwiftUI

// MARK: - Destiny Bet Flow Popup (Apuestas)

struct DestinyBetFlowPopup: View {

    enum Step: Int { case intro, wheel, dice, duration, accepted }

    // Dificultad (SIN INSANO) - UI ES, Firestore EN
    enum Difficulty: String, CaseIterable, Identifiable {
        case easy = "FÁCIL"
        case medium = "MEDIO"
        case hard = "DIFÍCIL"

        var id: String { rawValue }
        var pillText: String { rawValue }

        var firestoreKey: String {
            switch self {
            case .easy: return "EASY"
            case .medium: return "MEDIUM"
            case .hard: return "HARD"
            }
        }
    }

    // Foco - UI ES, Firestore EN
    enum Focus: String, CaseIterable, Identifiable {
        case upper = "Superior"
        case lower = "Inferior"
        case abs = "Abdomen"
        case cardio = "Cardio"

        var id: String { rawValue }

        var chip: String {
            switch self {
            case .upper: return "💪  Superior"
            case .lower: return "🦵  Inferior"
            case .abs: return "🔥  Abdomen"
            case .cardio: return "❤️  Cardio"
            }
        }

        var firestoreKey: String {
            switch self {
            case .upper: return "upper"
            case .lower: return "lower"
            case .abs: return "abs"
            case .cardio: return "cardio"
            }
        }
    }

    // Duración - UI ES, Firestore EN
    enum DurationType: String, CaseIterable, Identifiable {
        case daily = "DIARIO"
        case short = "CORTA"

        var id: String { rawValue }

        var subtitle: String {
            switch self {
            case .daily: return "24 horas"
            case .short: return "3 horas"
            }
        }

        var icon: String {
            switch self {
            case .daily: return "clock"
            case .short: return "bolt.fill"
            }
        }

        var firestoreKey: String {
            switch self {
            case .daily: return "daily"
            case .short: return "short"
            }
        }

        var pill: String { self == .daily ? "24h" : "3h" }
    }

    @EnvironmentObject private var session: SessionManager
    let onClose: () -> Void

    @State private var step: Step = .intro
    @State private var difficulty: Difficulty = .medium
    @State private var focus: Focus = .upper
    @State private var duration: DurationType = .daily

    @State private var isStarting = false
    @State private var errorMessage: String? = nil

    private let repo = BetRepository()

    var body: some View {
        Group {
            switch step {
            case .intro:
                DestinyIntroCard(
                    onClose: onClose,
                    onStart: { step = .wheel }
                )

            case .wheel:
                WheelCard3(
                    current: $difficulty,
                    onClose: onClose,
                    onBack: { step = .intro },
                    onNext: { step = .dice }
                )

            case .dice:
                DiceCard(
                    current: $focus,
                    onClose: onClose,
                    onBack: { step = .wheel },
                    onNext: { step = .duration }
                )

            case .duration:
                DurationCard(
                    selected: duration,
                    onClose: onClose,
                    onBack: { step = .dice },
                    onSelect: { duration = $0 },
                    onNext: { step = .accepted },
                    onRandom: {
                        duration = DurationType.allCases.randomElement() ?? .daily
                        step = .accepted
                    }
                )

            case .accepted:
                AcceptedCard(
                    difficulty: difficulty,
                    focus: focus,
                    duration: duration,
                    isStarting: isStarting,
                    errorMessage: errorMessage,
                    onClose: onClose,
                    onBack: { step = .duration },
                    onStartBet: { Task { await startBet() } }
                )
            }
        }
        .padding(.horizontal, 18)
    }

    @MainActor
    private func startBet() async {
        if isStarting { return }

        let uid = session.userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty else {
            errorMessage = "No hay usuario logueado."
            return
        }

        isStarting = true
        errorMessage = nil
        defer { isStarting = false }

        do {
            let tpl = try await repo.fetchRandomTemplate(
                difficulty: difficulty.firestoreKey,
                focus: focus.firestoreKey,
                durationType: duration.firestoreKey
            )

            try await repo.createUserBet(uid: uid, template: tpl)

            NotificationCenter.default.post(name: .betCreated, object: nil)
            onClose()
        } catch {
            // Dejá info útil para debug
            errorMessage = "No hay templates para \(difficulty.firestoreKey)/\(focus.firestoreKey)/\(duration.firestoreKey)."
        }
    }
}

// MARK: - Shared UI helpers

private struct BetPopupContainer<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        VStack(spacing: 14) { content }
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
}

private struct BetPopupHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.appGreen.opacity(0.18))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.appGreen.opacity(0.95))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))

                Text(subtitle)
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
}

private struct BetPrimaryButton: View {
    let title: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.appGreen.opacity(isDisabled ? 0.55 : 0.95))
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

private struct BetSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.90))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.appGreen.opacity(0.22), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

private struct BetSectionCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
            Text(subtitle)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
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

private struct BetPill: View {
    let text: String
    let isActive: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundColor(isActive ? Color.appGreen.opacity(0.95) : .white.opacity(0.70))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(isActive ? Color.appGreen.opacity(0.12) : Color.white.opacity(0.06)))
            .overlay(Capsule().stroke(isActive ? Color.appGreen.opacity(0.35) : Color.white.opacity(0.10), lineWidth: 1))
    }
}

// MARK: - Step 1

private struct DestinyIntroCard: View {
    let onClose: () -> Void
    let onStart: () -> Void

    var body: some View {
        BetPopupContainer {
            BetPopupHeader(
                icon: "die.face.5.fill",
                title: "Apuesta del destino",
                subtitle: "Dejá que el destino elija tu apuesta",
                onClose: onClose
            )

            VStack(spacing: 10) {
                BetSectionCard(title: "Girá la rueda", subtitle: "Define la dificultad")
                BetSectionCard(title: "Tirá los dados", subtitle: "Define el enfoque")
                BetSectionCard(title: "Elegí duración", subtitle: "Diaria o corta")
            }

            BetPrimaryButton(title: "EMPEZAR", action: onStart)
        }
    }
}

// MARK: - Step 2: Wheel (3 slices)

private struct WheelCard3: View {
    @Binding var current: DestinyBetFlowPopup.Difficulty
    let onClose: () -> Void
    let onBack: () -> Void
    let onNext: () -> Void

    @State private var rotation: Double = 0
    @State private var isSpinning: Bool = false

    var body: some View {
        BetPopupContainer {
            BetPopupHeader(
                icon: "die.face.5.fill",
                title: "Girá la rueda",
                subtitle: "Definí la dificultad",
                onClose: onClose
            )

            DifficultyWheel3(size: 210, rotation: rotation)
                .frame(height: 280)

            BetPill(text: "Actual: \(current.pillText)", isActive: true)

            BetPrimaryButton(title: "¡GIRAR!", isDisabled: isSpinning) { spinSnap3() }
            BetSecondaryButton(title: "Volver", action: onBack)

            HStack {
                Spacer()
                Button("Siguiente") { onNext() }
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.appGreen.opacity(0.95))
            }
        }
    }

    private func centerAngle(for d: DestinyBetFlowPopup.Difficulty) -> Double {
        switch d {
        case .easy: return 90
        case .hard: return 210
        case .medium: return 330
        }
    }

    private func spinSnap3() {
        guard !isSpinning else { return }
        isSpinning = true

        let winner = DestinyBetFlowPopup.Difficulty.allCases.randomElement() ?? .medium
        let pointerAngle: Double = 90
        let winnerCenter = centerAngle(for: winner)

        let extraTurns = Double(Int.random(in: 4...7)) * 360.0
        let jitter = Double.random(in: -6...6)

        let currentNormalized = rotation.truncatingRemainder(dividingBy: 360)
        let targetNormalized = (pointerAngle - winnerCenter + jitter).truncatingRemainder(dividingBy: 360)
        let deltaToSnap = targetNormalized - currentNormalized

        withAnimation(.easeInOut(duration: 1.25)) {
            rotation = rotation + extraTurns + deltaToSnap
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.27) {
            current = winner
            isSpinning = false
        }
    }
}

private struct DifficultyWheel3: View {
    let size: CGFloat
    let rotation: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.appGreen.opacity(0.22), lineWidth: 1)
                )

            ZStack {
                wheelBody
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(rotation))

                Triangle()
                    .fill(Color.appGreen.opacity(0.95))
                    .frame(width: 18, height: 14)
                    .offset(y: (size / 2) - 10)

                Circle()
                    .fill(Color.black.opacity(0.35))
                    .frame(width: size * 0.18, height: size * 0.28)

                Circle()
                    .stroke(Color.appGreen.opacity(0.30), lineWidth: 2)
                    .frame(width: size * 0.18, height: size * 0.28)
            }
        }
    }

    private var wheelBody: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.04))
            Circle().stroke(Color.appGreen.opacity(0.55), lineWidth: 2)

            SliceShape(start: 30, end: 150)
                .fill(Color.appGreen.opacity(0.42))
                .overlay(SliceShape(start: 30, end: 150).stroke(Color.black.opacity(0.10), lineWidth: 1))

            SliceShape(start: 150, end: 270)
                .fill(Color.appGreen.opacity(0.28))
                .overlay(SliceShape(start: 150, end: 270).stroke(Color.black.opacity(0.10), lineWidth: 1))

            SliceShape(start: 270, end: 390)
                .fill(Color.appGreen.opacity(0.34))
                .overlay(SliceShape(start: 270, end: 390).stroke(Color.black.opacity(0.10), lineWidth: 1))

            WheelSliceLabel(text: "FÁCIL", angleDeg: 90, radius: size * 0.28)
            WheelSliceLabel(text: "DIFÍCIL", angleDeg: 210, radius: size * 0.28)
            WheelSliceLabel(text: "MEDIO", angleDeg: 330, radius: size * 0.28)
        }
        .padding(10)
    }
}

private struct SliceShape: Shape {
    let start: Double
    let end: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var p = Path()
        p.move(to: center)
        p.addArc(center: center, radius: radius, startAngle: .degrees(start), endAngle: .degrees(end), clockwise: false)
        p.closeSubpath()
        return p
    }
}

private extension Text {
    func wheelBigLabel() -> some View {
        self.font(.system(size: 16, weight: .heavy, design: .rounded))
            .foregroundColor(.white.opacity(0.85))
            .shadow(radius: 1)
    }
}

// MARK: - Step 3: Dice

private struct DiceCard: View {
    @Binding var current: DestinyBetFlowPopup.Focus
    let onClose: () -> Void
    let onBack: () -> Void
    let onNext: () -> Void

    @State private var isRolling = false
    @State private var diceRotation: Double = 0
    @State private var diceScale: CGFloat = 1.0
    @State private var pipCount: Int = 1

    var body: some View {
        BetPopupContainer {
            BetPopupHeader(
                icon: "die.face.5.fill",
                title: "Tirá los dados",
                subtitle: "Descubrí el enfoque",
                onClose: onClose
            )

            DiceArea(rotation: diceRotation, scale: diceScale, pipCount: pipCount)

            BetPill(text: "Actual: \(current.chip)", isActive: true)

            HStack(spacing: 18) {
                Text("Superior"); Text("Inferior"); Text("Abdomen"); Text("Cardio")
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.45))

            BetPrimaryButton(title: "TIRAR", isDisabled: isRolling) { roll() }
            BetSecondaryButton(title: "Volver", action: onBack)

            HStack {
                Spacer()
                Button("Siguiente") { onNext() }
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.appGreen.opacity(0.95))
            }
        }
    }

    private func roll() {
        guard !isRolling else { return }
        isRolling = true

        let newFocus = DestinyBetFlowPopup.Focus.allCases.randomElement() ?? .upper
        let newPips = Int.random(in: 1...6)

        withAnimation(.easeInOut(duration: 0.18)) { diceScale = 0.92 }
        withAnimation(.easeInOut(duration: 0.9)) {
            diceRotation += Double(Int.random(in: 2...5)) * 360
            diceScale = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { pipCount = newPips }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            current = newFocus
            isRolling = false
        }
    }
}

private struct DiceArea: View {
    let rotation: Double
    let scale: CGFloat
    let pipCount: Int

    var body: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .frame(height: 260)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.appGreen.opacity(0.22), lineWidth: 1))
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.black.opacity(0.22))
                        .frame(width: 140, height: 140)
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.appGreen.opacity(0.22), lineWidth: 1))
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(scale)

                    DicePips(count: pipCount)
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(scale)
                }
            )
    }
}

private struct DicePips: View {
    let count: Int

    var body: some View {
        let positions = pipPositions(for: count)
        ZStack {
            ForEach(0..<positions.count, id: \.self) { i in
                Circle().fill(Color.white.opacity(0.85))
                    .frame(width: 10, height: 10)
                    .offset(x: positions[i].x, y: positions[i].y)
            }
        }
    }

    private func pipPositions(for n: Int) -> [CGPoint] {
        let d: CGFloat = 26
        let tl = CGPoint(x: -d, y: -d)
        let tr = CGPoint(x: d, y: -d)
        let bl = CGPoint(x: -d, y: d)
        let br = CGPoint(x: d, y: d)
        let ml = CGPoint(x: -d, y: 0)
        let mr = CGPoint(x: d, y: 0)
        let c = CGPoint(x: 0, y: 0)

        switch n {
        case 1: return [c]
        case 2: return [tl, br]
        case 3: return [tl, c, br]
        case 4: return [tl, tr, bl, br]
        case 5: return [tl, tr, c, bl, br]
        default: return [tl, tr, ml, mr, bl, br]
        }
    }
}

// MARK: - Step 4: Duration

private struct DurationCard: View {
    let selected: DestinyBetFlowPopup.DurationType
    let onClose: () -> Void
    let onBack: () -> Void
    let onSelect: (DestinyBetFlowPopup.DurationType) -> Void
    let onNext: () -> Void
    let onRandom: () -> Void

    var body: some View {
        BetPopupContainer {
            BetPopupHeader(
                icon: "die.face.5.fill",
                title: "Elegí duración",
                subtitle: "Seleccioná el tiempo",
                onClose: onClose
            )

            HStack(spacing: 12) {
                ForEach(DestinyBetFlowPopup.DurationType.allCases) { item in
                    Button { onSelect(item) } label: {
                        DurationOptionCard(item: item, isSelected: selected == item)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Seleccionado: \(selected == .daily ? "Diario (24h)" : "Corta (3h)")")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .frame(maxWidth: .infinity, alignment: .leading)

            BetPrimaryButton(title: "Siguiente", action: onNext)
            BetSecondaryButton(title: "ALEATORIO", action: onRandom)
            BetSecondaryButton(title: "Volver", action: onBack)
        }
    }
}

private struct DurationOptionCard: View {
    let item: DestinyBetFlowPopup.DurationType
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.appGreen.opacity(0.18) : Color.white.opacity(0.06))
                    .frame(width: 54, height: 54)

                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isSelected ? Color.appGreen.opacity(0.95) : .white.opacity(0.70))
            }

            Text(item.rawValue)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.92))

            Text(item.subtitle)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.60))

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(height: 150)
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

// MARK: - Step 5: Accepted

private struct AcceptedCard: View {
    let difficulty: DestinyBetFlowPopup.Difficulty
    let focus: DestinyBetFlowPopup.Focus
    let duration: DestinyBetFlowPopup.DurationType

    let isStarting: Bool
    let errorMessage: String?

    let onClose: () -> Void
    let onBack: () -> Void
    let onStartBet: () -> Void

    var body: some View {
        BetPopupContainer {
            BetPopupHeader(
                icon: "die.face.5.fill",
                title: "Apuesta lista",
                subtitle: "Tu destino está sellado",
                onClose: onClose
            )

            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    BetPill(text: difficulty.pillText, isActive: true)
                    BetPill(text: focus.rawValue, isActive: true)
                    BetPill(text: duration.pill, isActive: true)
                }

                if let err = errorMessage, !err.isEmpty {
                    Text(err)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.red.opacity(0.9))
                        .multilineTextAlignment(.center)
                }

                BetPrimaryButton(title: isStarting ? "CREANDO..." : "INICIAR APUESTA", isDisabled: isStarting) {
                    onStartBet()
                }

                BetSecondaryButton(title: "Volver", action: onBack)
            }
        }
    }
}

// MARK: - Shapes

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

private struct WheelSliceLabel: View {
    let text: String
    let angleDeg: Double
    let radius: CGFloat

    var body: some View {
        let rad = angleDeg * Double.pi / 180.0
        let x = CGFloat(cos(rad)) * radius
        let y = CGFloat(sin(rad)) * radius

        return Text(text)
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .foregroundColor(.white.opacity(0.85))
            .minimumScaleFactor(0.75)
            .allowsTightening(true)
            // si querés que queden “inclinados” como antes:
            .rotationEffect(.degrees(angleDeg))
            .offset(x: x, y: y)
    }
}
