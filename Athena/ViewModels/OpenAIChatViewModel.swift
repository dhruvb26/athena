//
//  OpenAIChatViewModel.swift
//  Athena
//
//  Created by Claude on 5/29/25.
//

import Combine
import Foundation

class OpenAIChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String? = nil

    private let apiKey = "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"
    private let openAIURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private var cancellables = Set<AnyCancellable>()

    enum APIError: Error {
        case networkError(Error)
        case invalidResponse
        case invalidData
        case serverError(Int)

        var localizedDescription: String {
            switch self {
            case let .networkError(error):
                "Network error: \(error.localizedDescription)"
            case .invalidResponse:
                "Invalid response from server"
            case .invalidData:
                "Invalid data received"
            case let .serverError(code):
                "Server error with code: \(code)"
            }
        }
    }

    struct ChatMessage: Identifiable {
        let id = UUID()
        var content: String
        let isUser: Bool
        var date: Date = .init()
    }

    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ChatMessage(content: inputMessage, isUser: true)
        messages.append(userMessage)
        inputMessage = ""

        isLoading = true
        error = nil

        var request = URLRequest(url: openAIURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let messageHistory = messages.map { message in
            ["role": message.isUser ? "user" : "assistant", "content": message.content]
        }

        let requestBody: [String: Any] = [
            "model": "gpt-4", // Replace with valid model name
            "messages": messageHistory,
            "stream": true,
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            self.error = "Failed to encode request: \(error.localizedDescription)"
            isLoading = false
            return
        }

        DispatchQueue.main.async {
            self.messages.append(ChatMessage(content: "", isUser: false))
        }

        var responseText = ""

        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }

                switch httpResponse.statusCode {
                case 200 ... 299:
                    return data
                default:
                    throw APIError.serverError(httpResponse.statusCode)
                }
            }
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    DispatchQueue.main.async {
                        self.isLoading = false

                        if case let .failure(error) = completion {
                            self.error = error.localizedDescription

                            if let lastMessage = self.messages.last, !lastMessage.isUser {
                                self.messages.removeLast()
                            }
                        }
                    }
                },
                receiveValue: { [weak self] data in
                    guard let self else { return }
                    let dataString = String(data: data, encoding: .utf8) ?? ""

                    for line in dataString.split(separator: "\n") {
                        if line.hasPrefix("data: ") {
                            let jsonString = line.dropFirst(6)

                            if jsonString == "[DONE]" {
                                continue
                            }

                            if let data = jsonString.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let choices = json["choices"] as? [[String: Any]],
                               let choice = choices.first,
                               let delta = choice["delta"] as? [String: Any],
                               let content = delta["content"] as? String
                            {
                                responseText += content

                                DispatchQueue.main.async {
                                    if let lastIndex = self.messages.lastIndex(where: { !$0.isUser }) {
                                        self.messages[lastIndex].content += content
                                    }
                                }
                            }
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }

    func clearChat() {
        messages.removeAll()
        error = nil
    }
}
