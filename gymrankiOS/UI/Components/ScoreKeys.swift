//
//  ScoreKeys.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 04/03/2026.
//

import Foundation

enum ScoreKeys {

    /// Ej: "2026-03"
    static func monthKey(for date: Date) -> String {
        let cal = Calendar(identifier: .iso8601)
        let c = cal.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
    }

    /// Ej: "2026-W10" (ISO week)
    static func weekKey(for date: Date) -> String {
        let cal = Calendar(identifier: .iso8601)
        let c = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let y = c.yearForWeekOfYear ?? 0
        let w = c.weekOfYear ?? 0
        return String(format: "%04d-W%02d", y, w)
    }
}
