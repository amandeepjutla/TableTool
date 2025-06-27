//
//  CSVDocument.swift
//  Table Tool
//
//  Created by Claude on 2025-06-27.
//  Copyright (c) 2025 Egger Apps. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct CSVDocument: FileDocument {
    // MARK: - FileDocument conformance
    static var readableContentTypes: [UTType] { [.commaSeparatedText, .plainText] }
    static var writableContentTypes: [UTType] { [.commaSeparatedText] }
    
    // MARK: - Document properties
    var data: [[String]]
    var configuration: CSVConfiguration
    var maxColumnCount: Int
    
    // MARK: - Initializers
    init() {
        self.data = [[""]]
        self.configuration = CSVConfiguration()
        self.maxColumnCount = 1
    }
    
    init(data: [[String]], configuration: CSVConfiguration = CSVConfiguration()) {
        self.data = data
        self.configuration = configuration
        self.maxColumnCount = data.map { $0.count }.max() ?? 1
    }
    
    // MARK: - FileDocument methods
    init(configuration: ReadConfiguration) throws {
        guard let fileData = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        // Try to detect the CSV format using heuristics
        let detectedConfig: CSVConfiguration
        do {
            detectedConfig = try CSVHeuristic.detectConfiguration(from: fileData)
        } catch {
            // Fall back to default configuration if detection fails
            detectedConfig = CSVConfiguration()
        }
        
        self.configuration = detectedConfig
        
        // Parse the CSV data
        let reader = CSVReader(data: fileData, configuration: detectedConfig)
        var parsedData: [[String]] = []
        
        do {
            while !reader.isAtEnd {
                if let row = try reader.readLine() {
                    parsedData.append(row)
                }
            }
        } catch {
            // If parsing fails, create a minimal document
            parsedData = [[""]]
        }
        
        self.data = parsedData.isEmpty ? [[""]] : parsedData
        self.maxColumnCount = data.map { $0.count }.max() ?? 1
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let writer = CSVWriter(configuration: self.configuration)
        let csvString = writer.writeData(self.data)
        
        guard let csvData = csvString.data(using: self.configuration.encoding) else {
            throw CocoaError(.fileWriteInvalidFileName)
        }
        
        return FileWrapper(regularFileWithContents: csvData)
    }
}

// MARK: - Document manipulation methods
extension CSVDocument {
    mutating func addRow(at index: Int? = nil) {
        let newRow = Array(repeating: "", count: maxColumnCount)
        if let index = index {
            data.insert(newRow, at: index)
        } else {
            data.append(newRow)
        }
    }
    
    mutating func deleteRow(at index: Int) {
        guard index < data.count else { return }
        data.remove(at: index)
        if data.isEmpty {
            data = [[""]]
        }
    }
    
    mutating func addColumn(at index: Int? = nil) {
        let insertIndex = index ?? maxColumnCount
        maxColumnCount += 1
        
        for i in 0..<data.count {
            if insertIndex < data[i].count {
                data[i].insert("", at: insertIndex)
            } else {
                data[i].append("")
            }
        }
    }
    
    mutating func deleteColumn(at index: Int) {
        guard index < maxColumnCount else { return }
        
        for i in 0..<data.count {
            if index < data[i].count {
                data[i].remove(at: index)
            }
        }
        
        maxColumnCount = data.map { $0.count }.max() ?? 1
        if maxColumnCount == 0 {
            data = [[""]]
            maxColumnCount = 1
        }
    }
    
    mutating func updateCell(row: Int, column: Int, value: String) {
        guard row < data.count else { return }
        
        // Extend row if necessary
        while data[row].count <= column {
            data[row].append("")
        }
        
        data[row][column] = value
        maxColumnCount = max(maxColumnCount, data[row].count)
    }
}