//
//  ChartyApp.swift
//  Charty
//
//  Created by Tefo Ntsako Hashatse on 2026/04/25.
//

import SwiftUI

@main
struct ChartyApp: App {
    @StateObject private var service = AppleMusicService()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ZStack(alignment: .bottom) {
                    ContentView()
                        .environmentObject(service)
                    
                    if let currentSong = service.nowPlayingSong {
                        NowPlaying(
                            song: currentSong,
                            isPlaying: service.isPlaying,
                            allSongs: service.songs,
                            allAlbums: service.albums,
                            allArtists: service.artists
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 6)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(), value: currentSong.id)
                    }
                }
            }
            .environmentObject(service) 
        }
    }
}
