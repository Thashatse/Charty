import SwiftUI

struct NowPlayingToolbarModifier: ViewModifier {
    @EnvironmentObject private var service: AppleMusicService
    let currentSongID: String?

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let song = service.nowPlayingSong,
                   song.id != currentSongID {
                    NavigationLink(destination: SongDetail(
                        song: song,
                        allSongs: service.songs,
                        allAlbums: service.albums,
                        allArtists: service.artists
                    )) {
                        AnimatedWaveform(isPlaying: service.isPlaying)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

extension View {
    func nowPlayingToolbar(currentSongID: String? = nil) -> some View {
        modifier(NowPlayingToolbarModifier(currentSongID: currentSongID))
    }
}
