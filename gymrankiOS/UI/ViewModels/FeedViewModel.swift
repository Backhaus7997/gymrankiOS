//
//  FeedViewModel.swift
//  gymrankiOS
//

import Foundation

@MainActor
final class FeedViewModel: ObservableObject {

    @Published var publicItems: [FeedProfileItem] = []
    @Published var isLoadingPublic: Bool = false
    @Published var errorMessagePublic: String? = nil

    // 🔥 Estado local para el botón (AGREGAR / PENDIENTE / AMIGOS / BLOQUEADO)
    @Published private(set) var relationByUid: [String: FriendStatus] = [:]

    private let feedRepo: FeedRepository
    private let friendRepo: FriendsRepository

    init(
        feedRepo: FeedRepository = .shared,
        friendRepo: FriendsRepository = .shared
    ) {
        self.feedRepo = feedRepo
        self.friendRepo = friendRepo
    }

    func loadPublic(myUid: String) async {
        let cleanUid = myUid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUid.isEmpty else {
            publicItems = []
            relationByUid = [:]
            return
        }

        errorMessagePublic = nil
        isLoadingPublic = true
        defer { isLoadingPublic = false }

        do {
            // 1) relaciones mías
            let rels = try await friendRepo.fetchRelations(myUid: cleanUid)
            relationByUid = Dictionary(uniqueKeysWithValues: rels.map { ($0.otherUid, $0.status) })

            // 2) perfiles públicos + sus últimas 3 rutinas
            publicItems = try await feedRepo.fetchPublicFeedProfiles(
                excludingUid: cleanUid,
                limitUsers: 30,
                limitRoutinesPerUser: 3
            )

        } catch {
            errorMessagePublic = error.localizedDescription
            publicItems = []
        }
    }

    func relationshipStatus(with uid: String) -> FriendStatus? {
        relationByUid[uid]
    }

    func sendRequest(myUid: String, to otherUid: String) async {
        let me = myUid.trimmingCharacters(in: .whitespacesAndNewlines)
        let other = otherUid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !me.isEmpty, !other.isEmpty, me != other else { return }

        do {
            try await friendRepo.sendRequest(myUid: me, to: other)
            relationByUid[other] = .requested // ✅ actualizar UI instantáneo
        } catch {
            errorMessagePublic = error.localizedDescription
        }
    }
}
