import Foundation

enum OllamaClientError: LocalizedError {
    case invalidURL
    case connectionFailed
    case badResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "OllamaのURLが正しくありません"
        case .connectionFailed:
            return "Ollamaに接続できません"
        case .badResponse:
            return "Ollamaから応答を受け取れませんでした"
        }
    }
}

struct OllamaClient {
    var config: AppConfig

    func checkConnection() async -> Bool {
        guard let url = URL(string: "\(config.ollamaBaseUrl)/api/tags") else {
            return false
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 3

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    func streamChat(messages: [Message]) async throws -> AsyncThrowingStream<String, Error> {
        guard let url = URL(string: "\(config.ollamaBaseUrl)/api/chat") else {
            throw OllamaClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": config.ollamaModel,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] },
            "stream": true
        ])

        let (bytes, response): (URLSession.AsyncBytes, URLResponse)
        do {
            (bytes, response) = try await URLSession.shared.bytes(for: request)
        } catch {
            throw OllamaClientError.connectionFailed
        }

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw OllamaClientError.badResponse
        }

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await line in bytes.lines {
                        guard
                            !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                            let data = line.data(using: .utf8),
                            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                        else {
                            continue
                        }

                        if
                            let message = object["message"] as? [String: Any],
                            let content = message["content"] as? String,
                            !content.isEmpty
                        {
                            continuation.yield(content)
                        }

                        if object["done"] as? Bool == true {
                            break
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func generateText(messages: [Message]) async throws -> String {
        guard let url = URL(string: "\(config.ollamaBaseUrl)/api/chat") else {
            throw OllamaClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": config.ollamaModel,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] },
            "stream": false
        ])

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw OllamaClientError.connectionFailed
        }

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw OllamaClientError.badResponse
        }

        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let message = object?["message"] as? [String: Any]
        return message?["content"] as? String ?? ""
    }
}

