//
//  RAWGGame.swift
//  GameTracker
//
//  Created by Armin Assadzadeh on 22.11.26.
//

import Foundation

struct RAWGGame: Identifiable, Decodable, Sendable {
    let id: Int
    let name: String
    let released: String?
    let backgroundImage: URL?

    var releaseYear: String {
        guard let released else {
            return "Unknown year"
        }

        return String(released.prefix(4))
    }
}

struct RAWGSearchResponse: Decodable, Sendable {
    let results: [RAWGGame]
}
