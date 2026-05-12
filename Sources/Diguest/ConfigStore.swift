import Foundation

struct ConfigStore {
    private let fileManager = FileManager.default

    var configDirectory: URL {
        fileManager.homeDirectoryForCurrentUser.appendingPathComponent("diguest", isDirectory: true)
    }

    var configURL: URL {
        configDirectory.appendingPathComponent("config.json")
    }

    func load() -> AppConfig {
        guard let data = try? Data(contentsOf: configURL) else {
            return .defaults
        }

        return (try? JSONDecoder().decode(AppConfig.self, from: data)) ?? .defaults
    }

    func save(_ config: AppConfig) throws {
        try fileManager.createDirectory(at: configDirectory, withIntermediateDirectories: true)
        let data = try JSONEncoder.pretty.encode(config)
        try data.write(to: configURL, options: [.atomic])
    }
}

extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

