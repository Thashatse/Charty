import SwiftUI
import _MusicKit_SwiftUI

struct NowPlaying: View {
    let song: SongItem
    let isPlaying: Bool
    let allSongs: [SongItem]
    let allAlbums: [AlbumItem]
    let allArtists: [ArtistItem]

    var body: some View {
        NavigationLink(destination: SongDetail(
            song: song,
            allSongs: allSongs,
            allAlbums: allAlbums,
            allArtists: allArtists
        )) {
            HStack(spacing: 12) {
                if let artwork = song.artwork {
                    ArtworkImage(artwork, width: 36, height: 36)
                        .cornerRadius(6)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(song.title)
                        .font(.subheadline).fontWeight(.semibold).lineLimit(1)
                    Text(song.artist)
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                AnimatedWaveform(isPlaying: isPlaying)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
            .padding(.horizontal, 12)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
