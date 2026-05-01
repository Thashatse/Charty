//
//  ChartyApp.swift
//  Charty
//
//  Created by Tefo Ntsako Hashatse on 2026/04/25.
//

import SwiftUI

@main
struct ChartyApp: App {
    @StateObject private var cosmosService: CosmosDBService
    @StateObject private var chartService: ChartService
    @StateObject private var appleMusicService: AppleMusicService
    
    init() {
        let cosmos = CosmosDBService()
        let charts = ChartService(cosmos: cosmos)
        let music = AppleMusicService(chartService: charts)
        
        _cosmosService = StateObject(wrappedValue: cosmos)
        _chartService = StateObject(wrappedValue: charts)
        _appleMusicService = StateObject(wrappedValue: music)
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ZStack(alignment: .bottom) {
                    ContentView()
                    
                    if let currentSong = appleMusicService.nowPlayingSong {
                        NowPlaying(
                            song: currentSong,
                            isPlaying: appleMusicService.isPlaying,
                            allSongs: appleMusicService.songs,
                            allAlbums: appleMusicService.albums,
                            allArtists: appleMusicService.artists
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 60)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(), value: currentSong.id)
                    }
                }
            }
            .environmentObject(cosmosService)
            .environmentObject(chartService)
            .environmentObject(appleMusicService)
        }
    }
}
