//
//  CourseEditViewModel.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/3/25.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation
import SwiftUI

struct Snippet: Identifiable, Codable {
    var id = UUID()
    var title: String
    var body: String
    var tags: [String]

    enum CodingKeys: String, CodingKey {
        case title, body, tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        tags = try container.decode([String].self, forKey: .tags)
        id = UUID() // Generate a new UUID since it's not in the JSON
    }
}

struct SnippetsResponse: Codable {
    var snippets: [Snippet]
}

@MainActor
class CourseEditViewModel: ObservableObject {
    @Published var isUploading = false
    @Published var isDeleting = false
    @Published var uploadError: Error?

    private let firestore = Firestore.firestore()
    private let storage = Storage.storage()
    private let quizItemViewModel = QuizItemViewModel()
    private var courseId: String = ""

    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    func updateCourse(
        _ course: Course, name: String, code: String, semester: String,
        notificationType: NotificationType, difficulty: Difficulty?,
        completion: @escaping () -> Void
    ) {
        guard let courseId = course.docID else { return }
        guard let userId = currentUserId, userId == course.userId else {
            uploadError = NSError(
                domain: "Auth", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Not authorized to edit this course"]
            )
            return
        }

        let updatedData: [String: Any] = [
            "name": name,
            "code": code,
            "semester": semester,
            "notificationType": notificationType.rawValue,
            "difficulty": difficulty?.rawValue as Any,
        ]

        firestore.collection("courses").document(courseId).updateData(updatedData) { error in
            if let error {
                self.uploadError = error
            } else {
                completion()
            }
        }
    }

    func uploadDocument(
        for course: Course, fileURL: URL, title: String, completion: @escaping () -> Void
    ) {
        guard course.docID != nil else { return }
        guard let userId = currentUserId, userId == course.userId else {
            uploadError = NSError(
                domain: "Auth", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Not authorized to edit this course"]
            )
            return
        }

        isUploading = true

        guard fileURL.startAccessingSecurityScopedResource() else {
            uploadError = NSError(
                domain: "Access", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Can't access file"]
            )
            isUploading = false
            return
        }

        defer { fileURL.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: fileURL)
            let ref = storage.reference().child("docs/\(title)_\(UUID().uuidString)")
            ref.putData(data, metadata: nil) { _, error in
                self.isUploading = false

                if let error {
                    self.uploadError = error
                    return
                }

                ref.downloadURL { url, error in
                    if let error {
                        self.uploadError = error
                        return
                    }

                    guard let url else { return }
                    let document = Document(
                        title: title, url: url.absoluteString
                    )
                    self.addDocumentReference(
                        to: course, document: document,
                        completion: {
                            // Call processDocument with the uploaded file's URL
                            self.processDocument(
                                url: url.absoluteString, courseID: course.docID ?? ""
                            )
                            completion()
                        }
                    )
                }
            }
        } catch {
            isUploading = false
            uploadError = error
        }
    }

    private func addDocumentReference(
        to course: Course, document: Document, completion: @escaping () -> Void
    ) {
        guard let courseId = course.docID else { return }

        firestore.collection("courses").document(courseId).updateData([
            "documents": FieldValue.arrayUnion([document.firestoreRepresentation()]),
        ]) { error in
            if let error {
                self.uploadError = error
            } else {
                completion()
            }
        }
    }

    func deleteDocument(course: Course, document: Document, completion: @escaping () -> Void) {
        guard let courseId = course.docID else { return }
        guard let userId = currentUserId, userId == course.userId else {
            uploadError = NSError(
                domain: "Auth", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Not authorized to edit this course"]
            )
            return
        }

        isDeleting = true

        // First, get the current course document to ensure we're working with the latest data
        firestore.collection("courses").document(courseId).getDocument {
            documentSnapshot, error in
            if let error {
                self.uploadError = error
                self.isDeleting = false
                return
            }

            guard let documentSnapshot, documentSnapshot.exists,
                  var courseData = try? documentSnapshot.data(as: Course.self)
            else {
                self.uploadError = NSError(
                    domain: "Firestore", code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Could not retrieve course data"]
                )
                self.isDeleting = false
                return
            }

            // Filter out the document with matching id
            courseData.documents = courseData.documents.filter { $0.id != document.id }

            // Update the course with the filtered documents array
            do {
                try self.firestore.collection("courses").document(courseId).setData(
                    from: courseData, merge: true
                ) { error in
                    if let error {
                        self.uploadError = error
                        self.isDeleting = false
                        return
                    }

                    // Now delete the file from storage if URL exists
                    if let fileURL = document.url {
                        let ref = self.storage.reference(forURL: fileURL)
                        ref.delete { error in
                            self.isDeleting = false
                            if let error {
                                self.uploadError = error
                            } else {
                                completion()
                            }
                        }
                    } else {
                        self.isDeleting = false
                        completion()
                    }
                }
            } catch {
                self.uploadError = error
                self.isDeleting = false
            }
        }
    }

    func processDocument(url: String, courseID: String) {
        courseId = courseID

        // Create URL for the OCR endpoint
        guard
            let ocrEndpoint = URL(
                string: "https://f687-2600-8800-12a1-7200-892d-b63d-1047-ea2a.ngrok-free.app/ocr")
        else {
            print("Error: Invalid endpoint URL")
            return
        }

        print("COURSE ID: \(courseID)")

        // Create request body with the document URL
        let requestBody = ["url": url]

        do {
            // Convert request body to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

            // Create HTTP request
            var request = URLRequest(url: ocrEndpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            // Create and start the data task
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error {
                    print("Error making request: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Error: Invalid response")
                    return
                }

                if httpResponse.statusCode == 200, let data {
                    // Handle successful response
                    do {
                        if let jsonResult = try JSONSerialization.jsonObject(with: data)
                            as? [String: Any]
                        {
                            print("OCR Result:")
                            print(jsonResult)
                            // Send OCR result to OpenAI
                            self.sendToGemini(ocrResult: jsonResult)
                        }
                    } catch {
                        print("Error parsing response: \(error.localizedDescription)")
                    }
                } else {
                    print("Error: HTTP status code \(httpResponse.statusCode)")
                    if let data, let errorMessage = String(data: data, encoding: .utf8) {
                        print("Server response: \(errorMessage)")
                    }
                }
            }

            task.resume()
        } catch {
            print("Error preparing request: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func sendToGemini(ocrResult: [String: Any]) {
        // Gemini API endpoint
        guard
            let geminiEndpoint = URL(
                string:
                "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
            )
        else {
            print("Error: Invalid Gemini endpoint URL")
            return
        }

        // Get Gemini API key (in a real app, store this securely)
        let apiKey = "AIzaSyBF6D16AWwA3Hu99LGHEmwtzEqb0CA8ki4"

        // Extract pages array from OCR result
        guard let pages = ocrResult["pages"] as? [[String: Any]] else {
            print("Error: Could not find 'pages' array in OCR result")
            return
        }

        // Process pages to extract only index, markdown and images
        var cleanedPages: [[String: Any]] = []

        for page in pages {
            var cleanedPage: [String: Any] = [:]

            // Extract index
            if let index = page["index"] as? Int {
                cleanedPage["index"] = index
            }

            // Extract markdown
            if let markdown = page["markdown"] as? String {
                cleanedPage["markdown"] = markdown
            }

            // Extract images if they exist
            if let images = page["images"] as? [[String: Any]] {
                cleanedPage["images"] = images
            }

            cleanedPages.append(cleanedPage)
        }

        // Convert the cleaned pages array to JSON
        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: cleanedPages, options: .prettyPrinted
            )
            guard let cleanedContent = String(data: jsonData, encoding: .utf8) else {
                print("Error: Failed to convert cleaned pages to string")
                return
            }

            // Prepare the request body for Gemini
            let requestBody: [String: Any] = [
                "contents": [
                    [
                        "role": "user",
                        "parts": [
                            [
                                "text":
                                    "You are an assistant that helps create snippets of topics from the given content. Understand the given content and return 2 snippets to be sent to users as notifications with a title and body. Return the snippets in json format and for every snippet include a field of tags. Process this content and return json format: \(cleanedContent)",
                            ],
                        ],
                    ],
                ],
            ]

            // Convert request body to JSON data
            let requestJsonData = try JSONSerialization.data(withJSONObject: requestBody)

            // Create HTTP request with API key in query parameter
            var urlComponents = URLComponents(url: geminiEndpoint, resolvingAgainstBaseURL: false)!
            urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]

            var request = URLRequest(url: urlComponents.url!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = requestJsonData

            // Create and start the data task
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error {
                    print("Error making Gemini request: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Error: Invalid Gemini response")
                    return
                }

                if httpResponse.statusCode == 200, let data {
                    // Handle successful response
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
                            // Try to parse the text as JSON containing snippets
                            if let jsonData = text.data(using: .utf8) {
                                do {
                                    // Clean up the text by removing markdown formatting
                                    var cleanedText =
                                        text
                                            .trimmingCharacters(in: .whitespacesAndNewlines)

                                    // Remove "```json" at the start if it exists
                                    if cleanedText.hasPrefix("```json") {
                                        cleanedText = String(cleanedText.dropFirst(7))
                                    } else if cleanedText.hasPrefix("```") {
                                        cleanedText = String(cleanedText.dropFirst(3))
                                    }

                                    // Remove "```" at the end if it exists
                                    if cleanedText.hasSuffix("```") {
                                        cleanedText = String(cleanedText.dropLast(3))
                                    }

                                    cleanedText = cleanedText.trimmingCharacters(
                                        in: .whitespacesAndNewlines)

                                    // Try to parse the cleaned text
                                    if let cleanedData = cleanedText.data(using: .utf8) {
                                        do {
                                            // Parse the array of snippets directly
                                            let snippets = try JSONDecoder().decode(
                                                [Snippet].self, from: cleanedData
                                            )
                                            print("Successfully parsed snippets:")

                                            // Add each snippet as a quiz item
                                            for snippet in snippets {
                                                print("\nTitle: \(snippet.title)")
                                                print("Body: \(snippet.body)")
                                                print("Tags: \(snippet.tags)")

                                                // Add the snippet as a quiz item
                                                self.quizItemViewModel.addQuizItem(
                                                    title: snippet.title,
                                                    body: snippet.body,
                                                    type: .snippet,
                                                    courseId: self.courseId,
                                                    tags: snippet.tags
                                                ) {
                                                    print("✅ Snippet added as quiz item")
                                                }
                                            }
                                        } catch {
                                            print("Error parsing snippets JSON: \(error)")
                                            print("Raw text from Gemini:")
                                            print(text)
                                        }
                                    }
                                } catch {
                                    print("Error parsing snippets JSON: \(error)")
                                    print("Raw text from Gemini:")
                                    print(text)
                                }
                            }
                        }
                    } catch {
                        print("Error parsing Gemini response: \(error.localizedDescription)")
                        if let responseText = String(data: data, encoding: .utf8) {
                            print("Raw response: \(responseText)")
                        }
                    }
                } else {
                    print("Error: Gemini HTTP status code \(httpResponse.statusCode)")
                    if let responseData = data {
                        if let errorMessage = String(data: responseData, encoding: .utf8) {
                            print("Gemini response: \(errorMessage)")
                        }
                    }
                }
            }

            task.resume()
        } catch {
            print("Error preparing Gemini request: \(error.localizedDescription)")
        }
    }
}
