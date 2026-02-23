//
//  SearchView.swift
//  Kids TV
//

import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @State private var results: [VideoModel] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var selectedVideo: VideoModel?
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search kids videos…", text: $query)
                    .textFieldStyle(.plain)
                    .focused($isFieldFocused)
                    .onSubmit { Task { await search() } }
                if !query.isEmpty {
                    Button("Search") { Task { await search() } }
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding()

            if isSearching {
                Spacer()
                ProgressView("Searching…")
            } else if let err = errorMessage {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                    Text(err)
                        .multilineTextAlignment(.center)
                }
                .foregroundColor(.secondary)
            } else if results.isEmpty && !query.isEmpty {
                Spacer()
                Text("No results. Try another search.")
                    .foregroundColor(.secondary)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(results) { video in
                            VideoCardView(video: video) {
                                selectedVideo = video
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedVideo) { v in
            VideoPlayerView(video: v)
        }
    }

    private func search() async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { return }
        isSearching = true
        errorMessage = nil
        do {
            let list = try await YouTubeService.shared.searchVideos(query: q, maxResults: 25)
            let filtered = list.filter { ParentalControlService.shared.isVideoAllowed($0) }
            await MainActor.run {
                results = filtered
                isSearching = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isSearching = false
            }
        }
    }
}
