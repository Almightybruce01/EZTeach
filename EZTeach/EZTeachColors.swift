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
    static let teal = Color.teal
    static let warmYellow = Color(red: 1, green: 0.85, blue: 0.35)
    static let softBlue = Color(red: 0.4, green: 0.6, blue: 1)
    static let cardWhite = Color.white
    static let textDark = Color(red: 0.12, green: 0.12, blue: 0.2)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textMutedLight = Color(red: 0.45, green: 0.45, blue: 0.55)
    static let backgroundColor = Color(UIColor.systemBackground)
    
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
    
    /// Premium glass card effect
    func ezGlassCard(color: Color = .white) -> some View {
        self
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.8))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
    
    /// Floating card with 3D effect
    func ezFloatingCard() -> some View {
        self
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.05))
                        .offset(x: 4, y: 4)
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                }
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    /// AI feature badge styling
    func ezAIBadge() -> some View {
        self
            .font(.caption.weight(.bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                LinearGradient(
                    colors: [Color.purple, Color.pink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
    }
    
    /// Feature highlight effect
    func ezFeatureHighlight(color: Color = EZTeachColors.brightTeal) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color, lineWidth: 2)
            )
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    /// Subtle shimmer effect for loading states
    func ezShimmer(active: Bool = true) -> some View {
        self.overlay(
            Group {
                if active {
                    ShimmerView()
                }
            }
        )
    }
}

// MARK: - Shimmer Effect View
struct ShimmerView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                .clear,
                .white.opacity(0.4),
                .clear
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .white, .clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: phase)
        )
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 300
            }
        }
    }
}

// MARK: - Premium UI Components
struct EZFeatureBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
            Text(text)
                .font(.caption2.weight(.bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color)
        .cornerRadius(12)
    }
}

struct EZAIBadge: View {
    var text: String = "AI"
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.caption2)
            Text(text)
                .font(.caption2.weight(.bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            LinearGradient(
                colors: [.purple, .pink],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(10)
    }
}

struct EZNewBadge: View {
    var body: some View {
        Text("NEW")
            .font(.system(size: 9, weight: .black))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.green)
            .cornerRadius(6)
    }
}

struct EZProgressRing: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 8
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

struct EZEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(EZTeachColors.brightTeal.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(EZTeachColors.brightTeal.opacity(0.6))
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(EZTeachColors.accentGradient)
                        .cornerRadius(12)
                }
            }
        }
        .padding(40)
    }
}

struct EZSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var badge: String? = nil
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(EZTeachColors.brightTeal)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let badge = badge {
                        EZAIBadge(text: badge)
                    }
                }
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - iPad Adaptive Layout Modifier
/// Ensures content looks great on both iPhone and iPad.
/// On iPad / Mac (regular width), centers content with a comfortable max width
/// and increases horizontal padding. On iPhone, uses standard padding.
struct iPadAdaptiveModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass

    let maxContentWidth: CGFloat
    let compactPadding: CGFloat
    let regularPadding: CGFloat

    init(maxWidth: CGFloat = 720, compactPadding: CGFloat = 16, regularPadding: CGFloat = 32) {
        self.maxContentWidth = maxWidth
        self.compactPadding = compactPadding
        self.regularPadding = regularPadding
    }

    func body(content: Content) -> some View {
        GeometryReader { geo in
            let isWide = sizeClass == .regular
            let hPadding = isWide ? regularPadding : compactPadding

            content
                .frame(maxWidth: isWide ? maxContentWidth : .infinity)
                .frame(maxWidth: .infinity) // centers the inner frame
                .padding(.horizontal, hPadding)
        }
    }
}

/// Modifier that adapts grid column count for iPad
struct iPadAdaptiveGridModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass

    let compactColumns: Int
    let regularColumns: Int

    func body(content: Content) -> some View {
        content
            .environment(\.iPadColumnCount, sizeClass == .regular ? regularColumns : compactColumns)
    }
}

/// Environment key to pass adaptive column count to child views
private struct iPadColumnCountKey: EnvironmentKey {
    static let defaultValue: Int = 1
}

extension EnvironmentValues {
    var iPadColumnCount: Int {
        get { self[iPadColumnCountKey.self] }
        set { self[iPadColumnCountKey.self] = newValue }
    }
}

extension View {
    /// Apply iPad-adaptive content centering with max readable width.
    /// Great for ScrollView-based content pages.
    func iPadReadableWidth(maxWidth: CGFloat = 720) -> some View {
        modifier(iPadAdaptiveModifier(maxWidth: maxWidth))
    }

    /// Provide adaptive column count via environment
    func iPadAdaptiveGrid(compact: Int = 1, regular: Int = 2) -> some View {
        modifier(iPadAdaptiveGridModifier(compactColumns: compact, regularColumns: regular))
    }
}
