import SwiftUI

struct LoginView: View {
    @Binding var path: NavigationPath

    @State private var emailOrUser = ""
    @State private var password = ""

    @State private var showRegisterSheet = false

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
                            placeholder: "Correo o usuario",
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

                    PrimaryButton(title: "ENTRAR  →") {
                        path.append(AppRoute.selectGym)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 18)

                    DividerRow(text: "O continuá con")
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 14)

                    HStack(spacing: 14) {
                        SocialButton(title: "Google") { }
                        SocialButton(title: "Apple") { }
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
    }
}

#Preview {
    LoginView(path: .constant(NavigationPath()))
}
