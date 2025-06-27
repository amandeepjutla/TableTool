//
//  CSVHeuristic.swift
//  Table2
//
//  Table2 created by Claude on 2025-06-27 for tifalab
//  Original TableTool (c) 2015 Egger Apps. All rights reserved//

import Foundation

class CSVHeuristic {
    static func detectConfiguration(from data: Data) throws -> CSVConfiguration {
        let possibleConfigurations = generatePossibleConfigurations()
        var bestConfiguration: CSVConfiguration?
        var bestScore = -1
        
        for config in possibleConfigurations {
            let score = evaluateConfiguration(config, with: data)
            if score > bestScore {
                bestScore = score
                bestConfiguration = config
            }
        }
        
        return bestConfiguration ?? CSVConfiguration()
    }
    
    private static func generatePossibleConfigurations() -> [CSVConfiguration] {
        var configurations: [CSVConfiguration] = []
        
        let separators = [",", ";", "\t", "|"]
        let quotes = ["\"", "'"]
        let escapes = ["\"", "\\"]
        let encodings: [String.Encoding] = [.utf8, .windowsCP1252, .macOSRoman, String.Encoding(rawValue: 0x80000632)]
        
        for encoding in encodings {
            for separator in separators {
                for quote in quotes {
                    for escape in escapes {
                        var config = CSVConfiguration()
                        config.encoding = encoding
                        config.columnSeparator = separator
                        config.quoteCharacter = quote
                        config.escapeCharacter = escape
                        configurations.append(config)
                        
                        // Also try with first row as header
                        var configWithHeader = config
                        configWithHeader.firstRowAsHeader = true
                        configurations.append(configWithHeader)
                    }
                }
            }
        }
        
        return configurations
    }
    
    private static func evaluateConfiguration(_ config: CSVConfiguration, with data: Data) -> Int {
        guard let csvString = String(data: data, encoding: config.encoding) else {
            return -1
        }
        
        let reader = CSVReader(string: csvString, configuration: config)
        var score = 0
        var rowCount = 0
        var columnCounts: [Int] = []
        
        do {
            while let row = try reader.readLine(), rowCount < 10 { // Only check first 10 rows for performance
                columnCounts.append(row.count)
                rowCount += 1
                
                // Bonus for consistent column counts
                if columnCounts.count > 1 && columnCounts.last == columnCounts[columnCounts.count - 2] {
                    score += 10
                }
                
                // Bonus for reasonable number of columns (2-50)
                if row.count >= 2 && row.count <= 50 {
                    score += 5
                }
                
                // Penalty for very short or very long rows
                if row.count == 1 {
                    score -= 2
                } else if row.count > 50 {
                    score -= 5
                }
                
                // Bonus for non-empty cells
                let nonEmptyCells = row.filter { !$0.isEmpty }.count
                score += nonEmptyCells
            }
        } catch {
            return -1
        }
        
        // Bonus for having multiple rows
        if rowCount > 1 {
            score += 20
        }
        
        // Bonus for consistent column structure
        if let mostCommonCount = mostFrequent(in: columnCounts) {
            let consistentRows = columnCounts.filter { $0 == mostCommonCount }.count
            score += consistentRows * 5
        }
        
        return score
    }
    
    private static func mostFrequent<T: Hashable>(in array: [T]) -> T? {
        let counts = array.reduce(into: [:]) { counts, element in
            counts[element, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
