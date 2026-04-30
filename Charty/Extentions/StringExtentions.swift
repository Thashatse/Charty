import Foundation

extension String {
    var normalizedForSearch: String {
        self.folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespaces)
    }
}
