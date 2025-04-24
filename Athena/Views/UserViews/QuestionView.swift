//
//  QuestionView.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/7/25.
//

import Combine
import SwiftUI

struct QuestionView: View {
    @StateObject private var viewModel = MCPViewModel()
    @State private var phase: CGFloat = 0
    @State private var opacity: Double = 0.6

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var body: some View {
        VStack {
            if !viewModel.isConnected {
                HStack {
                    Image(systemName: "circle.fill")
                        .foregroundColor(viewModel.isLoading ? .yellow : .red)
                        .font(.system(size: 10))
                    Text(viewModel.isLoading ? "Connecting..." : "Disconnected")
                        .font(.caption)
                        .foregroundColor(.gray)
                    if !viewModel.isLoading {
                        Button("Connect") {
                            Task {
                                await viewModel.connect()
                            }
                        }
                        .font(.caption)
                    }
                }
                .padding(.top, 8)
            }

            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            messageBubble(for: message)
                                .id(message.id)
                        }

                        if viewModel.isTyping {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    thinkingText()
                                        .padding(12)
                                        .cornerRadius(0)

                                    Text(formatDate(Date()))
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 4)
                                }
                                Spacer()
                            }
                            .id("thinking-indicator")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .onChange(of: viewModel.messages.count) {
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isTyping) { _, newValue in
                        if newValue {
                            withAnimation {
                                scrollView.scrollTo("thinking-indicator", anchor: .bottom)
                            }
                        }
                    }
                }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            VStack(spacing: 0) {
                HStack {
                    TextField("Ask a question.", text: $viewModel.inputMessage)
                        .padding(.trailing, 10)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(24)
                        .disabled(viewModel.isLoading)

                    Button {
                        Task {
                            await viewModel.sendMessage()
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(Color.secondaryPurple)
                    }
                    .disabled(
                        viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty || viewModel.isLoading)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .background(Color(.systemBackground))
        }
        .padding(.top, 20)
        .task {
            await viewModel.connect()
        }
    }

    private func messageBubble(for message: MCPMessage) -> some View {
        HStack {
            if message.isUser {
                Spacer()
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 2) {
                Text(message.content)
                    .padding(12)
                    .background(message.isUser ? Color.secondaryPurple : .clear)
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(message.isUser ? 20 : 0)

                Text(formatDate(message.date))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }

            if !message.isUser {
                Spacer()
            }
        }
    }

    private func thinkingText() -> some View {
        Text("Thinking")
            .foregroundColor(.primaryPurple)
            .overlay(
                LinearGradient(
                    colors: [
                        .primaryPurple.opacity(0.0), .secondaryPurple.opacity(0.7),
                        .primaryPurple.opacity(0.0),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .blur(radius: 2)
                .mask(
                    LinearGradient(
                        colors: [.clear, .black, .black, .clear],
                        startPoint: UnitPoint(x: phase - 0.5, y: 0.5),
                        endPoint: UnitPoint(x: phase + 0.5, y: 0.5)
                    )
                )
                .mask(
                    Text("Thinking")
                )
            )
            .opacity(opacity)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
                withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    opacity = 1.0
                }
            }
    }
}

#Preview {
    QuestionView()
}
