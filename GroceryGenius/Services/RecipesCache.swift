import Foundation

final class RecipesCache {
    private let fileName = "recipes_cache.json"

    private var url: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(fileName)
    }

    func load() -> [Recipe] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Recipe].self, from: data)) ?? []
    }

    func save(_ recipes: [Recipe]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(recipes) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}
