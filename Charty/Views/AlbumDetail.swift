import SwiftUI
import _MusicKit_SwiftUI

struct AlbumDetail: View {
    let album: AlbumItem
    let allSongs: [SongItem]
    
    // Filter songs that belong to this album
    private var albumSongs: [SongItem] {
        allSongs.filter { $0.albumID == album.id }
            .sorted(by: { $0.trackNumber < $1.trackNumber })
    }
    
    var body: some View {
        List {
            // New Header Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 16) {
                        if let artwork = album.artwork {
                            ArtworkImage(artwork, width: 140, height: 140)
                                .cornerRadius(8)
                                .shadow(radius: 4)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 140, height: 140)
                                .overlay(Image(systemName: "music.note").foregroundStyle(.secondary))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(album.title)
                                .font(.title3.bold())
                                .lineLimit(2)
                            
                            Text(album.artist)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let releaseDate = album.releaseDate {
                                Text("Released: \(releaseDate, formatter: albumDateFormatter)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let addedDate = album.libraryAddedDate {
                                Text("Added: \(addedDate, formatter: albumDateFormatter)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("\(album.playCount) total plays")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                            
                            if let award = album.award {
                                HStack {
                                    Text(award.displayName)
                                        .font(.caption.bold())
                                        .textCase(.uppercase)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(award.color.opacity(0.2))
                                        .foregroundStyle(award.color)
                                        .cornerRadius(4)
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Tracks")) {
                ForEach(albumSongs) { song in
                    ChartRow(
                        rank: song.trackNumber,
                        title: song.title,
                        subtitle: song.artist,
                        stat: song.playCount,
                        award: song.award,
                        artwork: nil
                    )
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var albumDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}
