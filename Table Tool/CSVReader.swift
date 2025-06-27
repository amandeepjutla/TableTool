//
//  CSVReader.swift
//  Table Tool
//
//  Created by Claude on 2025-06-27.
//  Copyright (c) 2025 Egger Apps. All rights reserved.
//

import Foundation

class CSVReader {
    private let data: Data
    private let configuration: CSVConfiguration
    private var currentPosition: Int = 0
    private var csvString: String
    
    var isAtEnd: Bool {
        return currentPosition >= csvString.count
    }
    
    init(data: Data, configuration: CSVConfiguration) {
        self.data = data
        self.configuration = configuration
        
        // Convert data to string using the specified encoding
        self.csvString = String(data: data, encoding: configuration.encoding) ?? ""
    }
    
    init(string: String, configuration: CSVConfiguration) {
        self.data = Data()
        self.configuration = configuration
        self.csvString = string
    }
    
    func readLine() throws -> [String]? {
        guard !isAtEnd else { return nil }
        
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        var i = currentPosition
        
        while i < csvString.count {
            let char = csvString[csvString.index(csvString.startIndex, offsetBy: i)]
            let charString = String(char)
            
            if insideQuotes {
                if charString == configuration.quoteCharacter {
                    // Check if this is an escaped quote
                    let nextIndex = i + 1
                    if nextIndex < csvString.count {
                        let nextChar = csvString[csvString.index(csvString.startIndex, offsetBy: nextIndex)]
                        if String(nextChar) == configuration.escapeCharacter {
                            currentField += charString
                            i += 1 // Skip the escape character
                        } else {
                            insideQuotes = false
                        }
                    } else {
                        insideQuotes = false
                    }
                } else {
                    currentField += charString
                }
            } else {
                if charString == configuration.quoteCharacter {
                    insideQuotes = true
                } else if charString == configuration.columnSeparator {
                    fields.append(currentField)
                    currentField = ""
                } else if charString == "\n" || charString == "\r" {
                    // Handle different line endings
                    if charString == "\r" && i + 1 < csvString.count {
                        let nextChar = csvString[csvString.index(csvString.startIndex, offsetBy: i + 1)]
                        if nextChar == "\n" {
                            i += 1 // Skip the \n in \r\n
                        }
                    }
                    break
                } else {
                    currentField += charString
                }
            }
            
            i += 1
        }
        
        // Add the last field
        fields.append(currentField)
        
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