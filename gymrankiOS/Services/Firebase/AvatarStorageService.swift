import Foundation
import UIKit
import FirebaseStorage

final class AvatarStorageService {

    static let shared = AvatarStorageService()
    private init() {}

    private let storage = Storage.storage()

    func uploadAvatar(uid: String, imageData: Data) async throws -> String {
        let clean = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            throw NSError(domain: "AvatarStorageService", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "uid vacío"])
        }

        let finalData: Data
        if let ui = UIImage(data: imageData),
           let jpg = ui.jpegData(compressionQuality: 0.80) {
            finalData = jpg
        } else {
            finalData = imageData
        }

        let ref = storage.reference().child("avatars/\(clean).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // Upload
        _ = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<StorageMetadata, Error>) in
            ref.putData(finalData, metadata: metadata) { meta, error in
                if let error { cont.resume(throwing: error) }
                else { cont.resume(returning: meta ?? metadata) }
            }
        }

        // Verificación: metadata existe (si no, el archivo realmente no quedó)
        _ = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<StorageMetadata, Error>) in
            ref.getMetadata { meta, error in
                if let error { cont.resume(throwing: error) }
                else { cont.resume(returning: meta ?? metadata) }
            }
        }

        // Download URL (requiere permiso de READ en rules)
        let url: URL = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
            ref.downloadURL { url, error in
                if let error { cont.resume(throwing: error) }
                else if let url { cont.resume(returning: url) }
                else {
                    cont.resume(throwing: NSError(domain: "AvatarStorageService", code: 2,
                                                  userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener downloadURL"]))
                }
            }
        }

        return url.absoluteString
    }
}
