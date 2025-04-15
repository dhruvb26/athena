//
//  AIManager.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/12/25.
//

import Foundation
import Logging

class AIManager {
    private let logger = Logger(label: "athena.AIManager")

    func makeGeminiCall(_ content: String, _ notificationType: NotificationType) {
        guard
            let endpoint = URL(
                string:
                "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
            )
        else {
            logger.error("Error: Invalid Gemini API endpoint URL")
            return
        }

        let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String

        guard let snippetPrompt = loadPrompt(from: "SnippetPrompt"),
              let questionPrompt = loadPrompt(from: "QuestionPrompt")
        else {
            logger.error("Failed to load prompts")
            return
        }

        let prompt = notificationType == .snippet ? snippetPrompt : questionPrompt
        let finalText = prompt + content

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        [
                            "text": finalText,
                        ],
                    ],
                ],
            ],
        ]

        do {
            let requestJsonData = try JSONSerialization.data(withJSONObject: requestBody)

            var urlComponents = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
            urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]

            var request = URLRequest(url: urlComponents.url!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = requestJsonData

            let task = URLSession.shared.dataTask(with: request) { [self] data, response, error in
                if let error {
                    logger.error("Error making Gemini request: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    logger.error("Error: Invalid Gemini response")
                    return
                }

                guard httpResponse.statusCode == 200, let data else {
                    logger.error("Error: Gemini HTTP status code \(httpResponse.statusCode)")
                    return
                }

                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data)
                        as? [String: Any],
                        let candidates = jsonResponse["candidates"] as? [[String: Any]],
                        let firstCandidate = candidates.first,
                        let content = firstCandidate["content"] as? [String: Any],
                        let parts = content["parts"] as? [[String: Any]],
                        let firstPart = parts.first,
                        let text = firstPart["text"] as? String
                    {
                        let parsedText = cleanContent(text)
                        logger.info("Response from Gemini: \(parsedText)")
                    }
                } catch {
                    logger.error(
                        "Error parsing Gemini response: \(error.localizedDescription)")
                }
            }

            task.resume()
        } catch {
            logger.error("Error preparing Gemini request: \(error.localizedDescription)")
        }
    }

    private func loadPrompt(from filename: String) -> String? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "txt") else {
            logger.error("Failed to find prompt file")
            return nil
        }

        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            logger.error("Error reading prompt: \(error.localizedDescription)")
            return nil
        }
    }

    private func cleanContent(_ response: String) -> String {
        var cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.hasPrefix("```") {
            if let firstNewline = cleaned.range(of: "\n") {
                cleaned = String(cleaned[firstNewline.upperBound...])
            }
            if let lastBackticks = cleaned.range(of: "```", options: .backwards) {
                cleaned = String(cleaned[..<lastBackticks.lowerBound])
            }
        }

        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.lowercased().hasPrefix("json") {
            cleaned = String(cleaned.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return cleaned
    }
}
