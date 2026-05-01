import Foundation

public func getFileURL(for key: String) -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0].appendingPathComponent("\(key).json")
}

public func writeToFile(data: Data, key: String) {
    let url = getFileURL(for: key)
    do {
        try data.write(to: url, options: .atomic)
    } catch {
        print("Failed to write \(key) to disk: \(error)")
    }
}

public func readFromFile(key: String) -> Data? {
    let url = getFileURL(for: key)
    return try? Data(contentsOf: url)
}
