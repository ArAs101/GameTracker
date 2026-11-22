//
//  ContentView.swift
//  GameTracker
//
//  Created by Armin Assadzadeh on 22.11.26.
//

import SwiftUI

// Temporary Data model for the UI
private struct PreviewGame: Identifiable {
    let id = UUID()
    let title: String
    let year: Int
    let status: String
    let rating: Int
}

struct ContentView: View {
    @State private var showingAddGame = false

    // Test data to be replaced by SwiftData
    private let games: [PreviewGame] = [
        PreviewGame(
            title: "The Witcher 3: Wild Hunt",
            year: 2015,
            status: "Playing",
            rating: 5
        ),
        PreviewGame(
            title: "Minecraft",
            year: 2011,
            status: "Paused",
            rating: 4
        ),
        PreviewGame(
            title: "Stardew Valley",
            year: 2016,
            status: "Completed",
            rating: 5
        )
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(games) { game in
                            NavigationLink {
                                Text(game.title)
                                    .navigationTitle("Game details")
                            } label: {
                                gameCard(game)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }

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
                .padding()
            }
            .navigationTitle("My Tracked Games")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddGame) {
                NavigationStack {
                    ContentUnavailableView(
                        "Game Search",
                        systemImage: "magnifyingglass",
                        description: Text(
                            "RAWG Search to be implemented..."
                        )
                    )
                    .navigationTitle("Add Game")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Close") {
                                showingAddGame = false
                            }
                        }
                    }
                }
            }
        }
    }

    private func gameCard(_ game: PreviewGame) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.15))
                .overlay {
                    Image(systemName: "gamecontroller.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 80, height: 100)

            VStack(alignment: .leading, spacing: 6) {
                Text(game.title)
                    .font(.headline)

                Text(String(game.year))
                    .foregroundStyle(.secondary)

                Text("Status: \(game.status)")
                    .font(.subheadline)

                Text(
                    String(repeating: "★", count: game.rating) +
                    String(repeating: "☆", count: 5 - game.rating)
                )
                .foregroundStyle(.orange)
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

#Preview {
    ContentView()
}
