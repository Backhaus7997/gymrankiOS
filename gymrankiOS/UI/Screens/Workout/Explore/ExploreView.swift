//
//  ExploreView.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 10/02/2026.
//

import SwiftUI

struct ExploreView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: ExploreTab = .official
    @State private var query: String = ""

    enum ExploreTab: String, CaseIterable, Identifiable {
        case official = "Oficial"
        case community = "Comunidad"
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {

                    topBar

                    headerCard

                    segmentedTabs

                    searchBar

                    VStack(spacing: 14) {
                        ProgramCard(
                            title: "Candito - Fuerza 6 Semanas",
                            subtitle: "Ideal para testear 1RM y competir",
                            tags: ["PRO", "6 Semanas", "Intermedio", "Fuerza"],
                            frequency: "4x/sem",
                            level: "Intermedio",
                            isPro: true,
                            imageName: "program1"
                        )

                        ProgramCard(
                            title: "Juggernaut - Deadlift",
                            subtitle: "Enfocado a levantar más en 16 semanas",
                            tags: ["PRO", "16 Semanas", "Fuerza"],
                            frequency: "4x/sem",
                            level: "Intermedio",
                            isPro: true,
                            imageName: "program2"
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .padding(.top, 10)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - UI

    private var topBar: some View {
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

            Text("Explorar")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.top, 4)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Programas y rutinas")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))

            Text("Elegí un programa y empezá hoy.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private var segmentedTabs: some View {
        HStack(spacing: 10) {
            ForEach(ExploreTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTab == tab ? .black : .white.opacity(0.85))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedTab == tab ? Color.appGreen.opacity(0.95) : Color.black.opacity(0.25))
                        )
                        .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.45))

            TextField("Buscar programas...", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

// MARK: - Program Card

private struct ProgramCard: View {

    let title: String
    let subtitle: String
    let tags: [String]
    let frequency: String
    let level: String
    let isPro: Bool

    let imageName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            ZStack(alignment: .topLeading) {
                headerImage

                if isPro {
                    Badge(text: "PRO")
                        .padding(10)
                }
            }

            Text(title)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))

            Text(subtitle)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))

            FlowTags(tags: tags)

            HStack(spacing: 10) {
                InfoMiniCard(title: "Frecuencia", value: frequency)
                InfoMiniCard(title: "Nivel", value: level)

                Spacer()

                Button {
                    print("ver programa")
                } label: {
                    Text("Ver")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .frame(width: 64, height: 36)
                        .background(Capsule().fill(Color.appGreen.opacity(0.95)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.appGreen.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var headerImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))

            if let name = imageName {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 78)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white.opacity(0.25))
            }
        }
        .frame(height: 78)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

private struct Badge: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundColor(Color.appGreen.opacity(0.95))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.black.opacity(0.45)))
            .overlay(Capsule().stroke(Color.appGreen.opacity(0.35), lineWidth: 1))
    }
}

private struct FlowTags: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(tag == "PRO" ? Color.appGreen.opacity(0.95) : .white.opacity(0.75))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.06)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
                }
            }
        }
    }
}

private struct InfoMiniCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.45))

            Text(value)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.90))
        }
        .padding(10)
        .frame(width: 120, height: 54, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.10), lineWidth: 1))
        )
    }
}

// MARK: - Preview

#Preview {
    ExploreView()
}
