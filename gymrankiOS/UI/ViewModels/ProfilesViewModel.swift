//
//  ProfilesViewModel.swift
//  gymrankiOS
//

import Foundation

@MainActor
final class ProfilesViewModel: ObservableObject {

    // MARK: - UI state

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchText: String = ""

    // MARK: - Data

    @Published private(set) var friends: [UserProfile] = []
    @Published private(set) var incomingRequests: [UserProfile] = []
    @Published private(set) var outgoingRequests: [UserProfile] = []
    @Published private(set) var suggested: [UserProfile] = []

    // MARK: - Internal

    private let userRepo: UserRepository
    private let friendsRepo: FriendsRepository

    private var myUid: String = ""
    private var relationsByUid: [String: FriendRelation] = [:]

    init(
        userRepo: UserRepository = .shared,
        friendsRepo: FriendsRepository = .shared
    ) {
        self.userRepo = userRepo
        self.friendsRepo = friendsRepo
    }

    // MARK: - Load

    func load(myUid: String) async {
        let uid = myUid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty else { return }
        self.myUid = uid

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            // ✅ ahora compila siempre: gracias al alias listRelations()
            let relations = try await friendsRepo.listRelations(myUid: uid)
            relationsByUid = Dictionary(uniqueKeysWithValues: relations.map { ($0.otherUid, $0) })

            let acceptedIds = relations.filter { $0.status == FriendStatus.accepted }.map { $0.otherUid }

            let requestedIncomingIds = relations.filter {
                $0.status == FriendStatus.requested && ($0.requestedBy ?? "") != uid
            }.map { $0.otherUid }

            let requestedOutgoingIds = relations.filter {
                $0.status == FriendStatus.requested && ($0.requestedBy ?? "") == uid
            }.map { $0.otherUid }

            let blockedIds = relations.filter { $0.status == FriendStatus.blocked }.map { $0.otherUid }

            async let acceptedProfiles = userRepo.fetchUserProfiles(uids: acceptedIds)
            async let incomingProfiles = userRepo.fetchUserProfiles(uids: requestedIncomingIds)
            async let outgoingProfiles = userRepo.fetchUserProfiles(uids: requestedOutgoingIds)

            let (a, inc, out) = try await (acceptedProfiles, incomingProfiles, outgoingProfiles)

            // Sugerencias públicas (por si después querés re-usarlas en otro lado)
            let rawSuggested = try await userRepo.fetchSuggestedPublicProfiles(limit: 40)
            let excluded = Set([uid] + acceptedIds + requestedIncomingIds + requestedOutgoingIds + blockedIds)
            let sug = rawSuggested.filter { !excluded.contains($0.uid) }

            friends = a.sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
            incomingRequests = inc.sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
            outgoingRequests = out.sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
            suggested = sug.sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Filtered lists (search)

    var friendsFiltered: [UserProfile] { filterBySearch(friends) }
    var incomingFiltered: [UserProfile] { filterBySearch(incomingRequests) }
    var outgoingFiltered: [UserProfile] { filterBySearch(outgoingRequests) }
    var suggestedFiltered: [UserProfile] { filterBySearch(suggested) }

    private func filterBySearch(_ items: [UserProfile]) -> [UserProfile] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return items }
        return items.filter {
            $0.displayName.lowercased().contains(q) ||
            ($0.fullName?.lowercased().contains(q) ?? false)
        }
    }

    // MARK: - Relationship state for UI

    enum RelationshipUIState: Equatable {
        case none
        case requestedIncoming
        case requestedOutgoing
        case friends
        case blocked
    }

    func relationshipState(with uid: String) -> RelationshipUIState {
        guard let rel = relationsByUid[uid] else { return .none }
        switch rel.status {
        case .accepted:
            return .friends
        case .blocked:
            return .blocked
        case .requested:
            return (rel.requestedBy ?? "") == myUid ? .requestedOutgoing : .requestedIncoming
        }
    }

    // MARK: - Actions

    func sendRequest(to otherUid: String) async {
        guard !myUid.isEmpty else { return }
        do {
            // ✅ alias: sendFriendRequest(...) existe en FriendsRepository extension
            try await friendsRepo.sendFriendRequest(myUid: myUid, to: otherUid)
            await load(myUid: myUid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func accept(uid otherUid: String) async {
        guard !myUid.isEmpty else { return }
        do {
            try await friendsRepo.acceptFriendRequest(myUid: myUid, otherUid: otherUid)
            await load(myUid: myUid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func remove(uid otherUid: String) async {
        guard !myUid.isEmpty else { return }
        do {
            try await friendsRepo.removeRelation(myUid: myUid, otherUid: otherUid)
            await load(myUid: myUid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func block(uid otherUid: String) async {
        guard !myUid.isEmpty else { return }
        do {
            try await friendsRepo.blockUser(myUid: myUid, otherUid: otherUid)
            await load(myUid: myUid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
