//
//  AppBackground.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 06/02/2026.
//

import SwiftUI

struct AppBackground: View {
    var body: some View {
        ZStack {
            Color.black

            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.05),
                    Color.clear
                ]),
                center: .top,
                startRadius: 20,
                endRadius: 600
            )

            RadialGradient(
                gradient: Gradient(colors: [
                    Color.appGreen.opacity(0.10),
                    Color.clear
                ]),
                center: .center,
                startRadius: 60,
                endRadius: 520
            )
        }
    }
}
