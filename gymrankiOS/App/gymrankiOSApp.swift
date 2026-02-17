//
//  gymrankiOSApp.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 05/02/2026.
//

import SwiftUI

@main
struct gymrankiOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

private struct TitleBlock: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("GYM")
                .foregroundColor(.white)

            Text("RANK")
                .foregroundColor(Color.appGreen)
        }
        .font(.system(size: 44, weight: .heavy))
        .tracking(1)
    }
}

private struct SubtitleBlock: View {
    var body: some View {
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
    }
}

