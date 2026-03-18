//
//  ProfileImageService.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 12/03/2026.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseStorage

final class ProfileImageService {
    static let shared = ProfileImageService()
    private init() {}

    private let storage = Storage.storage()
    private let userRepo = UserRepository.shared

    enum ImageKind {
        case avatar
        case cover

        var fileName: String {
            switch self {
            case .avatar: return "avatar.jpg"
            case .cover: return "cover.jpg"
            }
        }

        var folderName: String {
            "profile_images"
        }
    }

    func uploadProfileImage(
        image: UIImage,
        kind: ImageKind,
        uid: String
    ) async throws -> String {
        let cleanUid = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUid.isEmpty else {
            throw NSError(
                domain: "ProfileImageService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "UID inválido"]
            )
        }

        let data: Data
        switch kind {
        case .avatar:
            data = try ImageCompressor.jpegData(
                from: image,
                maxDimension: 512,
                compressionQuality: 0.82
            )
        case .cover:
            data = try ImageCompressor.jpegData(
                from: image,
                maxDimension: 1280,
                compressionQuality: 0.82
            )
        }

        let path = "\(kind.folderName)/\(cleanUid)/\(kind.fileName)"
        let ref = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.cacheControl = "public,max-age=3600"

        _ = try await ref.putDataAsync(data, metadata: metadata)
        let downloadURL = try await ref.downloadURL()
        let urlString = downloadURL.absoluteString

        switch kind {
        case .avatar:
            try await userRepo.updateAvatarUrl(uid: cleanUid, avatarUrl: urlString)
        case .cover:
            try await userRepo.updateCoverUrl(uid: cleanUid, coverUrl: urlString)
        }

        return urlString
    }

    func currentUid() -> String? {
        Auth.auth().currentUser?.uid.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
