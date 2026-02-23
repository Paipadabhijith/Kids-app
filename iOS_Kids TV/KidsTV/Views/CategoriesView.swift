//
//  CategoriesView.swift
//  Kids TV
//

import SwiftUI

struct CategoryTarget: Identifiable, Hashable {
    let id: String
    let name: String
    let query: String
}

struct CategoriesView: View {
    @State private var selectedCategory: CategoryTarget?
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 12) {
                ForEach(Constants.kidCategories) { cat in
                    Button {
                        selectedCategory = CategoryTarget(id: cat.id, name: cat.title, query: cat.query)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: cat.iconName)
                                .font(.title)
                            Text(cat.title)
                                .font(.subheadline.weight(.semibold))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(AppTheme.standardRadius)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedCategory) { target in
            CategoryVideosView(categoryName: target.name, searchQuery: target.query)
        }
    }
}

// NavigationDestination with optional item requires Item: Hashable. Use a wrapper.
struct CategoryVideosView: View {
    let categoryName: String
    let searchQuery: String
    @State private var videos: [VideoModel] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedVideo: VideoModel?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                    Text(err)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(videos) { video in
                            VideoCardView(video: video) {
                                selectedVideo = video
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(categoryName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { Task { await load() } }
        .navigationDestination(item: $selectedVideo) { v in
            VideoPlayerView(video: v)
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let list = try await YouTubeService.shared.searchVideos(query: searchQuery, maxResults: 25)
            let filtered = list.filter { ParentalControlService.shared.isVideoAllowed($0) }
            await MainActor.run {
                videos = filtered
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
