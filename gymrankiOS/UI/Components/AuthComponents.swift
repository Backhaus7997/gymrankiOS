//
//  AuthComponents.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 06/02/2026.
//

import SwiftUI

struct AuthBackground: View {
    var body: some View {
        ZStack {
            Color.black

            RadialGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.05), .clear]),
                center: .top,
                startRadius: 20,
                endRadius: 520
            )

            RadialGradient(
                gradient: Gradient(colors: [Color.appGreen.opacity(0.14), .clear]),
                center: .center,
                startRadius: 40,
                endRadius: 420
            )
        }
    }
}

struct TrophyBadge: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appGreen.opacity(0.4), lineWidth: 2)
                .frame(width: 120, height: 120)

            Circle()
                .fill(Color.black.opacity(0.25))
                .frame(width: 104, height: 104)

            Text("🏆")
                .font(.system(size: 44))
        }
    }
}

struct DividerRow: View {
    let text: String
    var body: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
        }
    }
}

struct SocialButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct BottomRegisterRow: View {
    let onRegisterTap: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("¿No tenés cuenta?")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))

            Button("Registrate") {
                onRegisterTap()
            }
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(Color.appGreen)
        }
    }
}

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    let leftIconSystemName: String?

    var body: some View {
        HStack(spacing: 12) {
            if let leftIconSystemName {
                Image(systemName: leftIconSystemName)
                    .foregroundColor(.white.opacity(0.45))
            }

            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder).foregroundColor(.white.opacity(0.35))
                }
                .foregroundColor(.white)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.10), lineWidth: 1))
    }
}

struct AppSecureField: View {
    let placeholder: String
    @Binding var text: String
    var leftIconSystemName: String = "lock"

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: leftIconSystemName)
                .font(.system(size: 16, weight: .semibold))   
                .foregroundColor(.white.opacity(0.55))
                .frame(width: 22)

            SecureField("", text: $text, prompt: Text(placeholder)
                .foregroundColor(.white.opacity(0.45))
            )
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
