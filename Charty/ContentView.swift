import SwiftUI

struct ContentView: View {
    @StateObject private var service = AppleMusicService()
    @State private var selectedChart = 0
    @State private var searchText = ""
    @State private var showingSyncSheet = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Chart Type", selection: $selectedChart) {
                    Text("Songs").tag(0)
                    Text("Albums").tag(1)
                    Text("Artists").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                Group {
                    if service.isLoading {
                        ProgressView("Loading your charts...")
                            .frame(maxHeight: .infinity)
                    } else {
                        List {
                            if selectedChart == 0 {
                                let filteredSongs = searchResults(for: service.songs)
                                ForEach(filteredSongs, id: \.item.id) { result in
                                    NavigationLink(destination: SongDetail(
                                        song: result.item,
                                        allSongs: service.songs,
                                        allAlbums: service.albums,
                                        allArtists: service.artists
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
                                    .buttonStyle(.plain) // Ensures the row doesn't look like a blue button
                                }
                            } else if selectedChart == 1 {
                                let filteredAlbums = searchResults(for: service.albums)
                                ForEach(filteredAlbums, id: \.item.id) { result in
                                    NavigationLink(destination: AlbumDetail(
                                        album: result.item,
                                        allSongs: service.songs,
                                        allAlbums: service.albums,
                                        allArtists: service.artists
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
                                let filteredArtists = searchResults(for: service.artists)
                                ForEach(filteredArtists, id: \.item.id) { result in
                                    NavigationLink(destination: ArtistDetail(
                                        artist: result.item,
                                        allSongs: service.songs,
                                        allAlbums: service.albums,
                                        allArtists: service.artists,
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
            .navigationTitle("Charty")
            .searchable(text: $searchText, prompt: "Search...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSyncSheet = true
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath.circle")
                            .symbolEffect(.rotate, isActive: service.isSyncing)
                            .foregroundStyle(service.isOutOfDate ? .orange : .accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingSyncSheet) {
                SyncStatusView(service: service)
            }
            .task {
                await service.loadOnLaunch()
            }
        }
    }
    
    /// This helper takes a full list, attaches the rank (index + 1),
    /// and then filters it based on search text.
    private func searchResults<T>(for items: [T]) -> [(rank: Int, item: T)] {
        // Attach the rank first based on the original sorted order
        let rankedItems = items.enumerated().map { (index: $0, item: $1) }
        
        // If search is empty, return the standard limited list
        if searchText.isEmpty {
            let limit = (selectedChart == 0) ? 500 : 100
            return rankedItems.prefix(limit).map { ($0.index + 1, $0.item) }
        }
        
        // Otherwise, search through the ENTIRE list
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
