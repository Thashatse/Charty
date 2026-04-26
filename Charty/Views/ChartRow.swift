import SwiftUI

struct ChartRow: View {
    let rank: Int
    let title: String
    let subtitle: String
    let stat: Int // Changed from String to Int

    // Custom formatter to use a space as a separator
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
            
            VStack(alignment: .leading) {
                Text(title)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(formattedStat) // Uses the space-separated string
                .font(.subheadline)
                .foregroundStyle(.blue)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 2)
    }
}
