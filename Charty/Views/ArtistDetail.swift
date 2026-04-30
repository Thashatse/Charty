import SwiftUI
import MusicKit
import _MusicKit_SwiftUI

struct ArtistDetail: View {
    let artist: ArtistItem
    let allSongs: [SongItem]
    let allAlbums: [AlbumItem]
    let allArtists: [ArtistItem]
    
    private var artistSongs: [SongItem] {
        allSongs.filter { song in
            let isMainArtist = song.albumArtist == artist.name
            
            let isContributor = song.artistNames.contains { name in
                name.normalizedForSearch == artist.name.normalizedForSearch
            }
            
            return isMainArtist || isContributor
        }
    }
    
    private var artistAlbums: [AlbumItem] {
        allAlbums.filter { $0.artist == artist.name }
            .sorted {
                if $0.playCount != $1.playCount { return $0.playCount > $1.playCount }
                let d0 = $0.libraryAddedDate ?? $0.releaseDate ?? .distantPast
                let d1 = $1.libraryAddedDate ?? $1.releaseDate ?? .distantPast
                return d0 > d1
            }
    }
    
    private var appearsOnSongs: [SongItem] {
            allSongs.filter { song in
                let targetName = artist.name.normalizedForSearch
                let isInContributorList = song.artistNames.contains { $0.normalizedForSearch == targetName }
                let isNotAlbumArtist = song.albumArtist.normalizedForSearch != targetName
                return isInContributorList && isNotAlbumArtist
            }
        }
    
    private var topSongs: [SongItem] {
        Array(artistSongs.sorted { $0.playCount > $1.playCount }.prefix(10))
    }
    
    private var topSong: SongItem? { topSongs.first }
    private var topAlbum: AlbumItem? { artistAlbums.first }
    
    private var artistRank: Int? {
        allArtists.firstIndex(where: { $0.id == artist.id }).map { $0 + 1 }
    }
    
    private var topSongRank: Int? {
        guard let song = topSong else { return nil }
        return allSongs.firstIndex(where: { $0.id == song.id }).map { $0 + 1 }
    }
    
    private var topAlbumRank: Int? {
        guard let album = topAlbum else { return nil }
        return allAlbums.firstIndex(where: { $0.id == album.id }).map { $0 + 1 }
    }
    
    private var awardTally: [(award: Award, count: Int)] {
        let songAwards = artistSongs.compactMap { $0.award }
        let albumAwards = artistAlbums.compactMap { $0.award }
        let allAwards = songAwards + albumAwards
        
        let counts = Award.allCases.compactMap { award -> (Award, Int)? in
            let count = allAwards.filter { $0 == award }.count
            return count > 0 ? (award, count) : nil
        }
        return counts.sorted { (a: (award: Award, count: Int), b: (award: Award, count: Int)) in
            a.award.tier > b.award.tier
        }
    }
    
    private var formattedPlays: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: artist.playCount)) ?? "\(artist.playCount)"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                
                // MARK: - Artwork
                Group {
                    GeometryReader { geometry in
                        let sideLength = geometry.size.width
                        
                        if let artwork = artist.artwork {
                            ArtworkImage(artwork, width: sideLength, height: sideLength)
                                .scaledToFill()
                                .frame(width: sideLength, height: sideLength)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: sideLength, height: sideLength)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 80))
                                        .foregroundStyle(.secondary)
                                )
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
                
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    
                    // MARK: - Sticky header
                    Section {
                        VStack(spacing: 6) {
                            HStack(spacing: 8) {
                                if let rank = artistRank {
                                    Text("No. \(rank) Overall")
                                    Text("•")
                                }
                                Text("\(formattedPlays) plays")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            
                            if let award = artist.award {
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
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity)
                        
                        // MARK: - Top Song, Album & Award Tally
                        if topSong != nil || topAlbum != nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Highlights")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                if let song = topSong, let rank = topSongRank {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Top Song")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal)
                                        
                                        NavigationLink(destination: SongDetail(
                                            song: song,
                                            allSongs: allSongs,
                                            allAlbums: allAlbums,
                                            allArtists: allArtists
                                        )) {
                                            ChartRow(
                                                rank: rank,
                                                title: song.title,
                                                subtitle: song.albumTitle,
                                                stat: song.playCount,
                                                award: song.award,
                                                artwork: song.artwork
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.horizontal)
                                    }
                                }
                                
                                if let album = topAlbum, let rank = topAlbumRank {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Top Album")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal)
                                        NavigationLink(destination: AlbumDetail(
                                            album: album,
                                            allSongs: allSongs,
                                            allAlbums: allAlbums,
                                            allArtists: allArtists
                                        )) {
                                            ChartRow(
                                                rank: rank,
                                                title: album.title,
                                                subtitle: album.artist,
                                                stat: album.playCount,
                                                award: album.award,
                                                artwork: album.artwork
                                            )
                                            .padding(.horizontal)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                
                                if !awardTally.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Awards")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal)
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            ForEach(awardTally, id: \.award) { entry in
                                                HStack(spacing: 8) {
                                                    
                                                    Text("\(entry.count)x")
                                                        .font(.subheadline)
                                                        .foregroundStyle(.primary)
                                                    
                                                    Text(entry.award.displayName)
                                                        .font(.caption.bold())
                                                        .textCase(.uppercase)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(entry.award.color.opacity(0.2))
                                                        .foregroundStyle(entry.award.color)
                                                        .cornerRadius(4)
                                                    
                                                    Spacer()
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                    .padding(.bottom, 20)
                                }
                                
                            }
                            .padding(.bottom, 20)
                        }
                        
                        // MARK: - Top 10 Songs
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Top Songs")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                            
                            ForEach(Array(topSongs.enumerated()), id: \.element.id) { index, song in
                                NavigationLink(destination: SongDetail(
                                    song: song,
                                    allSongs: allSongs,
                                    allAlbums: allAlbums,
                                    allArtists: allArtists
                                )) {
                                    ChartRow(
                                        rank: index + 1,
                                        title: song.title,
                                        subtitle: song.albumTitle +
                                        (song.releaseDate != nil ? " • " + String(Calendar.current.component(.year, from: song.releaseDate!)) : ""),
                                        stat: song.playCount,
                                        award: song.award,
                                        artwork: song.artwork
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                                .padding(.vertical, 6)
                                
                                Divider().padding(.leading)
                            }
                        }
                        .padding(.bottom, 20)
                        
                        // MARK: - All Albums
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Albums")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                            
                            ForEach(Array(artistAlbums.enumerated()), id: \.element.id) { index, album in
                                NavigationLink(destination: AlbumDetail(
                                    album: album,
                                    allSongs: allSongs,
                                    allAlbums: allAlbums,
                                    allArtists: allArtists
                                )) {
                                    ChartRow(
                                        rank: index + 1,
                                        title: album.title,
                                        subtitle: album.releaseDate.map {
                                            String(Calendar.current.component(.year, from: $0))
                                        } ?? "",
                                        stat: album.playCount,
                                        award: album.award,
                                        artwork: album.artwork
                                    )
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)
                                Divider().padding(.leading)
                            }
                        }
                        .padding(.bottom, 20)
                        
                        // MARK: - Appears On Section (Featured Songs)
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("Appears On")
                                        .font(.headline)
                                        .padding(.horizontal)
                                        .padding(.bottom, 8)
                                    
                                    // Sorted by playcount, showing top 10 features
                                    ForEach(appearsOnSongs.sorted(by: { $0.playCount > $1.playCount }).prefix(10), id: \.id) { song in
                                        // Calculate rank based on global allSongs list
                                        let globalRank = (allSongs.firstIndex(where: { $0.id == song.id }) ?? 0) + 1
                                        
                                        NavigationLink(destination: SongDetail(song: song, allSongs: allSongs, allAlbums: allAlbums, allArtists: allArtists)) {
                                            ChartRow(
                                                rank: globalRank,
                                                title: song.title,
                                                subtitle: song.albumArtist + " — " + song.albumTitle,
                                                stat: song.playCount,
                                                award: song.award,
                                                artwork: song.artwork
                                            )
                                            .padding(.horizontal)
                                            .padding(.vertical, 6)
                                        }
                                        .buttonStyle(.plain)
                                        Divider().padding(.leading)
                                    }
                                }
                                .padding(.bottom, 40)
                        
                    } header: {
                        Text(artist.name)
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(UIColor.systemBackground))
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
    }
}
