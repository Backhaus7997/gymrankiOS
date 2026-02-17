import SwiftUI

// MARK: - Destiny Bet Flow Popup (Apuestas)

struct DestinyBetFlowPopup: View {

    // Orden de popups
    enum Step: Int {
        case intro
        case wheel
        case dice
        case duration
        case accepted
    }

    // Dificultad de la rueda
    enum Difficulty: String, CaseIterable, Identifiable {
        case easy = "FÁCIL"
        case medium = "MEDIO"
        case hard = "DIFÍCIL"
        case insane = "INSANO"

        var id: String { rawValue }
        var pillText: String { rawValue }

        /// Orden visual de los cuadrantes (igual a tu wheel actual):
        /// 0: arriba-derecha (FÁCIL)
        /// 1: derecha (MEDIO)  -> lo usamos como “siguiente” en sentido horario en el snap
        /// 2: abajo (DIFÍCIL)
        /// 3: izquierda (INSANO)
        ///
        /// Importante: NO es “arriba puntero”, es el orden de tus labels actuales.
        static let wheelOrder: [Difficulty] = [.easy, .medium, .hard, .insane]
    }

    // Foco de los dados
    enum Focus: String, CaseIterable, Identifiable {
        case upper = "Superior"
        case lower = "Inferior"
        case abs = "Abdomen"
        case cardio = "Cardio"

        var id: String { rawValue }

        var chip: String {
            switch self {
            case .upper: return "💪  Upper"
            case .lower: return "🦵  Lower"
            case .abs: return "🔥  Abs"
            case .cardio: return "❤️  Cardio"
            }
        }
    }

    // Duración
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
    }

    let onClose: () -> Void

    @State private var step: Step = .intro

    // resultados del “destino”
    @State private var difficulty: Difficulty = .medium
    @State private var focus: Focus = .upper
    @State private var duration: DurationType = .daily

    var body: some View {
        Group {
            switch step {

            case .intro:
                DestinyIntroCard(
                    onClose: onClose,
                    onStart: { step = .wheel }
                )

            case .wheel:
                WheelCard(
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
                    onClose: onClose,
                    onStartMission: { onClose() }
                )
            }
        }
        .padding(.horizontal, 18)
    }
}

// MARK: - Shared UI helpers (con nombres únicos para NO chocar)

private struct BetPopupContainer<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        VStack(spacing: 14) {
            content
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
            .background(
                Capsule().fill(isActive ? Color.appGreen.opacity(0.12) : Color.white.opacity(0.06))
            )
            .overlay(
                Capsule().stroke(isActive ? Color.appGreen.opacity(0.35) : Color.white.opacity(0.10), lineWidth: 1)
            )
    }
}

// MARK: - Step 1: Intro

private struct DestinyIntroCard: View {
    let onClose: () -> Void
    let onStart: () -> Void

    var body: some View {
        BetPopupContainer {
            BetPopupHeader(
                icon: "die.face.5.fill",
                title: "Apuesta del destino",
                subtitle: "Dejá que el destino elija tu desafío",
                onClose: onClose
            )

            VStack(spacing: 10) {
                BetSectionCard(title: "Girá la rueda", subtitle: "Define la dificultad")
                BetSectionCard(title: "Tirás los dados", subtitle: "Define el foco del cuerpo")
                BetSectionCard(title: "Elegís duración", subtitle: "Diario o misión corta")
            }

            BetPrimaryButton(title: "EMPEZAR", action: onStart)
        }
    }
}

// MARK: - Step 2: Wheel (FUNCIONAL + SNAP para que los títulos queden como la referencia)

private struct WheelCard: View {
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
                subtitle: "Definí el nivel del desafío",
                onClose: onClose
            )

            DifficultyWheel(
                size: 210,
                rotation: rotation
            )
            .frame(height: 280)

            BetPill(text: "Actual: \(current.pillText)", isActive: true)

            BetPrimaryButton(title: "¡GIRAR!", isDisabled: isSpinning) {
                spinSnap()
            }

            BetSecondaryButton(title: "Volver", action: onBack)

            HStack {
                Text("Tip: girá para elegir la dificultad")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))

                Spacer()

                Button("Siguiente") { onNext() }
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.appGreen.opacity(0.95))
            }
            .padding(.top, 4)
        }
    }

    /// Gira y “encastra” en una posición fija para que las labels queden iguales a la referencia.
    private func spinSnap() {
        guard !isSpinning else { return }
        isSpinning = true

        let winner = DestinyBetFlowPopup.Difficulty.allCases.randomElement() ?? .medium

        // Ángulo “centro” de cada label según cómo las dibujaste:
        // FÁCIL: arriba (con tilt 30)
        // MEDIO: derecha (tilt 120)
        // DIFÍCIL: abajo (tilt 210)
        // INSANO: izquierda (tilt 300)
        //
        // Queremos que el GANADOR quede en la flecha (arriba).
        // Entonces el target rotation es: -(angleDelWinner) + jitter + n vueltas.
        let centerAngle: Double = {
            switch winner {
            case .easy: return 0
            case .medium: return 90
            case .hard: return 180
            case .insane: return 270
            }
        }()

        let extraTurns = Double(Int.random(in: 4...7)) * 360.0
        let jitter = Double.random(in: -6...6)

        // Hacemos continuidad: calculamos la rot actual normalizada
        let currentNormalized = rotation.truncatingRemainder(dividingBy: 360)
        let targetNormalized = (-centerAngle + jitter).truncatingRemainder(dividingBy: 360)
        let deltaToSnap = targetNormalized - currentNormalized

        let target = rotation + extraTurns + deltaToSnap

        withAnimation(.easeInOut(duration: 1.25)) {
            rotation = target
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.27) {
            current = winner
            isSpinning = false
        }
    }
}

// MARK: - Wheel Drawing (igual a la imagen)

private struct DifficultyWheel: View {
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
                    .frame(width: size * 0.28, height: size * 0.28)

                Circle()
                    .stroke(Color.appGreen.opacity(0.30), lineWidth: 2)
                    .frame(width: size * 0.28, height: size * 0.28)
            }
        }
        .padding(.top, 2)
    }

    private var wheelBody: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.04))

            Circle()
                .stroke(Color.appGreen.opacity(0.55), lineWidth: 2)

            // 4 cuadrantes
            ForEach(0..<4) { i in
                QuadrantShape(index: i)
                    .fill(i % 2 == 0 ? Color.appGreen.opacity(0.42) : Color.appGreen.opacity(0.28))
                    .overlay(
                        QuadrantShape(index: i)
                            .stroke(Color.black.opacity(0.10), lineWidth: 1)
                    )
            }

            // Labels diagonales (como la referencia)
            ZStack {
                Text("FÁCIL")
                    .wheelBigLabel()
                    .offset(y: (size * 0.30))
                    .rotationEffect(.degrees(40))

                Text("MEDIO")
                    .wheelBigLabel()
                    .offset(y: (size * 0.30))
                    .rotationEffect(.degrees(140))

                Text("DIFÍCIL")
                    .wheelBigLabel()
                    .offset(y: (size * 0.30))
                    .rotationEffect(.degrees(220))

                Text("INSANO")
                    .wheelBigLabel()
                    .offset(y: (size * 0.30))
                    .rotationEffect(.degrees(310))
            }
        }
        .padding(10)
    }
}

private extension Text {
    func wheelBigLabel() -> some View {
        self.font(.system(size: 16, weight: .heavy, design: .rounded))
            .foregroundColor(.white.opacity(0.85))
            .shadow(radius: 1)
    }
}

private struct QuadrantShape: Shape {
    let index: Int // 0..3
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let start = Angle.degrees(Double(index) * 90.0)
        let end = Angle.degrees(Double(index + 1) * 90.0)

        var p = Path()
        p.move(to: center)
        p.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        p.closeSubpath()
        return p
    }
}

// MARK: - Step 3: Dice (FUNCIONAL)

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
                subtitle: "Descubrí tu objetivo",
                onClose: onClose
            )

            DiceArea(
                rotation: diceRotation,
                scale: diceScale,
                pipCount: pipCount
            )

            BetPill(text: "Actual: \(current.chip)", isActive: true)

            HStack(spacing: 18) {
                Text("Superior")
                Text("Inferior")
                Text("Abdomen")
                Text("Cardio")
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.45))

            BetPrimaryButton(title: "TIRAR", isDisabled: isRolling) {
                roll()
            }

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

        withAnimation(.easeInOut(duration: 0.18)) {
            diceScale = 0.92
        }

        withAnimation(.easeInOut(duration: 0.9)) {
            diceRotation += Double(Int.random(in: 2...5)) * 360
            diceScale = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            pipCount = newPips
        }

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
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .frame(height: 260)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.appGreen.opacity(0.22), lineWidth: 1)
                )
                .overlay(
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.black.opacity(0.22))
                            .frame(width: 140, height: 140)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color.appGreen.opacity(0.22), lineWidth: 1)
                            )
                            .rotationEffect(.degrees(rotation))
                            .scaleEffect(scale)

                        DicePips(count: pipCount)
                            .rotationEffect(.degrees(rotation))
                            .scaleEffect(scale)
                    }
                )
        }
    }
}

private struct DicePips: View {
    let count: Int

    var body: some View {
        let positions = pipPositions(for: count)

        ZStack {
            ForEach(0..<positions.count, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.85))
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

            Text("Seleccionado: \(selected == .daily ? "Diario" : "Corta")")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)

            BetPrimaryButton(title: "ALEATORIO", action: onRandom)
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

    let onClose: () -> Void
    let onStartMission: () -> Void

    var body: some View {
        BetPopupContainer {
            BetPopupHeader(
                icon: "die.face.5.fill",
                title: "Misión aceptada",
                subtitle: "Tu destino está sellado",
                onClose: onClose
            )

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.appGreen.opacity(0.14))
                        .frame(width: 86, height: 86)
                        .overlay(Circle().stroke(Color.appGreen.opacity(0.35), lineWidth: 1))

                    Image(systemName: "checkmark")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundColor(.white.opacity(0.90))
                }
                .padding(.top, 4)

                Text("¡Tu misión te espera!")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))

                HStack(spacing: 10) {
                    BetPill(text: difficulty.pillText.capitalized, isActive: true)
                    BetPill(text: focus.rawValue, isActive: true)
                }

                HStack(spacing: 10) {
                    BetPill(text: duration == .daily ? "Diario" : "Corta", isActive: true)
                    BetPill(text: "Hasta +3 ELO", isActive: true)
                }

                Text("Dificultad, foco y duración fueron elegidos por el destino.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)

                BetPrimaryButton(title: "INICIAR MISIÓN", action: onStartMission)
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

// MARK: - Preview (usa tu CenterModalOverlay global)

#Preview {
    ZStack {
        AppBackground().ignoresSafeArea()
        CenterModalOverlay(isPresented: .constant(true)) {
            DestinyBetFlowPopup(onClose: {})
        }
    }
}
