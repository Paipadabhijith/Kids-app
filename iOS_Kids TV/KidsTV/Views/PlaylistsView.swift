//
//  PlaylistsView.swift
//  Kids TV
//

import SwiftUI

struct PlaylistsView: View {
    @EnvironmentObject var storage: StorageService
    @State private var playlists: [PlaylistModel] = []
    @State private var selectedPlaylist: PlaylistModel?

    var body: some View {
        Group {
            if playlists.isEmpty {
                ContentUnavailableView(
                    "No playlists",
                    systemImage: "list.bullet",
                    description: Text("Create a playlist from the video player.")
                )
            } else {
                List {
                    ForEach(playlists) { pl in
                        Button {
                            selectedPlaylist = pl
                        } label: {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(AppTheme.primary)
                                VStack(alignment: .leading) {
                                    Text(pl.name)
                                        .font(.headline)
                                    Text("\(pl.videoIds.count) videos")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Playlists")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { playlists = storage.getPlaylists() }
        .navigationDestination(item: $selectedPlaylist) { pl in
            PlaylistDetailView(playlist: pl)
        }
    }
}

struct PlaylistDetailView: View {
    let playlist: PlaylistModel
    @EnvironmentObject var storage: StorageService
    @State private var videos: [VideoModel] = []
    @State private var selectedVideo: VideoModel?

    var body: some View {
        List {
            ForEach(videos) { video in
                VideoCardView(video: video) {
                    selectedVideo = video
                }
            }
        }
        .navigationTitle(playlist.name)
        .onAppear {
            let history = storage.getWatchHistory(profileId: nil)
            videos = playlist.videoIds.compactMap { id in history.first { $0.id == id } }
        }
        .navigationDestination(item: $selectedVideo) { v in
            VideoPlayerView(video: v)
        }
    }
}

