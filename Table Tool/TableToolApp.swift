//
//  TableToolApp.swift
//  Table2
//
//  Table2 created by Claude on 2025-06-27 for tifalab
//  Original TableTool (c) 2015 Egger Apps. All rights reserved
//

import SwiftUI
import AppKit

// MARK: - App Settings
@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    private let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static let restoreWindowsOnLaunch = "restoreWindowsOnLaunch"
        static let openDocumentPaths = "openDocumentPaths"
    }
    
    @Published var restoreWindowsOnLaunch: Bool {
        didSet {
            userDefaults.set(restoreWindowsOnLaunch, forKey: Keys.restoreWindowsOnLaunch)
        }
    }
    
    private var openDocumentPaths: [String] {
        get {
            userDefaults.stringArray(forKey: Keys.openDocumentPaths) ?? []
        }
        set {
            userDefaults.set(newValue, forKey: Keys.openDocumentPaths)
        }
    }
    
    private init() {
        self.restoreWindowsOnLaunch = userDefaults.object(forKey: Keys.restoreWindowsOnLaunch) as? Bool ?? true
    }
    
    func saveOpenDocuments(_ documentURLs: [URL]) {
        let paths: [String] = documentURLs.compactMap { url in
            guard url.isFileURL, FileManager.default.fileExists(atPath: url.path) else { 
                print("DEBUG: Skipping invalid URL: \(url)")
                return nil 
            }
            return url.path
        }
        print("DEBUG: AppSettings saving paths: \(paths)")
        openDocumentPaths = paths
        userDefaults.synchronize()
    }
    
    func getDocumentsToRestore() -> [URL] {
        guard restoreWindowsOnLaunch else { 
            print("DEBUG: Window restoration disabled, returning empty array")
            return [] 
        }
        
        let currentPaths = openDocumentPaths
        print("DEBUG: AppSettings found stored paths: \(currentPaths)")
        
        let urls: [URL] = currentPaths.compactMap { path in
            let url = URL(fileURLWithPath: path)
            guard FileManager.default.fileExists(atPath: path) else { 
                print("DEBUG: File no longer exists: \(path)")
                return nil 
            }
            return url
        }
        print("DEBUG: AppSettings returning \(urls.count) valid URLs")
        return urls
    }
    
    func clearStoredDocuments() {
        openDocumentPaths = []
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @StateObject private var appSettings = AppSettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Table Tool Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            GroupBox("Window Behavior") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Restore windows on launch", isOn: $appSettings.restoreWindowsOnLaunch)
                    
                    Text("When enabled, Table Tool will automatically reopen the CSV files that were open when you last quit the app, even if macOS's global \"Close windows when quitting an app\" setting is enabled.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Done") {
                    NSApplication.shared.keyWindow?.close()
                }
                .keyboardShortcut(.return)
            }
        }
        .padding(20)
        .frame(width: 450, height: 280)
    }
}

// MARK: - App Delegate for Window Restoration
class AppDelegate: NSObject, NSApplicationDelegate {
    private var hasRestoredWindows = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("DEBUG: AppDelegate.applicationDidFinishLaunching called")
        Task { @MainActor in
            // Small delay to let DocumentGroup initialize
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            self.restoreWindowsIfNeeded()
        }
    }
    
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        print("DEBUG: applicationShouldOpenUntitledFile called")
        let appSettings = AppSettings.shared
        
        // Check if we should restore windows instead
        if appSettings.restoreWindowsOnLaunch && !appSettings.getDocumentsToRestore().isEmpty {
            print("DEBUG: Preventing untitled file - will restore documents instead")
            return false
        }
        
        print("DEBUG: Allowing untitled file creation")
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("DEBUG: AppDelegate.applicationWillTerminate called")
        Task { @MainActor in
            saveCurrentWindowState()
        }
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        print("DEBUG: AppDelegate.applicationDidBecomeActive called")
        // Save state periodically
        if hasRestoredWindows {
            Task { @MainActor in
                saveCurrentWindowState()
            }
        }
    }
    
    @MainActor
    private func restoreWindowsIfNeeded() {
        print("DEBUG: AppDelegate.restoreWindowsIfNeeded called")
        guard !hasRestoredWindows else { 
            print("DEBUG: Already restored windows, skipping")
            return 
        }
        hasRestoredWindows = true
        
        let appSettings = AppSettings.shared
        guard appSettings.restoreWindowsOnLaunch else { 
            print("DEBUG: Window restoration is disabled")
            return 
        }
        
        let documentsToRestore = appSettings.getDocumentsToRestore()
        print("DEBUG: Found \(documentsToRestore.count) documents to restore: \(documentsToRestore.map(\.lastPathComponent))")
        
        guard !documentsToRestore.isEmpty else { 
            print("DEBUG: No documents to restore")
            return 
        }
        
        // Close any existing untitled documents first
        let existingDocuments = NSDocumentController.shared.documents
        print("DEBUG: Found \(existingDocuments.count) existing documents")
        
        for document in existingDocuments {
            if document.fileURL == nil {
                print("DEBUG: Closing untitled document")
                document.close()
            }
        }
        
        // Restore the saved documents
        for documentURL in documentsToRestore {
            print("DEBUG: Restoring document: \(documentURL.lastPathComponent)")
            NSDocumentController.shared.openDocument(withContentsOf: documentURL, display: true) { _, _, _ in
                print("DEBUG: Document restoration completed: \(documentURL.lastPathComponent)")
            }
        }
    }
    
    @MainActor
    private func saveCurrentWindowState() {
        print("DEBUG: AppDelegate.saveCurrentWindowState called")
        let appSettings = AppSettings.shared
        guard appSettings.restoreWindowsOnLaunch else { 
            print("DEBUG: Restoration disabled, clearing saved documents")
            appSettings.clearStoredDocuments()
            return 
        }
        
        // Get all currently open document URLs
        let openDocuments = NSDocumentController.shared.documents.compactMap { document -> URL? in
            guard let fileURL = document.fileURL else { 
                print("DEBUG: Skipping untitled document")
                return nil 
            }
            guard FileManager.default.fileExists(atPath: fileURL.path) else { 
                print("DEBUG: Skipping non-existent file: \(fileURL.path)")
                return nil 
            }
            return fileURL
        }
        
        print("DEBUG: Saving \(openDocuments.count) documents: \(openDocuments.map(\.lastPathComponent))")
        appSettings.saveOpenDocuments(openDocuments)
    }
}

@main
struct TableToolApp: App {
    @StateObject private var appSettings = AppSettings.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        print("DEBUG: TableToolApp.init called")
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
            SettingsCommands()
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

struct SettingsCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .appInfo) {
            Button("Settings...") {
                openSettingsWindow()
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
    
    private func openSettingsWindow() {
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        settingsWindow.title = "Settings"
        settingsWindow.contentView = NSHostingView(rootView: SettingsView())
        settingsWindow.center()
        settingsWindow.makeKeyAndOrderFront(nil)
        
        // Keep window reference and prevent deallocation
        settingsWindow.isReleasedWhenClosed = false
    }
}

// MARK: - Notification names
extension Notification.Name {
    static let addRow = Notification.Name("addRow")
    static let addColumn = Notification.Name("addColumn")
    static let deleteRow = Notification.Name("deleteRow")
    static let deleteColumn = Notification.Name("deleteColumn")
}
