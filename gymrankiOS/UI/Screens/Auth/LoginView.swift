import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Binding var path: NavigationPath

    @State private var emailOrUser = ""
    @State private var password = ""

    @State private var showRegisterSheet = false

    @StateObject private var vm = AuthViewModel()
    @State private var showErrorAlert = false

    var body: some View {
        ZStack {
            AuthBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 130)

                    TrophyBadge()

                    Spacer().frame(height: 18)

                    VStack(spacing: 8) {
                        Text("FITRANK")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)

                        Text("¿Listo para escalar el ranking argentino?")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.65))
                    }

                    Spacer().frame(height: 26)

                    VStack(spacing: 14) {
                        AppTextField(
                            placeholder: "Correo",
                            text: $emailOrUser,
                            leftIconSystemName: "envelope"
                        )

                        AppSecureField(
                            placeholder: "Contraseña",
                            text: $password,
                            leftIconSystemName: "lock"
                        )
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 18)

                    PrimaryButton(title: vm.isLoading ? "ENTRANDO..." : "ENTRAR  →") {
                        Task {
                            let email = emailOrUser.trimmingCharacters(in: .whitespacesAndNewlines)
                            await vm.login(email: email, password: password)

                            if vm.errorMessage != nil {
                                showErrorAlert = true
                            } else {
                                path.append(AppRoute.dashboard)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .disabled(vm.isLoading)

                    Spacer().frame(height: 18)

                    DividerRow(text: "O continuá con")
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 14)

                    HStack(spacing: 14) {
                        SocialButton(title: "Google") {
                            Task {
                                await vm.loginWithGoogle()
                                if vm.errorMessage != nil { showErrorAlert = true }
                                else { path.append(AppRoute.dashboard) }
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 22)

                    BottomRegisterRow {
                        showRegisterSheet = true
                    }

                    Spacer().frame(height: 24)
                }
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showRegisterSheet) {
            RegisterSheetView(onCreated: {
                path.append(AppRoute.profileSetup)
            })
        }
        .alert("Error de login", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.errorMessage ?? "Ocurrió un error.")
        }
    }
}

#Preview {
    LoginView(path: .constant(NavigationPath()))
}
