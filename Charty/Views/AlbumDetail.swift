import SwiftUI
import _MusicKit_SwiftUI

struct AlbumDetail: View {
    @EnvironmentObject private var service: AppleMusicService
    
    let album: AlbumItem
    let allSongs: [SongItem]
    let allAlbums: [AlbumItem]
    let allArtists: [ArtistItem]
    
    private var albumSongs: [SongItem] {
        allSongs.filter { $0.albumTitle == album.title && $0.albumArtist == album.artist }
            .sorted { $0.trackNumber < $1.trackNumber }
    }
    
    private var artist: ArtistItem? {
        allArtists.first { $0.name == album.artist }
    }
    
    private var albumRank: Int? {
        allAlbums.firstIndex(where: { $0.id == album.id }).map { $0 + 1 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    GeometryReader { geometry in
                        let sideLength = geometry.size.width
                        
                        if let artwork = album.artwork {
                            ArtworkImage(artwork, width: sideLength, height: sideLength)
                                .scaledToFill()
                                .frame(width: sideLength, height: sideLength)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: sideLength, height: sideLength)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 80))
                                        .foregroundStyle(.secondary)
                                )
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity)
                
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    Section {
                        VStack(spacing: 4) {
                            
                            
                            HStack(spacing: 8) {
                                if let rank = albumRank {
                                    Text("No. \(rank) Overall")
                                    Text("•")
                                }
                                Text("\(album.playCount) plays")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            
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
                        }
                        .padding(.bottom, 20)
                        
                        ForEach(albumSongs) { song in
                            NavigationLink(destination: SongDetail(
                                song: song,
                                allSongs: allSongs,
                                allAlbums: allAlbums,
                                allArtists: allArtists
                            )) {
                                ChartRow(
                                    rank: song.trackNumber,
                                    title: song.title,
                                    subtitle: song.artist == album.artist ? "" : song.artist,
                                    stat: song.playCount,
                                    award: song.award,
                                    artwork: nil,
                                    isNowPlaying: service.nowPlayingSong?.id == song.id,
                                )
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            
                            Divider().padding(.leading)
                        }
                        
                        // MARK: - Metadata
                        VStack(spacing: 12) {
                            Divider()
                            HStack {
                                Text("Released").font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                
                                if let releaseDate = album.releaseDate {
                                    Text(releaseDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline.bold())
                                }
                                else{
                                    Text(album.releaseDate.map { String(Calendar.current.component(.year, from: $0)) } ?? "Unknown")
                                        .font(.subheadline.bold())
                                }
                            }
                            .padding(.horizontal)
                            
                            HStack {
                                Text("Added to Library").font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Text(album.libraryAddedDate?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
                                    .font(.subheadline.bold())
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 40)
                        
                    } header: {
                        VStack(spacing: 2) {
                            Text(album.title)
                                .font(.headline)
                                .lineLimit(1)
                            
                            if let artist {
                                NavigationLink(destination: ArtistDetail(
                                    artist: artist,
                                    allSongs: allSongs,
                                    allAlbums: allAlbums,
                                    allArtists: allArtists
                                )) {
                                    Text(album.artist)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.accentColor)
                                        .lineLimit(1)
                                }
                            } else {
                                Text(album.artist)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            
                            if let releaseDate = album.releaseDate {
                                Text(String(Calendar.current.component(.year, from: releaseDate)))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .nowPlayingToolbar()
    }
    
    var albumDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}
