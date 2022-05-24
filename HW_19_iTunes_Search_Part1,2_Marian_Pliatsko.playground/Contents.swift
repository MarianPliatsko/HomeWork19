import UIKit
import Foundation

var searchingSong: [String:String] = ["term":"kalush", "media":"music"]

struct StoreItem {
    let name: String
    let artist: String
    let kind: String
    let description: String
    let url: URL
    
    enum CodingKeys: String, CodingKey {
        case name = "trackName"
        case artist = "artistName"
        case kind
        case description = "longDescription"
        case url = "trackViewUrl"
    }
}

struct SearchResponse: Codable {
    let results: [StoreItem]
}

extension StoreItem: Codable {
    
    enum AdditionalKeys: String, CodingKey {
        case longDescription = "description"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: CodingKeys.name)
        artist = try values.decode(String.self, forKey: CodingKeys.artist)
        kind = try values.decode(String.self, forKey: CodingKeys.kind)
        url = try values.decode(URL.self, forKey: CodingKeys.url)
        if let description = try? values.decode(String.self, forKey: CodingKeys.description) {
            self.description = description
        } else {
            let additionalValues = try decoder.container(keyedBy: AdditionalKeys.self)
            description = (try? additionalValues.decode(String.self, forKey: AdditionalKeys.longDescription)) ?? "No description"
        }
    }
}

enum StoreItemError: Error, LocalizedError {
    case itemsNotFound
}

func fetchItems(query: [String:String]) async throws -> [StoreItem] {
    var urlComponents = URLComponents(string: "https://itunes.apple.com/search")!
    urlComponents.queryItems = searchingSong.map {URLQueryItem(name: $0.key, value: $0.value)}
    let (data, response) = try await URLSession.shared.data(from: urlComponents.url!)
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw StoreItemError.itemsNotFound
    }
    let decoder = JSONDecoder()
    let searchResponse = try decoder.decode(SearchResponse.self, from: data)
    return searchResponse.results
}

Task {
    do {
        let storeItem = try await fetchItems(query: searchingSong)
        storeItem.forEach { item in
            print("""
    Name: \(item.name)
    Artist: \(item.artist)
    Kind: \(item.kind)
    Description: \(item.description)
    Url: \(item.url)
    
    
    
    """)
        }
    } catch {
        print("error")
    }
}
extension Data {
    func prettyPrintedJSONString() {
        guard
            let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []),
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
            let prettyJSONString = String(data: jsonData, encoding: .utf8) else {
                print("Failed to print JSON Object.")
                return
            }
        print(prettyJSONString)
    }
}





