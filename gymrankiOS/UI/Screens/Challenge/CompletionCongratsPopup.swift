//
//  CompletionCongratsPopup.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 10/03/2026.
//

import SwiftUI

struct CompletionCongratsPopup: View {

    enum Kind {
        case challenge
        case mission
        case bet

        var title: String {
            switch self {
            case .challenge: return "Desafío"
            case .mission: return "Misión"
            case .bet: return "Apuesta"
            }
        }

        var icon: String {
            switch self {
            case .challenge: return "flag.checkered"
            case .mission: return "trophy.fill"
            case .bet: return "die.face.5.fill"
            }
        }
    }

    let kind: Kind
    let itemTitle: String
    let points: Int
    let onClose: () -> Void

    var body: some View {
        CongratsPopupContainer {
            header

            badge

            VStack(spacing: 8) {
                Text("¡Felicitaciones!")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.center)

                Text("Completaste \(kind.title):")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)

                Text(itemTitle)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
            .padding(.top, 4)

            pointsCard

            CongratsPrimaryButton(title: "CONTINUAR", action: onClose)
        }
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.appGreen.opacity(0.18))
                    .frame(width: 44, height: 44)

                Image(systemName: kind.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.appGreen.opacity(0.95))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Completado")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))

                Text(kind.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            Button { onClose() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var badge: some View {
        ZStack {
            Circle()
                .fill(Color.appGreen.opacity(0.14))
                .frame(width: 92, height: 92)
                .overlay(Circle().stroke(Color.appGreen.opacity(0.35), lineWidth: 1))

            Image(systemName: "checkmark")
                .font(.system(size: 36, weight: .heavy))
                .foregroundColor(.white.opacity(0.92))
        }
        .padding(.top, 6)
    }

    private var pointsCard: some View {
        VStack(spacing: 8) {
            Text("Puntos ganados")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.55))

            Text("+\(points)")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundColor(Color.appGreen.opacity(0.95))

            Text("Se sumaron a tu puntaje")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.appGreen.opacity(0.22), lineWidth: 1)
                )
        )
        .padding(.top, 4)
    }
}

// MARK: - UI Helpers

private struct CongratsPopupContainer<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        VStack(spacing: 14) { content }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.black.opacity(0.90))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.appGreen.opacity(0.18), lineWidth: 1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

private struct CongratsPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.appGreen.opacity(0.95))
                )
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
    }
}

#Preview {
    ZStack {
        AppBackground().ignoresSafeArea()
        CenterModalOverlay(isPresented: .constant(true)) {
            CompletionCongratsPopup(
                kind: .bet,
                itemTitle: "Apuesta cardio express",
                points: 120,
                onClose: {}
            )
            .padding(.horizontal, 18)
        }
    }
}
