//
//  MuscleSetStat.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 24/02/2026.
//

import Foundation

struct MuscleSetStat: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var sets: Int
}
