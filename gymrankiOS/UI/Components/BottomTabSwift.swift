//
//  BottomTabSwift.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 17/02/2026.
//

import SwiftUI

struct BottomTabBar: View {
    @Binding var selected: DashboardView.Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DashboardView.Tab.allCases) { tab in
                Button { selected = tab } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: tab == selected ? 18 : 17, weight: .semibold))
                            .foregroundColor(tab == selected ? Color.appGreen : .white.opacity(0.45))

                        Text(tab.title)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(tab == selected ? .white.opacity(0.90) : .white.opacity(0.45))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.70))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}
