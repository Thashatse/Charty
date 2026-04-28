import SwiftUI
import _MusicKit_SwiftUI

struct AlbumDetail: View {
    let album: AlbumItem
    let allSongs: [SongItem]
    
    private var albumSongs: [SongItem] {
        allSongs.filter { $0.albumTitle == album.title && $0.albumArtist == album.artist }
            .sorted { $0.trackNumber < $1.trackNumber }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    if let artwork = album.artwork {
                        ArtworkImage(artwork, width: 250, height: 250)
                            .cornerRadius(10)
                            .shadow(radius: 6)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 250, height: 250)
                            .overlay(Image(systemName: "music.note").foregroundStyle(.secondary))
                    }
                    
                    VStack(spacing: 4) {
                        
                        if let award = album.award {
                            Text(award.displayName)
                                .font(.caption.bold())
                                .textCase(.uppercase)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(award.color.opacity(0.2))
                                .foregroundStyle(award.color)
                                .cornerRadius(4)
                        }
                        
                        Text("\(album.playCount) plays")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
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
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity)
                
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    Section {
                        ForEach(albumSongs) { song in
                            ChartRow(
                                rank: song.trackNumber,
                                title: song.title,
                                subtitle: song.artist,
                                stat: song.playCount,
                                award: song.award,
                                artwork: nil
                            )
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                            Divider()
                                .padding(.leading)
                        }
                    } header: {
                        VStack(spacing: 2) {
                            Text(album.title)
                                .font(.headline)
                                .lineLimit(1)
                            Text(album.artist)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(10)
                    }
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
