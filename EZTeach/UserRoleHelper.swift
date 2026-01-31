//
//  UserRoleHelper.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-11.
//

import FirebaseAuth
import FirebaseFirestore

struct UserRoleHelper {

    static func isSchool(completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument { snap, _ in
                let role = snap?.data()?["role"] as? String
                completion(role == "school")
            }
    }
}
