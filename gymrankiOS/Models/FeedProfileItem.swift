//
//  FeedProfileItem.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 27/02/2026.
//

import Foundation

struct FeedProfileItem: Identifiable, Equatable {
    var id: String { profile.uid }
    let profile: UserProfile
    let latestRoutines: [FeedRoutinePreview]
}

struct FeedRoutinePreview: Identifiable, Equatable {
    let id: String
    let title: String
    let createdAt: Date?
    let exercisesSummary: [FeedWorkoutExercise]
    let timeAgo: String
}
