//
//  SecondaryButton.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 05/02/2026.
//
import SwiftUI

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    Capsule().fill(Color.white.opacity(0.06))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
