//
//  Announcement.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-11.
//

import Foundation

struct Announcement: Identifiable {
    let id: String
    let schoolId: String
    let title: String
    let body: String
    /// `false` when taken down; omitted/true = active.
    let isActive: Bool
}
