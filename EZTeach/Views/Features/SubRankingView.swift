//
//  SubRankingView.swift
//  EZTeach
//
//  Substitute ranking: value score, categories, complaints/compliments.
//  Top 100 overall + Top 100 by city. Schools and districts only.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SubRankingView: View {
    let schoolId: String
    let districtSchoolIds: [String]
    let isDistrict: Bool

    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var ranking: [SubRankingItem] = []
    @State private var byCity: [String: [SubRankingItem]] = [:]
    @State private var allReviews: [SubReview] = []
    @State private var isLoading = true
    @State private var messageSubId: SubIdWrapper?

    private let db = Firestore.firestore()

    private var schoolIds: [String] {
        isDistrict ? districtSchoolIds : [schoolId]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                EZTeachColors.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    Picker("", selection: $selectedTab) {
                        Text("Top 100 Overall").tag(0)
                        Text("Top 100 by City").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    if selectedTab == 1 {
                        cityPickerSection
                    }

                    searchBar

                    if isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else {
                        rankingList
                    }
                }
            }
            .navigationTitle("Sub Ranking")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: load)
            .sheet(item: $messageSubId) { _ in
                MessageSubPlaceholder()
            }
        }
    }

    private var cityPickerSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(byCity.keys).sorted(), id: \.self) { city in
                    Button {
                        searchText = city
                    } label: {
                        Text(city)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(EZTeachColors.secondaryBackground)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search substitutes", text: $searchText)
        }
        .padding(12)
        .background(EZTeachColors.secondaryBackground)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom, 12)
    }

    private var rankingList: some View {
        let list = filteredRanking
        return List {
            ForEach(Array(list.enumerated()), id: \.element.subId) { idx, item in
                SubRankingRow(
                    rank: idx + 1,
                    item: item,
                    reviews: allReviews.filter { $0.subId == item.subId }
                ) {
                    messageSubId = SubIdWrapper(id: item.subId)
                }
            }
        }
        .listStyle(.plain)
    }

    private var filteredRanking: [SubRankingItem] {
        let base = selectedTab == 0 ? ranking : (byCity[searchText.isEmpty ? (byCity.keys.sorted().first ?? "") : searchText] ?? [])
        if searchText.isEmpty { return base }
        return base.filter {
            $0.subName.localizedCaseInsensitiveContains(searchText) ||
            $0.city.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func load() {
        isLoading = true
        Task {
            await fetchReviewsAndRank()
            await MainActor.run { isLoading = false }
        }
    }

    private func fetchReviewsAndRank() async {
        var reviews: [SubReview] = []
        for sid in schoolIds {
            let snap = try? await db.collection("subReviews")
                .whereField("schoolId", isEqualTo: sid)
                .getDocuments()
            for doc in snap?.documents ?? [] {
                if let r = SubReview.fromDocument(doc) { reviews.append(r) }
            }
        }
        await MainActor.run { allReviews = reviews }

        let grouped = Dictionary(grouping: reviews) { $0.subId }
        var items: [SubRankingItem] = []
        var cityMap: [String: [SubRankingItem]] = [:]

        for (subId, subRevs) in grouped {
            let first = subRevs.first!
            var breakdown: [String: Double] = [:]
            var compl = 0, comp = 0
            for r in subRevs {
                if r.type == .complaint { compl += 1 } else { comp += 1 }
                let k = r.category.rawValue
                breakdown[k, default: 0] += r.valueScore
            }
            for k in breakdown.keys { breakdown[k]? /= Double(subRevs.filter { $0.category.rawValue == k }.count) }
            let overall = subRevs.map(\.valueScore).reduce(0, +) / Double(subRevs.count)
            let city = first.schoolCity.isEmpty ? first.schoolName : first.schoolCity
            let item = SubRankingItem(
                subId: subId,
                subUserId: first.subUserId,
                subName: first.subName,
                city: city,
                overallValue: overall,
                categoryBreakdown: breakdown,
                complaintCount: compl,
                complimentCount: comp,
                reviewCount: subRevs.count
            )
            items.append(item)
            cityMap[city, default: []].append(item)
        }

        items.sort { $0.overallValue > $1.overallValue }
        for k in cityMap.keys { cityMap[k]?.sort { $0.overallValue > $1.overallValue } }

        await MainActor.run {
            ranking = Array(items.prefix(100))
            byCity = cityMap.mapValues { Array($0.prefix(100)) }
        }
    }
}

struct SubRankingRow: View {
    let rank: Int
    let item: SubRankingItem
    let reviews: [SubReview]
    let onMessage: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("#\(rank)")
                    .font(.headline.monospacedDigit())
                    .foregroundColor(EZTeachColors.accent)
                    .frame(width: 36, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.subName)
                        .font(.headline)
                    Text("Value: \(String(format: "%.1f", item.overallValue)) • \(item.reviewCount) reviews")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Message", action: onMessage)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(EZTeachColors.accent)
            }

            HStack(spacing: 16) {
                Label("\(item.complimentCount)", systemImage: "hand.thumbsup.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                Label("\(item.complaintCount)", systemImage: "hand.thumbsdown.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            if !item.categoryBreakdown.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Category breakdown")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    ForEach(Array(item.categoryBreakdown.keys.sorted()), id: \.self) { k in
                        HStack {
                            Text(SubReview.ReviewCategory(rawValue: k)?.displayName ?? k)
                                .font(.caption2)
                            Spacer()
                            Text(String(format: "%.1f", item.categoryBreakdown[k] ?? 0))
                                .font(.caption2.monospacedDigit())
                        }
                    }
                }
            }

            if !reviews.isEmpty {
                DisclosureGroup("Complaints & Compliments") {
                    ForEach(reviews.prefix(5)) { r in
                        HStack(alignment: .top) {
                            Image(systemName: r.type == .compliment ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                                .foregroundColor(r.type == .compliment ? .green : .red)
                                .font(.caption)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(r.schoolName)
                                    .font(.caption.weight(.medium))
                                Text(r.category.displayName)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                if let c = r.comment, !c.isEmpty {
                                    Text(c)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct SubIdWrapper: Identifiable { let id: String }

struct MessageSubPlaceholder: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text("Message sub – open Messages from the menu and start a conversation.")
                .padding()
                .navigationTitle("Message Sub")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}
