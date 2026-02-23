//
//  CuratedContentView.swift
//  Kids TV - Favorites / saved videos
//

import SwiftUI

struct CuratedContentView: View {
    @EnvironmentObject var storage: StorageService
    @State private var videos: [VideoModel] = []
    @State private var selectedVideo: VideoModel?

    var body: some View {
        Group {
            if videos.isEmpty {
                ContentUnavailableView(
                    "No favorites",
                    systemImage: "heart.slash",
                    description: Text("Save videos from the player to see them here.")
                )
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
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { videos = storage.getCuratedVideos() }
        .navigationDestination(item: $selectedVideo) { v in
            VideoPlayerView(video: v)
        }
    }
}
