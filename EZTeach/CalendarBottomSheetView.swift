//
//  CalendarBottomSheetView.swift
//  EZTeach
//
//  Created by Brian Bruce on 2026-01-12.
//

import SwiftUI

struct CalendarBottomSheetView: View {

    let events: [SchoolEvent]
    var viewerRole: String? = nil

    @State private var expanded = false
    @GestureState private var dragY: CGFloat = 0

    private let calendar = Calendar.current

    var body: some View {
        GeometryReader { geo in
            let collapsedHeight: CGFloat = 180
            let expandedHeight: CGFloat = min(520, geo.size.height * 0.65)

            VStack(spacing: 0) {
                // Grab handle + title row
                VStack(spacing: 8) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.35))
                        .frame(width: 42, height: 6)
                        .padding(.top, 10)

                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(EZTeachColors.navy)
                        Text("School Calendar")
                            .font(.headline)
                        Spacer()
                        Image(systemName: expanded ? "chevron.down" : "chevron.up")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                }

                Divider()

                ScrollView {
                    LazyVStack(spacing: 10) {
                        if events.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 36))
                                    .foregroundColor(.secondary)
                                Text("No upcoming events")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                        } else {
                            ForEach(events) { event in
                                eventCard(event)
                            }
                        }
                    }
                    .padding(14)
                }
            }
            .frame(width: geo.size.width)
            .frame(height: expanded ? expandedHeight : collapsedHeight, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.10), radius: 14, y: -2)
            )
            .offset(y: geo.size.height - (expanded ? expandedHeight : collapsedHeight) + dragOffset())
            .gesture(
                DragGesture()
                    .updating($dragY) { value, state, _ in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        if value.translation.height < -60 { expanded = true }
                        if value.translation.height > 60 { expanded = false }
                    }
            )
            .onTapGesture {
                withAnimation { expanded.toggle() }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: expanded)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Event Card (Calendar Style)
    private func eventCard(_ event: SchoolEvent) -> some View {
        HStack(spacing: 12) {
            // Date box (calendar style)
            VStack(spacing: 2) {
                Text(monthAbbrev(event.date))
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                Text(dayNumber(event.date))
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            .frame(width: 50, height: 54)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(eventColor(event))
            )

            // Event details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(event.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)

                    if event.teachersOnly, viewerRole == "school" || viewerRole == "teacher" {
                        Image(systemName: "eye.slash.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: eventIcon(event))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(weekdayName(event.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Day number badge on right
            Text(dayNumber(event.date))
                .font(.caption.bold())
                .foregroundColor(EZTeachColors.navy)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(EZTeachColors.cardFill)
                )
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    // MARK: - Helpers
    private func monthAbbrev(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }

    private func dayNumber(_ date: Date) -> String {
        "\(calendar.component(.day, from: date))"
    }

    private func weekdayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private func eventColor(_ event: SchoolEvent) -> Color {
        switch event.type.lowercased() {
        case "dayoff", "day off":
            return .green
        case "event":
            return EZTeachColors.navy
        default:
            return .blue
        }
    }

    private func eventIcon(_ event: SchoolEvent) -> String {
        switch event.type.lowercased() {
        case "dayoff", "day off":
            return "sun.max.fill"
        case "event":
            return "star.fill"
        default:
            return "calendar"
        }
    }

    private func dragOffset() -> CGFloat {
        let maxDrag: CGFloat = 90
        return max(-maxDrag, min(maxDrag, dragY))
    }
}
