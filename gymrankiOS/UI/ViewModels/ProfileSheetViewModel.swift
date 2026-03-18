//
//  ProfileSheetViewModel.swift
//  gymrankiOS
//

import Foundation
import SwiftUI
import PhotosUI
import UIKit

@MainActor
final class ProfileSheetViewModel: ObservableObject {

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var didSave: Bool = false

    // Perfil actual
    @Published var profile: UserProfile? = nil

    // Campos editables
    @Published var fullName: String = ""
    @Published var birthdate: Date = Date()
    @Published var weightKg: Double = 70
    @Published var heightCm: Double = 170
    @Published var gender: String = "Masculino"
    @Published var experience: String = "Principiante"

    // Solicitudes entrantes
    @Published private(set) var incomingRequests: [UserProfile] = []

    // Avatar
    @Published var pickedAvatarItem: PhotosPickerItem? = nil
    @Published var avatarPreviewImage: UIImage? = nil
    @Published var isUploadingAvatar: Bool = false

    // Cover
    @Published var pickedCoverItem: PhotosPickerItem? = nil
    @Published var coverPreviewImage: UIImage? = nil
    @Published var isUploadingCover: Bool = false

    // Privacidad
    @Published var selectedFeedVisibility: FeedVisibility = .public
    @Published var isUpdatingPrivacy: Bool = false

    private let userRepo: UserRepository
    private let friendsRepo: FriendsRepository
    private let imageService: ProfileImageService

    private var myUid: String = ""

    init(
        userRepo: UserRepository = .shared,
        friendsRepo: FriendsRepository = .shared,
        imageService: ProfileImageService = .shared
    ) {
        self.userRepo = userRepo
        self.friendsRepo = friendsRepo
        self.imageService = imageService
    }

    func load(myUid: String) async {
        let uid = myUid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty else { return }
        self.myUid = uid

        errorMessage = nil
        didSave = false
        isLoading = true
        defer { isLoading = false }

        do {
            if let p = try await userRepo.fetchUserProfile(uid: uid) {
                profile = p
                fullName = p.fullName ?? ""
                experience = p.experience ?? (p.subtitle ?? "Principiante")
                gender = p.gender ?? "Masculino"
                selectedFeedVisibility = p.feedVisibility
            }

            let relations = try await friendsRepo.fetchRelations(myUid: uid)

            let incomingIds = relations
                .filter { rel in
                    rel.status == FriendStatus.requested && (rel.requestedBy ?? "") != uid
                }
                .map { $0.otherUid }

            incomingRequests = try await userRepo.fetchUserProfiles(uids: incomingIds)

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveProfile() async {
        guard !myUid.isEmpty else { return }

        errorMessage = nil
        didSave = false
        isLoading = true
        defer { isLoading = false }

        do {
            try await userRepo.updateProfile(
                uid: myUid,
                fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                birthdate: birthdate,
                weightKg: weightKg,
                heightCm: heightCm,
                gender: gender,
                experience: experience
            )
            didSave = true
            await load(myUid: myUid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func acceptRequest(from otherUid: String) async {
        guard !myUid.isEmpty else { return }
        do {
            try await friendsRepo.acceptRequest(myUid: myUid, from: otherUid)
            await load(myUid: myUid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func rejectRequest(from otherUid: String) async {
        guard !myUid.isEmpty else { return }
        do {
            try await friendsRepo.removeRelation(myUid: myUid, otherUid: otherUid)
            await load(myUid: myUid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Avatar upload

    func onPickedAvatarChanged() async {
        guard let item = pickedAvatarItem else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                avatarPreviewImage = image
                await uploadAvatar(image: image)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func uploadAvatar(image: UIImage) async {
        guard !myUid.isEmpty else { return }

        isUploadingAvatar = true
        defer { isUploadingAvatar = false }

        do {
            _ = try await imageService.uploadProfileImage(
                image: image,
                kind: .avatar,
                uid: myUid
            )
            await load(myUid: myUid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Cover upload

    func onPickedCoverChanged() async {
        guard let item = pickedCoverItem else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                coverPreviewImage = image
                await uploadCover(image: image)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func uploadCover(image: UIImage) async {
        guard !myUid.isEmpty else { return }

        isUploadingCover = true
        defer { isUploadingCover = false }

        do {
            _ = try await imageService.uploadProfileImage(
                image: image,
                kind: .cover,
                uid: myUid
            )
            await load(myUid: myUid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Privacy

    func updatePrivacy(_ value: FeedVisibility) async {
        guard !myUid.isEmpty else { return }

        isUpdatingPrivacy = true
        defer { isUpdatingPrivacy = false }

        do {
            try await userRepo.updateFeedVisibility(uid: myUid, value: value)
            selectedFeedVisibility = value
            await load(myUid: myUid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
