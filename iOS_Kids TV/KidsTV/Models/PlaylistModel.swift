//
//  PlaylistModel.swift
//  Kids TV
//

import Foundation

struct PlaylistModel: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var description: String?
    var videoIds: [String]
    var createdAt: Date
    var updatedAt: Date?

    init(
        id: String,
        name: String,
        description: String? = nil,
        videoIds: [String],
        createdAt: Date,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.videoIds = videoIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
