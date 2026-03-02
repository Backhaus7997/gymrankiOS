import Foundation
import FirebaseFirestore

final class ChallengeRepository {

    private let db = Firestore.firestore()

    func fetchActiveTemplates() async throws -> [ChallengeTemplate] {
        let base = db.collection("challenge_templates")
            .whereField("isActive", isEqualTo: true)

        do {
            let snap = try await base.order(by: "updatedAt", descending: true).getDocuments()
            return snap.documents.map { ChallengeTemplate(document: $0) }
        } catch {
            let snap = try await base.getDocuments()
            var items = snap.documents.map { ChallengeTemplate(document: $0) }
            items.sort { ($0.updatedAt?.seconds ?? 0) > ($1.updatedAt?.seconds ?? 0) }
            return items
        }
    }

    func fetchTemplates(byIds ids: [String]) async throws -> [ChallengeTemplate] {
        guard !ids.isEmpty else { return [] }

        let chunks = ids.chunked(into: 10)
        var all: [ChallengeTemplate] = []

        for chunk in chunks {
            let snap = try await db.collection("challenge_templates")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            all.append(contentsOf: snap.documents.map { ChallengeTemplate(document: $0) })
        }

        let map = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
        return ids.compactMap { map[$0] }
    }

    func fetchUserChallenges(uid: String, onlyActive: Bool) async throws -> [UserChallenge] {
        var q: Query = db.collection("user_challenges")
            .whereField("uid", isEqualTo: uid)

        if onlyActive {
            q = q.whereField("status", isEqualTo: UserChallengeStatus.active)
        }

        do {
            let snap = try await q.order(by: "createdAt", descending: true).getDocuments()
            return snap.documents.map { UserChallenge(document: $0) }
        } catch {
            let snap = try await q.getDocuments()
            var rows = snap.documents.map { UserChallenge(document: $0) }
            rows.sort { $0.createdAt > $1.createdAt }
            return rows
        }
    }
    
    func joinChallenge(uid: String, templateId: String) async throws {
        let docId = "\(uid)_\(templateId)"
        let ref = db.collection("user_challenges").document(docId)

        let nowMs = Int64(Date().timeIntervalSince1970 * 1000.0)

        let data: [String: Any] = [
            "uid": uid,
            "templateId": templateId,
            "status": UserChallengeStatus.active,
            "createdAt": nowMs,
            "startedAt": nowMs,
            "updatedAt": nowMs
        ]

        let existing = try await ref.getDocument()
        if existing.exists,
           let status = existing.data()?["status"] as? String,
           status == UserChallengeStatus.active {
            return
        }

        try await ref.setData(data, merge: true)
    }
}

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

extension ChallengeRepository {

    func setUserChallengeStatus(uid: String, templateId: String, status: String) async throws {
        let docId = "\(uid)_\(templateId)"
        let ref = db.collection("user_challenges").document(docId)

        let nowMs = Int64(Date().timeIntervalSince1970 * 1000.0)

        try await ref.setData([
            "uid": uid,
            "templateId": templateId,
            "status": status,
            "updatedAt": nowMs
        ], merge: true)
    }
}
