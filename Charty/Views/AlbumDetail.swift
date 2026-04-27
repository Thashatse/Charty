import SwiftUI

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
                    Text(album.title)
                        .font(.title.bold())
                    
                    HStack {
                        Text(album.artist)
                        
                        if let releaseDate = album.releaseDate {
                            Text("•")
                            // This will display the full date (e.g., "January 1, 2024")
                            Text(releaseDate.formatted(date: .long, time: .omitted))
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    Text("\(album.playCount) total plays")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let award = album.award {
                        HStack {
                            Text("Certified ")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
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
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Tracks")) {
                ForEach(albumSongs) { song in
                    ChartRow(
                        rank: song.trackNumber,
                        title: song.title,
                        subtitle: song.artist,
                        stat: song.playCount,
                        award: song.award
                    )
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
