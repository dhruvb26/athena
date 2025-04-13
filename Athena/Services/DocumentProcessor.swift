//
//  DocumentProcessor.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/12/25.
//

import Foundation
import Logging

class DocumentProcessor: ObservableObject {
    private let logger = Logger(label: "athena.DocumentProcessor")
    private let aiManager = AIManager()

    func processDocument(_ url: String, _ course: Course) async {
//        let courseID = course.docID
        let notificationType = course.notificationType

        do {
            let extractedText = try await convertToText(url)
            // TODO: Process the extracted text further based on courseID and notificationType
            aiManager.makeGeminiCall(extractedText, notificationType)

        } catch {
            logger.error("Failed to process document: \(error.localizedDescription)")
        }
    }

    func convertToText(_ url: String) async throws -> String {
        // make the api call
        guard let baseURLString = Bundle.main.infoDictionary?["API_BASE_URL"] as? String,
              let baseURL = URL(string: baseURLString)
        else {
            logger.error("Failed to construct base URL")
            throw NSError(
                domain: "DocumentProcessor", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid base URL"]
            )
        }

        let endpoint = baseURL.appendingPathComponent("ocr")
        let reqBody = ["url": url]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: reqBody)

            var request = URLRequest(url: endpoint)
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
