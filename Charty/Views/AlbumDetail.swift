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
                            ArtworkImage(artwork, width: 100, height: 100)
                                .cornerRadius(8)
                                .shadow(radius: 4)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
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
                                Text(String(Calendar.current.component(.year, from: releaseDate)))
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
}
