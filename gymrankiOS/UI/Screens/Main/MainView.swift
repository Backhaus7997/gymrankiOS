//
//  MainView.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 17/02/2026.
//

import SwiftUI
import FirebaseAuth

struct MainView: View {

    let onGoToWorkout: () -> Void
    let onGoToRanking: () -> Void

    private let sideMargin: CGFloat = 12

    @State private var showLogoutPopup = false
    @State private var logoutErrorMessage: String?
    @State private var showLogoutError = false

    @State private var routinePlan: RoutinePlan = RoutineStorage.load() ?? RoutinePlan()

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            GeometryReader { geo in
                let contentWidth = max(0, geo.size.width - (sideMargin * 2))

                VStack(spacing: 14) {

                    TopBar(onTapProfile: { showLogoutPopup = true })
                        .frame(width: contentWidth, alignment: .center)
                        .padding(.top, 10)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {

                            HomeQuickActionsRow(
                                onLoadWorkout: onGoToWorkout,
                                onViewRanking: onGoToRanking
                            )

                            // ✅ Ahora pinta músculos según la rutina de HOY
                            WeeklyMusclesCard(routinePlan: routinePlan)

                            TrainingCalendarCard(maxWidth: contentWidth)

                            // ✅ Mi rutina
                            MiRutinaCard(routinePlan: $routinePlan)

                            // ✅ Sets por músculo
                            SetsPerMuscleCard()
                        }
                        .frame(width: contentWidth, alignment: .center)
                        .padding(.bottom, 120)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .confirmationDialog(
            "Cuenta",
            isPresented: $showLogoutPopup,
            titleVisibility: .visible
        ) {
            Button("Cerrar sesión", role: .destructive) {
                do {
                    try AuthService.shared.logout()
                    RoutineStorage.clear()
                } catch {
                    logoutErrorMessage = (error as NSError).localizedDescription
                    showLogoutError = true
                }
            }

            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("¿Querés cerrar sesión?")
        }
        .alert("No se pudo cerrar sesión", isPresented: $showLogoutError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(logoutErrorMessage ?? "Ocurrió un error.")
        }
    }
}

// MARK: - Top bar

private struct TopBar: View {

    var onTapProfile: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Hola 👋")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Button { print("notifications") } label: {
                    Image(systemName: "bell")
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white.opacity(0.06)))
                        .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button(action: onTapProfile) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white.opacity(0.06)))
                        .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Text("Atleta")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
        }
    }
}

// MARK: - Quick actions row

private struct HomeQuickActionsRow: View {
    let onLoadWorkout: () -> Void
    let onViewRanking: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            HomeQuickCard(
                title: "Cargar entreno",
                subtitle: "Registrá tu sesión",
                icon: "figure.strengthtraining.traditional",
                onTap: onLoadWorkout
            )

            HomeQuickCard(
                title: "Ver ranking",
                subtitle: "Tu posición y top",
                icon: "chart.line.uptrend.xyaxis",
                onTap: onViewRanking
            )
        }
        .padding(.top, 2)
    }
}

private struct HomeQuickCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.appGreen.opacity(0.16))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.appGreen.opacity(0.95))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .frame(height: 78)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.appGreen.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Muscle masks structure

private enum BodySide { case front, back }

fileprivate enum MuscleGroup: String, CaseIterable, Identifiable {
    case chest, abs, obliques, shoulders, traps, biceps, quads, calves
    case lats, back, lowerback, glutes, forearms, hamstrings

    var id: String { rawValue }

    func maskName(for side: BodySide) -> String? {
        switch (self, side) {
        case (.chest, .front): return "mask_front_chest"
        case (.abs, .front): return "mask_front_abs"
        case (.obliques, .front): return "mask_front_obliques"
        case (.shoulders, .front): return "mask_front_shoulders"
        case (.traps, .front): return "mask_front_traps"
        case (.biceps, .front): return "mask_front_biceps"
        case (.quads, .front): return "mask_front_quads"
        case (.calves, .front): return "mask_front_calves"

        case (.traps, .back): return "mask_back_traps"
        case (.lats, .back): return "mask_back_lats"
        case (.back, .back): return "mask_back_back"
        case (.lowerback, .back): return "mask_back_lowerback"
        case (.glutes, .back): return "mask_back_glutes"
        case (.forearms, .back): return "mask_back_forearms"
        case (.hamstrings, .back): return "mask_back_hamstrings"
        case (.calves, .back): return "mask_back_calves"
        case (.shoulders, .back): return "mask_back_shoulders"

        default:
            return nil
        }
    }
}

// ✅ esto reemplaza el método que antes estaba dentro de RoutineMuscle (cuando era private en este file)
fileprivate extension RoutineMuscle {
    func toMuscleGroups() -> [MuscleGroup] {
        switch self {
        case .pecho: return [.chest]
        case .espalda: return [.back, .lats]
        case .femorales: return [.hamstrings]
        case .hombros: return [.shoulders]
        case .biceps: return [.biceps]
        case .triceps: return [] // no mask en tu enum actual
        case .abdomen: return [.abs]
        case .gluteos: return [.glutes]
        case .cuadriceps: return [.quads]
        case .pantorrillas: return [.calves]
        case .trapecios: return [.traps]
        case .antebrazos: return [.forearms]
        }
    }
}

private struct MuscleHighlight: Identifiable {
    let id = UUID()
    let group: MuscleGroup
    let intensity: Intensity

    enum Intensity: Double {
        case x1 = 0.20
        case x2 = 0.55
        case x3plus = 1.00
    }
}

private struct BodyWithHighlights: View {
    let baseImageName: String
    let side: BodySide
    let muscleHighlights: [MuscleHighlight]

    var body: some View {
        ZStack {
            Image(baseImageName)
                .resizable()
                .scaledToFit()
                .opacity(0.95)

            ForEach(Array(muscleHighlights.enumerated()), id: \.element.id) { _, h in
                if let maskName = h.group.maskName(for: side) {
                    Image(maskName)
                        .resizable()
                        .scaledToFit()
                        .colorMultiply(tint(for: h.intensity))
                        .opacity(opacity(for: h.intensity))
                        .blendMode(.sourceAtop)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private func opacity(for intensity: MuscleHighlight.Intensity) -> Double {
        switch intensity {
        case .x1: return 0.25
        case .x2: return 0.65
        case .x3plus: return 1.00
        }
    }

    private func tint(for intensity: MuscleHighlight.Intensity) -> Color {
        switch intensity {
        case .x1:
            return Color(red: 0.10, green: 0.35, blue: 0.22)
        case .x2:
            return Color(red: 0.08, green: 0.55, blue: 0.28)
        case .x3plus:
            return Color(red: 0.05, green: 0.75, blue: 0.30)
        }
    }
}

// MARK: - Weekly muscles (pinta lo de HOY según Mi rutina)

private struct MuscleBodyCard: View {
    let title: String
    let baseImageName: String
    let side: BodySide
    let highlights: [MuscleHighlight]

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.65))

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    BodyWithHighlights(
                        baseImageName: baseImageName,
                        side: side,
                        muscleHighlights: highlights
                    )
                    .padding(.horizontal, 1)
                    .padding(.vertical, 10)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
                .frame(height: 280)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WeeklyMusclesCard: View {

    let routinePlan: RoutinePlan

    private var today: Weekday { .today }
    private var todaysMuscles: [RoutineMuscle] { routinePlan.muscles(for: today) }

    private var highlightsFront: [MuscleHighlight] {
        let groups = todaysMuscles.flatMap { $0.toMuscleGroups() }
        let frontAllowed: Set<MuscleGroup> = [.chest, .abs, .obliques, .shoulders, .traps, .biceps, .quads, .calves]
        let filtered = groups.filter { frontAllowed.contains($0) }
        return Array(Set(filtered)).map { .init(group: $0, intensity: .x2) }
    }

    private var highlightsBack: [MuscleHighlight] {
        let groups = todaysMuscles.flatMap { $0.toMuscleGroups() }
        let backAllowed: Set<MuscleGroup> = [.traps, .lats, .back, .lowerback, .glutes, .forearms, .hamstrings, .calves, .shoulders]
        let filtered = groups.filter { backAllowed.contains($0) }
        return Array(Set(filtered)).map { .init(group: $0, intensity: .x2) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Músculos para hoy")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text(routinePlan.isEmpty ? "Cargá tu plan en “Mi rutina”" : "Según tu plan semanal")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                Image(systemName: "gearshape")
                    .foregroundColor(.white.opacity(0.55))
            }

            HStack(spacing: 10) {
                Text("Intensidad")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))

                IntensityDot(label: "1x", opacity: 0.35)
                IntensityDot(label: "2x", opacity: 0.60)
                IntensityDot(label: "3x+", opacity: 0.95)

                Spacer()
            }
            .padding(.top, 2)

            HStack(spacing: 14) {
                MuscleBodyCard(
                    title: "Frente",
                    baseImageName: "bodyfront",
                    side: BodySide.front,
                    highlights: highlightsFront
                )

                MuscleBodyCard(
                    title: "Espalda",
                    baseImageName: "bodyback",
                    side: BodySide.back,
                    highlights: highlightsBack
                )
            }

            Text("* Basado en tu rutina configurada")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
                .padding(.top, 2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appGreen.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private func IntensityDot(label: String, opacity: Double) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.appGreen.opacity(opacity))
                .frame(width: 6, height: 6)

            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.65))
        }
    }
}

// MARK: - Mi rutina card

private struct MiRutinaCard: View {
    @Binding var routinePlan: RoutinePlan
    @State private var showEditor = false

    private var today: Weekday { .today }
    private var todaysMuscles: [RoutineMuscle] { routinePlan.muscles(for: today) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mi rutina")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text("Plan semanal de entrenamiento")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                Button {
                    showEditor = true
                } label: {
                    Text(routinePlan.isEmpty ? "Cargar plan" : "Editar plan")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.appGreen.opacity(0.95))
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.appGreen.opacity(0.25), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 8) {

                Text("Hoy (\(today.fullLabel))")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))

                if routinePlan.isEmpty {
                    Text("Todavía no cargaste tu plan. Tocá “Cargar plan” y elegí músculos por día.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                } else if todaysMuscles.isEmpty {
                    Text("No tenés músculos asignados para hoy.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                } else {
                    FlowChips(items: todaysMuscles.map { $0.rawValue })
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showEditor) {
            RoutineEditorSheet(
                plan: routinePlan,
                onSave: { newPlan in
                    routinePlan = newPlan
                    RoutineStorage.save(newPlan)
                    showEditor = false
                },
                onCancel: { showEditor = false }
            )
        }
    }
}

private struct FlowChips: View {
    let items: [String]

    private let cols: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: cols, alignment: .leading, spacing: 10) {
            ForEach(items, id: \.self) { t in
                MuscleChip(title: t)
            }
        }
    }
}

private struct MuscleChip: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {

            ZStack {
                Circle()
                    .fill(Color.appGreen.opacity(0.22))
                    .frame(width: 22, height: 22)

                Image(systemName: "bolt.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.appGreen.opacity(0.95))
            }

            Text(title)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.90))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.appGreen.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Routine Editor Sheet

private struct RoutineEditorSheet: View {
    @State private var draft: RoutinePlan
    let onSave: (RoutinePlan) -> Void
    let onCancel: () -> Void

    init(plan: RoutinePlan, onSave: @escaping (RoutinePlan) -> Void, onCancel: @escaping () -> Void) {
        _draft = State(initialValue: plan)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(Weekday.allCases) { day in
                    NavigationLink {
                        RoutineDayPicker(
                            day: day,
                            selected: Binding(
                                get: { Set(draft.byDay[day] ?? []) },
                                set: { newSet in
                                    draft.byDay[day] = Array(newSet).sorted(by: { $0.rawValue < $1.rawValue })
                                }
                            )
                        )
                    } label: {
                        HStack {
                            Text(day.fullLabel)
                            Spacer()
                            let count = (draft.byDay[day] ?? []).count
                            Text(count == 0 ? "—" : "\(count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Cargar plan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { onSave(draft) }
                        .fontWeight(.bold)
                }
            }
        }
    }
}

private struct RoutineDayPicker: View {
    let day: Weekday
    @Binding var selected: Set<RoutineMuscle>

    var body: some View {
        List {
            ForEach(RoutineMuscle.allCases) { m in
                Button {
                    if selected.contains(m) {
                        selected.remove(m)
                    } else {
                        selected.insert(m)
                    }
                } label: {
                    HStack {
                        Text(m.rawValue)
                        Spacer()
                        if selected.contains(m) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
        .navigationTitle(day.fullLabel)
    }
}

// MARK: - Calendar

private struct TrainingCalendarCard: View {

    let maxWidth: CGFloat
    private let widthFactor: CGFloat = 1

    private let days: [String] = ["L", "M", "M", "J", "V", "S", "D"]

    private var currentWeekdayIndex: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return ((weekday + 5) % 7) + 1
    }

    private var weekProgressPercent: Int {
        Int((Double(currentWeekdayIndex) / 7.0) * 100.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Calendario de entrenamientos")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            HStack {
                Text("Objetivo semanal: \(currentWeekdayIndex)/7")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))

                Spacer()

                Text("\(weekProgressPercent)%")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            HStack(spacing: 14) {
                ForEach(Array(days.enumerated()), id: \.offset) { idx, label in
                    DayPill(label, isActive: (idx + 1) == currentWeekdayIndex)
                }
            }
            .padding(.top, 4)
        }
        .padding(14)
        .frame(width: maxWidth * widthFactor, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func DayPill(_ text: String, isActive: Bool = false) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundColor(.white.opacity(isActive ? 0.95 : 0.75))
            .padding(.horizontal, 12)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isActive ? Color.appGreen.opacity(0.18) : Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isActive ? Color.appGreen.opacity(0.55) : Color.white.opacity(0.10), lineWidth: 1)
            )
    }
}

// MARK: - Sets per muscle

private struct MuscleSetStat: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var sets: Int
}

private struct SetsPerMuscleCard: View {

    @State private var stats: [MuscleSetStat] = [
        .init(name: "Pecho", sets: 8),
        .init(name: "Espalda", sets: 6),
        .init(name: "Femorales", sets: 0),
        .init(name: "Hombros", sets: 5),
        .init(name: "Bíceps", sets: 0),
        .init(name: "Tríceps", sets: 4),
        .init(name: "Abdomen", sets: 0),
        .init(name: "Glúteos", sets: 0),
        .init(name: "Cuadriceps", sets: 2),
        .init(name: "Pantorrillas", sets: 1),
        .init(name: "Trapecios", sets: 0),
        .init(name: "Antebrazos", sets: 1)
    ]

    @State private var expanded = false

    private var sortedItems: [MuscleSetStat] {
        stats.sorted {
            if $0.sets != $1.sets { return $0.sets > $1.sets }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var shownItems: [MuscleSetStat] {
        expanded ? sortedItems : Array(sortedItems.prefix(4))
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: expanded ? 3 : 4)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerView
            innerBoxView
        }
        .padding(14)
        .background(outerBackground)
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sets por músculo")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("Esta semana")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            Image(systemName: "bell")
                .foregroundColor(.white.opacity(0.55))
        }
    }

    private var innerBoxView: some View {
        VStack(alignment: .leading, spacing: 10) {
            gridView
            toggleButton
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(innerBackground)
    }

    private var gridView: some View {
        LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 10) {
            ForEach(shownItems) { item in
                MuscleSetPill(name: item.name, value: item.sets)
            }
        }
    }

    private var toggleButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                expanded.toggle()
            }
        } label: {
            Text(expanded ? "Ver menos" : "Ver más")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(Color.appGreen.opacity(0.95))
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
    }

    private var innerBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.black.opacity(0.22))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    private var outerBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
    }
}

private struct MuscleSetPill: View {
    let name: String
    let value: Int

    var body: some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.92))

            Capsule()
                .fill(value > 0 ? Color.appGreen.opacity(0.95) : Color.white.opacity(0.14))
                .frame(width: 26, height: 3)

            Text(name)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(value > 0 ? Color.appGreen.opacity(0.35) : Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

#Preview {
    MainView(
        onGoToWorkout: {},
        onGoToRanking: {}
    )
}
