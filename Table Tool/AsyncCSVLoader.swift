//
//  AsyncCSVLoader.swift
//  Table Tool
//
//  Created by Claude on 2025-06-27 for performance improvements
//

import Foundation
import SwiftUI

@MainActor
class AsyncCSVLoader: ObservableObject {
    @Published var isLoading = false
    @Published var progress: Double = 0.0
    @Published var error: Error?
    @Published var document: CSVDocument?
    
    func loadDocument(from fileData: Data) async {
        isLoading = true
        progress = 0.0
        error = nil
        document = nil
        
        do {
            // Phase 1: Async heuristic detection (0-60% progress)
            let detectedConfig = try await CSVHeuristic.detectConfigurationAsync(from: fileData) { heuristicProgress in
                self.progress = heuristicProgress * 0.6
            }
            
            // Phase 2: Async CSV parsing (60-100% progress)
            let parsedDocument = await parseCSVAsync(data: fileData, configuration: detectedConfig) { parseProgress in
                self.progress = 0.6 + (parseProgress * 0.4)
            }
            
            document = parsedDocument
            progress = 1.0
            
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    private func parseCSVAsync(data: Data, configuration: CSVConfiguration, progress: @escaping (Double) -> Void) async -> CSVDocument {
        return await withTaskGroup(of: [[String]].self) { group in
            
            group.addTask {
                return await Task.detached {
                    let reader = CSVReader(data: data, configuration: configuration)
                    var parsedData: [[String]] = []
                    var rowCount = 0
                    let estimatedTotalRows = max(1, data.count / 100) // Rough estimate
                    
                    do {
                        while !reader.isAtEnd {
                            if let row = try reader.readLine() {
                                parsedData.append(row)
                                rowCount += 1
                                
                                // Update progress periodically
                                if rowCount % 100 == 0 {
                                    let currentProgress = min(1.0, Double(rowCount) / Double(estimatedTotalRows))
                                    await MainActor.run {
                                        progress(currentProgress)
                                    }
                                }
                            }
                        }
                    } catch {
                        // If parsing fails, create a minimal document
                        parsedData = [[""]]
                    }
                    
                    return parsedData.isEmpty ? [[""]] : parsedData
                }.value
            }
            
            // Wait for parsing to complete
            var finalData: [[String]] = [[""]]
            for await result in group {
                finalData = result
            }
            
            return CSVDocument(data: finalData, configuration: configuration)
        }
    }
}