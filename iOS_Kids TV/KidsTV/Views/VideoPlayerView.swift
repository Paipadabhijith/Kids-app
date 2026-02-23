//
//  VideoPlayerView.swift
//  Kids TV - WKWebView-based YouTube player
//

import SwiftUI
import WebKit

struct VideoPlayerView: View {
    let video: VideoModel
    @Environment(\.dismiss) private var dismiss
    @State private var startTime: Date?
    @State private var totalMinutesWatched: Int = 0
    @State private var showBreakReminder = false
    private let parental = ParentalControlService.shared
    private let storage = StorageService.shared

    var body: some View {
        VStack(spacing: 0) {
            YouTubeWebView(videoId: video.id)
                .aspectRatio(16/9, contentMode: .fit)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(video.title)
                        .font(.headline)
                    Text(video.channelTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startTime = Date()
            storage.addToWatchHistory(video)
        }
        .onDisappear {
            if let start = startTime {
                let mins = max(1, Int(Date().timeIntervalSince(start) / 60))
                parental.recordVideoWatch(minutesWatched: mins)
            }
        }
        .alert("Time for a break?", isPresented: $showBreakReminder) {
            Button("OK") { showBreakReminder = false }
        } message: {
            Text("You've been watching for a while. Take a short break!")
        }
    }
}

/// WKWebView that loads YouTube embed URL
struct YouTubeWebView: UIViewRepresentable {
    let videoId: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let web = WKWebView(frame: .zero, configuration: config)
        web.scrollView.isScrollEnabled = false
        return web
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html><html><head><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"></head>
        <body style=\"margin:0\">
        <iframe width=\"100%\" height=\"100%\" src=\"https://www.youtube.com/embed/\(videoId)?playsinline=1\" frameborder=\"0\" allow=\"accelerometer;autoplay;encrypted-media;gyroscope;picture-in-picture\" allowfullscreen></iframe>
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
    }
}
