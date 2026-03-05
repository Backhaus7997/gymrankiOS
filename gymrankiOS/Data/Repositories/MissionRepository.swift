//
//  MissionRepository.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 02/03/2026.
//

import Foundation
import FirebaseFirestore

final class MissionRepository {

    private let db = Firestore.firestore()

    // MARK: - Templates

    func fetchActiveTemplates() async throws -> [MissionTemplate] {
        let base = db.collection("mission_templates")
            .whereField("isActive", isEqualTo: true)

        do {
            let snap = try await base.order(by: "updatedAt", descending: true).getDocuments()
            return snap.documents.map { MissionTemplate(document: $0) }
        } catch {
            let snap = try await base.getDocuments()
            var items = snap.documents.map { MissionTemplate(document: $0) }
            items.sort { ($0.updatedAt?.seconds ?? 0) > ($1.updatedAt?.seconds ?? 0) }
            return items
        }
    }

    func fetchTemplates(byIds ids: [String]) async throws -> [MissionTemplate] {
        guard !ids.isEmpty else { return [] }

        let chunks = ids.chunked(into: 10)
        var all: [MissionTemplate] = []

        for chunk in chunks {
            let snap = try await db.collection("mission_templates")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            all.append(contentsOf: snap.documents.map { MissionTemplate(document: $0) })
        }

        let map: [String: MissionTemplate] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
        return ids.compactMap { map[$0] }
    }

    // MARK: - User missions

    func fetchUserMissions(uid: String, onlyActive: Bool) async throws -> [UserMission] {
        var q: Query = db.collection("user_missions")
            .whereField("uid", isEqualTo: uid)

        if onlyActive {
            q = q.whereField("status", isEqualTo: UserMissionStatus.active)
        }

        let snap = try await q.getDocuments()

        var rows = snap.documents.map { UserMission(document: $0) }
        rows.sort { $0.createdAt > $1.createdAt }
        return rows
    }
    
    func joinMission(uid: String, templateId: String) async throws {
        let docId = "\(uid)_\(templateId)"
        let ref = db.collection("user_missions").document(docId)

        let nowMs = Int64(Date().timeIntervalSince1970 * 1000.0)

        let data: [String: Any] = [
            "uid": uid,
            "templateId": templateId,
            "status": UserMissionStatus.active,
            "createdAt": nowMs,
            "startedAt": nowMs,
            "updatedAt": nowMs
        ]

        let existing = try await ref.getDocument()
        if existing.exists,
           let status = existing.data()?["status"] as? String,
           status == UserMissionStatus.active {
            return
        }

        try await ref.setData(data, merge: true)
    }

    func setUserMissionStatus(uid: String, templateId: String, status: String) async throws {
        let docId = "\(uid)_\(templateId)"
        let ref = db.collection("user_missions").document(docId)

        let nowMs = Int64(Date().timeIntervalSince1970 * 1000.0)

        try await ref.setData([
            "uid": uid,
            "templateId": templateId,
            "status": status,
            "updatedAt": nowMs
        ], merge: true)
    }

    // MARK: - Create custom template

    func createCustomTemplate(uid: String, draft: MissionDraft) async throws -> String {
        let ref = db.collection("mission_templates").document()
        try await ref.setData([
            "title": draft.title,
            "subtitle": draft.subtitle,
            "durationDays": draft.durationDays,
            "level": draft.level,
            "points": draft.points,
            "tags": draft.tags,
            "isActive": true,
            "authorUid": uid,
            "goalWorkouts": draft.goalWorkouts as Any,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: false)
        return ref.documentID
    }
}

// MARK: - Helpers

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        var result: [[Element]] = []
        var index = 0
        while index < count {
            let end = Swift.min(index + size, count)
            result.append(Array(self[index..<end]))
            index += size
        }
        return result
    }
}
