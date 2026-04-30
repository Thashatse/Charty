import SwiftUI
import MusicKit

struct SongDetail: View {
    @EnvironmentObject private var service: AppleMusicService
    
    let song: SongItem
    let allSongs: [SongItem]
    let allAlbums: [AlbumItem]
    let allArtists: [ArtistItem]
    
    private var songRank: Int? {
        allSongs.firstIndex(where: { $0.id == song.id }).map { $0 + 1 }
    }
    
    private var parentAlbum: AlbumItem? {
        allAlbums.first { $0.title == song.albumTitle && $0.artist == song.albumArtist }
    }
    
    private var formattedPlays: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: song.playCount)) ?? "\(song.playCount)"
    }
    
    private var releaseYear: String {
        song.releaseDate.map { String(Calendar.current.component(.year, from: $0)) } ?? "Unknown"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Artwork
                GeometryReader { geometry in
                    let sideLength = geometry.size.width
                    if let artwork = song.artwork {
                        ArtworkImage(artwork, width: sideLength, height: sideLength)
                            .scaledToFill()
                            .frame(width: sideLength, height: sideLength)
                            .clipped()
                    } else {
                        Rectangle().fill(Color.gray.opacity(0.2))
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                
                VStack(spacing: 24) {
                    // MARK: - Header
                    VStack(spacing: 12) {
                        VStack(spacing: 8) {
                            
                            // Now Playing indicator
                            if service.nowPlayingSong?.id == song.id {
                                HStack(spacing: 6) {
                                    AnimatedWaveform(isPlaying: service.isPlaying)
                                    Text("Now Playing")
                                        .font(.caption.bold())
                                        .foregroundStyle(service.isPlaying ? .blue : .secondary)
                                        .textCase(.uppercase)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(service.isPlaying ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.1))
                                .clipShape(Capsule())
                            }
                            
                            Text(song.title)
                                .font(.title.bold())
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            VStack(spacing: 6) {
                                HStack(spacing: 8) {
                                    if let rank = songRank {
                                        Text("No. \(rank) Overall")
                                        Text("•")
                                    }
                                    Text("\(formattedPlays) plays")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                            
                            if let award = song.award {
                                Text(award.displayName)
                                    .font(.caption.bold())
                                    .textCase(.uppercase)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(award.color.opacity(0.2))
                                    .foregroundStyle(award.color)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.top, 24)
                    
                    // MARK: - Album and Artist
                    VStack(alignment: .leading, spacing: 16) {
                        // Album Link
                        if let album = parentAlbum {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("From the album")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                
                                NavigationLink(destination: AlbumDetail(album: album, allSongs: allSongs, allAlbums: allAlbums, allArtists: allArtists)) {
                                    HStack(spacing: 12) {
                                        if let artwork = album.artwork {
                                            ArtworkImage(artwork, width: 50, height: 50)
                                                .cornerRadius(4)
                                        }
                                        VStack(alignment: .leading) {
                                            Text(album.title)
                                                .font(.body.bold())
                                            Text(album.artist)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // MARK: - Artists List
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Artists")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            
                            ForEach(song.artistNames, id: \.self) { name in
                                
                                if let artistItem = allArtists.first(where: { $0.name == name }) {
                                    NavigationLink(destination: ArtistDetail(artist: artistItem, allSongs: allSongs, allAlbums: allAlbums, allArtists: allArtists)) {
                                        HStack(spacing: 12) {
                                            if let artwork = artistItem.artwork {
                                                ArtworkImage(artwork, width: 44, height: 44)
                                                    .clipShape(Circle())
                                            } else {
                                                // Fallback circle if no image is found
                                                Circle()
                                                    .fill(Color.secondary.opacity(0.2))
                                                    .frame(width: 44, height: 44)
                                                    .overlay(Image(systemName: "person.fill").foregroundStyle(.secondary))
                                            }
                                            
                                            Text(name)
                                                .font(.body.bold())
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if name != song.artistNames.last {
                                        Divider()
                                            .padding(.leading, 56)
                                    }
                                } else {
                                    HStack {
                                        Text(name)
                                            .font(.body)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("Metadata only")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .onAppear {
                        print("👥 song.artistNames array: \(song.artistNames)")
                    }
                    
                    // MARK: - Metadata
                    VStack(spacing: 12) {
                        Divider()
                        HStack {
                            Text("Released").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            if let releaseDate = song.releaseDate {
                                Text(releaseDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline.bold())
                            }
                            else{
                                Text(releaseYear).font(.subheadline.bold())
                            }
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Text("Added to Library").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Text(song.libraryAddedDate?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
                                .font(.subheadline.bold())
                        }
                        .padding(.horizontal)
                        
                        if let lastPlayed = song.lastPlayed {
                            HStack {
                                Text("Last Played").font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Text(lastPlayed.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline.bold())
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .nowPlayingToolbar(currentSongID: song.id)
    }
}
