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
    @State private var dragStartPosition: CellPosition?
    @State private var isDragging = false
    
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
                            } onDragStart: { position in
                                startDrag(at: position)
                            } onDragUpdate: { position in
                                updateDragSelection(to: position)
                            } onDragEnd: {
                                endDrag()
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onTapGesture {
            // Clear selections when tapping on ScrollView background
            clearAllSelections()
        }
        .onKeyPress(.escape) {
            clearAllSelections()
            return .handled
        }
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
    
    private func startDrag(at position: CellPosition) {
        dragStartPosition = position
        isDragging = true
        selectedCells = [position]
        selectedRows.removeAll()
        selectedColumns.removeAll()
    }
    
    private func updateDragSelection(to position: CellPosition) {
        guard let startPosition = dragStartPosition, isDragging else { return }
        
        // Clamp the target position to valid bounds
        let clampedRow = max(0, min(position.row, document.data.count - 1))
        let clampedColumn = max(0, min(position.column, document.maxColumnCount - 1))
        let clampedPosition = CellPosition(row: clampedRow, column: clampedColumn)
        
        let minRow = min(startPosition.row, clampedPosition.row)
        let maxRow = max(startPosition.row, clampedPosition.row)
        let minColumn = min(startPosition.column, clampedPosition.column)
        let maxColumn = max(startPosition.column, clampedPosition.column)
        
        var newSelection: Set<CellPosition> = []
        for row in minRow...maxRow {
            for column in minColumn...maxColumn {
                newSelection.insert(CellPosition(row: row, column: column))
            }
        }
        
        selectedCells = newSelection
    }
    
    private func endDrag() {
        isDragging = false
        dragStartPosition = nil
    }
    
    private func clearAllSelections() {
        selectedCells.removeAll()
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
                .fill(isSelected ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.1))
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
    let onDragStart: (CellPosition) -> Void
    let onDragUpdate: (CellPosition) -> Void
    let onDragEnd: () -> Void
    
    @State private var isEditing = false
    @State private var editingText = ""
    @State private var isDragActive = false
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
            HStack {
                if isEditing {
                    TextField("", text: $editingText)
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                        .onSubmit {
                            onTextChange(editingText)
                            isEditing = false
                        }
                        .onExitCommand {
                            editingText = text
                            isEditing = false
                        }
                } else {
                    Text(text.isEmpty ? " " : text) // Ensure empty cells have content
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 120, height: 24) // Fixed size for consistent grid
        .contentShape(Rectangle()) // Make entire area tappable
        .gesture(
            // Prioritize drag gesture over taps to fix gesture conflicts
            DragGesture()
                .onChanged { value in
                    // Use location-based calculation instead of translation
                    let cellWidth: CGFloat = 120
                    let cellHeight: CGFloat = 24
                    
                    // Calculate the offset from start position
                    let offsetX = value.location.x - value.startLocation.x
                    let offsetY = value.location.y - value.startLocation.y
                    
                    // Only start drag selection if we've moved a meaningful distance
                    if abs(offsetX) > 5 || abs(offsetY) > 5 {
                        // Initialize drag if not already active
                        if !isDragActive {
                            isDragActive = true
                            onDragStart(position)
                        }
                        
                        // Calculate target cell position
                        let columnOffset = Int(round(offsetX / cellWidth))
                        let rowOffset = Int(round(offsetY / cellHeight))
                        
                        let targetColumn = position.column + columnOffset
                        let targetRow = position.row + rowOffset
                        
                        let targetPosition = CellPosition(row: targetRow, column: targetColumn)
                        onDragUpdate(targetPosition)
                    }
                }
                .onEnded { value in
                    let offsetX = value.location.x - value.startLocation.x
                    let offsetY = value.location.y - value.startLocation.y
                    
                    // If the drag was minimal, treat it as a tap
                    if abs(offsetX) <= 5 && abs(offsetY) <= 5 {
                        if !isEditing {
                            onCellTap(position)
                        }
                    } else if isDragActive {
                        // End drag selection
                        onDragEnd()
                    }
                    
                    // Reset drag state
                    isDragActive = false
                }
        )
        .onTapGesture(count: 2) {
            // Double tap to edit
            editingText = text
            isEditing = true
        }
        .onChange(of: isEditing) { _, editing in
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
