//
//  ContentView.swift
//  GameTracker
//
//  Created by Armin Assadzadeh on 22.11.26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrackedGame.title)
    private var games: [TrackedGame]

    @State private var showingAddGame = false
    @State private var gameToDelete: TrackedGame?
    @State private var showDeleteConfirmation = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(games) { game in
                    NavigationLink {
                        GameDetailView(game: game)
                    } label: {
                        gameCard(game)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(
                        EdgeInsets(
                            top: 6,
                            leading: 16,
                            bottom: 6,
                            trailing: 16
                        )
                    )
                    .swipeActions(
                        edge: .trailing,
                        allowsFullSwipe: false
                    ) {
                        Button {
                            gameToDelete = game
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
            .listStyle(.plain)
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
            .alert(
                "Delete game?",
                isPresented: $showDeleteConfirmation,
                presenting: gameToDelete
            ) { game in
                Button("Cancel", role: .cancel) {
                    gameToDelete = nil
                }

                Button("Delete", role: .destructive) {
                    deleteGame(game)
                    gameToDelete = nil
                }
            } message: { game in
                Text(
                    "Are you sure you want to delete \(game.title) and all associated data? This action cannot be undone."
                )
            }
            .alert("Delete failed", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteErrorMessage)
            }
        }
    }
    
    private func deleteGame(_ game: TrackedGame) {
        withAnimation {
            modelContext.delete(game)
            do {
                try modelContext.save()
            } catch {
                modelContext.rollback()
                deleteErrorMessage = error.localizedDescription
                showDeleteError = true
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
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            Image(
                                systemName: star <= game.rating
                                    ? "star.fill"
                                    : "star"
                            )
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                        }
                    }
                    .accessibilityLabel("\(game.rating) out of 5 stars")
                } else {
                    Text("Not rated")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            Color.gray.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 12)
        )
    }
}
