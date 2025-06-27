//
//  AsyncDocumentView.swift
//  Table Tool
//
//  Created by Claude on 2025-06-27 for async document loading
//

import SwiftUI
import UniformTypeIdentifiers

struct AsyncDocumentView: View {
    let fileData: Data
    @StateObject private var loader = AsyncCSVLoader()
    
    var body: some View {
        Group {
            if loader.isLoading {
                VStack(spacing: 20) {
                    ProgressView(value: loader.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 300)
                    
                    Text("Loading CSV file...")
                        .font(.headline)
                    
                    Text("\(Int(loader.progress * 100))% complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)
            } else if let error = loader.error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Failed to Load CSV")
                        .font(.headline)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        Task {
                            await loader.loadDocument(from: fileData)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let document = loader.document {
                ContentView(document: .constant(document))
            } else {
                Text("Preparing to load...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await loader.loadDocument(from: fileData)
        }
    }
}

// MARK: - Enhanced FileDocument with Async Support
struct AsyncCSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText, .plainText] }
    static var writableContentTypes: [UTType] { [.commaSeparatedText] }
    
    private let fileData: Data
    
    init() {
        self.fileData = Data()
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.fileData = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // For writing, we'll need to get the document from the view
        // This is a simplified implementation - in practice, you'd need to
        // maintain a reference to the loaded document for writing
        return FileWrapper(regularFileWithContents: fileData)
    }
}

// MARK: - Document content view factory
extension AsyncCSVDocument {
    func makeContentView() -> some View {
        AsyncDocumentView(fileData: fileData)
    }
}