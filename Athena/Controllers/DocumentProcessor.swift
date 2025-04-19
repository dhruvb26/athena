//
//  DocumentProcessor.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/12/25.
//

import FirebaseFirestore
import Foundation
import Logging

class DocumentProcessor: ObservableObject {
    private let aiManager = AIManager()
    private let logger = Logger(label: "athena.DocumentProcessor")
    private let quizItemManager = QuizItemManager()
    private let db = Firestore.firestore()

    func processDocument(_ url: String, _ course: Course) async {
        do {
            let extractedText = try await convertToText(url)
            let geminiResponse = try await aiManager.makeGeminiCall(
                extractedText, course.notificationType
            )

            let quizItems = parseAndCleanQuizItems(from: geminiResponse, for: course)

            for item in quizItems {
                do {
                    try await quizItemManager.saveQuizItemToDB(item)
                } catch {
                    logger.error("Failed to save: \(error)")
                }
            }
        } catch {
            logger.error("Failed to process document: \(error.localizedDescription)")
        }
    }

    private func parseAndCleanQuizItems(from geminiResponse: String, for course: Course) -> [QuizItem] {
        guard let data = geminiResponse.data(using: .utf8) else {
            logger.error("Failed to convert geminiResponse to Data.")
            return []
        }

        guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            logger.error("Failed to parse JSON array from data.")
            return []
        }

        let quizItems: [QuizItem] = jsonArray.compactMap { dict in
            var mutableDict = dict

            if course.notificationType == .question {
                mutableDict["answered"] = false
            }
            mutableDict["scheduled"] = false
            mutableDict["type"] = course.notificationType.rawValue
            mutableDict["courseId"] = course.docID
            mutableDict["docID"] = UUID().uuidString

            guard let jsonData = try? JSONSerialization.data(withJSONObject: mutableDict) else {
                return nil
            }

            let decoder = JSONDecoder()
            do {
                let quizItem = try decoder.decode(QuizItem.self, from: jsonData)
                return quizItem
            } catch {
                return nil
            }
        }

        return quizItems
    }

    private func convertToText(_ url: String) async throws -> String {
        // make the api call -> custom endpoint
        guard
            let baseURL = URL(
                string: "https://athena-api-eight.vercel.app/ocr")
        else {
            logger.error("Failed to construct base URL")
            throw NSError(
                domain: "DocumentProcessor", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid base URL"]
            )
        }

        let reqBody = ["url": url]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: reqBody)

            var request = URLRequest(url: baseURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200 ... 299).contains(httpResponse.statusCode)
            else {
                throw NSError(
                    domain: "DocumentProcessor", code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid server response"]
                )
            }

            // parse the response and clean the OCR content
            guard let jsonResult = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let pages = jsonResult["pages"] as? [[String: Any]]
            else {
                throw NSError(
                    domain: "DocumentProcessor", code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]
                )
            }

            // process pages to extract only index, markdown and images
            var cleanedPages: [[String: Any]] = []

            for page in pages {
                var cleanedPage: [String: Any] = [:]

                if let index = page["index"] as? Int {
                    cleanedPage["index"] = index
                }

                if let markdown = page["markdown"] as? String {
                    cleanedPage["markdown"] = markdown
                }

                if let images = page["images"] as? [[String: Any]] {
                    cleanedPage["images"] = images
                }

                cleanedPages.append(cleanedPage)
            }

            // convert the cleaned pages array to JSON
            let cleanedData = try JSONSerialization.data(
                withJSONObject: cleanedPages, options: .prettyPrinted
            )
            guard let cleanedContent = String(data: cleanedData, encoding: .utf8) else {
                throw NSError(
                    domain: "DocumentProcessor", code: 4,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Failed to convert cleaned pages to string",
                    ]
                )
            }

            return cleanedContent

        } catch {
            logger.error("Error processing document: \(error.localizedDescription)")
            throw error
        }
    }
}
