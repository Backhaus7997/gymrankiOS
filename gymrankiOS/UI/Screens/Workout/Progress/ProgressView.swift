//
//  ProgressView.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 10/02/2026.
//

import SwiftUI

struct ProgressView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                topBar(title: "Progreso")
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                Spacer()

                VStack(spacing: 10) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white.opacity(0.30))

                    Text("Todavía no hay datos de progreso")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.90))

                    Text("Empezá a registrar entrenamientos para ver tu evolución.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func topBar(title: String) -> some View {
        HStack(spacing: 10) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Text(title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        ProgressView()
    }
}
