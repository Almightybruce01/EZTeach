//
//  GradeUtils.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-11.
//

import Foundation

enum GradeUtils {
    // 0 = Pre-K, 1 = K, 2 = 1st ... 13 = 12th
    static let allGrades: [Int] = Array(0...13)

    static func label(_ grade: Int) -> String {
        switch grade {
        case 0: return "Pre‑K"
        case 1: return "Kindergarten"
        case 2: return "1st Grade"
        case 3: return "2nd Grade"
        case 4: return "3rd Grade"
        case 5: return "4th Grade"
        case 6: return "5th Grade"
        case 7: return "6th Grade"
        case 8: return "7th Grade"
        case 9: return "8th Grade"
        case 10: return "9th Grade"
        case 11: return "10th Grade"
        case 12: return "11th Grade"
        case 13: return "12th Grade"
        default: return "Grade \(grade)"
        }
    }
}
