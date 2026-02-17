//
//  CoachView.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 10/02/2026.
//

import SwiftUI

struct CoachAIView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var selectedFrequency: FrequencyOption? = .two
    private let totalSteps: Int = 5
    private let currentStep: Int = 1

    enum FrequencyOption: String, CaseIterable, Identifiable {
        case two = "2 times per week"
        case three = "3 times per week"
        case four = "4 times per week"
        case five = "5 times per week"
        case six = "6 times per week"

        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            VStack(spacing: 18) {
                topBar(title: "Coach IA")

                VStack(spacing: 10) {
                    Text("Step \(currentStep)/\(totalSteps)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))

                    Text("Premium only - Free to preview")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.60))

                    Text("How often would you like to train?")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.top, 10)
                }
                .padding(.top, 4)

                VStack(spacing: 12) {
                    ForEach(FrequencyOption.allCases) { option in
                        SelectPillButton(
                            title: option.rawValue,
                            isSelected: selectedFrequency == option
                        ) {
                            selectedFrequency = option
                        }
                    }
                }
                .padding(.top, 6)

                VStack(spacing: 12) {
                    Button {
                        print("next step")
                    } label: {
                        Text("Next")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .fill(Color.appGreen.opacity(0.95))
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.appGreen.opacity(0.95))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(Color.white.opacity(0.04))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - TopBar

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

// MARK: - Components

private struct SelectPillButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? Color.appGreen.opacity(0.95) : .white.opacity(0.70))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(isSelected ? Color.appGreen.opacity(0.25) : Color.white.opacity(0.10), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        CoachAIView()
    }
}
