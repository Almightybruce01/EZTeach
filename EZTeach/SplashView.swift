//
//  SplashView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-06.
//

import SwiftUI

struct SplashView: View {
    
    @State private var logoScale: CGFloat = 1.0
    @State private var logoGlow: CGFloat = 0
    @State private var contentScale: CGFloat = 1.0
    @State private var contentOpacity: Double = 1.0
    @State private var vacuumProgress: CGFloat = 0
    @State private var showVacuum = false
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                // Base background - Navy
                Color(red: 0.118, green: 0.173, blue: 0.294)
                    .ignoresSafeArea()
                
                // Vacuum effect - radial lines pulling to center
                if showVacuum {
                    ForEach(0..<12, id: \.self) { i in
                        let angle = Double(i) * (360.0 / 12.0)
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 3, height: geometry.size.height)
                            .offset(y: -geometry.size.height / 2)
                            .rotationEffect(.degrees(angle))
                            .scaleEffect(y: 1 - vacuumProgress)
                            .opacity(Double(1 - vacuumProgress))
                    }
                    .position(center)
                }
                
                // Main content that gets vacuumed
                ZStack {
                    // Glow effect behind logo
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.6),
                                    Color(red: 0.3, green: 0.5, blue: 1.0).opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 180
                            )
                        )
                        .frame(width: 350, height: 350)
                        .scaleEffect(1 + logoGlow * 0.2)
                        .opacity(0.8 + logoGlow * 0.2)
                    
                    // Outer glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(1 + logoGlow * 0.15)
                        .opacity(logoGlow)
                    
                    // Logo with vibrant enhancement
                    Image("EZTeachLogoPolished.jpg")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 36))
                        .overlay(
                            RoundedRectangle(cornerRadius: 36)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.8),
                                            Color.white.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                        )
                        .shadow(color: Color(red: 0.3, green: 0.5, blue: 1.0).opacity(0.8), radius: 30, x: 0, y: 0)
                        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                        .scaleEffect(logoScale)
                }
                .scaleEffect(contentScale)
                .opacity(contentOpacity)
                .position(center)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Phase 1: Logo pulse glow effect (0 - 0.6s)
        withAnimation(.easeInOut(duration: 0.6)) {
            logoGlow = 1.0
        }
        
        // Phase 2: Logo shrinks slightly (0.6s - 1.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.4)) {
                logoScale = 0.85
            }
        }
        
        // Phase 3: Start vacuum effect (1.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showVacuum = true
            
            // Vacuum lines animate inward
            withAnimation(.easeIn(duration: 0.5)) {
                vacuumProgress = 1.0
            }
        }
        
        // Phase 4: SNAP - Everything collapses to center (1.3s - 1.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            // Quick snap to center
            withAnimation(.easeIn(duration: 0.25)) {
                contentScale = 0.5
                logoGlow = 0
            }
            
            // Final vacuum snap
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeIn(duration: 0.15)) {
                    contentScale = 0.01
                    contentOpacity = 0
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
