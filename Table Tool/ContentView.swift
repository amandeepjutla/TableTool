//
//  ContentView.swift
//  Table Tool
//
//  Created by Claude on 2025-06-27.
//  Copyright (c) 2025 Egger Apps. All rights reserved.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @Binding var document: CSVDocument
    @State private var selectedRows: Set<Int> = []
    @State private var selectedColumns: Set<Int> = []
    @State private var showingFormatSheet = false
    
    var body: some View {
        NavigationSplitView {
            FormatSidebar(document: $document, showingFormatSheet: $showingFormatSheet)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            CSVTableView(
                document: $document,
                selectedRows: $selectedRows,
                selectedColumns: $selectedColumns
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Add Row") {
                    document.addRow()
                }
                .help("Add a new row")
                
                Button("Add Column") {
                    document.addColumn()
                }
                .help("Add a new column")
                
                Button("Delete Row") {
                    if let firstSelected = selectedRows.first {
                        document.deleteRow(at: firstSelected)
                        selectedRows.remove(firstSelected)
                    }
                }
                .help("Delete selected row")
                .disabled(selectedRows.isEmpty)
                
                Button("Delete Column") {
                    if let firstSelected = selectedColumns.first {
                        document.deleteColumn(at: firstSelected)
                        selectedColumns.remove(firstSelected)
                    }
                }
                .help("Delete selected column")
                .disabled(selectedColumns.isEmpty)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .addRow)) { _ in
            document.addRow()
        }
        .onReceive(NotificationCenter.default.publisher(for: .addColumn)) { _ in
            document.addColumn()
        }
        .onReceive(NotificationCenter.default.publisher(for: .deleteRow)) { _ in
            if let firstSelected = selectedRows.first {
                document.deleteRow(at: firstSelected)
                selectedRows.remove(firstSelected)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .deleteColumn)) { _ in
            if let firstSelected = selectedColumns.first {
                document.deleteColumn(at: firstSelected)
                selectedColumns.remove(firstSelected)
            }
        }
        .sheet(isPresented: $showingFormatSheet) {
            FormatConfigurationView(document: $document)
        }
    }
}

struct FormatSidebar: View {
    @Binding var document: CSVDocument
    @Binding var showingFormatSheet: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CSV Format")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Separator: \(document.configuration.columnSeparator)")
                Text("Quote: \(document.configuration.quoteCharacter)")
                Text("Encoding: \(encodingName)")
                Text("First row as header: \(document.configuration.firstRowAsHeader ? "Yes" : "No")")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Button("Configure Format...") {
                showingFormatSheet = true
            }
            
            Divider()
            
            Text("Document Info")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Rows: \(document.data.count)")
                Text("Columns: \(document.maxColumnCount)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Divider()
            
            Text("💡 Tip")
                .font(.headline)
            
            Text("To use tabs, drag one window into another, or use Window → Merge All Windows (⌥⌘M)")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var encodingName: String {
        CSVConfiguration.supportedEncodings.first { $0.encoding == document.configuration.encoding }?.name ?? "Unknown"
    }
}

#Preview {
    ContentView(document: .constant(CSVDocument()))
}