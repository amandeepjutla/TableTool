//
//  CSVHeuristic.swift
//  Table2
//
//  Table2 created by Claude on 2025-06-27 for tifalab
//  Original TableTool (c) 2015 Egger Apps. All rights reserved//

import Foundation

class CSVHeuristic {
    static func detectConfiguration(from data: Data) throws -> CSVConfiguration {
        let possibleConfigurations = generateSmartConfigurations(from: data)
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
    
    @MainActor
    static func detectConfigurationAsync(from data: Data, progress: @escaping (Double) -> Void) async throws -> CSVConfiguration {
        let possibleConfigurations = generateSmartConfigurations(from: data)
        var bestConfiguration: CSVConfiguration?
        var bestScore = -1
        
        let totalConfigs = possibleConfigurations.count
        
        return await withTaskGroup(of: (CSVConfiguration, Int).self) { group in
            var processedCount = 0
            
            // Process configurations in batches to avoid overwhelming the system
            let batchSize = min(8, totalConfigs) // Process 8 at a time
            for i in stride(from: 0, to: totalConfigs, by: batchSize) {
                let endIndex = min(i + batchSize, totalConfigs)
                let batch = Array(possibleConfigurations[i..<endIndex])
                
                for config in batch {
                    group.addTask {
                        let score = await Task.detached {
                            evaluateConfiguration(config, with: data)
                        }.value
                        return (config, score)
                    }
                }
            }
            
            // Collect results and update progress
            for await (config, score) in group {
                if score > bestScore {
                    bestScore = score
                    bestConfiguration = config
                }
                
                processedCount += 1
                let progressValue = Double(processedCount) / Double(totalConfigs)
                progress(progressValue)
            }
            
            return bestConfiguration ?? CSVConfiguration()
        }
    }
    
    private static func generateSmartConfigurations(from data: Data) -> [CSVConfiguration] {
        var configurations: [CSVConfiguration] = []
        
        // First, try to detect encoding intelligently
        let detectedEncodings = intelligentEncodingDetection(data: data)
        
        // Then detect likely separators by analyzing the first few lines
        let likelySeparators = detectLikelySeparators(from: data, encodings: detectedEncodings)
        
        let quotes = ["\"", "'"]
        let escapes = ["\"", "\\"]
        
        // Generate configurations only for detected encodings and likely separators
        for encoding in detectedEncodings {
            for separator in likelySeparators {
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
    
    private static func intelligentEncodingDetection(data: Data) -> [String.Encoding] {
        var encodings: [String.Encoding] = []
        
        // Check for BOM markers
        if data.count >= 3 {
            let bom = data.prefix(3)
            if bom == Data([0xEF, 0xBB, 0xBF]) {
                encodings.append(.utf8)
                return encodings // UTF-8 BOM found, very likely UTF-8
            }
        }
        
        if data.count >= 2 {
            let bom = data.prefix(2)
            if bom == Data([0xFF, 0xFE]) || bom == Data([0xFE, 0xFF]) {
                encodings.append(.utf16)
                return encodings // UTF-16 BOM found
            }
        }
        
        // Try UTF-8 first (most common)
        if String(data: data, encoding: .utf8) != nil {
            encodings.append(.utf8)
        }
        
        // Try other common encodings
        let fallbackEncodings: [String.Encoding] = [.windowsCP1252, .macOSRoman]
        for encoding in fallbackEncodings {
            if String(data: data, encoding: encoding) != nil {
                encodings.append(encoding)
            }
        }
        
        // If nothing worked, fall back to UTF-8
        if encodings.isEmpty {
            encodings.append(.utf8)
        }
        
        return encodings
    }
    
    private static func detectLikelySeparators(from data: Data, encodings: [String.Encoding]) -> [String] {
        let allSeparators = [",", ";", "\t", "|", " "]
        var separatorCounts: [String: Int] = [:]
        
        // Try with the first encoding that works
        guard let encoding = encodings.first,
              let csvString = String(data: data, encoding: encoding) else {
            return [","] // Default fallback
        }
        
        // Analyze first 1000 characters or 10 lines, whichever comes first
        let sampleString = String(csvString.prefix(1000))
        let lines = sampleString.components(separatedBy: .newlines).prefix(10)
        
        for separator in allSeparators {
            var totalCount = 0
            for line in lines {
                let count = line.components(separatedBy: separator).count - 1
                totalCount += count
            }
            separatorCounts[separator] = totalCount
        }
        
        // Return separators with significant presence, prioritizing common ones
        let likelySeparators = separatorCounts
            .filter { $0.value > 0 }
            .sorted { first, second in
                // Prioritize comma, then semicolon, then tab, then others
                let priority = [",": 4, ";": 3, "\t": 2, "|": 1]
                let firstPriority = priority[first.key] ?? 0
                let secondPriority = priority[second.key] ?? 0
                
                if firstPriority != secondPriority {
                    return firstPriority > secondPriority
                }
                return first.value > second.value
            }
            .prefix(3) // Only take top 3 candidates
            .map { $0.key }
        
        return likelySeparators.isEmpty ? [","] : Array(likelySeparators)
    }
    
    private static func generatePossibleConfigurations() -> [CSVConfiguration] {
        // Keep the old method for backward compatibility, but mark as deprecated
        var configurations: [CSVConfiguration] = []
        
        let separators = [",", ";", "\t", "|"]
        let quotes = ["\"", "'"]
        let escapes = ["\"", "\\"]
        let encodings: [String.Encoding] = [.utf8, .windowsCP1252, .macOSRoman]
        
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
