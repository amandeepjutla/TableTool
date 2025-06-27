//
//  CSVDocument.swift
//  Table2
//
//  Table2 created by Claude on 2025-06-27 for tifalab
//  Original TableTool (c) 2015 Egger Apps. All rights reserved//

import SwiftUI
import UniformTypeIdentifiers

struct CSVDocument: FileDocument {
    // MARK: - FileDocument conformance
    static var readableContentTypes: [UTType] { [.commaSeparatedText, .plainText] }
    static var writableContentTypes: [UTType] { [.commaSeparatedText] }
    
    // MARK: - Document properties
    var data: [[String]]
    var configuration: CSVConfiguration
    private var _maxColumnCount: Int?
    
    var maxColumnCount: Int {
        if let cached = _maxColumnCount {
            return cached
        }
        return data.map { $0.count }.max() ?? 1
    }
    
    private mutating func updateMaxColumnCount() {
        _maxColumnCount = data.map { $0.count }.max() ?? 1
    }
    
    // MARK: - Initializers
    init() {
        self.data = [[""]]
        self.configuration = CSVConfiguration()
        self._maxColumnCount = 1
    }
    
    init(data: [[String]], configuration: CSVConfiguration = CSVConfiguration()) {
        self.data = data
        self.configuration = configuration
        self._maxColumnCount = nil // Will be calculated lazily
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
        self._maxColumnCount = nil // Will be calculated lazily when accessed
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
        // Column count unchanged, no need to invalidate cache
    }
    
    mutating func deleteRow(at index: Int) {
        guard index < data.count else { return }
        data.remove(at: index)
        if data.isEmpty {
            data = [[""]]
        }
        // Deleting a row might change max column count
        updateMaxColumnCount()
    }
    
    mutating func addColumn(at index: Int? = nil) {
        let insertIndex = index ?? maxColumnCount
        let newMaxCount = maxColumnCount + 1
        
        for i in 0..<data.count {
            if insertIndex < data[i].count {
                data[i].insert("", at: insertIndex)
            } else {
                data[i].append("")
            }
        }
        
        // Update cached value directly since we know it increased by 1
        _maxColumnCount = newMaxCount
    }
    
    mutating func deleteColumn(at index: Int) {
        guard index < maxColumnCount else { return }
        
        for i in 0..<data.count {
            if index < data[i].count {
                data[i].remove(at: index)
            }
        }
        
        // Recalculate and cache max column count
        updateMaxColumnCount()
        if maxColumnCount == 0 {
            data = [[""]]
            _maxColumnCount = 1
        }
    }
    
    mutating func updateCell(row: Int, column: Int, value: String) {
        guard row < data.count else { return }
        
        // Check if we need to extend the row
        let currentRowLength = data[row].count
        let needsExtension = column >= currentRowLength
        
        // Extend row if necessary
        while data[row].count <= column {
            data[row].append("")
        }
        
        data[row][column] = value
        
        // Only update max column count if we extended a row
        if needsExtension {
            let newRowLength = data[row].count
            if let cached = _maxColumnCount {
                _maxColumnCount = max(cached, newRowLength)
            } else {
                // Will be calculated on next access
            }
        }
    }
}
