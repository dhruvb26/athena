//
//  MCPViewModel.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/23/25.
//

import Foundation
import Logging
import MCP
import SwiftUI

struct MCPServer: Hashable, Identifiable {
    let id = UUID()
    let url: String
    let description: String
}

struct GenericNotification: MCP.Notification, Sendable {
    static var name: String { "notifications/message" }
    typealias Parameters = Value
}

struct MCPMessage: Identifiable {
    let id = UUID()
    var content: String
    let isUser: Bool
    var date: Date = .init()
}

@MainActor
public class MCPViewModel: ObservableObject {
    private let client: Client = .init(name: "Athena", version: "1.0.0")
    private let logger = Logger(label: "athena.MCPViewModel")
    private let serverURL = "https://c6e3-2607-fb91-8e93-d56f-2575-7ff-b545-cee2.ngrok-free.app/mcp"
    private let apiKey = Bundle.main.infoDictionary?["ANTHROPIC_API_KEY"] as? String

    @Published var messages: [MCPMessage] = []
    @Published var inputMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var isTyping: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isConnected: Bool = false

    private var anthropicMessages: [[String: Any]] = []

    func connect() async {
        guard let url = URL(string: serverURL) else { return }
        isLoading = true

        do {
            let transport = StreamableClientTransport(
                endpoint: url,
                configuration: .default,
                logger: nil
            )

            try await client.connect(transport: transport)

            await client.onNotification(GenericNotification.self) { message in
                self.logger.debug("Received notification: \(message.params)")
            }

            let serverCapabilities = try await client.initialize()
            logger.info("Connected to server: \(serverCapabilities.serverInfo.name)")

            await transport.startEventListener()
            isConnected = true

        } catch {
            logger.error("Connection error: \(error.localizedDescription)")
            errorMessage = "Failed to connect: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func sendMessage() async {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard isConnected else {
            errorMessage = "Not connected to server. Please wait..."
            await connect()
            return
        }

        let userMessage = inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        inputMessage = ""
        isLoading = true
        isTyping = true
        errorMessage = nil

        await MainActor.run {
            messages.append(MCPMessage(content: userMessage, isUser: true))
        }

        do {
            let toolsResponse = try await client.listTools()
            var toolsArray: [[String: Any]] = []

            for tool in toolsResponse.tools {
                let inputSchemaDict: [String: Any] =
                    if let schema = tool.inputSchema {
                        try JSONSerialization.jsonObject(
                            with: JSONEncoder().encode(schema)
                        ) as? [String: Any] ?? [:]
                    } else {
                        [:]
                    }

                let toolDict: [String: Any] = [
                    "name": tool.name,
                    "description": tool.description,
                    "input_schema": inputSchemaDict,
                ]
                toolsArray.append(toolDict)
            }

            anthropicMessages.append([
                "role": "user",
                "content": userMessage,
            ])

            var finalResponse = ""
            var shouldContinue = true

            while shouldContinue {
                let url = URL(string: "https://api.anthropic.com/v1/messages")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(
                    apiKey ?? "",
                    forHTTPHeaderField: "x-api-key"
                )
                request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

                let requestBody: [String: Any] = [
                    "model": "claude-3-5-sonnet-latest",
                    "max_tokens": 1024,
                    "messages": anthropicMessages.filter {
                        if let content = $0["content"] {
                            if let strContent = content as? String {
                                return !strContent.isEmpty
                            } else if let arrContent = content as? [[String: Any]] {
                                return !arrContent.isEmpty
                            }
                        }
                        return false
                    },
                    "tools": toolsArray,
                ]

                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(
                        domain: "MCPViewModel", code: 2,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Invalid response type from Anthropic API",
                        ]
                    )
                }

                if !(200 ... 299).contains(httpResponse.statusCode) {
                    let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                    let errorMessage = errorJson?["error"] as? [String: Any]
                    let errorType = errorMessage?["type"] as? String
                    let errorDetails = errorMessage?["message"] as? String

                    throw NSError(
                        domain: "MCPViewModel",
                        code: httpResponse.statusCode,
                        userInfo: [
                            NSLocalizedDescriptionKey: errorDetails
                                ?? "Invalid response from Anthropic API",
                            "errorType": errorType ?? "unknown",
                            "statusCode": httpResponse.statusCode,
                        ]
                    )
                }

                guard
                    let responseDict = try? JSONSerialization.jsonObject(with: data)
                    as? [String: Any],
                    let content = responseDict["content"] as? [[String: Any]]
                else {
                    throw NSError(
                        domain: "MCPViewModel",
                        code: 3,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Failed to parse Anthropic API response",
                        ]
                    )
                }

                var assistantMessageContent: [[String: Any]] = []
                shouldContinue = false

                for item in content {
                    if let type = item["type"] as? String {
                        switch type {
                        case "text":
                            if let text = item["text"] as? String, !text.isEmpty {
                                finalResponse += text
                                assistantMessageContent.append(item)

                                await MainActor.run {
                                    isTyping = false

                                    if let lastMessage = messages.last, !lastMessage.isUser {
                                        if content.count > 1,
                                           content[1]["type"] as? String == "tool_use"
                                        {
                                            messages[messages.count - 1].content += text
                                        } else {
                                            messages[messages.count - 1].content += text
                                        }
                                    } else {
                                        messages.append(MCPMessage(content: text, isUser: false))
                                    }
                                }
                            }
                        case "tool_use":
                            if let toolName = item["name"] as? String,
                               let toolInput = item["input"] as? [String: Any],
                               let toolId = item["id"] as? String
                            {
                                do {
                                    var mcpArguments: [String: MCP.Value] = [:]
                                    for (key, value) in toolInput {
                                        if let stringValue = value as? String {
                                            mcpArguments[key] = .string(stringValue)
                                        }
                                    }

                                    let toolResponse = try await client.callTool(
                                        name: toolName,
                                        arguments: mcpArguments
                                    )

                                    var toolResponseText = ""
                                    for content in toolResponse.content {
                                        if case let .text(text) = content {
                                            toolResponseText += text
                                        }
                                    }

                                    let formattedToolResponse =
                                        toolResponseText
                                            .split(separator: "\n")
                                            .map { "  \($0)" }
                                            .joined(separator: "\n")

                                    finalResponse += "\n\(formattedToolResponse)\n"
                                    assistantMessageContent.append(item)

                                    await MainActor.run {
                                        isTyping = false

                                        if let lastMessage = messages.last, !lastMessage.isUser {
                                        } else {
                                            messages.append(
                                                MCPMessage(
                                                    content: "Using tool: \(toolName)",
                                                    isUser: false
                                                ))
                                        }
                                        messages.append(
                                            MCPMessage(
                                                content: formattedToolResponse, isUser: false
                                            ))
                                    }

                                    anthropicMessages.append([
                                        "role": "assistant",
                                        "content": assistantMessageContent,
                                    ])
                                    anthropicMessages.append([
                                        "role": "user",
                                        "content": [
                                            [
                                                "type": "tool_result",
                                                "tool_use_id": toolId,
                                                "content": formattedToolResponse,
                                            ],
                                        ],
                                    ])

                                    shouldContinue = true
                                    break
                                } catch {
                                    let errorMessage =
                                        "Error executing tool '\(toolName)': \(error.localizedDescription)"
                                    finalResponse += "\n\(errorMessage)"
                                    logger.error("\(errorMessage)")

                                    await MainActor.run {
                                        messages.append(
                                            MCPMessage(content: errorMessage, isUser: false))
                                    }
                                }
                            }
                        default:
                            break
                        }
                    }
                }

                if !shouldContinue {
                    anthropicMessages.append([
                        "role": "assistant",
                        "content": assistantMessageContent,
                    ])
                }
            }

        } catch {
            await MainActor.run {
                messages.append(
                    MCPMessage(content: "Error: \(error.localizedDescription)", isUser: false))
                errorMessage = error.localizedDescription

                isTyping = false
                isLoading = false
            }
            if let urlError = error as? URLError {
                logger.error(
                    "Network error: \(urlError.code.rawValue), \(urlError.localizedDescription)")
            } else {
                logger.error("Error: \(error.localizedDescription)")
            }
            return
        }

        isTyping = false
        isLoading = false
    }

    func clearChat() {
        messages.removeAll()
        anthropicMessages.removeAll()
        errorMessage = nil
    }
}
