import SwiftUI

struct GymCheckInPromptView: View {
    let onYes: () -> Void
    let onNo: () -> Void
    let onClose: (() -> Void)?    // 👈 opcional para el botón X
    let isLoading: Bool
    let errorMessage: String?

    init(
        onYes: @escaping () -> Void,
        onNo: @escaping () -> Void,
        onClose: (() -> Void)? = nil,
        isLoading: Bool,
        errorMessage: String?
    ) {
        self.onYes = onYes
        self.onNo = onNo
        self.onClose = onClose
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }

    var body: some View {
        ZStack {
            // Backdrop (opaco y legible)
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                header

                Text("Si respondés que sí, sumás 20 puntos al ranking.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.red.opacity(0.95))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }

                buttons
            }
            .padding(18)
            .frame(maxWidth: 420)
            .background(cardBackground)        // ✅ sin transparencia
            .overlay(cardBorder)
            .padding(.horizontal, 16)
        }
        // ⚠️ Si NO lo mostrás con .sheet, podés borrar estas 2 líneas
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.appGreen.opacity(0.22))
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Color.appGreen.opacity(0.40), lineWidth: 1))

                Image(systemName: "figure.run")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.appGreen.opacity(0.95))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Check-in diario")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))

                Text("¿Hoy fuiste a entrenar?")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if let onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
        }
    }

    // MARK: - Buttons

    private var buttons: some View {
        HStack(spacing: 12) {
            Button(action: onNo) {
                Text("No")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

            Button(action: onYes) {
                HStack(spacing: 8) {
                    if isLoading {
                        SwiftUI.ProgressView()
                            .tint(.black.opacity(0.85))
                            .scaleEffect(0.9)
                    }
                    Text(isLoading ? "Sumando..." : "Sí")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.black.opacity(0.92))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.appGreen.opacity(0.95))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.appGreen.opacity(0.55), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
        .padding(.top, 4)
    }

    // MARK: - Card style

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.black.opacity(0.92))               // ✅ opaco
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.appGreen.opacity(0.10))    // leve tinte
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(Color.white.opacity(0.10), lineWidth: 1)
    }
}

#Preview {
    ZStack {
        AppBackground().ignoresSafeArea()
        GymCheckInPromptView(
            onYes: {},
            onNo: {},
            onClose: {},
            isLoading: false,
            errorMessage: nil
        )
    }
}
