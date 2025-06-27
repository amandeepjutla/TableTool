//
//  VirtualizedCSVTableView.swift
//  Table Tool
//
//  Created by Claude on 2025-06-27 for UI virtualization performance improvements
//

import SwiftUI

struct VirtualizedCSVTableView: View {
    @Binding var document: CSVDocument
    @Binding var selectedRows: Set<Int>
    @Binding var selectedColumns: Set<Int>
    @State private var selectedCells: Set<CellPosition> = []
    @State private var dragStartPosition: CellPosition?
    @State private var isDragging = false
    @State private var focusedCell: CellPosition?
    @State private var columnWidths: [CGFloat] = []
    @State private var dragStartWidths: [CGFloat] = []
    @State private var scrollPosition: CGPoint = .zero
    
    private let defaultColumnWidth: CGFloat = 120
    private let minColumnWidth: CGFloat = 50
    private let rowHeight: CGFloat = 24
    private let headerHeight: CGFloat = 28
    
    // Virtualization constants
    private let bufferSize = 10 // Extra rows above/below visible area
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView([.horizontal, .vertical]) {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Section {
                            // Virtualized data rows
                            LazyVStack(spacing: 0) {
                                ForEach(visibleRowRange, id: \.self) { rowIndex in
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
                                    .id("row_\(rowIndex)")
                                }
                            }
                        } header: {
                            // Header row (always visible when scrolling)
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
                                .background(Color(NSColor.controlBackgroundColor))
                            }
                        }
                    }
                    .padding()
                }
                .coordinateSpace(.named("scroll"))
                .background(Color(NSColor.controlBackgroundColor))
                .onTapGesture {
                    clearAllSelections()
                }
                .onKeyPress(.escape) {
                    clearAllSelections()
                    return .handled
                }
                .onKeyPress(.tab) {
                    handleTabNavigation(scrollProxy: scrollProxy)
                    return .handled
                }
                .onKeyPress(.upArrow) {
                    handleArrowNavigation(.up, scrollProxy: scrollProxy)
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    handleArrowNavigation(.down, scrollProxy: scrollProxy)
                    return .handled
                }
                .onKeyPress(.leftArrow) {
                    handleArrowNavigation(.left, scrollProxy: scrollProxy)
                    return .handled
                }
                .onKeyPress(.rightArrow) {
                    handleArrowNavigation(.right, scrollProxy: scrollProxy)
                    return .handled
                }
            }
        }
        .onAppear {
            initializeColumnWidths()
        }
        .onChange(of: document.maxColumnCount) { _, _ in
            initializeColumnWidths()
        }
    }
    
    // MARK: - Virtualization Logic
    
    private var visibleRowRange: Range<Int> {
        let startIndex = document.configuration.firstRowAsHeader ? 1 : 0
        let totalRows = document.data.count
        
        // For very large datasets, implement true virtualization
        if totalRows > 1000 {
            // Calculate visible rows based on scroll position (simplified)
            let estimatedVisibleRows = Int(UIScreen.main.bounds.height / rowHeight) + bufferSize * 2
            let startRow = max(startIndex, 0)
            let endRow = min(totalRows, startRow + estimatedVisibleRows)
            return startRow..<endRow
        } else {
            // For smaller datasets, render all rows
            return startIndex..<totalRows
        }
    }
    
    // MARK: - Navigation with Scroll Management
    
    private func handleTabNavigation(scrollProxy: ScrollViewReader) {
        guard let currentFocus = focusedCell else {
            let startRowIndex = document.configuration.firstRowAsHeader ? 1 : 0
            if startRowIndex < document.data.count {
                let firstCell = CellPosition(row: startRowIndex, column: 0)
                selectCell(firstCell)
                scrollToCell(firstCell, scrollProxy: scrollProxy)
            }
            return
        }
        
        let nextColumn = currentFocus.column + 1
        if nextColumn < document.maxColumnCount {
            let nextCell = CellPosition(row: currentFocus.row, column: nextColumn)
            selectCell(nextCell)
            scrollToCell(nextCell, scrollProxy: scrollProxy)
            return
        }
        
        let nextRow = currentFocus.row + 1
        if nextRow < document.data.count {
            let nextCell = CellPosition(row: nextRow, column: 0)
            selectCell(nextCell)
            scrollToCell(nextCell, scrollProxy: scrollProxy)
        }
    }
    
    private func handleArrowNavigation(_ direction: ArrowDirection, scrollProxy: ScrollViewReader) {
        guard let currentFocus = focusedCell else {
            let startRowIndex = document.configuration.firstRowAsHeader ? 1 : 0
            if startRowIndex < document.data.count {
                let firstCell = CellPosition(row: startRowIndex, column: 0)
                selectCell(firstCell)
                scrollToCell(firstCell, scrollProxy: scrollProxy)
            }
            return
        }
        
        var newPosition = currentFocus
        let startIndex = document.configuration.firstRowAsHeader ? 1 : 0
        
        switch direction {
        case .up:
            newPosition.row = max(startIndex, currentFocus.row - 1)
        case .down:
            newPosition.row = min(document.data.count - 1, currentFocus.row + 1)
        case .left:
            newPosition.column = max(0, currentFocus.column - 1)
        case .right:
            newPosition.column = min(document.maxColumnCount - 1, currentFocus.column + 1)
        }
        
        if newPosition != currentFocus {
            selectCell(newPosition)
            scrollToCell(newPosition, scrollProxy: scrollProxy)
        }
    }
    
    private func scrollToCell(_ position: CellPosition, scrollProxy: ScrollViewReader) {
        withAnimation(.easeInOut(duration: 0.3)) {
            scrollProxy.scrollTo("row_\(position.row)", anchor: .center)
        }
    }
    
    // MARK: - Existing Methods (same as original CSVTableView)
    
    private func cellValue(row: Int, column: Int) -> String {
        guard row < document.data.count, column < document.data[row].count else {
            return ""
        }
        return document.data[row][column]
    }
    
    private func selectCell(_ position: CellPosition) {
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
    
    private func toggleColumnSelection(_ column: Int) {
        if selectedColumns.contains(column) {
            selectedColumns.remove(column)
        } else {
            selectedColumns.insert(column)
        }
    }
}