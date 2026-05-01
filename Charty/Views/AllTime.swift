import Foundation
import SwiftUI

struct AllTimeView: View {
    @EnvironmentObject private var musicService: AppleMusicService
    @EnvironmentObject private var chartService: ChartService
    @State private var selectedChart = 0
    let searchText: String

    var body: some View {
        VStack {
            Picker("Chart Type", selection: $selectedChart) {
                Text("Songs").tag(0)
                Text("Albums").tag(1)
                Text("Artists").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            Group {
                if musicService.isLoading {
                    ProgressView("Loading your charts...")
                        .frame(maxHeight: .infinity)
                } else {
                    List {
                        if selectedChart == 0 {
                            let filteredSongs = searchResults(for: musicService.songs)
                            ForEach(filteredSongs, id: \.item.id) { result in
                                NavigationLink(destination: SongDetail(
                                    song: result.item,
                                    allSongs: musicService.songs,
                                    allAlbums: musicService.albums,
                                    allArtists: musicService.artists
                                )) {
                                    ChartRow(
                                        rank: result.rank,
                                        title: result.item.title,
                                        subtitle: result.item.artist + (result.item.releaseDate != nil ?
                                            " • " + String(Calendar.current.component(.year, from: result.item.releaseDate!)) : ""),
                                        stat: result.item.playCount,
                                        award: result.item.award,
                                        artwork: result.item.artwork,
                                        isNowPlaying: musicService.nowPlayingSong?.id == result.item.id
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        } else if selectedChart == 1 {
                            let filteredAlbums = searchResults(for: musicService.albums)
                            ForEach(filteredAlbums, id: \.item.id) { result in
                                NavigationLink(destination: AlbumDetail(
                                    album: result.item,
                                    allSongs: musicService.songs,
                                    allAlbums: musicService.albums,
                                    allArtists: musicService.artists
                                )) {
                                    ChartRow(
                                        rank: result.rank,
                                        title: result.item.title,
                                        subtitle: result.item.artist + (result.item.releaseDate != nil ?
                                            " • " + String(Calendar.current.component(.year, from: result.item.releaseDate!)) : ""),
                                        stat: result.item.playCount,
                                        award: result.item.award,
                                        artwork: result.item.artwork
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            let filteredArtists = searchResults(for: musicService.artists)
                            ForEach(filteredArtists, id: \.item.id) { result in
                                NavigationLink(destination: ArtistDetail(
                                    artist: result.item,
                                    allSongs: musicService.songs,
                                    allAlbums: musicService.albums,
                                    allArtists: musicService.artists
                                )) {
                                    ChartRow(
                                        rank: result.rank,
                                        title: result.item.name,
                                        subtitle: "",
                                        stat: result.item.playCount,
                                        award: result.item.award,
                                        artwork: result.item.artwork
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private func searchResults<T>(for items: [T]) -> [(rank: Int, item: T)] {
        let rankedItems = items.enumerated().map { (index: $0, item: $1) }
        if searchText.isEmpty {
            let limit = (selectedChart == 0) ? 500 : 100
            return rankedItems.prefix(limit).map { ($0.index + 1, $0.item) }
        }
        return rankedItems.filter { ranked in
            let searchTarget: String
            if let song = ranked.item as? SongItem {
                searchTarget = "\(song.title) \(song.artist) \(song.albumTitle)"
            } else if let album = ranked.item as? AlbumItem {
                searchTarget = "\(album.title) \(album.artist) \(album.searchTarget)"
            } else if let artist = ranked.item as? ArtistItem {
                searchTarget = "\(artist.name) \(artist.searchTarget)"
            } else {
                searchTarget = ""
            }
            return searchTarget.localizedCaseInsensitiveContains(searchText)
        }.map { ($0.index + 1, $0.item) }
    }
}
