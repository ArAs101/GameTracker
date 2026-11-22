//
//  RAWGService.swift
//  GameTracker
//
//  Created by Armin Assadzadeh on 22.11.26.
//

import Foundation

enum RAWGError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "RAWG API key is missing."
        case .invalidURL:
            return "Invalid request URL."
        case .invalidResponse:
            return "Invalid server response."
        case .httpError(let status):
            return "RAWG returned HTTP \(status)."
        }
    }
}

struct RAWGService {
    func searchGames(_ searchTerm: String) async throws -> [RAWGGame] {
        guard let apiKey = Bundle.main.object(
            forInfoDictionaryKey: "RAWG_API_KEY"
        ) as? String,
              !apiKey.isEmpty,
              !apiKey.contains("$(") else {
            throw RAWGError.missingAPIKey
        }

        guard var components = URLComponents(
            string: "https://api.rawg.io/api/games"
        ) else {
            throw RAWGError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "search", value: searchTerm),
            URLQueryItem(name: "page_size", value: "10")
        ]

        guard let url = components.url else {
            throw RAWGError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(
            from: url
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RAWGError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw RAWGError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let searchResponse = try decoder.decode(
            RAWGSearchResponse.self,
            from: data
        )

        return searchResponse.results
    }
}
