import SwiftUI

struct RegisterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let onCreated: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    @StateObject private var vm = AuthViewModel()
    @State private var showErrorAlert = false

    private var canSubmit: Bool {
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !e.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else { return false }
        guard password == confirmPassword else { return false }
        return password.count >= 6
    }

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

                    AppSecureField(placeholder: "Contraseña (mín. 6)", text: $password)

                    AppSecureField(placeholder: "Confirmá tu contraseña", text: $confirmPassword)
                }
                .padding(.horizontal, 22)

                Spacer().frame(height: 16)

                PrimaryButton(title: vm.isLoading ? "CREANDO..." : "CREAR CUENTA") {
                    Task {
                        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)

                        guard password == confirmPassword else {
                            vm.errorMessage = "Las contraseñas no coinciden."
                            showErrorAlert = true
                            return
                        }

                        await vm.register(email: e, password: password)

                        if vm.errorMessage != nil {
                            showErrorAlert = true
                        } else {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                onCreated()
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
                .disabled(!canSubmit || vm.isLoading)

                Spacer().frame(height: 14)

                DividerRow(text: "O continuá con")
                    .padding(.horizontal, 22)

                Spacer().frame(height: 14)

                HStack(spacing: 14) {
                    SocialButton(
                        title: vm.isLoading ? "Google..." : "Google"
                    ) {
                        Task {
                            await signUpWithGoogle()
                        }
                    }
                    .disabled(vm.isLoading)
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
        .alert("Error al crear cuenta", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.errorMessage ?? "Ocurrió un error.")
        }
    }

    // MARK: - Google sign up

    @MainActor
    private func signUpWithGoogle() async {
        // Reutilizamos el loader/error del vm para UI consistente
        vm.errorMessage = nil
        vm.isLoading = true

        do {
            _ = try await AuthService.shared.signInWithGoogle()
            vm.isLoading = false

            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                onCreated()
            }
        } catch {
            vm.isLoading = false
            vm.errorMessage = (error as NSError).localizedDescription
            showErrorAlert = true
        }
    }
}

#Preview {
    RegisterSheetView(onCreated: {})
}
