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
    @State private var focusedCell: CellPosition?
    @State private var columnWidths: [CGFloat] = []
    @State private var dragStartWidths: [CGFloat] = []
    
    private let defaultColumnWidth: CGFloat = 120
    private let minColumnWidth: CGFloat = 50
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) {
                // Header row if configured
                if document.configuration.firstRowAsHeader && !document.data.isEmpty {
                    HStack(spacing: 0) {
                        ForEach(0..<document.maxColumnCount, id: \.self) { columnIndex in
                            HStack(spacing: 0) {
                                HeaderCell(
                                    text: columnIndex < document.data[0].count ? document.data[0][columnIndex] : "",
                                    isSelected: selectedColumns.contains(columnIndex),
                                    width: getColumnWidth(columnIndex)
                                ) {
                                    toggleColumnSelection(columnIndex)
                                }
                                
                                if columnIndex < document.maxColumnCount - 1 {
                                    ColumnResizeHandle(columnIndex: columnIndex) { translation in
                                        resizeColumn(columnIndex, translation: translation)
                                    } onDragStart: {
                                        startColumnResize()
                                    } onDragEnd: { finalTranslation in
                                        endColumnResize(columnIndex, finalTranslation: finalTranslation)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Data rows
                ForEach(dataRowIndices, id: \.self) { rowIndex in
                    HStack(spacing: 0) {
                        ForEach(0..<document.maxColumnCount, id: \.self) { columnIndex in
                            HStack(spacing: 0) {
                                DataCell(
                                    text: cellValue(row: rowIndex, column: columnIndex),
                                    isSelected: selectedCells.contains(CellPosition(row: rowIndex, column: columnIndex)),
                                    isRowSelected: selectedRows.contains(rowIndex),
                                    isColumnSelected: selectedColumns.contains(columnIndex),
                                    isCurrentlyFocused: focusedCell == CellPosition(row: rowIndex, column: columnIndex),
                                    position: CellPosition(row: rowIndex, column: columnIndex),
                                    width: getColumnWidth(columnIndex)
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
                                
                                if columnIndex < document.maxColumnCount - 1 {
                                    ColumnResizeHandle(columnIndex: columnIndex) { translation in
                                        resizeColumn(columnIndex, translation: translation)
                                    } onDragStart: {
                                        startColumnResize()
                                    } onDragEnd: { finalTranslation in
                                        endColumnResize(columnIndex, finalTranslation: finalTranslation)
                                    }
                                }
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
        .onKeyPress(.tab) {
            handleTabNavigation()
            return .handled
        }
        .onAppear {
            initializeColumnWidths()
        }
        .onChange(of: document.maxColumnCount) { _, _ in
            initializeColumnWidths()
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
        focusedCell = position
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
        focusedCell = nil
    }
    
    private func handleTabNavigation() {
        // If no cell is currently focused, start with the first cell
        guard let currentFocus = focusedCell else {
            let startRowIndex = document.configuration.firstRowAsHeader ? 1 : 0
            if startRowIndex < document.data.count {
                let firstCell = CellPosition(row: startRowIndex, column: 0)
                selectCell(firstCell)
            }
            return
        }
        
        // Move to next column in the same row
        let nextColumn = currentFocus.column + 1
        if nextColumn < document.maxColumnCount {
            let nextCell = CellPosition(row: currentFocus.row, column: nextColumn)
            selectCell(nextCell)
            return
        }
        
        // Move to first column of the next row
        let nextRow = currentFocus.row + 1
        if nextRow < document.data.count {
            let nextCell = CellPosition(row: nextRow, column: 0)
            selectCell(nextCell)
            return
        }
        
        // If we're at the end, do nothing (as requested)
    }
    
    private func initializeColumnWidths() {
        let columnCount = document.maxColumnCount
        if columnWidths.count != columnCount {
            columnWidths = Array(repeating: defaultColumnWidth, count: columnCount)
        }
    }
    
    private func getColumnWidth(_ columnIndex: Int) -> CGFloat {
        guard columnIndex < columnWidths.count else {
            return defaultColumnWidth
        }
        return columnWidths[columnIndex]
    }
    
    private func startColumnResize() {
        dragStartWidths = columnWidths
    }
    
    private func resizeColumn(_ columnIndex: Int, translation: CGFloat) {
        // Do nothing during drag - no state changes to avoid jitter
    }
    
    private func endColumnResize(_ columnIndex: Int, finalTranslation: CGFloat) {
        guard columnIndex < columnWidths.count && columnIndex < dragStartWidths.count else { return }
        
        let startingWidth = dragStartWidths[columnIndex]
        let newWidth = max(minColumnWidth, startingWidth + finalTranslation)
        columnWidths[columnIndex] = newWidth
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
    let width: CGFloat
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
        .frame(width: width, height: 28)
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
    let isCurrentlyFocused: Bool
    let position: CellPosition
    let width: CGFloat
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
        .frame(width: width, height: 24) // Dynamic width for resizable columns
        .contentShape(Rectangle()) // Make entire area tappable
        .gesture(
            // Prioritize drag gesture over taps to fix gesture conflicts
            DragGesture()
                .onChanged { value in
                    // Use location-based calculation instead of translation
                    let cellWidth: CGFloat = width
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
                    
                    // If the drag was minimal, treat it as a tap for selection
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
        .onTapGesture {
            // Single tap to edit
            if !isEditing {
                editingText = text
                isEditing = true
            }
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

struct ColumnResizeHandle: View {
    let columnIndex: Int
    let onResize: (CGFloat) -> Void
    let onDragStart: () -> Void
    let onDragEnd: (CGFloat) -> Void
    
    @State private var isDragging = false
    @State private var finalTranslation: CGFloat = 0
    
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 4, height: .infinity)
            .contentShape(Rectangle())
            .onHover { isHovering in
                if isHovering {
                    NSCursor.resizeLeftRight.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            onDragStart()
                        }
                        
                        finalTranslation = value.translation.width
                        // Don't call onResize during drag to avoid state changes
                    }
                    .onEnded { _ in
                        isDragging = false
                        NSCursor.arrow.set()
                        onDragEnd(finalTranslation)
                    }
            )
            .overlay(
                Rectangle()
                    .fill(isDragging ? Color.accentColor : Color.clear)
                    .frame(width: 1)
            )
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
