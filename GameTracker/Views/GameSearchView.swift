//
//  GameSearchView.swift
//  GameTracker
//
//  Created by Armin Assadzadeh on 22.11.26.
//

import SwiftUI
import SwiftData
import Combine

private final class SearchDebouncer: ObservableObject {
    let input = PassthroughSubject<String, Never>()
    let output: AnyPublisher<String, Never>

    init() {
        output = input
            .debounce(
                for: .milliseconds(1000),
                scheduler: DispatchQueue.main
            )
            .eraseToAnyPublisher()
    }
}

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
    @StateObject private var searchDebouncer = SearchDebouncer()
    @State private var lastStartedQuery: String?
    
    private let rawgService = RAWGService()
    
    private var currentQuery: String {
        searchTerm.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search field is permanently visible
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search games", text: $searchTerm)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit {
                            startSearch(for: currentQuery, force: true)
                        }
                }
                .padding(12)
                .background(
                    Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .padding(.horizontal)
                .padding(.vertical, 10)

                // List of results
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
                    if results.isEmpty {
                        if isLoading {
                            ProgressView("Searching games...")
                        } else {
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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    Divider()

                    Link(
                        "Game data provided by RAWG",
                        destination: URL(string: "https://rawg.io")!
                    )
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .background(Color(.systemBackground))
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onDisappear {
                searchTask?.cancel()
            }
            .onChange(of: currentQuery) { _, newQuery in
                searchTask?.cancel()
                isLoading = false
                lastStartedQuery = nil

                if newQuery.isEmpty {
                    results = []
                    hasSearched = false
                }

                searchDebouncer.input.send(newQuery)
            }
            .onReceive(searchDebouncer.output) { query in
                startSearch(for: query)
            }
        }
    }

    private func startSearch(
        for query: String,
        force: Bool = false
    ) {
        guard query.count >= 2,
              query == currentQuery,
              !isLoading else {
            return
        }

        guard force || lastStartedQuery != query else {
            return
        }

        searchTask?.cancel()
        lastStartedQuery = query
        isLoading = true

        searchTask = Task {
            await searchGames(for: query)
        }
    }



    private func isTracked(_ game: RAWGGame) -> Bool {
        trackedGames.contains {
            $0.rawgID == game.id
        }
    }
    
    private func searchGames(for query: String) async {
        do {
            try Task.checkCancellation()

            print("RAWG search: \(query)")

            let games = try await rawgService.searchGames(query)

            try Task.checkCancellation()

            guard currentQuery == query else {
                return
            }

            results = games
            hasSearched = true
            isLoading = false

        } catch {
            guard !Task.isCancelled,
                  currentQuery == query else {
                return
            }

            isLoading = false
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
