import SwiftUI
import MusicKit

struct ChartRow: View {
    @EnvironmentObject private var service: AppleMusicService
    
    let rank: Int
    let title: String
    let subtitle: String
    let stat: Int
    let award: Award?
    let artwork: Artwork?
    var isNowPlaying: Bool = false
    
    private var formattedStat: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " " // Set the space here
        return formatter.string(from: NSNumber(value: stat)) ?? "\(stat)"
    }
    
    var body: some View {
        HStack {
            Text("\(rank)")
                .font(.system(.body, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .frame(width: 35, alignment: .leading)
            
            Group {
                if let artwork = artwork {
                    ArtworkImage(artwork, width: 44, height: 44)
                        .cornerRadius(6)
                }
            }
            
            VStack(alignment: .leading) {
                HStack(spacing: 8) {
                    Text(title)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    if let award = award {
                        Text(award.rawValue) // Display "G", "P", or "d"
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(award.color.opacity(0.2))
                            .foregroundStyle(award.color)
                            .cornerRadius(4)
                    }
                }
                
                if subtitle.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if isNowPlaying {
                AnimatedWaveform(isPlaying: service.isPlaying)
                    .frame(width: 25, alignment: .leading)
            }
            
            Text(formattedStat)
                .font(.subheadline)
                .foregroundStyle(.blue)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 2)
    }
}
