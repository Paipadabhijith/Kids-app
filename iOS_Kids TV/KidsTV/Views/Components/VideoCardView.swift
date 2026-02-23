//
//  VideoCardView.swift
//  Kids TV
//

import SwiftUI

struct VideoCardView: View {
    let video: VideoModel
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: URL(string: video.thumbnailUrl)) { phase in
                    switch phase {
                    case .success(let image): image.resizable().aspectRatio(contentMode: .fill)
                    case .failure: Color.gray.opacity(0.3)
                    default: ProgressView()
                    }
                }
                .aspectRatio(video.aspectRatio, contentMode: .fit)
                .clipped()
                .cornerRadius(AppTheme.standardRadius)

                Text(video.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Text(video.channelTitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}
