//
//  Ranking.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 04/03/2026.
//

import Foundation

struct RankingTop {
    let name: String
    let points: Int
}

struct RankingRow: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let role: String
    let points: Int
}

struct RankingMe {
    let rank: Int
    let points: Int
}
