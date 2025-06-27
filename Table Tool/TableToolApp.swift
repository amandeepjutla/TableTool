//
//  TableToolApp.swift
//  Table Tool
//
//  Created by Claude on 2025-06-27.
//  Copyright (c) 2025 Egger Apps. All rights reserved.
//

import SwiftUI
import AppKit

@main
struct TableToolApp: App {
    init() {
        // Set window tabbing preference to automatic
        NSWindow.allowsAutomaticWindowTabbing = true
    }
    
    var body: some Scene {
        DocumentGroup(newDocument: CSVDocument()) { file in
            ContentView(document: file.$document)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.automatic)
        .commands {
            CSVCommands()
            WindowCommands()
        }
    }
}

struct WindowCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .windowArrangement) {
            Divider()
            
            Button("Merge All Windows") {
                // This will merge all windows into tabs
                NSApplication.shared.windows.forEach { window in
                    if let windowController = window.windowController {
                        window.tabbingMode = .preferred
                    }
                }
            }
            .keyboardShortcut("m", modifiers: [.command, .option])
            
            Button("Show Previous Tab") {
                NSApplication.shared.keyWindow?.selectPreviousTab(nil)
            }
            .keyboardShortcut("[", modifiers: [.command, .shift])
            
            Button("Show Next Tab") {
                NSApplication.shared.keyWindow?.selectNextTab(nil)
            }
            .keyboardShortcut("]", modifiers: [.command, .shift])
        }
    }
}

struct CSVCommands: Commands {
    var body: some Commands {
        CommandMenu("CSV") {
            Button("Add Row") {
                // This will be handled by the ContentView
                NotificationCenter.default.post(name: .addRow, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)
            
            Button("Add Column") {
                NotificationCenter.default.post(name: .addColumn, object: nil)
            }
            .keyboardShortcut("c", modifiers: .command)
            
            Divider()
            
            Button("Delete Row") {
                NotificationCenter.default.post(name: .deleteRow, object: nil)
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            
            Button("Delete Column") {
                NotificationCenter.default.post(name: .deleteColumn, object: nil)
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
        }
    }
}

// MARK: - Notification names
extension Notification.Name {
    static let addRow = Notification.Name("addRow")
    static let addColumn = Notification.Name("addColumn")
    static let deleteRow = Notification.Name("deleteRow")
    static let deleteColumn = Notification.Name("deleteColumn")
}