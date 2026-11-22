//
//  TrackedGame.swift
//  GameTracker
//
//  Created by Armin Assadzadeh on 22.11.26.
//

import Foundation
import SwiftData

@Model
final class TrackedGame {
    var rawgID: Int
    var title: String
    var releaseDate: String?
    var coverURL: String?

    var status: String
    var rating: Int

    init(from game: RAWGGame) {
        self.rawgID = game.id
        self.title = game.name
        self.releaseDate = game.released
        self.coverURL = game.backgroundImage?.absoluteString

        self.status = "-"
        self.rating = 0
    }

    var releaseYear: String {
        guard let releaseDate else {
            return "Unknown year"
        }

        return String(releaseDate.prefix(4))
    }
}
