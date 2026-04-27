import Foundation
import CryptoKit

class CosmosDBService {
    private let accountName: String
    private let masterKey: String
    private let databaseId: String
    private let containerId: String
    
    init(accountName: String, masterKey: String, databaseId: String, containerId: String) {
        self.accountName = accountName
        self.masterKey = masterKey
        self.databaseId = databaseId
        self.containerId = containerId
    }
    
    func getDocument<T: Decodable>(id: String, partitionKey: String) async throws -> T {
        let resourcePath = "dbs/\(databaseId)/colls/\(containerId)/docs/\(id)"
        let url = URL(string: "https://\(accountName).documents.azure.com/\(resourcePath)")!
        
        let dateString = HTTPDateString()
        let authHeader = generateAuthToken(verb: "get", resourceType: "docs", resourceId: resourcePath, date: dateString)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(authHeader, forHTTPHeaderField: "Authorization")
        request.addValue(dateString, forHTTPHeaderField: "x-ms-date")
        request.addValue("2018-12-31", forHTTPHeaderField: "x-ms-version")
        request.addValue(partitionKey, forHTTPHeaderField: "x-ms-documentdb-partitionkey")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "CosmosError", code: (response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }

    func upsertDocument<T: Encodable>(_ document: T, partitionKey: String) async throws {
        let url = URL(string: "https://\(accountName).documents.azure.com/dbs/\(databaseId)/colls/\(containerId)/docs")!
        
        let dateString = HTTPDateString()
        let authHeader = generateAuthToken(verb: "post", resourceType: "docs", resourceId: "dbs/\(databaseId)/colls/\(containerId)", date: dateString)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(authHeader, forHTTPHeaderField: "Authorization")
        request.addValue(dateString, forHTTPHeaderField: "x-ms-date")
        request.addValue("2018-12-31", forHTTPHeaderField: "x-ms-version")
        request.addValue("true", forHTTPHeaderField: "x-ms-documentdb-is-upsert") // Crucial for Weekly updates
        request.addValue("[\"\(partitionKey)\"]", forHTTPHeaderField: "x-ms-documentdb-partitionkey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try JSONEncoder().encode(document)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw NSError(domain: "CosmosError", code: httpResponse.statusCode)
        }
    }

    private func generateAuthToken(verb: String, resourceType: String, resourceId: String, date: String) -> String {
        let stringToSign = "\(verb.lowercased())\n\(resourceType.lowercased())\n\(resourceId)\n\(date.lowercased())\n\n"
        let key = Data(base64Encoded: masterKey)!
        let signature = HMAC<SHA256>.authenticationCode(for: Data(stringToSign.utf8), using: SymmetricKey(data: key))
        let signatureBase64 = Data(signature).base64EncodedString()
        
        let authString = "type=master&ver=1.0&sig=\(signatureBase64)"
        return authString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }

    private func HTTPDateString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.dateFormat = "E, dd MMM yyyy HH:mm:ss"
        return formatter.string(from: Date()) + " GMT"
    }
}
