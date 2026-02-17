import SwiftUI

struct HomeView: View {
    @Binding var path: NavigationPath
    @State private var showRegister = false

    var body: some View {
        ZStack {
            AuthBackground().ignoresSafeArea()

            VStack {
                Spacer().frame(height: 24)

                HStack(spacing: 8) {
                    Text("🇦🇷")
                    Text("ARGENTINA")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.white.opacity(0.08)))
                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.appGreen.opacity(0.4), lineWidth: 2)
                        .frame(width: 150, height: 150)

                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 132, height: 132)

                    Text("💪")
                        .font(.system(size: 56))
                }

                Spacer().frame(height: 24)

                HStack(spacing: 0) {
                    Text("FIT").foregroundColor(.white)
                    Text("RANK").foregroundColor(.appGreen)
                }
                .font(.system(size: 44, weight: .heavy))
                .tracking(1)

                Spacer().frame(height: 12)

                VStack(spacing: 8) {
                    Text("Dominá el ranking. Subí de nivel.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    Text("La comunidad fitness más competitiva de Argentina.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 32)

                VStack(spacing: 14) {
                    PrimaryButton(title: "EMPEZAR") {
                        showRegister = true
                    }

                    SecondaryButton(title: "¿Ya tenés cuenta?") {
                        path.append(AppRoute.login)
                    }
                }
                .padding(.horizontal, 28)

                Spacer()

                VStack(spacing: 6) {
                    Text("v1.0")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.35))

                    Text("HECHO PARA LOS QUE COMPITEN")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(1)
                }
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterSheetView(
                onCreated: {
                    showRegister = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        path.append(AppRoute.profileSetup)
                    }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(26)
        }
    }
}

#Preview {
    HomeView(path: .constant(NavigationPath()))
}
