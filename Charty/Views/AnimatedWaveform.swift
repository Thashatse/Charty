import SwiftUI

struct AnimatedWaveform: View {
    let isPlaying: Bool

    private let durations: [Double] = [0.5, 0.35, 0.6, 0.4, 0.55]
    private let delays: [Double] = [0.0, 0.1, 0.2, 0.05, 0.15]
    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            HStack(alignment: .center, spacing: 2) {
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isPlaying ? Color.blue : Color.secondary)
                        .frame(width: 3, height: barHeight(index: i, date: timeline.date))
                }
            }
            .frame(width: 24, height: 18)
        }
    }

    private func barHeight(index: Int, date: Date) -> CGFloat {
        guard isPlaying else { return 4 }
        let t = date.timeIntervalSince(startDate) + delays[index]
        let sine = (sin(t * .pi * 2 / durations[index]) + 1) / 2
        return 4 + sine * 14
    }
}
