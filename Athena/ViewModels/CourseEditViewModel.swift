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

        // First fetch the course to check its notification type
        firestore.collection("courses").document(courseID).getDocument {
            [weak self] snapshot, error in
            guard let self else { return }

            if let error {
                print("Error fetching course: \(error.localizedDescription)")
                return
            }

            guard let snapshot, snapshot.exists else {
                print("Course not found")
                return
            }

            do {
                // Decode the course from the snapshot
                let course = try snapshot.data(as: Course.self)

                // Determine which type of content to generate based on notification type
                switch course.notificationType {
                case .snippet:
                    // For snippet notification type, generate snippets
                    processDocumentWithOCR(url: url, courseID: courseID, contentType: .snippet)
                case .question:
                    // For question notification type, generate questions
                    processDocumentWithOCR(
                        url: url, courseID: courseID, contentType: .question
                    )
                case .mixed:
                    // For both, process twice - once for each type
                    processDocumentWithOCR(url: url, courseID: courseID, contentType: .snippet)
                    processDocumentWithOCR(
                        url: url, courseID: courseID, contentType: .question
                    )
                }
            } catch {
                print("Error decoding course: \(error.localizedDescription)")
            }
        }
    }

    private func processDocumentWithOCR(
        url: String, courseID: String, contentType: ContentGenerationType
    ) {
        // Create URL for the OCR endpoint
        guard
            let ocrEndpoint = URL(
                string: "https://f687-2600-8800-12a1-7200-892d-b63d-1047-ea2a.ngrok-free.app/ocr")
        else {
            print("Error: Invalid endpoint URL")
            return
        }

        print("COURSE ID: \(courseID), Processing for: \(contentType)")

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

                            // Extract and clean the content
                            if let pages = jsonResult["pages"] as? [[String: Any]] {
                                let cleanedContent = self.cleanOCRContent(pages: pages)
                                // Process with the specified content type
                                Task { @MainActor in
                                    self.sendToGeminiWithContent(
                                        cleanedContent: cleanedContent, contentType: contentType
                                    )
                                }
                            }
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
        // Extract and clean the content before sending to Gemini
        guard let pages = ocrResult["pages"] as? [[String: Any]] else {
            print("Error: Could not find 'pages' array in OCR result")
            return
        }

        let cleanedContent = cleanOCRContent(pages: pages)
        // Default to snippet type
        sendToGeminiWithContent(cleanedContent: cleanedContent, contentType: .snippet)
    }

    // Enum to define the type of content to generate
    enum ContentGenerationType {
        case snippet
        case question
    }

    private func cleanOCRContent(pages: [[String: Any]]) -> String {
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
                return ""
            }
            return cleanedContent
        } catch {
            print("Error cleaning OCR content: \(error.localizedDescription)")
            return ""
        }
    }

    @MainActor
    private func sendToGeminiWithContent(cleanedContent: String, contentType: ContentGenerationType) {
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

        // Create the appropriate prompt based on content type
        let promptText = switch contentType {
        case .snippet:
            "You are an assistant that helps create snippets of topics from the given content. Understand the given content and return 2 snippets to be sent to users as notifications with a title and body. Return the snippets in json format and for every snippet include a field of tags. Process this content and return json format: \(cleanedContent)"
        case .question:
            "You are an assistant that helps create multiple-choice quiz questions from the given content. Understand the given content and return 2 quiz questions with a title, body (question text), and 4 options (possible answers) with the index of the correct answer (0-3). Return the questions in json format and for every question include a field of tags. Process this content and return json format don't include a key in the json, just the array of questions: \(cleanedContent)"
        }

        // Prepare the request body for Gemini
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        [
                            "text": promptText,
                        ],
                    ],
                ],
            ],
        ]

        // Convert request body to JSON data
        do {
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
                            // Try to parse the text as JSON containing snippets or questions
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
                                        switch contentType {
                                        case .snippet:
                                            self.processSnippetResponse(cleanedData: cleanedData)
                                        case .question:
                                            self.processQuestionResponse(
                                                cleanedData: cleanedData, rawText: text
                                            )
                                        }
                                    }
                                } catch {
                                    print("Error parsing JSON: \(error)")
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

    @MainActor
    private func processSnippetResponse(cleanedData: Data) {
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
                quizItemViewModel.addQuizItem(
                    title: snippet.title,
                    body: snippet.body,
                    type: .snippet,
                    courseId: courseId,
                    tags: snippet.tags
                ) {
                    print("✅ Snippet added as quiz item")
                }
            }
        } catch {
            print("Error parsing snippets JSON: \(error)")
        }
    }

    // Define a Question struct to parse JSON responses for quiz questions
    struct Question: Codable {
        var title: String
        var body: String
        var options: [String]
        var tags: [String]

        // Support both naming conventions
        var correctAnswerIndex: Int?
        var correct_answer: Int?

        // Computed property to get the correct answer index regardless of which field is used
        var correctAnswer: Int {
            correctAnswerIndex ?? correct_answer ?? 0
        }
    }

    // Define a wrapper struct for when questions are nested inside an object
    struct QuestionResponse: Codable {
        var quiz_questions: [Question]?

        // Support for direct array of questions
        var questions: [Question]?

        // Allow single question objects too
        var title: String?
        var body: String?
        var options: [String]?
        var tags: [String]?
        var correctAnswerIndex: Int?
        var correct_answer: Int?

        // Function to get all questions regardless of format
        func getAllQuestions() -> [Question] {
            if let quizQuestions = quiz_questions {
                return quizQuestions
            }

            if let questionList = questions {
                return questionList
            }

            // If we have a single question embedded in the response
            if let title, let body, let options, let tags {
                let correctAnswer = correctAnswerIndex ?? correct_answer ?? 0
                let question = Question(
                    title: title,
                    body: body,
                    options: options,
                    tags: tags,
                    correctAnswerIndex: correctAnswer,
                    correct_answer: nil
                )
                return [question]
            }

            return []
        }
    }

    @MainActor
    private func processQuestionResponse(cleanedData: Data, rawText: String) {
        if let jsonString = String(data: cleanedData, encoding: .utf8)?.trimmingCharacters(
            in: .whitespacesAndNewlines),
            let firstChar = jsonString.first, firstChar == "["
        {
            do {
                let questionsArray = try JSONDecoder().decode([Question].self, from: cleanedData)
                handleParsedQuestions(questionsArray)
                return
            } catch {
                print("Error parsing questions as array JSON: \(error)")
            }
        } else {
            do {
                let questionResponse = try JSONDecoder().decode(
                    QuestionResponse.self, from: cleanedData
                )
                let questions = questionResponse.getAllQuestions()
                if !questions.isEmpty {
                    handleParsedQuestions(questions)
                    return
                }
            } catch {
                print("Error parsing QuestionResponse JSON: \(error)")
            }
        }

        print("Error parsing questions JSON:")
        print("Raw text from Gemini:")
        print(rawText)

        // Try to manually extract the JSON if it's enclosed in backticks
        var extractedText = rawText
        if extractedText.contains("```json") {
            extractedText = extractedText.replacingOccurrences(of: "```json", with: "")
            extractedText = extractedText.replacingOccurrences(of: "```", with: "")
        } else if extractedText.contains("```") {
            let components = extractedText.components(separatedBy: "```")
            if components.count >= 3 {
                extractedText = components[1]
            }
        }
        extractedText = extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !extractedText.isEmpty, let data = extractedText.data(using: .utf8) {
            do {
                let questionResponse = try JSONDecoder().decode(QuestionResponse.self, from: data)
                let questions = questionResponse.getAllQuestions()
                if !questions.isEmpty {
                    handleParsedQuestions(questions)
                    return
                }
                let questionsArray = try JSONDecoder().decode([Question].self, from: data)
                handleParsedQuestions(questionsArray)
            } catch {
                print("Failed to parse extracted JSON: \(error)")
            }
        }
    }

    @MainActor
    private func handleParsedQuestions(_ questions: [Question]) {
        print("Successfully parsed \(questions.count) questions:")

        // Add each question as a quiz item
        for question in questions {
            print("\nTitle: \(question.title)")
            print("Body: \(question.body)")
            print("Options: \(question.options)")
            print("Correct Answer: \(question.correctAnswer)")
            print("Tags: \(question.tags)")

            // Add the question as a quiz item
            quizItemViewModel.addQuizItem(
                title: question.title,
                body: question.body,
                type: .question,
                courseId: courseId,
                tags: question.tags,
                options: question.options,
                correctAnswerIndex: question.correctAnswer
            ) {
                print("✅ Question added as quiz item")
            }
        }
    }

    // Public method to generate snippets from the course content
    func generateSnippets(courseID: String) {
        courseId = courseID
        getLatestDocumentAndProcess(courseID: courseID, contentType: .snippet)
    }

    // Public method to generate questions from the course content
    func generateQuestions(courseID: String) {
        courseId = courseID
        getLatestDocumentAndProcess(courseID: courseID, contentType: .question)
    }

    private func getLatestDocumentAndProcess(courseID: String, contentType: ContentGenerationType) {
        // Fetch the course to get the latest document
        firestore.collection("courses").document(courseID).getDocument {
            [weak self] documentSnapshot, error in
            guard let self else { return }

            if let error {
                print("Error fetching course: \(error.localizedDescription)")
                return
            }

            guard let documentSnapshot,
                  documentSnapshot.exists,
                  let course = try? documentSnapshot.data(as: Course.self),
                  let latestDocument = course.documents.last,
                  let documentURL = latestDocument.url
            else {
                print("No documents found for the course")
                return
            }

            // Create URL for the OCR endpoint
            guard
                let ocrEndpoint = URL(
                    string:
                    "https://f687-2600-8800-12a1-7200-892d-b63d-1047-ea2a.ngrok-free.app/ocr")
            else {
                print("Error: Invalid endpoint URL")
                return
            }

            // Create request body with the document URL
            let requestBody = ["url": documentURL]

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

                                // Extract and clean the content
                                if let pages = jsonResult["pages"] as? [[String: Any]] {
                                    let cleanedContent = self.cleanOCRContent(pages: pages)
                                    // Process with the specified content type
                                    Task { @MainActor in
                                        self.sendToGeminiWithContent(
                                            cleanedContent: cleanedContent, contentType: contentType
                                        )
                                    }
                                }
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
    }
}
