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
    /// Card fill with subtle tint (adapts to dark mode)
    static let cardFill = Color.blue.opacity(0.08)
    
    /// Card stroke/border (better contrast in dark mode)
    static let cardStroke = Color.primary.opacity(0.15)
    
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
    
    // MARK: - Tron / Neon (Student Portal & EZLearningGames)
    static let tronBackground = Color(red: 0.02, green: 0.04, blue: 0.12)
    static let tronBackgroundMid = Color(red: 0.04, green: 0.08, blue: 0.2)
    static let tronCyan = Color(red: 0.2, green: 0.95, blue: 1)
    static let tronBlue = Color(red: 0.3, green: 0.5, blue: 1)
    static let tronPurple = Color(red: 0.6, green: 0.2, blue: 1)
    static let tronPink = Color(red: 1, green: 0.3, blue: 0.6)
    static let tronGreen = Color(red: 0.2, green: 1, blue: 0.5)
    static let tronOrange = Color(red: 1, green: 0.6, blue: 0.2)
    static let tronYellow = Color(red: 1, green: 0.9, blue: 0.3)
    
    static let tronGradient = LinearGradient(
        colors: [tronBackground, tronBackgroundMid],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let tronNeonCyanGradient = LinearGradient(
        colors: [tronCyan.opacity(0.9), tronBlue],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Light Appeal Theme (Student Portal, Games, Readings)
    /// Soft sky gradient - inviting, light, attention-grabbing
    static let lightSky = Color(red: 0.93, green: 0.96, blue: 1)
    static let lightMint = Color(red: 0.88, green: 0.98, blue: 0.94)
    static let lightCoral = Color(red: 1, green: 0.45, blue: 0.45)
    static let softOrange = Color(red: 1, green: 0.65, blue: 0.35)
    static let softPurple = Color(red: 0.6, green: 0.4, blue: 0.95)
    static let brightTeal = Color(red: 0.2, green: 0.78, blue: 0.75)
    static let warmYellow = Color(red: 1, green: 0.85, blue: 0.35)
    static let softBlue = Color(red: 0.4, green: 0.6, blue: 1)
    static let cardWhite = Color.white
    static let textDark = Color(red: 0.12, green: 0.12, blue: 0.2)
    static let textMutedLight = Color(red: 0.45, green: 0.45, blue: 0.55)
    
    static let lightAppealGradient = LinearGradient(
        colors: [lightSky, lightMint.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gamesAccentGradient = LinearGradient(
        colors: [brightTeal, softBlue],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let readingsAccentGradient = LinearGradient(
        colors: [softPurple, lightCoral],
        startPoint: .leading,
        endPoint: .trailing
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
