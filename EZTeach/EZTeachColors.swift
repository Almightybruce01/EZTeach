//
//  EZTeachColors.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-06.
//

import SwiftUI

enum EZTeachColors {
    // MARK: - Core Backgrounds
    /// Primary background (adapts to light/dark mode)
    static let background = Color(.systemBackground)
    
    /// Secondary background for cards and elevated surfaces
    static let secondaryBackground = Color(.secondarySystemBackground)
    
    /// Tertiary background for nested elements
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    
    // MARK: - Brand Colors
    /// Primary brand navy - deep, professional
    static let navy = Color(red: 10/255, green: 31/255, blue: 68/255)
    
    /// Lighter navy for gradients
    static let navyLight = Color(red: 25/255, green: 55/255, blue: 109/255)
    
    /// Accent blue - vibrant, futuristic
    static let accent = Color(red: 59/255, green: 130/255, blue: 246/255)
    
    /// Success green
    static let success = Color(red: 34/255, green: 197/255, blue: 94/255)
    
    /// Warning amber
    static let warning = Color(red: 251/255, green: 191/255, blue: 36/255)
    
    /// Error red
    static let error = Color(red: 239/255, green: 68/255, blue: 68/255)
    
    // MARK: - UI Elements
    /// Card fill with subtle tint
    static let cardFill = Color.blue.opacity(0.08)
    
    /// Card stroke/border
    static let cardStroke = Color.gray.opacity(0.2)
    
    /// Subtle divider
    static let divider = Color.gray.opacity(0.15)
    
    /// Muted text
    static let textMuted = Color.gray
    
    /// Premium gold for subscription elements
    static let gold = Color(red: 255/255, green: 193/255, blue: 7/255)
    
    // MARK: - Gradients
    /// Primary gradient for headers and CTAs
    static let primaryGradient = LinearGradient(
        colors: [navy, navyLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Accent gradient for buttons
    static let accentGradient = LinearGradient(
        colors: [accent, Color(red: 99/255, green: 102/255, blue: 241/255)],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Premium gradient for subscription
    static let premiumGradient = LinearGradient(
        colors: [gold, Color(red: 251/255, green: 146/255, blue: 60/255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - View Modifiers
extension View {
    /// Standard card styling
    func ezCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(EZTeachColors.secondaryBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    /// Accent button styling
    func ezButton() -> some View {
        self
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(EZTeachColors.accentGradient)
            .cornerRadius(12)
    }
    
    /// Secondary button styling
    func ezSecondaryButton() -> some View {
        self
            .font(.headline)
            .foregroundColor(EZTeachColors.accent)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(EZTeachColors.accent.opacity(0.1))
            .cornerRadius(12)
    }
}
