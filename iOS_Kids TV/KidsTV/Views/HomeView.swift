//
//  HomeView.swift
//  Kids TV
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var themeService: AppThemeService
    @EnvironmentObject var storage: StorageService
    private let parental = ParentalControlService.shared
    @StateObject private var auth = AuthService.shared
    @State private var remainingMinutes: Int = -1
    @State private var isLimitExceeded = false
    @State private var trending: [VideoModel] = []
    @State private var recommended: [VideoModel] = []
    @State private var isLoadingTrending = false
    @State private var isLoadingRecommended = false
    @State private var trendingReason: String?
    @State private var recommendedReason: String?
    @State private var showParental = false
    @State private var showCategories = false
    @State private var showSearch = false
    @State private var showFavorites = false
    @State private var showPlaylists = false
    @State private var selectedVideo: VideoModel?
    @State private var selectedCategoryTarget: CategoryTarget?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if remainingMinutes >= 0 {
                        TimeLimitWidget(remainingMinutes: remainingMinutes, isLimitExceeded: isLimitExceeded) {
                            showParental = true
                        }
                        .padding(.horizontal)
                    }
                    if isLimitExceeded {
                        limitExceededBanner
                    }

                    quickAccessSection
                    learnPlaySection
                    recommendedSection
                    trendingSection
                }
                .padding(.bottom, 32)
            }
            .refreshable { await refreshContent() }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Kids TV")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        tierBadge
                        Button { showSearch = true } label: {
                            Image(systemName: "magnifyingglass")
                        }
                        .disabled(isLimitExceeded)
                        Menu {
                            Button("Parental settings") { showParental = true }
                            Button("Account") { }
                            if auth.isSignedIn {
                                Button("Sign out", role: .destructive) {
                                    try? auth.signOut()
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.circle.fill")
                        }
                    }
                }
            }
            .onAppear {
                checkTimeLimit()
                loadCachedThenRefresh()
            }
            .navigationDestination(isPresented: $showParental) { ParentalSettingsView() }
            .navigationDestination(isPresented: $showCategories) { CategoriesView() }
            .navigationDestination(isPresented: $showSearch) { SearchView() }
            .navigationDestination(isPresented: $showFavorites) { CuratedContentView() }
            .navigationDestination(isPresented: $showPlaylists) { PlaylistsView() }
            .navigationDestination(item: $selectedCategoryTarget) { target in
                CategoryVideosView(categoryName: target.name, searchQuery: target.query)
            }
            .navigationDestination(item: $selectedVideo) { video in
                VideoPlayerView(video: video)
            }
        }
    }

    private var tierBadge: some View {
        Text(SubscriptionService.shared.getSubscription().tierBadge)
            .font(.caption2.weight(.bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(AppTheme.primary)
            .clipShape(Capsule())
    }

    private var limitExceededBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text("Daily time limit reached. Please ask a parent to adjust settings.")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.red)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .cornerRadius(AppTheme.standardRadius)
        .padding(.horizontal)
    }

    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Access")
                .font(.headline)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    quickCard(title: "Categories", subtitle: "Browse by type", icon: "square.grid.2x2.fill", color: .purple) { showCategories = true }
                    quickCard(title: "Favorites", subtitle: "Saved content", icon: "heart.fill", color: .red) { showFavorites = true }
                    quickCard(title: "Playlists", subtitle: "My collections", icon: "list.bullet", color: .pink) { showPlaylists = true }
                }
                .padding(.horizontal)
            }
            .frame(height: 120)
        }
    }

    private func quickCard(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(.white)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(width: 140, height: 100, alignment: .leading)
            .padding(12)
            .background(LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .cornerRadius(AppTheme.standardRadius)
        }
        .buttonStyle(.plain)
        .disabled(isLimitExceeded)
    }

    private var learnPlaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Learn & Play")
                .font(.headline)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    categoryChip("Alphabets", "textformat.abc", "alphabet learning for kids ABC")
                    categoryChip("Numbers", "number", "numbers counting for kids 123")
                    categoryChip("Colors", "paintpalette.fill", "colors learning for kids rainbow")
                    categoryChip("Animals", "pawprint.fill", "animals for kids learning zoo")
                    categoryChip("Nursery Rhymes", "music.note", "nursery rhymes for kids songs")
                }
                .padding(.horizontal)
            }
            .frame(height: 100)
        }
    }

    private func categoryChip(_ title: String, _ icon: String, _ query: String) -> some View {
        Button {
            selectedCategoryTarget = CategoryTarget(id: title, name: title, query: query)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .frame(width: 90, height: 70)
            .background(Color.blue.opacity(0.15))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(isLimitExceeded)
    }

    private var recommendedSection: some View {
        sectionContent(
            title: "Recommended For You",
            videos: recommended,
            isLoading: isLoadingRecommended,
            emptyReason: recommendedReason,
            onSeeAll: { showSearch = true }
        ) { video in
            selectedVideo = video
        }
    }

    private var trendingSection: some View {
        sectionContent(
            title: "Trending Kids Shows",
            videos: trending,
            isLoading: isLoadingTrending,
            emptyReason: trendingReason,
            onSeeAll: { showCategories = true }
        ) { video in
            selectedVideo = video
        }
    }

    private func sectionContent(
        title: String,
        videos: [VideoModel],
        isLoading: Bool,
        emptyReason: String?,
        onSeeAll: @escaping () -> Void,
        onTap: @escaping (VideoModel) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if !videos.isEmpty && !isLimitExceeded {
                    Button("See all", action: onSeeAll)
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding(.horizontal)

            if isLoading {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: AppTheme.standardRadius)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 150, height: 100)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 180)
            } else if videos.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "film")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(emptyReason ?? "No videos right now.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(videos) { video in
                            VideoCardView(video: video) {
                                onTap(video)
                            }
                            .frame(width: 160)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 200)
            }
        }
    }

    private func checkTimeLimit() {
        remainingMinutes = ParentalControlService.shared.getRemainingTimeMinutes()
        isLimitExceeded = ParentalControlService.shared.isTimeLimitExceeded()
    }

    private func loadCachedThenRefresh() {
        let cacheKeyTrending = "api_cache_trending_kids_shows"
        let cacheKeyRec = "api_cache_recommendations"
        if let data = UserDefaults.standard.data(forKey: cacheKeyTrending),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let ts = json["timestampMs"] as? Int,
           Date().timeIntervalSince1970 * 1000 - Double(ts) < 12 * 3600 * 1000,
           let payload = json["data"] as? [String: Any],
           let arr = payload["videos"] as? [[String: Any]] {
            trending = (try? JSONDecoder().decode([VideoModel].self, from: JSONSerialization.data(withJSONObject: arr))) ?? []
        }
        if let data = UserDefaults.standard.data(forKey: cacheKeyRec),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let ts = json["timestampMs"] as? Int,
           Date().timeIntervalSince1970 * 1000 - Double(ts) < 12 * 3600 * 1000,
           let payload = json["data"] as? [String: Any],
           let arr = payload["videos"] as? [[String: Any]] {
            recommended = (try? JSONDecoder().decode([VideoModel].self, from: JSONSerialization.data(withJSONObject: arr))) ?? []
        }
        Task {
            await refreshContent()
        }
    }

    private func refreshContent() async {
        checkTimeLimit()
        await loadTrending()
        await loadRecommendations()
    }

    private func loadTrending() async {
        guard Constants.hasValidApiKey else {
            await MainActor.run {
                trending = []
                isLoadingTrending = false
                trendingReason = "YouTube API key is missing or invalid."
            }
            return
        }
        await MainActor.run { isLoadingTrending = true }
        do {
            let list = try await YouTubeService.shared.getTrendingKidsShows(maxResults: 5)
            let filtered = list.filter { ParentalControlService.shared.isVideoAllowed($0) }
            await MainActor.run {
                trending = filtered
                isLoadingTrending = false
                trendingReason = filtered.isEmpty ? "No trending videos right now." : nil
            }
        } catch {
            await MainActor.run {
                trending = []
                isLoadingTrending = false
                trendingReason = error.localizedDescription
            }
        }
    }

    private func loadRecommendations() async {
        await MainActor.run { isLoadingRecommended = true }
        let fallbackQuery = "popular educational kids videos"
        do {
            let list = try await YouTubeService.shared.searchVideos(query: fallbackQuery, maxResults: 5)
            let filtered = list.filter { ParentalControlService.shared.isVideoAllowed($0) }
            await MainActor.run {
                recommended = Array(filtered.prefix(5))
                isLoadingRecommended = false
                recommendedReason = recommended.isEmpty ? "No recommendations right now." : nil
            }
        } catch {
            await MainActor.run {
                recommended = []
                isLoadingRecommended = false
                recommendedReason = error.localizedDescription
            }
        }
    }
}

// Make VideoModel identifiable for navigationDestination(item:)
extension VideoModel: @retroactive Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
