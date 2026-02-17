import SwiftUI

struct RegisterSheetView: View {
    @Environment(\.dismiss) private var dismiss

    let onCreated: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.black.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.6), radius: 30, x: 0, y: 18)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                TrophyBadge().padding(.top, 18)
                Spacer().frame(height: 14)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Creá tu cuenta")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text("Sumate al ranking y competí con los mejores de Argentina.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.60))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.top, 16)

                Spacer().frame(height: 16)

                VStack(spacing: 14) {
                    AppTextField(
                        placeholder: "Correo electrónico",
                        text: $email,
                        leftIconSystemName: "envelope"
                    )
                    AppSecureField(placeholder: "Contraseña", text: $password)
                    AppSecureField(placeholder: "Confirmá tu contraseña", text: $confirmPassword)
                }
                .padding(.horizontal, 22)

                Spacer().frame(height: 16)

                PrimaryButton(title: "CREAR CUENTA") {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        onCreated()
                    }
                }
                .padding(.horizontal, 22)

                Spacer().frame(height: 14)

                DividerRow(text: "O continuá con")
                    .padding(.horizontal, 22)

                Spacer().frame(height: 14)

                HStack(spacing: 14) {
                    SocialButton(title: "Google") { }
                    SocialButton(title: "Apple") { }
                }
                .padding(.horizontal, 22)

                Spacer().frame(height: 14)

                Button("Cancelar") { dismiss() }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.bottom, 18)
            }
        }
        .presentationBackground(.clear)
    }
}

#Preview {
    RegisterSheetView(onCreated: {})
}
