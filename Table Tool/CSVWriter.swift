//
//  CSVWriter.swift
//  Table2
//
//  Table2 created by Claude on 2025-06-27 for tifalab
//  Original TableTool (c) 2015 Egger Apps. All rights reserved//

import Foundation

class CSVWriter {
    private let configuration: CSVConfiguration
    
    init(configuration: CSVConfiguration) {
        self.configuration = configuration
    }
    
    func writeData(_ data: [[String]]) -> String {
        var csvLines: [String] = []
        
        for row in data {
            let csvRow = writeRow(row)
            csvLines.append(csvRow)
        }
        
        return csvLines.joined(separator: "\n")
    }
    
    private func writeRow(_ row: [String]) -> String {
        let processedFields = row.map { field in
            processField(field)
        }
        
        return processedFields.joined(separator: configuration.columnSeparator)
    }
    
    private func processField(_ field: String) -> String {
        let needsQuoting = shouldQuoteField(field)
        
        if needsQuoting {
            let escapedField = escapeField(field)
            return "\(configuration.quoteCharacter)\(escapedField)\(configuration.quoteCharacter)"
        } else {
            return field
        }
    }
    
    private func shouldQuoteField(_ field: String) -> Bool {
        // Quote if field contains separator, quote character, or newlines
        return field.contains(configuration.columnSeparator) ||
               field.contains(configuration.quoteCharacter) ||
               field.contains("\n") ||
               field.contains("\r") ||
               field.hasPrefix(" ") ||
               field.hasSuffix(" ")
    }
    
    private func escapeField(_ field: String) -> String {
        // Escape quote characters within the field
        if configuration.escapeCharacter == configuration.quoteCharacter {
            // Double-quote escaping (standard CSV)
            return field.replacingOccurrences(of: configuration.quoteCharacter, 
                                            with: configuration.quoteCharacter + configuration.quoteCharacter)
        } else {
            // Backslash or other character escaping
            return field.replacingOccurrences(of: configuration.quoteCharacter, 
                                            with: configuration.escapeCharacter + configuration.quoteCharacter)
        }
    }
    
    func writeToData(_ data: [[String]]) -> Data? {
        let csvString = writeData(data)
        return csvString.data(using: configuration.encoding)
    }
}
