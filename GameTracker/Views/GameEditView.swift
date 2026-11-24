//
//  GameEditView.swift
//  GameTracker
//
//  Created by Armin Assadzadeh on 22.11.26.
//

import SwiftUI
import SwiftData

enum GameStatus: String, CaseIterable {
    case planned = "Planned"
    case playing = "Playing"
    case paused = "Paused"
    case completed = "Completed"
    case dropped = "Dropped"
}

struct GameEditView: View {
    let game: TrackedGame

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedStatus: String
    @State private var selectedRating: Int

    @State private var showSaveError = false
    @State private var errorMessage = ""

    init(game: TrackedGame) {
        self.game = game

        _selectedStatus = State(initialValue: game.status)
        _selectedRating = State(initialValue: game.rating)
    }

    var body: some View {
        Form {
            // Game information
            Section {
                HStack(spacing: 12) {
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
                    }
                    .frame(width: 65, height: 85)
                    .clipped()

                    VStack(alignment: .leading, spacing: 6) {
                        Text(game.title)
                            .font(.headline)

                        Text(game.releaseYear)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Status selection
            Section("Status") {
                Picker("Status", selection: $selectedStatus) {
                    Text("-").tag("-")

                    ForEach(
                        GameStatus.allCases,
                        id: \.rawValue
                    ) { status in
                        Text(status.rawValue)
                            .tag(status.rawValue)
                    }
                }
            }

            // Rating selection
            Section("Rating") {
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            selectedRating =
                                selectedRating == star ? 0 : star
                        } label: {
                            Image(
                                systemName: star <= selectedRating
                                    ? "star.fill"
                                    : "star"
                            )
                            .font(.title2)
                            .foregroundStyle(
                                star <= selectedRating
                                    ? Color.orange
                                    : Color.secondary
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            "\(star) out of 5 stars"
                        )
                    }
                }
                .padding(.vertical, 8)

                Button("Clear rating") {
                    selectedRating = 0
                }
                .disabled(selectedRating == 0)
            }
        }
        .navigationTitle("Edit Game details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
                .fontWeight(.semibold)
            }
        }
        .alert("Save failed", isPresented: $showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func saveChanges() {
        game.status = selectedStatus
        game.rating = selectedRating

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
            showSaveError = true
        }
    }
}
