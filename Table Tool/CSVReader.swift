//
//  CSVReader.swift
//  Table2
//
//  Table2 created by Claude on 2025-06-27 for tifalab
//  Original TableTool (c) 2015 Egger Apps. All rights reserved//

import Foundation

class CSVReader {
    private let data: Data
    private let configuration: CSVConfiguration
    private var currentPosition: Int = 0
    private let csvBytes: [UInt8]
    private let separatorByte: UInt8
    private let quoteByte: UInt8
    private let escapeByte: UInt8
    private let crByte: UInt8 = 13 // \r
    private let lfByte: UInt8 = 10 // \n
    
    var isAtEnd: Bool {
        return currentPosition >= csvBytes.count
    }
    
    init(data: Data, configuration: CSVConfiguration) {
        self.data = data
        self.configuration = configuration
        
        // Convert to byte array for efficient processing
        self.csvBytes = Array(data)
        
        // Cache separator bytes for performance
        self.separatorByte = configuration.columnSeparator.utf8.first ?? 44 // Default to comma
        self.quoteByte = configuration.quoteCharacter.utf8.first ?? 34 // Default to quote
        self.escapeByte = configuration.escapeCharacter.utf8.first ?? 34 // Default to quote
    }
    
    init(string: String, configuration: CSVConfiguration) {
        self.data = Data()
        self.configuration = configuration
        
        // Convert string to UTF-8 bytes for efficient processing
        self.csvBytes = Array(string.utf8)
        
        // Cache separator bytes for performance
        self.separatorByte = configuration.columnSeparator.utf8.first ?? 44
        self.quoteByte = configuration.quoteCharacter.utf8.first ?? 34
        self.escapeByte = configuration.escapeCharacter.utf8.first ?? 34
    }
    
    func readLine() throws -> [String]? {
        guard !isAtEnd else { return nil }
        
        var fields: [String] = []
        var currentFieldBytes: [UInt8] = []
        var insideQuotes = false
        var i = currentPosition
        
        while i < csvBytes.count {
            let byte = csvBytes[i]
            
            if insideQuotes {
                if byte == quoteByte {
                    // Check if this is an escaped quote
                    let nextIndex = i + 1
                    if nextIndex < csvBytes.count && csvBytes[nextIndex] == escapeByte {
                        currentFieldBytes.append(byte)
                        i += 1 // Skip the escape character
                    } else {
                        insideQuotes = false
                    }
                } else {
                    currentFieldBytes.append(byte)
                }
            } else {
                if byte == quoteByte {
                    insideQuotes = true
                } else if byte == separatorByte {
                    // Convert current field bytes to string and add to fields
                    let fieldString = String(data: Data(currentFieldBytes), encoding: configuration.encoding) ?? ""
                    fields.append(fieldString)
                    currentFieldBytes.removeAll(keepingCapacity: true)
                } else if byte == lfByte || byte == crByte {
                    // Handle different line endings
                    if byte == crByte && i + 1 < csvBytes.count && csvBytes[i + 1] == lfByte {
                        i += 1 // Skip the \n in \r\n
                    }
                    break
                } else {
                    currentFieldBytes.append(byte)
                }
            }
            
            i += 1
        }
        
        // Add the last field
        let fieldString = String(data: Data(currentFieldBytes), encoding: configuration.encoding) ?? ""
        fields.append(fieldString)
        
        // Update position for next read
        currentPosition = i + 1
        
        return fields.isEmpty ? nil : fields
    }
    
    func readAllLines() throws -> [[String]] {
        reset()
        var allLines: [[String]] = []
        
        while let line = try readLine() {
            allLines.append(line)
        }
        
        return allLines
    }
    
    func reset() {
        currentPosition = 0
    }
    
    // For compatibility with existing paste functionality
    func readLine(forPastingTo columnsOrder: [Int], maxColumnIndex: Int) -> [String]? {
        guard let line = try? readLine() else { return nil }
        
        var adjustedLine = Array(repeating: "", count: maxColumnIndex + 1)
        
        for (index, value) in line.enumerated() {
            if index < columnsOrder.count {
                let targetColumn = columnsOrder[index]
                if targetColumn <= maxColumnIndex {
                    adjustedLine[targetColumn] = value
                }
            }
        }
        
        return adjustedLine
    }
}
