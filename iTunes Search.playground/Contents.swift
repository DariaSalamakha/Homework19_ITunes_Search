import UIKit

// MARK: - Properties
let query = [
    "term": "My Bad",
    "media": "music"
]

var urlComponents = URLComponents(string: "https://itunes.apple.com/search?")!
urlComponents.queryItems = query.map{ URLQueryItem(name: $0.key, value: $0.value) }

// MARK: - Extension
extension Data {
    func prettyPrintedJSONString() {
        guard
            let jsonObject = try?
                JSONSerialization.jsonObject(with: self,
                                             options: []),
            let jsonData = try?
                JSONSerialization.data(withJSONObject:
                                        jsonObject, options: [.prettyPrinted]),
            let prettyJSONString = String(data: jsonData,
                                          encoding: .utf8) else {
                print("Failed to read JSON Object.")
                return
            }
        print(prettyJSONString)
    }
}

// MARK: - Clousure
Task {
    let (data, response) = try await URLSession.shared.data(from: urlComponents.url!)
    
    if let httpResponse = response as? HTTPURLResponse,
       httpResponse.statusCode == 200 {
        data.prettyPrintedJSONString()
    }
}

// MARK: - Structures
struct StoreItem: Codable {
    var name: String
    var artist: String
    var description: String
    var kind: String
    var artworkURL: URL
    
    enum CodingKeys: String, CodingKey {
        case name = "trackName"
        case artist = "artistName"
        case kind
        case description = "longDescription"
        case artworkURL = "artworkUrl100"
    }
    
    enum AdditionalKeys: CodingKey {
        case longDescription
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: CodingKeys.name)
        artist = try values.decode(String.self, forKey: CodingKeys.artist)
        kind = try values.decode(String.self, forKey: CodingKeys.kind)
        artworkURL = try values.decode(URL.self, forKey:
           CodingKeys.artworkURL)

        if let description = try? values.decode(String.self,
           forKey: CodingKeys.description) {
            self.description = description
        } else {
            let additionalValues = try decoder.container(keyedBy:
               AdditionalKeys.self)
            description = (try? additionalValues.decode(String.self,
               forKey: AdditionalKeys.longDescription)) ?? ""
        }
    }
}

struct SearchResponse: Codable {
    let results: [StoreItem]
}

// MARK: - Enumeration
enum StoreItemError: Error, LocalizedError {
    case itemsNotFound
}

// MARK: - Methods
func fetchItems(matching query: [String: String]) async
   throws -> [StoreItem] {
    var urlComponents = URLComponents(string:
       "https://itunes.apple.com/search")!
    urlComponents.queryItems = query.map { URLQueryItem(name: $0.key,
       value: $0.value) }
    let (data, response) = try await URLSession.shared.data(from:
       urlComponents.url!)
        guard let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 200 else {
        throw StoreItemError.itemsNotFound
    }

    let decoder = JSONDecoder()
    let searchResponse = try decoder.decode(SearchResponse.self,
       from: data)

    return searchResponse.results
}

// MARK: - Testing
Task {
    do {
        let storeItems = try await fetchItems(matching: query)
        storeItems.forEach { item in
            print("""
            Name: \(item.name)
            Artist: \(item.artist)
            Kind: \(item.kind)
            Description: \(item.description)
            Artwork URL: \(item.artworkURL)


            """)
        }
    } catch {
        print(error)
    }
}
