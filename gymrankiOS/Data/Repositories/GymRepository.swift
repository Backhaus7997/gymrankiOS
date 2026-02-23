//
//  GymRepository.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 17/02/2026.
//

import Foundation
import FirebaseFirestore

struct Gym: Identifiable, Hashable {
    let id: String
    let name: String
    let city: String
    let address: String?
    let isActive: Bool

    init(id: String, name: String, city: String, address: String?, isActive: Bool) {
        self.id = id
        self.name = name
        self.city = city
        self.address = address
        self.isActive = isActive
    }

    init?(doc: QueryDocumentSnapshot) {
        let d = doc.data()
        guard
            let name = d["name"] as? String,
            let city = d["city"] as? String
        else { return nil }

        let address = d["address"] as? String
        let isActive = d["isActive"] as? Bool ?? true

        self.init(id: doc.documentID, name: name, city: city, address: address, isActive: isActive)
    }
}

final class GymRepository {
    static let shared = GymRepository()
    private init() {}

    private let db = Firestore.firestore()

    func fetchActiveGyms() async throws -> [Gym] {
        let snap = try await db.collection("gyms")
            .whereField("isActive", isEqualTo: true)
            .getDocuments()

        return snap.documents.compactMap { Gym(doc: $0) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
