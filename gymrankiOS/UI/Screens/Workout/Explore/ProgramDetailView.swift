//
//  ProgramDetailView.swift
//  gymrankiOS
//

import SwiftUI
import FirebaseFirestore

struct ProgramDetailView: View {

    @Environment(\.dismiss) private var dismiss
    let template: WorkoutTemplate

    @StateObject private var vm = ProgramDetailVM()

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {

                    TopBar(title: "Programa") { dismiss() }

                    HeaderCard(template: template)

                    if vm.isLoading {
                        loadingState
                    } else if let err = vm.errorMessage {
                        errorState(err)
                    } else {
                        ForEach(vm.days) { day in
                            DayCard(day: day)
                        }
                    }

                    Spacer(minLength: 14)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .padding(.top, 10)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task(id: template.id) {
            await vm.loadDays(templateId: template.id)
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 10) {
            ProgressView().tint(Color.appGreen.opacity(0.95))
            Text("Cargando días…")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.top, 18)
    }

    private func errorState(_ msg: String) -> some View {
        VStack(spacing: 10) {
            Text("No se pudo cargar")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.9))

            Text(msg)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)

            Button {
                Task { await vm.loadDays(templateId: template.id) }
            } label: {
                Text("Reintentar")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(Capsule().fill(Color.appGreen.opacity(0.95)))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 18)
    }
}

// MARK: - VM (path directo, sin índices)

@MainActor
final class ProgramDetailVM: ObservableObject {
    @Published var isLoading = false
    @Published var days: [WorkoutTemplateDay] = []
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var requestToken = UUID()

    func loadDays(templateId: String) async {
        let token = UUID()
        requestToken = token

        isLoading = true
        errorMessage = nil
        days = []

        do {
            let snap = try await db
                .collection("workoutTemplates")
                .document(templateId)
                .collection("days")
                .getDocuments()

            guard requestToken == token else { return }

            let parsed: [WorkoutTemplateDay] = snap.documents.compactMap { doc in
                let data = doc.data()

                let description = (data["description"] as? String) ?? ""

                let exArr = data["exercises"] as? [[String: Any]] ?? []
                let exercises: [WorkoutTemplateExercise] = exArr.compactMap { ex in
                    guard
                        let name = ex["name"] as? String,
                        let reps = ex["reps"] as? Int,
                        let sets = ex["sets"] as? Int
                    else { return nil }

                    return WorkoutTemplateExercise(
                        name: name,
                        reps: reps,
                        sets: sets,
                        usesBodyweight: ex["usesBodyweight"] as? Bool ?? false,
                        weightKg: ex["weightKg"] as? Double ?? 0,
                        order: ex["order"] as? Int,
                        weekday: ex["weekday"] as? Int
                    )
                }
                .sorted { ($0.order ?? 0) < ($1.order ?? 0) }

                let dayIndex =
                    (data["dayIndex"] as? Int)
                    ?? Self.extractDayNumber(from: doc.documentID)
                    ?? exercises.first?.weekday
                    ?? 0

                let titleFromDb = data["title"] as? String ?? data["tittle"] as? String
                let title = titleFromDb ?? "Día \(dayIndex) - \(exercises.first?.name ?? "Entrenamiento")"

                let uniqueId = "\(templateId)_\(doc.documentID)"

                return WorkoutTemplateDay(
                    id: uniqueId,
                    title: title,
                    description: description,
                    weekday: dayIndex,
                    order: dayIndex,
                    exercises: exercises
                )
            }
            .sorted { ($0.order ?? 0) < ($1.order ?? 0) }

            self.days = parsed
            self.isLoading = false
        } catch {
            guard requestToken == token else { return }
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }

    private static func extractDayNumber(from docId: String) -> Int? {
        let parts = docId.split(separator: "_")
        if let last = parts.last, let n = Int(last) { return n }
        let digits = docId.filter { $0.isNumber }
        return Int(digits)
    }
}

// MARK: - UI Components (autocontenidos)

private struct TopBar: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Text(title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.top, 4)
    }
}

private struct HeaderCard: View {
    let template: WorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgramHero(
                title: template.title,
                subtitle: template.description,
                imageName: heroImageName(for: template)
            )

            FlowTags(tags: buildTags())
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.appGreen.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func buildTags() -> [String] {
        var out: [String] = []
        if template.isPro { out.append("PRO") }
        out.append("\(template.weeks) \(template.weeks == 1 ? "Semana" : "Semanas")")
        out.append(template.level)
        out.append("\(template.frequencyPerWeek)x/sem")
        out.append(contentsOf: template.goalTags)

        var seen = Set<String>()
        return out.filter { seen.insert($0).inserted }
    }

    private func heroImageName(for t: WorkoutTemplate) -> String {
        let lower = t.title.lowercased()
        if lower.contains("candito") { return "program1" }
        if lower.contains("juggernaut") { return "program2" }
        return "program2"
    }
}

private struct ProgramHero: View {
    let title: String
    let subtitle: String
    let imageName: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [Color.black.opacity(0.05), Color.black.opacity(0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

private struct FlowTags: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(tag == "PRO" ? Color.appGreen.opacity(0.95) : .white.opacity(0.75))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.06)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
                }
            }
        }
    }
}

private struct DayCard: View {
    let day: WorkoutTemplateDay

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(day.title)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))

            if !day.description.isEmpty {
                Text(day.description)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(day.exercises) { ex in
                    HStack(spacing: 10) {
                        Text("• \(ex.name)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.90))

                        Spacer()

                        Text("\(ex.sets)x\(ex.reps)")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}
