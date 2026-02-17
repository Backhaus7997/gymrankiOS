//
//  ProfileSetupFlowView.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 11/02/2026.
//

import SwiftUI

// MARK: - Profile Setup Flow (5 pasos)

struct ProfileSetupFlowView: View {

    let onFinish: () -> Void

    @State private var step: Step = .birthdate

    // Datos
    @State private var birthdate: Date? = nil
    @State private var weightKg: String = ""
    @State private var heightCm: String = ""
    @State private var gender: Gender? = nil
    @State private var experience: Experience? = nil

    // UI
    @State private var showDatePicker = false

    enum Step: Int, CaseIterable {
        case birthdate = 1
        case weight = 2
        case height = 3
        case gender = 4
        case experience = 5

        var title: String {
            switch self {
            case .birthdate: return "Fecha de nacimiento"
            case .weight: return "Peso"
            case .height: return "Altura"
            case .gender: return "Género"
            case .experience: return "Experiencia"
            }
        }

        var subtitle: String {
            switch self {
            case .birthdate: return "¿Cuándo naciste?"
            case .weight: return "Ingresá tu peso actual"
            case .height: return "Ingresá tu altura"
            case .gender: return "Seleccioná tu género"
            case .experience: return "Contanos tu experiencia"
            }
        }

        var buttonTitle: String {
            self == .experience ? "Finalizar" : "Continuar"
        }
    }

    enum Gender: String, CaseIterable, Identifiable {
        case male = "Masculino"
        case female = "Femenino"
        case other = "Otro"
        var id: String { rawValue }
    }

    enum Experience: String, CaseIterable, Identifiable {
        case beginner = "Principiante"
        case intermediate = "Intermedio"
        case advanced = "Avanzado"
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            VStack(spacing: 0) {

                // Top area
                topHeader
                    .padding(.top, 10)
                    .padding(.horizontal, 18)

                Spacer().frame(height: 18)

                // Icon (dumbbell)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(Color.appGreen.opacity(0.28))
                    .padding(.top, 10)

                Spacer()

                // Center card
                centerCard
                    .padding(.horizontal, 18)

                Spacer()

                // Bottom actions
                bottomBar
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(
                current: birthdate ?? Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date(),
                onCancel: { showDatePicker = false },
                onSave: { picked in
                    birthdate = picked
                    showDatePicker = false
                }
            )
            .presentationDetents([.height(360)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(22)
        }
    }

    // MARK: - Top Header

    private var topHeader: some View {
        VStack(spacing: 12) {

            HStack {
                Text("Armá tu perfil")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))

                Spacer()

                Text("Paso \(step.rawValue) de 5")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
            }

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.10))
                    .frame(height: 6)

                Capsule()
                    .fill(Color.appGreen.opacity(0.95))
                    .frame(width: progressWidth(totalWidth: UIScreen.main.bounds.width - 36), height: 6)
            }

            // Pill “GYM RANK”
            Text("GYM RANK")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.80))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.35))
                        .overlay(
                            Capsule().stroke(Color.appGreen.opacity(0.25), lineWidth: 1)
                        )
                )
        }
    }

    private func progressWidth(totalWidth: CGFloat) -> CGFloat {
        let t = CGFloat(step.rawValue) / 5.0
        return max(40, totalWidth * t)
    }

    // MARK: - Card

    private var centerCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            VStack(alignment: .leading, spacing: 6) {
                Text(step.title)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))

                Text(step.subtitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            switch step {
            case .birthdate:
                dateField

            case .weight:
                inputField(
                    icon: "scalemass",
                    placeholder: "Peso (kg)",
                    text: $weightKg,
                    keyboard: .numberPad
                )

            case .height:
                inputField(
                    icon: "arrow.up.and.down",
                    placeholder: "Altura (cm)",
                    text: $heightCm,
                    keyboard: .numberPad
                )

            case .gender:
                optionRow(
                    items: Gender.allCases.map { $0.rawValue },
                    selected: gender?.rawValue,
                    onTap: { picked in
                        gender = Gender.allCases.first(where: { $0.rawValue == picked })
                    }
                )

                hintText("Tocá una opción para continuar")

            case .experience:
                optionRow(
                    items: Experience.allCases.map { $0.rawValue },
                    selected: experience?.rawValue,
                    onTap: { picked in
                        experience = Experience.allCases.first(where: { $0.rawValue == picked })
                    }
                )

                hintText("Tocá una opción para continuar")
            }

        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.55))
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

    private var dateField: some View {
        Button {
            showDatePicker = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "person")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.45))
                    .frame(width: 18)

                Text(birthdateText)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(birthdate == nil ? .white.opacity(0.35) : .white.opacity(0.85))

                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var birthdateText: String {
        guard let birthdate else { return "DD/MM/AAAA" }
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        return f.string(from: birthdate)
    }

    private func inputField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.45))
                .frame(width: 18)

            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.88))
                .tint(Color.appGreen.opacity(0.95))

            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func optionRow(items: [String], selected: String?, onTap: @escaping (String) -> Void) -> some View {
        HStack(spacing: 10) {
            ForEach(items, id: \.self) { item in
                Button {
                    onTap(item)
                } label: {
                    Text(item)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(selected == item ? .white.opacity(0.92) : .white.opacity(0.70))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(selected == item ? Color.appGreen.opacity(0.14) : Color.white.opacity(0.06))
                        )
                        .overlay(
                            Capsule()
                                .stroke(selected == item ? Color.appGreen.opacity(0.35) : Color.white.opacity(0.10), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
    }

    private func hintText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.40))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 2)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(alignment: .center, spacing: 14) {

            Button {
                goBack()
            } label: {
                Text("Volver")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .frame(width: 56, alignment: .leading)
            }
            .buttonStyle(.plain)
            .opacity(step == .birthdate ? 0.25 : 1.0)
            .disabled(step == .birthdate)

            Button {
                goNext()
            } label: {
                Text(step.buttonTitle)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.appGreen.opacity(isNextEnabled ? 0.95 : 0.45))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!isNextEnabled)
        }
    }

    private var isNextEnabled: Bool {
        switch step {
        case .birthdate:
            return birthdate != nil
        case .weight:
            return isPositiveNumber(weightKg)
        case .height:
            return isPositiveNumber(heightCm)
        case .gender:
            return gender != nil
        case .experience:
            return experience != nil
        }
    }

    private func isPositiveNumber(_ s: String) -> Bool {
        let filtered = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !filtered.isEmpty else { return false }
        let replaced = filtered.replacingOccurrences(of: ",", with: ".")
        guard let v = Double(replaced) else { return false }
        return v > 0
    }

    private func goBack() {
        guard let prev = Step(rawValue: step.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            step = prev
        }
    }

    private func goNext() {
        if step == .experience {
            onFinish()
            return
        }
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            step = next
        }
    }
}

// MARK: - Date Picker Sheet

private struct DatePickerSheet: View {
    let current: Date
    let onCancel: () -> Void
    let onSave: (Date) -> Void

    @State private var selectedDate: Date

    init(current: Date, onCancel: @escaping () -> Void, onSave: @escaping (Date) -> Void) {
        self.current = current
        self.onCancel = onCancel
        self.onSave = onSave
        _selectedDate = State(initialValue: current)
    }

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            VStack(spacing: 14) {
                Spacer().frame(height: 6)

                // Header
                HStack {
                    Text("Elegí tu fecha")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))

                    Spacer()

                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Color.white.opacity(0.06)))
                            .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                // Calendar card
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .overlay(
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .tint(Color.appGreen.opacity(0.95))
                            .environment(\.colorScheme, .dark)
                            .environment(\.locale, Locale(identifier: "es_AR"))
                            .padding(.horizontal, 28)
                            .padding(.top, 5)
                            .frame(height: 300)
                    )
                    .frame(height: 300)

                // Button
                Button {
                    onSave(selectedDate)
                } label: {
                    Text("Guardar")
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
                .padding(.top, 4)

                Spacer(minLength: 40)
            }
            .padding(16)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileSetupFlowView(onFinish: { print("finish") })
    }
}
