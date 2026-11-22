//
//  GameSearchView.swift
//  GameTracker
//
//  Created by Armin Assadzadeh on 22.11.26.
//

import SwiftUI
import SwiftData

struct GameSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var trackedGames: [TrackedGame]

    @State private var searchTerm = ""
    @State private var results: [RAWGGame] = []
    @State private var isLoading = false
    @State private var hasSearched = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var searchTask: Task<Void, Never>?
    
    private let rawgService = RAWGService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Dauerhaft sichtbares Suchfeld
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search games", text: $searchTerm)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit {
                            startSearch()
                        }

                    Button {
                        startSearch()
                    } label: {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                    }
                    .disabled(
                        searchTerm.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty || isLoading
                    )
                }
                .padding(12)
                .background(
                    Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .padding(.horizontal)
                .padding(.vertical, 10)

                // Ergebnisliste
                List {
                    ForEach(results) { game in
                        HStack(spacing: 12) {
                            AsyncImage(url: game.backgroundImage) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName: "gamecontroller.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 60, height: 75)
                            .clipped()

                            VStack(alignment: .leading, spacing: 6) {
                                Text(game.name)
                                    .font(.headline)

                                Text(game.releaseYear)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 4)

                            Button {
                                addGame(game)
                            } label: {
                                Image(
                                    systemName: isTracked(game)
                                        ? "checkmark.circle.fill"
                                        : "plus.circle"
                                )
                                .font(.title2)
                            }
                            .disabled(isTracked(game))
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .overlay {
                    if isLoading {
                        ProgressView("Searching games...")
                    } else if results.isEmpty {
                        ContentUnavailableView(
                            hasSearched
                                ? "No games found"
                                : "Search for a game",
                            systemImage: "magnifyingglass",
                            description: Text(
                                hasSearched
                                    ? "Try another search term."
                                    : "Enter a game title to search RAWG."
                            )
                        )
                    }
                }
            }
            .navigationTitle("Add Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        searchTask?.cancel()
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Link(
                    "Game data provided by RAWG",
                    destination: URL(string: "https://rawg.io")!
                )
                .font(.caption)
                .padding(8)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onDisappear {
                searchTask?.cancel()
            }
        }
    }

    private func startSearch() {
        searchTask?.cancel()

        searchTask = Task {
            await searchGames()
        }
    }


    private func isTracked(_ game: RAWGGame) -> Bool {
        trackedGames.contains {
            $0.rawgID == game.id
        }
    }

    private func searchGames() async {
        let query = searchTerm.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !query.isEmpty else { return }

        isLoading = true
        hasSearched = true
        results = []

        defer {
            isLoading = false
        }

        do {
            results = try await rawgService.searchGames(query)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func addGame(_ game: RAWGGame) {
        guard !isTracked(game) else { return }

        let trackedGame = TrackedGame(from: game)
        modelContext.insert(trackedGame)

        do {
            try modelContext.save()
        } catch {
            modelContext.delete(trackedGame)
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
