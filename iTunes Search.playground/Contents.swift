import UIKit

// MARK: - Properties
let query = [
    "term": "My Bad",
    "media": "music"
]

var urlComponents = URLComponents(string: "https://itunes.apple.com/search?")!
urlComponents.queryItems = query.map{ URLQueryItem(name: $0.key, value: $0.value) }

// MARK: - Clousure
Task {
    let (data, response) = try await URLSession.shared.data(from: urlComponents.url!)
    
    if let httpResponse = response as? HTTPURLResponse,
       httpResponse.statusCode == 200,
       let stringData = String(data: data, encoding: .utf8) {
        print(stringData)
    }
}

