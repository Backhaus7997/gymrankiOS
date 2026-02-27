//
//  UserProfile+FeedVisibility.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 27/02/2026.
//

import Foundation

extension UserProfile {

    var feedVisibilityRaw: String {

        if let any = Mirror(reflecting: self).children.first(where: { $0.label == "feedVisibility" })?.value {
            if let s = any as? String { return s }
        }

        if let any = Mirror(reflecting: self).children.first(where: { $0.label == "feedVisibility" })?.value {
            if let v = any as? any RawRepresentable, let s = v.rawValue as? String { return s }
        }

        if let any = Mirror(reflecting: self).children.first(where: { $0.label == "authorFeedVisibility" })?.value {
            if let s = any as? String { return s }
        }

        return "PUBLIC"
    }
}
