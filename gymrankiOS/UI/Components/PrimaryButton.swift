//
//  PrimaryButton.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 05/02/2026.
//
import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    Capsule().fill(Color.appGreen)
                )
        }
        .buttonStyle(.plain)
    }
}
