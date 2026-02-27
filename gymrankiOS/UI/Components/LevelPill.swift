//
//  LevelPill.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 26/02/2026.
//

import SwiftUI

struct LevelPill: View {
    let level: Int

    var body: some View {
        Text("Nivel \(level)")
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundColor(Color.appGreen.opacity(0.95))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.appGreen.opacity(0.10))
            )
            .overlay(
                Capsule().stroke(Color.appGreen.opacity(0.35), lineWidth: 1)
            )
    }
}
