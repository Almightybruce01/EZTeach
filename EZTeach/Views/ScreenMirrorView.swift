//
//  ScreenMirrorView.swift
//  EZTeach
//
//  Screen Mirroring and AirPlay integration for presentations
//

import SwiftUI
import AVKit

struct ScreenMirrorButton: View {
    @State private var showingMirrorSheet = false
    
    var body: some View {
        Button {
            showingMirrorSheet = true
        } label: {
            Image(systemName: "airplayvideo")
                .foregroundColor(EZTeachColors.softBlue)
        }
        .sheet(isPresented: $showingMirrorSheet) {
            ScreenMirrorView()
        }
    }
}

struct ScreenMirrorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isSearching = false
    @State private var connectedDevice: String? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Connection Status
                    connectionStatusSection
                    
                    // AirPlay Instructions
                    instructionsSection
                    
                    // Quick Tips
                    quickTipsSection
                    
                    // Native AirPlay Route Picker
                    airPlayPickerSection
                }
                .padding()
            }
            .background(EZTeachColors.backgroundColor)
            .navigationTitle("Screen Mirror")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [EZTeachColors.softBlue, EZTeachColors.teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "airplayvideo")
                    .font(.system(size: 45))
                    .foregroundColor(.white)
            }
            
            Text("Screen Mirroring & AirPlay")
                .font(.title2.bold())
                .foregroundColor(EZTeachColors.textPrimary)
            
            Text("Share your screen to TVs, projectors, and Apple devices")
                .font(.subheadline)
                .foregroundColor(EZTeachColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - Connection Status
    private var connectionStatusSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: connectedDevice != nil ? "checkmark.circle.fill" : "circle.dotted")
                    .foregroundColor(connectedDevice != nil ? .green : .gray)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(connectedDevice != nil ? "Connected" : "Not Connected")
                        .font(.headline)
                        .foregroundColor(EZTeachColors.textPrimary)
                    
                    Text(connectedDevice ?? "Tap below to connect to a display")
                        .font(.caption)
                        .foregroundColor(EZTeachColors.textSecondary)
                }
                
                Spacer()
                
                if isSearching {
                    ProgressView()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(connectedDevice != nil ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
            )
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - AirPlay Picker Section
    private var airPlayPickerSection: some View {
        VStack(spacing: 16) {
            Text("Connect to Display")
                .font(.headline)
                .foregroundColor(EZTeachColors.textPrimary)
            
            // Native iOS AirPlay Route Picker
            AirPlayRoutePickerView()
                .frame(width: 200, height: 60)
            
            Text("Tap the icon above to see available AirPlay devices")
                .font(.caption)
                .foregroundColor(EZTeachColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - Instructions
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How to Mirror Your Screen")
                .font(.headline)
                .foregroundColor(EZTeachColors.textPrimary)
            
            InstructionStep(
                number: 1,
                title: "Open Control Center",
                description: "Swipe down from the top-right corner of your iPhone/iPad"
            )
            
            InstructionStep(
                number: 2,
                title: "Tap Screen Mirroring",
                description: "Look for the two overlapping rectangles icon"
            )
            
            InstructionStep(
                number: 3,
                title: "Select Your Device",
                description: "Choose your Apple TV, Smart TV, or AirPlay-compatible display"
            )
            
            InstructionStep(
                number: 4,
                title: "Enter Code if Prompted",
                description: "Some displays require a code shown on the TV screen"
            )
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - Quick Tips
    private var quickTipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tips for Best Experience")
                .font(.headline)
                .foregroundColor(EZTeachColors.textPrimary)
            
            TipRow(
                icon: "wifi",
                tip: "Ensure both devices are on the same Wi-Fi network"
            )
            
            TipRow(
                icon: "battery.100",
                tip: "Keep your device charged - mirroring uses more battery"
            )
            
            TipRow(
                icon: "speaker.wave.2.fill",
                tip: "Audio will play through the connected display"
            )
            
            TipRow(
                icon: "rectangle.on.rectangle",
                tip: "Rotate your device to change display orientation"
            )
            
            TipRow(
                icon: "lock.shield.fill",
                tip: "Notifications may still appear - enable Do Not Disturb for presentations"
            )
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
}

// MARK: - AirPlay Route Picker (UIKit Wrapper)
struct AirPlayRoutePickerView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.backgroundColor = .clear
        routePickerView.activeTintColor = UIColor(EZTeachColors.softBlue)
        routePickerView.tintColor = UIColor(EZTeachColors.textSecondary)
        return routePickerView
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

// MARK: - Supporting Views
struct InstructionStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(EZTeachColors.softBlue)
                    .frame(width: 28, height: 28)
                Text("\(number)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(EZTeachColors.textPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(EZTeachColors.textSecondary)
            }
        }
    }
}

struct TipRow: View {
    let icon: String
    let tip: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(EZTeachColors.teal)
                .frame(width: 24)
            
            Text(tip)
                .font(.caption)
                .foregroundColor(EZTeachColors.textSecondary)
        }
    }
}

// MARK: - Global AirPlay Overlay Modifier
struct ScreenMirrorOverlay: ViewModifier {
    @State private var showMirrorSheet = false
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showMirrorSheet = true
                    } label: {
                        Image(systemName: "airplayvideo")
                            .foregroundColor(EZTeachColors.softBlue)
                    }
                }
            }
            .sheet(isPresented: $showMirrorSheet) {
                ScreenMirrorView()
            }
    }
}

extension View {
    func withScreenMirror() -> some View {
        modifier(ScreenMirrorOverlay())
    }
}
