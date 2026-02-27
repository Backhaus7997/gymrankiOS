import SwiftUI

struct FeedRoutinesSheet: View {

    @Environment(\.dismiss) private var dismiss

    let username: String
    let routines: [FeedRoutinePreview]              // ✅ previews
    let onOpenRoutine: (FeedRoutinePreview) -> Void // ✅ preview

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            VStack(spacing: 12) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(routines, id: \.id) { r in
                            Button {
                                onOpenRoutine(r)
                            } label: {
                                RoutineCardPreviewView(routine: r)
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .padding(.top, 8)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Entrenamientos")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text(username)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.10)))
                    .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }
}

// MARK: - Card (Preview)

private struct RoutineCardPreviewView: View {

    let routine: FeedRoutinePreview

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(routine.title)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))

            // ✅ TODOS LOS EJERCICIOS DEL ENTRENAMIENTO (no recorta)
            VStack(spacing: 8) {
                ForEach(routine.exercisesSummary) { ex in
                    ExerciseRowPreviewView(name: ex.name, reps: ex.reps, weight: ex.weight)
                }
            }

            Text("Público • \(routine.timeAgo)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
                .padding(.top, 2)
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

private struct ExerciseRowPreviewView: View {

    let name: String
    let reps: String
    let weight: String

    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.90))

            Spacer()

            Text("\(reps) • \(weight)")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.65))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.30))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
