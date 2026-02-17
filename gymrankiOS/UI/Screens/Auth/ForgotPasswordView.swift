//
//  ForgotPasswordView.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 05/02/2026.
//

import SwiftUI

struct ForgotPasswordView: View {

    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Recuperar contraseña")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text("Pantalla placeholder")
                    .foregroundColor(.white.opacity(0.6))

                PrimaryButton(title: "Volver") {
                    path.removeLast()
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ForgotPasswordView(path: .constant(NavigationPath()))
}
