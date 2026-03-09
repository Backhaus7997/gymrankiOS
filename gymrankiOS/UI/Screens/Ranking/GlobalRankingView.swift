//
//  GlobalRankingView.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 05/03/2026.
//

import SwiftUI

struct GlobalRankingView: View {

    @EnvironmentObject private var session: SessionManager

    let bottomInset: CGFloat
    @StateObject private var vm = GlobalRankingVM()

    private var uid: String { session.userId }

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            VStack(spacing: 12) {
                topBar

                Divider()
                    .overlay(Color.white.opacity(0.08))

                if let err = vm.errorMessage, !err.isEmpty {
                    Text(err)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.red.opacity(0.9))
                        .padding(.horizontal, 16)
                }

                podium
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(vm.rest) { row in
                            RankingRowView(row: row)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 120)
                }
            }

            if vm.isLoading {
                ProgressView().tint(.white)
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomPinnedCard
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, max(8, bottomInset - 8))
                .background(Color.black.opacity(0.75))
        }
        .task {
            await vm.load(sessionUserId: uid)
        }
        .navigationBarBackButtonHidden(false)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Top Global")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))

                Text("Todos los atletas")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private var podium: some View {
        let t = vm.top3
        return HStack(alignment: .top, spacing: 18) {

            PodiumItemView(
                rank: 2,
                name: t.count > 1 ? t[1].name : "—",
                points: t.count > 1 ? t[1].points : 0
            )
            .frame(maxWidth: CGFloat.infinity)

            PodiumItemView(
                rank: 1,
                name: t.count > 0 ? t[0].name : "—",
                points: t.count > 0 ? t[0].points : 0
            )
            .frame(maxWidth: CGFloat.infinity)

            PodiumItemView(
                rank: 3,
                name: t.count > 2 ? t[2].name : "—",
                points: t.count > 2 ? t[2].points : 0
            )
            .frame(maxWidth: CGFloat.infinity)
        }
    }

    private var bottomPinnedCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Tu posición global")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))

                Text(vm.me.rank > 0 ? "#\(vm.me.rank) · \(formatPoints(vm.me.points)) gp" : "—")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.75))
        )
    }

    private func formatPoints(_ points: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        return formatter.string(from: NSNumber(value: points)) ?? "\(points)"
    }
}
