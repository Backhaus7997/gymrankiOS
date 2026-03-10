//
//  BetRepository.swift
//  gymrankiOS
//

import Foundation
import FirebaseFirestore

final class BetRepository {

    private let db = Firestore.firestore()

    private let templatesCol = "bet_templates"
    private let userBetsCol = "user_bets"

    private func nowMs() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000.0)
    }

    // MARK: - Public API (lo que usa la UI)

    func startBet(uid: String, difficulty: String, focus: String, durationType: String) async throws {
        let tpl = try await fetchRandomTemplate(
            difficulty: difficulty,
            focus: focus,
            durationType: durationType
        )
        try await createUserBet(uid: uid, template: tpl)
    }

    // MARK: Templates

    func fetchRandomTemplate(difficulty: String, focus: String, durationType: String) async throws -> BetTemplate {
        let snap = try await db.collection(templatesCol)
            .whereField("isActive", isEqualTo: true)
            .whereField("difficulty", isEqualTo: difficulty)
            .whereField("focus", isEqualTo: focus)
            .whereField("durationType", isEqualTo: durationType)
            .getDocuments()

        let templates = snap.documents.compactMap { BetTemplate(doc: $0) }

        guard let chosen = templates.randomElement() else {
            throw NSError(domain: "BetRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "No hay templates que coincidan con dificultad/foco/duración."
            ])
        }
        return chosen
    }

    func fetchTemplates(byIds ids: [String]) async throws -> [BetTemplate] {
        guard !ids.isEmpty else { return [] }

        var all: [BetTemplate] = []
        let chunks = stride(from: 0, to: ids.count, by: 10).map { Array(ids[$0..<min($0+10, ids.count)]) }

        for chunk in chunks {
            let snap = try await db.collection(templatesCol)
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            all.append(contentsOf: snap.documents.compactMap { BetTemplate(doc: $0) })
        }
        return all
    }

    // MARK: User Bets

    func fetchUserBets(uid: String, onlyActive: Bool) async throws -> [UserBet] {
        var q: Query = db.collection(userBetsCol).whereField("uid", isEqualTo: uid)
        if onlyActive {
            q = q.whereField("status", isEqualTo: UserBetStatus.active)
        }

        let snap = try await q.getDocuments()

        let bets: [UserBet] = snap.documents.compactMap { doc in
            let d = doc.data()

            let uid = d["uid"] as? String ?? ""
            let templateId = d["templateId"] as? String ?? ""
            let status = d["status"] as? String ?? ""

            let createdAt = FSNum.int64(d["createdAt"])
            let startedAt = FSNum.int64(d["startedAt"])
            let expiresAt = FSNum.int64(d["expiresAt"])

            // progress puede venir como [Int] o [NSNumber]
            let rawProgress = d["progress"] as? [Any] ?? []
            let progress = rawProgress.map { FSNum.int($0) }

            guard !uid.isEmpty, !templateId.isEmpty, !status.isEmpty else { return nil }

            return UserBet(
                id: doc.documentID,
                uid: uid,
                templateId: templateId,
                status: status,
                createdAt: createdAt,
                startedAt: startedAt,
                expiresAt: expiresAt,
                progress: progress
            )
        }

        return bets.sorted { $0.createdAt > $1.createdAt }
    }

    func createUserBet(uid: String, template: BetTemplate) async throws {
        let now = nowMs()
        let expires = now + Int64(template.timeLimitSeconds) * 1000

        let docId = "\(uid)_\(template.id)"
        let ref = db.collection(userBetsCol).document(docId)

        let progress = Array(repeating: 0, count: template.tasks.count)

        try await ref.setData([
            "uid": uid,
            "templateId": template.id,
            "status": UserBetStatus.active,
            "createdAt": now,
            "startedAt": now,
            "expiresAt": expires,
            "progress": progress,
            "updatedAt": now
        ], merge: true)
    }

    func updateProgress(uid: String, templateId: String, progress: [Int]) async throws {
        let now = nowMs()
        let ref = db.collection(userBetsCol).document("\(uid)_\(templateId)")
        try await ref.updateData([
            "progress": progress,
            "updatedAt": now
        ])
    }

    func setStatus(uid: String, templateId: String, status: String) async throws {
        let now = nowMs()
        let ref = db.collection(userBetsCol).document("\(uid)_\(templateId)")
        try await ref.updateData([
            "status": status,
            "updatedAt": now
        ])
    }
}


