//
//  GameDetailView.swift
//  GameTracker
//
//  Created by Armin Assadzadeh on 22.11.26.
//

import SwiftUI

struct GameDetailView: View {
    let game: TrackedGame

    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Game information
                HStack(alignment: .top, spacing: 16) {
                    AsyncImage(
                        url: game.coverURL.flatMap {
                            URL(string: $0)
                        }
                    ) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "gamecontroller.fill")
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 110, height: 145)
                    .clipped()
                    .clipShape(
                        RoundedRectangle(cornerRadius: 10)
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text(game.title)
                            .font(.title3)
                            .bold()

                        Text(game.releaseYear)
                            .foregroundStyle(.secondary)
                    }
                }

                // Status
                HStack {
                    Text("Status")
                        .font(.headline)

                    Spacer()

                    Text(
                        game.status.isEmpty
                            ? "-"
                            : game.status
                    )
                }

                // Rating
                HStack {
                    Text("Rating")
                        .font(.headline)

                    Spacer()

                    if game.rating == 0 {
                        Text("Not rated")
                            .foregroundStyle(.secondary)
                    } else {
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { star in
                                Image(
                                    systemName: star <= game.rating
                                        ? "star.fill"
                                        : "star"
                                )
                                .foregroundStyle(.orange)
                            }
                        }
                    }
                }

                Divider()

                // Progress log placeholder
                Text("Progress Log")
                    .font(.title3)
                    .bold()

                ContentUnavailableView(
                    "No progress entries yet...",
                    systemImage: "text.book.closed",
                    description: Text(
                        "Progress tracking will be added next."
                    )
                )

                Link(
                    "Game data provided by RAWG",
                    destination: URL(string: "https://rawg.io")!
                )
                .font(.caption)
            }
            .padding()
        }
        .navigationTitle("Game details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEdit = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("Edit game")
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                GameEditView(game: game)
            }
        }
    }
}
