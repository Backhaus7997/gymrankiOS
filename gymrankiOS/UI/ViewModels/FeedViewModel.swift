//
//  FeedViewModel.swift
//  gymrankiOS
//

import Foundation

@MainActor
final class FeedViewModel: ObservableObject {

    // MARK: - Search
    @Published var searchText: String = ""

    // MARK: - Public tab
    @Published var publicItems: [FeedProfileItem] = []
    @Published var isLoadingPublic: Bool = false
    @Published var errorMessagePublic: String? = nil

    // MARK: - Friends tab (same cards as public, but only friends)
    @Published var friendsItems: [FeedProfileItem] = []
    @Published var isLoadingFriends: Bool = false
    @Published var errorMessageFriends: String? = nil

    @Published private(set) var relationByUid: [String: FriendStatus] = [:]

    private let feedRepo: FeedRepository
    private let friendRepo: FriendsRepository
    private let userRepo: UserRepository

    init(
        feedRepo: FeedRepository = .shared,
        friendRepo: FriendsRepository = .shared,
        userRepo: UserRepository = .shared
    ) {
        self.feedRepo = feedRepo
        self.friendRepo = friendRepo
        self.userRepo = userRepo
    }

    // MARK: - Load Public

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
            // 1) relaciones mías (para el botón)
            let rels = try await friendRepo.fetchRelations(myUid: cleanUid)
            relationByUid = Dictionary(uniqueKeysWithValues: rels.map { ($0.otherUid, $0.status) })

            // 2) público: 1 item por usuario (tu repo ya trae todos y decide si muestra rutinas según feedVisibility)
            publicItems = try await feedRepo.fetchPublicFeedProfiles(
                excludingUid: cleanUid,
                limitUsers: 50,
                limitRoutinesPerUser: 3
            )
        } catch {
            errorMessagePublic = error.localizedDescription
            publicItems = []
        }
    }

    // MARK: - Load Friends

    func loadFriends(myUid: String) async {
        let cleanUid = myUid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUid.isEmpty else {
            friendsItems = []
            return
        }

        errorMessageFriends = nil
        isLoadingFriends = true
        defer { isLoadingFriends = false }

        do {
            // UIDs de amigos aceptados
            let friendUids = try await feedRepo.fetchFriendsUids(myUid: cleanUid)
            if friendUids.isEmpty {
                friendsItems = []
                return
            }

            // Traer perfiles
            let profiles = try await userRepo.fetchUserProfiles(uids: friendUids)

            // Armar items con sus últimas rutinas (solo si el perfil es PUBLIC, igual que en público)
            var out: [FeedProfileItem] = []
            out.reserveCapacity(profiles.count)

            for p in profiles {
                let isPublicProfile = (p.feedVisibility == .public)

                let routines: [FeedRoutinePreview] = isPublicProfile
                    ? (try await feedRepo.fetchLatestRoutinePreviews(for: p.uid, limit: 3))
                    : []

                out.append(.init(profile: p, latestRoutines: routines))
            }

            // Orden por actividad
            friendsItems = out.sorted {
                let d0 = $0.latestRoutines.first?.createdAt ?? .distantPast
                let d1 = $1.latestRoutines.first?.createdAt ?? .distantPast
                return d0 > d1
            }

        } catch {
            errorMessageFriends = error.localizedDescription
            friendsItems = []
        }
    }

    // MARK: - Relationship / Actions

    func relationshipStatus(with uid: String) -> FriendStatus? {
        relationByUid[uid]
    }

    func sendRequest(myUid: String, to otherUid: String) async {
        let me = myUid.trimmingCharacters(in: .whitespacesAndNewlines)
        let other = otherUid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !me.isEmpty, !other.isEmpty, me != other else { return }

        do {
            try await friendRepo.sendRequest(myUid: me, to: other)
            relationByUid[other] = .requested
        } catch {
            errorMessagePublic = error.localizedDescription
        }
    }

    // MARK: - Filtering

    var publicItemsFiltered: [FeedProfileItem] {
        filter(items: publicItems)
    }

    var friendsItemsFiltered: [FeedProfileItem] {
        filter(items: friendsItems)
    }

    private func filter(items: [FeedProfileItem]) -> [FeedProfileItem] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return items }

        return items.filter { item in
            let dn = item.profile.displayName.lowercased()
            let fn = (item.profile.fullName ?? "").lowercased()
            return dn.contains(q) || fn.contains(q)
        }
    }
}
