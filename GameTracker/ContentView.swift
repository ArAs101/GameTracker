//
//  ContentView.swift
//  GameTracker
//
//  Created by Armin Assadzadeh on 22.11.26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \TrackedGame.title)
    private var games: [TrackedGame]

    @State private var showingAddGame = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(games) { game in
                        NavigationLink {
                            GameDetailView(game: game)
                        } label: {
                            gameCard(game)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .overlay {
                if games.isEmpty {
                    ContentUnavailableView(
                        "No tracked games",
                        systemImage: "gamecontroller",
                        description: Text(
                            "Add your first game to your collection."
                        )
                    )
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    Button {
                        showingAddGame = true
                    } label: {
                        Label(
                            "Add Game",
                            systemImage: "plus.rectangle.on.rectangle"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Link(
                        "Game data provided by RAWG",
                        destination: URL(string: "https://rawg.io")!
                    )
                    .font(.caption)
                }
                .padding()
                .background(.regularMaterial)
            }
            .navigationTitle("My Tracked Games")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddGame) {
                GameSearchView()
            }
        }
    }

    private func gameCard(_ game: TrackedGame) -> some View {
        HStack(spacing: 14) {
            AsyncImage(
                url: game.coverURL.flatMap { URL(string: $0) }
            ) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "gamecontroller.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80, height: 100)
            .clipped()

            VStack(alignment: .leading, spacing: 6) {
                Text(game.title)
                    .font(.headline)

                Text(game.releaseYear)
                    .foregroundStyle(.secondary)

                Text("Status: \(game.status.isEmpty ? "-" : game.status)")
                    .font(.subheadline)

                if game.rating > 0 {
                    Text(
                        String(repeating: "★", count: game.rating) +
                        String(repeating: "☆", count: 5 - game.rating)
                    )
                    .foregroundStyle(.orange)
                } else {
                    Text("Not rated")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            Color.gray.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 12)
        )
    }
}
