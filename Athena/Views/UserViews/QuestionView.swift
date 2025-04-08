//
//  QuestionView.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/7/25.
//

import Combine
import SwiftUI

struct QuestionView: View {
    @StateObject private var viewModel = OpenAIChatViewModel()

    var body: some View {
        VStack {
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            VStack(spacing: 0) {
                HStack {
                    TextField("Ask a question.", text: $viewModel.inputMessage)
                        .padding(.trailing, 10)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .disabled(viewModel.isLoading)

                    Button {
                        viewModel.sendMessage()
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

                //                if viewModel.isLoading {
                //                    HStack {
                //                        Spacer()
                //                        ProgressView()
                //                            .padding(.horizontal)
                //                        Spacer()
                //                    }
                //                    .padding(.vertical, 5)
                //                }
                //
                //                if let error = viewModel.error {
                //                    Text(error)
                //                        .font(.caption)
                //                        .foregroundColor(.red)
                //                        .padding(.horizontal)
                //                }
            }
            .background(Color(.systemBackground))
        }
    }
}

struct MessageBubble: View {
    let message: OpenAIChatViewModel.ChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 2) {
                Text(message.content)
                    .padding(12)
                    .background(message.isUser ? Color.secondaryPurple : .clear)
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(message.isUser ? 16 : 0)

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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    QuestionView()
}
