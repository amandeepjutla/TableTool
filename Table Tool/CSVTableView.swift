//
//  CSVTableView.swift
//  Table Tool
//
//  Created by Claude on 2025-06-27.
//  Copyright (c) 2025 Egger Apps. All rights reserved.
//

import SwiftUI
import Foundation

struct CSVTableView: View {
    @Binding var document: CSVDocument
    @Binding var selectedRows: Set<Int>
    @Binding var selectedColumns: Set<Int>
    @State private var selectedCells: Set<CellPosition> = []
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) {
                // Header row if configured
                if document.configuration.firstRowAsHeader && !document.data.isEmpty {
                    HStack(spacing: 0) {
                        ForEach(0..<document.maxColumnCount, id: \.self) { columnIndex in
                            HeaderCell(
                                text: columnIndex < document.data[0].count ? document.data[0][columnIndex] : "",
                                isSelected: selectedColumns.contains(columnIndex)
                            ) {
                                toggleColumnSelection(columnIndex)
                            }
                        }
                    }
                }
                
                // Data rows
                ForEach(dataRowIndices, id: \.self) { rowIndex in
                    HStack(spacing: 0) {
                        ForEach(0..<document.maxColumnCount, id: \.self) { columnIndex in
                            DataCell(
                                text: cellValue(row: rowIndex, column: columnIndex),
                                isSelected: selectedCells.contains(CellPosition(row: rowIndex, column: columnIndex)),
                                isRowSelected: selectedRows.contains(rowIndex),
                                isColumnSelected: selectedColumns.contains(columnIndex),
                                position: CellPosition(row: rowIndex, column: columnIndex)
                            ) { newValue in
                                document.updateCell(row: rowIndex, column: columnIndex, value: newValue)
                            } onCellTap: { position in
                                selectCell(position)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var dataRowIndices: Range<Int> {
        let startIndex = document.configuration.firstRowAsHeader ? 1 : 0
        return startIndex..<document.data.count
    }
    
    private func cellValue(row: Int, column: Int) -> String {
        guard row < document.data.count, column < document.data[row].count else {
            return ""
        }
        return document.data[row][column]
    }
    
    private func selectCell(_ position: CellPosition) {
        // Clear previous selection and select only this cell
        selectedCells = [position]
        selectedRows.removeAll()
        selectedColumns.removeAll()
    }
    
    
    private func toggleRowSelection(_ row: Int) {
        if selectedRows.contains(row) {
            selectedRows.remove(row)
        } else {
            selectedRows.insert(row)
        }
    }
    
    private func toggleColumnSelection(_ column: Int) {
        if selectedColumns.contains(column) {
            selectedColumns.remove(column)
        } else {
            selectedColumns.insert(column)
        }
    }
}

struct CellPosition: Hashable {
    let row: Int
    let column: Int
}

struct HeaderCell: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(isSelected ? Color.accentColor.opacity(0.3) : Color(NSColor.headerColor))
                .overlay(
                    Rectangle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                )
            
            Text(text)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
        }
        .frame(width: 120, height: 28)
        .onTapGesture {
            onTap()
        }
    }
}

struct DataCell: View {
    let text: String
    let isSelected: Bool
    let isRowSelected: Bool
    let isColumnSelected: Bool
    let position: CellPosition
    let onTextChange: (String) -> Void
    let onCellTap: (CellPosition) -> Void
    
    @State private var isEditing = false
    @State private var editingText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            // Background that covers the entire cell area
            Rectangle()
                .fill(backgroundColor)
                .overlay(
                    Rectangle()
                        .stroke(strokeColor, lineWidth: strokeWidth)
                )
            
            // Content
            if isEditing {
                TextField("", text: $editingText)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .background(Color.white)
                    .onSubmit {
                        onTextChange(editingText)
                        isEditing = false
                    }
                    .onExitCommand {
                        editingText = text
                        isEditing = false
                    }
                    .padding(.horizontal, 4)
            } else {
                HStack {
                    Text(text.isEmpty ? " " : text) // Ensure empty cells have content
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(width: 120, height: 24) // Fixed size for consistent grid
        .contentShape(Rectangle()) // Make entire area tappable
        .onTapGesture(count: 2) {
            // Double tap to edit - this needs to come first to take precedence
            editingText = text
            isEditing = true
        }
        .onTapGesture {
            // Single tap to select
            if !isEditing {
                onCellTap(position)
            }
        }
        .onChange(of: isEditing) { editing in
            if editing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocused = true
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.6)
        } else {
            return Color(NSColor.controlBackgroundColor)
        }
    }
    
    private var strokeColor: Color {
        if isSelected {
            return Color.accentColor
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    private var strokeWidth: CGFloat {
        return isSelected ? 2.0 : 0.5
    }
}

#Preview {
    CSVTableView(
        document: .constant(CSVDocument(data: [
            ["Name", "Age", "City"],
            ["John", "25", "New York"],
            ["Jane", "30", "San Francisco"]
        ])),
        selectedRows: .constant([]),
        selectedColumns: .constant([])
    )
}