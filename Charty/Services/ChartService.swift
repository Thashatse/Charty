import Foundation
import Combine

@MainActor
class ChartService: ObservableObject {
    @Published var isBuilding: Bool = false
    @Published var lastBuilt: Date? = nil
    @Published var buildError: String? = nil
    
    private let cosmos: CosmosDBService
    private let documentId = "user1"
    private let cacheKey = "charty_chart_document2"
    private let lastBuiltKey = "charty_chart_last_built2"
    private let buildIntervalHours: Double = 12
    
    init(cosmos: CosmosDBService) {
        self.cosmos = cosmos
        lastBuilt = UserDefaults.standard.object(forKey: lastBuiltKey) as? Date
    }
    
    // MARK: - Public API
    
    var isDue: Bool {
        guard let last = lastBuilt else { return true }
        return Date().timeIntervalSince(last) > buildIntervalHours * 3600
    }
    
    func buildIfNeeded(songs: [SongItem], albums: [AlbumItem], artists: [ArtistItem]) async {
        guard isDue else { return }
        await build(songs: songs, albums: albums, artists: artists)
    }
    
    func build(songs: [SongItem], albums: [AlbumItem], artists: [ArtistItem]) async {
        guard !isBuilding else { return }
        isBuilding = true
        buildError = nil
        defer { isBuilding = false }
        
        let period = PeriodHelper.getCurrentPeriod()
        
        // Load or create base document
        var document = await loadFromCache() ?? makeEmptyDocument(periodId: period.id,
                                                                  start: period.start,
                                                                  end: period.end)
        
        // Ensure the current period exists in Periods array
        if !document.Periods.contains(where: { $0.id == period.id }) {
            document.Periods.append(Period(id: period.id, start: period.start, end: period.end))
        }
        
        
        // Build / merge play data
        document.PlayData = buildPlayData(songs: songs, periodId: period.id, periodStart: period.start, existing: document.PlayData)
        
        buildingChart = buildChartData(from: document.PlayData, songs: songs, periodId: period.id)
        
        // Persist
        saveToCache(document)
        
        let now = Date()
        lastBuilt = now
        UserDefaults.standard.set(now, forKey: lastBuiltKey)
        
        guard cosmos.isConfigured else {
            print("Cosmos DB not configured, skipping cloud sync.")
            return
        }
        do {
            try await cosmos.upsertDocument(document, partitionKey: document.userid)
        } catch {
            print(error)
            buildError = "Cosmos sync failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Chart Data Builder
    
    @Published var buildingChart: BuildingChartData = BuildingChartData()
    
    struct BuildingChartData {
        var singles: [(rank: Int, songId: String, plays: Int)] = []
        var albums: [(rank: Int, albumId: String, plays: Int)] = []
        var artists: [(rank: Int, artistId: String, plays: Int)] = []
    }
    
    private func buildChartData(from playData: [SongPlay], songs: [SongItem], periodId: String) -> BuildingChartData {
        // Singles — sum PeriodPlays per song
        let singlesRaw = playData.compactMap { play -> (String, Int)? in
            guard let history = play.PlayHistory.first(where: { $0.PeriodId == periodId }),
                  let plays = Int(history.PeriodPlays), plays > 0
            else { return nil }
            return (play.SongId, plays)
        }
            .sorted { $0.1 > $1.1 }
            .prefix(40)
        
        // Albums — aggregate PeriodPlays by AlbumId, requiring at least 4 unique song
        var libraryAlbumCounts: [String: Set<String>] = [:]
        for song in songs {
            let aId = song.albumID ?? song.albumTitle
            libraryAlbumCounts[aId, default: Set<String>()].insert(song.id)
        }
        var albumTotals: [String: Int] = [:]
        for play in playData {
            let aId = play.AlbumId
            
            let uniqueSongCount = libraryAlbumCounts[aId]?.count ?? 0
            guard uniqueSongCount >= 3 else { continue }
            
            guard let history = play.PlayHistory.first(where: { $0.PeriodId == periodId }),
                  let plays = Int(history.PeriodPlays), plays > 0 else { continue }
                  
            albumTotals[aId, default: 0] += plays
        }
        let albumsRaw = albumTotals.sorted { $0.value > $1.value }.prefix(40)
        
        // Artists — aggregate PeriodPlays by ArtistId
        var artistTotals: [String: Int] = [:]
        for play in playData {
            guard let history = play.PlayHistory.first(where: { $0.PeriodId == periodId }),
                  let plays = Int(history.PeriodPlays), plays > 0 else { continue }
            artistTotals[play.ArtistId, default: 0] += plays
        }
        let artistsRaw = artistTotals.sorted { $0.value > $1.value }.prefix(40)
        
        return BuildingChartData(
            singles: singlesRaw.enumerated().map { (rank: $0.offset + 1, songId: $0.element.0, plays: $0.element.1) },
            albums: albumsRaw.enumerated().map { (rank: $0.offset + 1, albumId: $0.element.key, plays: $0.element.value) },
            artists: artistsRaw.enumerated().map { (rank: $0.offset + 1, artistId: $0.element.key, plays: $0.element.value) }
        )
    }
    
    // MARK: - Play Data Builder
    
    private func buildPlayData(songs: [SongItem],
                               periodId: String,
                               periodStart: String,
                               existing: [SongPlay]) -> [SongPlay] {
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_ZA")
        let today = df.string(from: Date())
        let periodStartDate = PeriodHelper.date(from: periodStart)
        
        // Index existing entries for quick lookup / mutation
        var index: [String: SongPlay] = Dictionary(
            uniqueKeysWithValues: existing.map { ($0.SongId, $0) }
        )
        
        for song in songs {
            let songId = song.id
            let albumId = song.albumID ?? song.albumTitle
            let artistId = song.artistID ?? song.artist
            
            var entry = index[songId] ?? SongPlay(
                SongId: songId,
                ArtistId: artistId,
                AlbumId: albumId,
                PlayHistory: []
            )
            
            let totalPlays = song.playCount
            
            // Find or create history record for the current period
            if let histIdx = entry.PlayHistory.firstIndex(where: { $0.PeriodId == periodId }) {
                var history = entry.PlayHistory[histIdx]
                let prevTotal = Int(history.TotalPlays) ?? 0
                
                // 1. Calculate the delta
                let delta = totalPlays - prevTotal
                
                if delta < 0 {
                    // SCENARIO: MusicKit play count dropped (Sync issue)
                    // We update the TotalPlays reference so we can start counting
                    // from the new floor immediately, but we don't change PeriodPlays.
                    history.TotalPlays = String(totalPlays)
                } else if delta > 0 {
                    // SCENARIO: Normal play increase
                    if let dayIdx = history.PerDayPlays.firstIndex(where: { $0.date == today }) {
                        let existingDayPlays = Int(history.PerDayPlays[dayIdx].plays) ?? 0
                        history.PerDayPlays[dayIdx].plays = String(existingDayPlays + delta)
                    } else {
                        history.PerDayPlays.append(DayPlays(date: today, plays: String(delta)))
                    }
                    
                    // Recalculate totals
                    let periodTotal = history.PerDayPlays.compactMap { Int($0.plays) }.reduce(0, +)
                    history.PeriodPlays = String(periodTotal)
                    history.TotalPlays = String(totalPlays)
                }
                
                entry.PlayHistory[histIdx] = history
            } else {
                // ── First time we see this song in this period ──────────────────
                // We must determine how many of the all-time plays are attributable
                // to THIS period before we can record anything meaningful.
                //
                // Three cases, in order of confidence:
                //
                // CASE A — lastPlayed is before the period started.
                //   All plays are historical. Nothing happened this period.
                //   → periodPlays = 0, dayPlays = 0
                //
                // CASE B — lastPlayed is inside the period BUT libraryAddedDate
                //   is before the period. The song existed before the week began so
                //   we have no way to know how many of the total plays fall inside
                //   the window vs before it.
                //   → periodPlays = 0, dayPlays = 0
                //
                // CASE C — Both lastPlayed AND libraryAddedDate are inside the period.
                //   The song was added this week so every single play must have
                //   happened this period.
                //   → periodPlays = totalPlays, dayPlays = totalPlays
                //
                // In every case we store totalPlays so the delta logic works correctly
                // on subsequent runs without any special-casing.
                
                let lastPlayedDate = song.lastPlayed ?? .distantPast
                let lastPlayedInPeriod = lastPlayedDate >= periodStartDate
                
                let addedDate = song.libraryAddedDate ?? .distantPast
                let addedInPeriod = addedDate >= periodStartDate
                
                let attributablePlays: Int
                if !lastPlayedInPeriod {
                    // Case A: Last play was before 01/05.
                    // Even if addedInPeriod is true (rare), no plays happened this week.
                    attributablePlays = 0
                } else if !addedInPeriod {
                    // Case B: Played this week, but added before this week.
                    // We can't know the split, so we start at 0 and track deltas from here.
                    attributablePlays = 0
                } else {
                    // Case C: Added AND played this week.
                    // Every single play is guaranteed to be within 01/05 - 07/05.
                    attributablePlays = totalPlays
                }
                
                let dayPlays = DayPlays(date: today, plays: String(attributablePlays))
                let history = PlayHistory(
                    PeriodId: periodId,
                    PeriodPlays: String(attributablePlays),
                    TotalPlays: String(totalPlays),
                    PerDayPlays: [dayPlays]
                )
                entry.PlayHistory.append(history)
            }
            
            index[songId] = entry
        }
        
        return Array(index.values).sorted { $0.SongId < $1.SongId }
    }
    
    // MARK: - Document Factory
    
    private func makeEmptyDocument(periodId: String, start: String, end: String) -> ChartDocument {
        let emptyCategory = ChartCategory(Weekly: [])
        let emptyChartData = Chart(albums: emptyCategory, artist: emptyCategory, single: emptyCategory)
        return ChartDocument(
            id: documentId,
            userid: documentId,
            ChartData: [emptyChartData],
            PlayData: [],
            Periods: [Period(id: periodId, start: start, end: end)]
        )
    }
    
    // MARK: - Cache
    
    private func saveToCache(_ document: ChartDocument) {
        if let data = try? JSONEncoder().encode(document) {
            writeToFile(data: data, key: cacheKey)
        }
    }
    
    func loadFromCache() async -> ChartDocument? {
        if let localData = readFromFile(key: cacheKey),
           let decoded = try? JSONDecoder().decode(ChartDocument.self, from: localData) {
            return decoded
        }
        
        guard cosmos.isConfigured else {
            print("No local cache and Cosmos not configured.")
            return nil
        }
        
        do {
            if let cloudDoc: ChartDocument = try await cosmos.getDocument(id: documentId, partitionKey: documentId) {
                saveToCache(cloudDoc)
                return cloudDoc
            }
        } catch {
            print("Cosmos fallback failed: \(error)")
        }
        
        return nil
    }
}
