//
//  CreateRoutineView.swift
//  gymrankiOS
//

import SwiftUI

struct CreateRoutineView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager

    @StateObject private var vm = CreateRoutineViewModel()
    @State private var showError = false

    // ✅ Embedded catalog (NO JSON file)
    @State private var catalog: [ExercisesCatalogEntry] = ExercisesCatalogData.catalog
    @State private var selectedMuscles: Set<WorkoutMuscle> = []

    // Dropdown inline
    @State private var expandedExerciseId: String? = nil
    @State private var exerciseSearch: String = ""

    private var uid: String { session.userId }
    private var canSave: Bool { !uid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private var allExerciseNames: [String] {
        catalog.flatMap { $0.exercises }.uniqueSorted()
    }

    private var filteredExerciseNames: [String] {
        guard !selectedMuscles.isEmpty else { return allExerciseNames }

        let allowed = Set(selectedMuscles.map { $0.rawValue })
        return catalog
            .filter { allowed.contains($0.muscle) }
            .flatMap { $0.exercises }
            .uniqueSorted()
    }

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            VStack(spacing: 12) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {

                        detailsCard
                        musclesFilterCard
                        exercisesHeader
                        exercisesList
                        saveButton

                        Spacer().frame(height: 28)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "Ocurrió un error.")
        }
        .onChange(of: selectedMuscles) { _ in
            expandedExerciseId = nil
            exerciseSearch = ""
        }
    }

    // MARK: - Top bar

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

            VStack(alignment: .leading, spacing: 2) {
                Text("Crear entrenamiento")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))

                Text("Armá tu plantilla para seguir tu progreso")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    // MARK: - Details

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detalles")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.9))

            GlassTextField(placeholder: "Nombre del entrenamiento", text: $vm.title)
            GlassTextField(placeholder: "Descripción (opcional)", text: $vm.description)
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - Muscles filter

    private var musclesFilterCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Músculos del día")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))

                    Text("Filtra los ejercicios sugeridos")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                Button { selectedMuscles.removeAll() } label: {
                    Text("Limpiar")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))
                }
                .buttonStyle(.plain)
                .opacity(selectedMuscles.isEmpty ? 0.35 : 1.0)
                .disabled(selectedMuscles.isEmpty)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 10) {
                ForEach(WorkoutMuscle.allCases) { m in
                    MuscleChipSelectable(
                        title: m.rawValue,
                        isSelected: selectedMuscles.contains(m)
                    ) {
                        if selectedMuscles.contains(m) { selectedMuscles.remove(m) }
                        else { selectedMuscles.insert(m) }
                    }
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - Exercises header

    private var exercisesHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ejercicios")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))

                Text("Elegí de la lista o escribí manual")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            Button { vm.addExercise() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Agregar")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                }
                .foregroundColor(Color.appGreen.opacity(0.95))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(Color.white.opacity(0.06))
                        .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 2)
    }

    // MARK: - Exercises list

    private var exercisesList: some View {
        VStack(spacing: 14) {
            ForEach($vm.exercises) { $exercise in
                ExerciseCardView(
                    exercise: $exercise,
                    selectedMusclesEmpty: selectedMuscles.isEmpty,
                    filteredNames: filteredExerciseNames,
                    allNames: allExerciseNames,
                    expandedExerciseId: $expandedExerciseId,
                    exerciseSearch: $exerciseSearch,
                    onRemove: { id in
                        if expandedExerciseId == id {
                            expandedExerciseId = nil
                            exerciseSearch = ""
                        }
                        vm.removeExercise(id: id)
                    }
                )
            }
        }
    }

    // MARK: - Save button

    private var saveButton: some View {
        PrimaryBottomButton(
            title: vm.isLoading ? "GUARDANDO..." : "GUARDAR ENTRENAMIENTO",
            systemImage: "figure.strengthtraining.traditional"
        ) {
            Task {
                await vm.save(userId: uid)
                if vm.errorMessage != nil { showError = true }
                if vm.didSave { dismiss() }
            }
        }
        .padding(.top, 8)
        .disabled(!canSave || vm.isLoading)
        .opacity((!canSave || vm.isLoading) ? 0.6 : 1.0)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
    }
}

// MARK: - Inline dropdown exercise card

private struct ExerciseCardView: View {

    private struct ExerciseDropdownBody: View {
        @Binding var exerciseName: String
        @Binding var exerciseId: String?
        @Binding var searchText: String

        let options: [String]
        let onClose: () -> Void

        private var filtered: [String] {
            let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !q.isEmpty else { return options }
            return options.filter { $0.localizedCaseInsensitiveContains(q) }
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                searchField
                listView
            }
            .padding(12)
            .background(containerBackground)
        }

        private var searchField: some View {
            TextField("Buscar ejercicio…", text: $searchText)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(searchBackground)
        }

        private var listView: some View {
            ScrollView {
                LazyVStack(spacing: 8) {
                    if filtered.isEmpty {
                        Text("No hay resultados con ese filtro.")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.55))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(filtered.prefix(60), id: \.self) { name in
                            optionRow(name: name)
                        }

                        if filtered.count > 60 {
                            Text("Refiná la búsqueda para ver más resultados…")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.50))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 2)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: 220)
            .scrollIndicators(.hidden)
        }

        private func optionRow(name: String) -> some View {
            Button {
                exerciseName = name
                exerciseId = name.toExerciseSlug()
                onClose()
            } label: {
                HStack(spacing: 10) {
                    Text(name)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.90))
                        .lineLimit(2)

                    Spacer()

                    if exerciseName == name {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.appGreen.opacity(0.95))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(rowBackground)
            }
            .buttonStyle(.plain)
        }

        private var containerBackground: some View {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.20))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        }

        private var searchBackground: some View {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        }

        private var rowBackground: some View {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        }
    }

    @Binding var exercise: RoutineExercise

    let selectedMusclesEmpty: Bool
    let filteredNames: [String]
    let allNames: [String]

    @Binding var expandedExerciseId: String?
    @Binding var exerciseSearch: String

    let onRemove: (String) -> Void

    private var isExpanded: Bool { expandedExerciseId == exercise.id }
    private var optionsBase: [String] { filteredNames.isEmpty ? allNames : filteredNames }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            headerRow

            dropdownHeaderButton

            if isExpanded {
                ExerciseDropdownBody(
                    exerciseName: $exercise.name,
                    exerciseId: $exercise.exerciseId,
                    searchText: $exerciseSearch,
                    options: optionsBase,
                    onClose: closeDropdown
                )
                .transition(.opacity)
            }

            manualField

            HStack(spacing: 12) {
                StepperPill(title: "Sets", value: $exercise.sets, range: 1...50)
                StepperPill(title: "Reps", value: $exercise.reps, range: 1...200)
            }

            HStack(spacing: 12) {
                TogglePill(title: "Peso corporal", isOn: $exercise.usesBodyweight)

                WeightField(
                    title: "Kg",
                    value: exercise.weightKg,
                    isDisabled: exercise.usesBodyweight
                ) { newValue in
                    exercise.weightKg = newValue
                }
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private var headerRow: some View {
        HStack {
            Text("Ejercicio")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.85))

            Spacer()

            Button { onRemove(exercise.id) } label: {
                Image(systemName: "trash")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.06)))
            }
            .buttonStyle(.plain)
        }
    }

    private var dropdownHeaderButton: some View {
        Button(action: toggleDropdown) {
            dropdownHeaderView
        }
        .buttonStyle(.plain)
    }

    private var dropdownHeaderView: some View {
        let title = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Seleccionar ejercicio"
            : exercise.name

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.appGreen.opacity(0.16))
                    .frame(width: 44, height: 44)

                Image(systemName: "list.bullet")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.appGreen.opacity(0.95))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(2)

                Text(selectedMusclesEmpty ? "Mostrando todos" : "Filtrado por músculos seleccionados")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.45))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var manualField: some View {
        TextField("O escribir (ej: Press banca)", text: Binding(
            get: { exercise.name },
            set: { newValue in
                exercise.name = newValue
                exercise.exerciseId = nil
            }
        ))
        .textInputAutocapitalization(.sentences)
        .autocorrectionDisabled()
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .foregroundColor(.white.opacity(0.9))
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
    }

    private func toggleDropdown() {
        withAnimation(.spring(response: 0.30, dampingFraction: 0.92)) {
            if isExpanded {
                expandedExerciseId = nil
                exerciseSearch = ""
            } else {
                expandedExerciseId = exercise.id
                exerciseSearch = ""
            }
        }
    }

    private func closeDropdown() {
        withAnimation(.spring(response: 0.30, dampingFraction: 0.92)) {
            expandedExerciseId = nil
            exerciseSearch = ""
        }
    }
}

// MARK: - Catalog models + embedded data

struct ExercisesCatalogEntry {
    let muscle: String
    let exercises: [String]
}

enum ExercisesCatalogData {
    static let catalog: [ExercisesCatalogEntry] = [
        .init(muscle: "Pecho", exercises: [
            "Press plano con barra",
            "Press plano con mancuernas",
            "Press inclinado con barra",
            "Press inclinado con mancuernas",
            "Press declinado con barra",
            "Press declinado con mancuernas",
            "Press en máquina",
            "Press inclinado en máquina",
            "Press Hammer",
            "Press convergente",
            "Press en Smith plano",
            "Press en Smith inclinado",
            "Fondos en paralelas para pecho",
            "Flexiones",
            "Flexiones inclinadas",
            "Flexiones declinadas",
            "Aperturas con mancuernas planas",
            "Aperturas con mancuernas inclinadas",
            "Aperturas en peck deck (contractor)",
            "Cruces en polea alta (cable cross)",
            "Cruces en polea media",
            "Cruces en polea baja",
            "Aperturas en polea de pie",
            "Aperturas en polea acostado",
            "Pullover con mancuerna",
            "Pullover en polea",
            "Press con agarre neutro",
            "Press tipo Guillotine"
        ]),
        .init(muscle: "Espalda", exercises: [
            "Dominadas pronas",
            "Dominadas supinas",
            "Dominadas neutras",
            "Jalón al pecho en polea (agarre ancho)",
            "Jalón al pecho (agarre cerrado)",
            "Jalón al pecho (agarre neutro)",
            "Jalón tras nuca",
            "Remo con barra",
            "Remo Pendlay",
            "Remo con mancuerna a una mano",
            "Remo en banco inclinado (pecho apoyado)",
            "Remo en polea baja (sentado)",
            "Remo en máquina (remadora)",
            "Remo Hammer",
            "Remo en T",
            "Remo en T con apoyo de pecho",
            "Remo en Smith",
            "Jalón con brazos rectos (pullover en polea)",
            "Pull-over en máquina",
            "Peso muerto convencional",
            "Peso muerto estilo sumo",
            "Rack pull",
            "Buenos días",
            "Hiperextensiones lumbares",
            "Remo invertido",
            "Face pull",
            "Encogimientos escapulares en barra"
        ]),
        .init(muscle: "Femorales", exercises: [
            "Peso muerto rumano (barra)",
            "Peso muerto rumano (mancuernas)",
            "Peso muerto rumano a una pierna",
            "Buenos días (barra)",
            "Curl femoral acostado (máquina)",
            "Curl femoral sentado (máquina)",
            "Curl femoral parado (máquina)",
            "Curl nórdico (Nordic curl)",
            "Glute ham raise",
            "Pull-through en polea",
            "Kettlebell swing",
            "Hip hinge con banda elástica",
            "Curl femoral con fitball",
            "Curl femoral con deslizadores",
            "Peso muerto con piernas rígidas",
            "Buenos días en Smith",
            "Curl femoral en polea con tobillera",
            "RDL en Smith"
        ]),
        .init(muscle: "Hombros", exercises: [
            "Press militar con barra",
            "Press militar sentado con barra",
            "Press con mancuernas sentado",
            "Press con mancuernas parado",
            "Arnold press",
            "Press en máquina de hombros",
            "Press Hammer de hombros",
            "Press en Smith",
            "Elevaciones laterales con mancuernas",
            "Elevaciones laterales sentado",
            "Elevaciones laterales en polea",
            "Elevaciones laterales en máquina",
            "Elevaciones frontales con mancuernas",
            "Elevaciones frontales con disco",
            "Elevaciones frontales en polea",
            "Pájaros (deltoide posterior) con mancuernas",
            "Pájaros en peck deck inverso",
            "Pájaros en polea (cruce posterior)",
            "Face pull",
            "Remo al mentón (upright row)",
            "Encogimiento + press (push press)",
            "Y-raises en banco inclinado"
        ]),
        .init(muscle: "Bíceps", exercises: [
            "Curl con barra recta",
            "Curl con barra EZ",
            "Curl alternado con mancuernas",
            "Curl simultáneo con mancuernas",
            "Curl martillo",
            "Curl martillo cruzado",
            "Curl inclinado con mancuernas",
            "Curl predicador en banco Scott (barra EZ)",
            "Curl predicador con mancuerna",
            "Curl predicador en máquina",
            "Curl en polea baja (barra)",
            "Curl en polea con soga",
            "Curl concentración",
            "Curl araña (spider curl)",
            "Curl 21s",
            "Curl en banco inclinado con barra EZ",
            "Dominadas supinas (chin-up) enfocadas en bíceps",
            "Curl con banda elástica",
            "Curl en máquina (biceps machine)"
        ]),
        .init(muscle: "Tríceps", exercises: [
            "Press cerrado con barra",
            "Press cerrado en Smith",
            "Fondos en paralelas",
            "Fondos en banco (bench dips)",
            "Extensión de tríceps en polea (pushdown) con barra",
            "Extensión de tríceps en polea con soga",
            "Pushdown agarre inverso",
            "Extensión por encima de la cabeza con mancuerna (a dos manos)",
            "Extensión por encima de la cabeza con mancuerna (una mano)",
            "Extensión por encima de la cabeza en polea (con soga)",
            "Rompecráneos / press francés (skull crushers) con barra EZ",
            "Press francés sentado (barra EZ)",
            "Patada de tríceps con mancuerna (kickback)",
            "Patada de tríceps en polea",
            "Extensión acostado con mancuernas",
            "Flexiones diamante",
            "JM press",
            "Extensión en máquina de tríceps"
        ]),
        .init(muscle: "Abdomen", exercises: [
            "Crunch",
            "Crunch en máquina",
            "Crunch en polea",
            "Crunch en banco declinado",
            "Crunch con disco en el pecho",
            "Elevación de piernas colgado",
            "Elevación de rodillas colgado",
            "Elevación de piernas en paralelas",
            "Reverse crunch",
            "Plancha (plank)",
            "Plancha lateral",
            "Rueda abdominal (ab wheel)",
            "Dead bug",
            "Hollow hold",
            "Bicycle crunch",
            "Mountain climbers",
            "Toques de talón (heel taps)",
            "V-ups",
            "Russian twist",
            "Woodchopper en polea",
            "Pallof press en polea/banda"
        ]),
        .init(muscle: "Glúteos", exercises: [
            "Hip thrust con barra",
            "Hip thrust en máquina",
            "Hip thrust en Smith",
            "Puente de glúteos (glute bridge)",
            "Puente a una pierna",
            "Patada de glúteo en polea (tobillera)",
            "Patada de glúteo en máquina",
            "Abducción de cadera en máquina",
            "Abducción con banda (mini band)",
            "Sentadilla (barra)",
            "Sentadilla en Smith",
            "Sentadilla sumo",
            "Peso muerto sumo",
            "Zancadas caminando",
            "Zancadas atrás",
            "Búlgaras (Bulgarian split squat)",
            "Step-up (subidas al banco)",
            "Pull-through en polea",
            "Buenos días (enfocado en glúteo/hinge)",
            "Cable kickback cruzado"
        ]),
        .init(muscle: "Cuadriceps", exercises: [
            "Sentadilla con barra",
            "Sentadilla frontal",
            "Sentadilla goblet",
            "Sentadilla en Smith",
            "Hack squat (máquina)",
            "Prensa 45° (leg press)",
            "Prensa horizontal",
            "Extensión de piernas (máquina)",
            "Sissy squat",
            "Zancadas (lunges)",
            "Zancadas caminando",
            "Zancadas atrás",
            "Búlgaras",
            "Step-up",
            "Sentadilla en caja",
            "Sentadilla con pausa",
            "Wall sit",
            "Sentadilla sumo",
            "Trineo / empuje de trineo"
        ]),
        .init(muscle: "Pantorrillas", exercises: [
            "Gemelos de pie en máquina",
            "Gemelos sentado en máquina",
            "Gemelos en prensa",
            "Gemelos a una pierna",
            "Gemelos en Smith",
            "Donkey calf raise",
            "Saltar la soga",
            "Elevaciones excéntricas de gemelos",
            "Gemelos con mancuerna",
            "Gemelos en multipower"
        ]),
        .init(muscle: "Trapecios", exercises: [
            "Encogimientos con barra",
            "Encogimientos con mancuernas",
            "Encogimientos en Smith",
            "Encogimientos en máquina",
            "Farmer walk (caminata del granjero)",
            "Rack pull",
            "Peso muerto",
            "High pull",
            "Remo al mentón",
            "Face pull (trapecio medio/alto)",
            "Remo con barra (espalda alta)",
            "Y-raises / W-raises (trapecio medio)"
        ]),
        .init(muscle: "Antebrazos", exercises: [
            "Curl de muñeca con barra",
            "Curl de muñeca con mancuernas",
            "Curl de muñeca inverso",
            "Curl inverso con barra",
            "Curl martillo",
            "Farmer walk",
            "Colgarse de la barra",
            "Pinza con discos",
            "Pronación/supinación con mancuerna",
            "Wrist roller (rodillo de muñeca)",
            "Apretar hand gripper",
            "Extensión de dedos con banda elástica"
        ])
    ]
}

// MARK: - Muscles enum (local)

enum WorkoutMuscle: String, CaseIterable, Identifiable {
    case pecho = "Pecho"
    case espalda = "Espalda"
    case femorales = "Femorales"
    case hombros = "Hombros"
    case biceps = "Bíceps"
    case triceps = "Tríceps"
    case abdomen = "Abdomen"
    case gluteos = "Glúteos"
    case cuadriceps = "Cuadriceps"
    case pantorrillas = "Pantorrillas"
    case trapecios = "Trapecios"
    case antebrazos = "Antebrazos"

    var id: String { rawValue }
}

// MARK: - UI components

private struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .textInputAutocapitalization(.sentences)
            .autocorrectionDisabled()
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
    }
}

private struct StepperPill: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.75))

            Spacer()

            Button { value = max(range.lowerBound, value - 1) } label: {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.white.opacity(0.06)))
            }
            .buttonStyle(.plain)

            Text("\(value)")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .frame(minWidth: 24)

            Button { value = min(range.upperBound, value + 1) } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.white.opacity(0.06)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

private struct TogglePill: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.75))

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.appGreen.opacity(0.95))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

private struct WeightField: View {
    let title: String
    let value: Int?
    let isDisabled: Bool
    let onChange: (Int?) -> Void

    @State private var text: String = ""

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.75))

            Spacer()

            TextField("0", text: Binding(
                get: { text.isEmpty ? (value.map(String.init) ?? "") : text },
                set: { new in
                    text = new
                    let cleaned = new.trimmingCharacters(in: .whitespacesAndNewlines)
                    if cleaned.isEmpty { onChange(nil); return }
                    onChange(Int(cleaned))
                }
            ))
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .foregroundColor(.white.opacity(isDisabled ? 0.35 : 0.9))
            .disabled(isDisabled)
            .frame(width: 70)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .opacity(isDisabled ? 0.55 : 1.0)
        .onAppear {
            if let v = value { text = "\(v)" }
        }
    }
}

private struct PrimaryBottomButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Capsule().fill(Color.appGreen.opacity(0.95)))
        }
        .buttonStyle(.plain)
    }
}

private struct MuscleChipSelectable: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.appGreen.opacity(0.22) : Color.white.opacity(0.10))
                        .frame(width: 22, height: 22)

                    Image(systemName: isSelected ? "checkmark" : "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isSelected ? Color.appGreen.opacity(0.95) : .white.opacity(0.65))
                }

                Text(title)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(isSelected ? 0.92 : 0.80))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.appGreen.opacity(0.10) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? Color.appGreen.opacity(0.35) : Color.white.opacity(0.10), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helpers

private extension Array where Element == String {
    func uniqueSorted() -> [String] {
        Array(Set(self)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}

private extension String {
    func toExerciseSlug() -> String {
        let lower = self.lowercased()
        let noAccents = lower.folding(options: .diacriticInsensitive, locale: .current)

        let mapped = noAccents.map { ch -> Character in
            (ch.isLetter || ch.isNumber) ? ch : "-"
        }

        let raw = String(mapped)
        let collapsed = raw.replacingOccurrences(of: "-{2,}", with: "-", options: .regularExpression)
        return collapsed.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}
