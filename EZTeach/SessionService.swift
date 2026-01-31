//
//  SessionService.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-07.
//

import FirebaseAuth
import FirebaseFirestore

final class SessionService {
    static let shared = SessionService()
    private init() {}

    private let db = Firestore.firestore()

    func setActiveSession(_ isActive: Bool, completion: ((Error?) -> Void)? = nil) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion?(NSError(domain: "EZTeach", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not logged in"]))
            return
        }

        db.collection("users").document(uid).updateData([
            "activeSession": isActive
        ]) { error in
            completion?(error)
        }
    }
}
