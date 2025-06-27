# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Table Tool is a macOS native application written in Swift using SwiftUI. It's a simple CSV editor designed to handle various CSV formats, encodings, and delimiters automatically. The app was fully modernized from Objective-C/Cocoa to Swift/SwiftUI in 2025.

## Development Commands

### Building
```bash
# Open in Xcode (primary development environment)
open "Table Tool.xcodeproj"

# Build from command line
xcodebuild -project "Table Tool.xcodeproj" -scheme "Table Tool" -destination "platform=macOS" build

# Clean build
xcodebuild -project "Table Tool.xcodeproj" -scheme "Table Tool" clean
```

### Testing
```bash
# NOTE: Tests are currently broken due to legacy Objective-C test files referencing removed headers
# The legacy test file Table_ToolTests.m references CSVReader.h, CSVConfiguration.h, CSVHeuristic.h 
# which no longer exist after the Swift modernization

# This command will fail until tests are rewritten for Swift:
# xcodebuild -project "Table Tool.xcodeproj" -scheme "Table Tool" -destination "platform=macOS" test
```

## Architecture

### Current Swift Architecture (2025)

**Document Architecture**: Uses SwiftUI's DocumentGroup with FileDocument protocol via `CSVDocument.swift`.

**CSV Processing Engine** (Swift):
- `CSVReader.swift` - Parses CSV files with various formats
- `CSVWriter.swift` - Exports CSV with different configurations  
- `CSVConfiguration.swift` - Manages CSV format settings (delimiters, encoding, quotes)
- `CSVHeuristic.swift` - Automatically detects CSV format using heuristic analysis

**SwiftUI Views**:
- `TableToolApp.swift` - Main App entry point with DocumentGroup
- `ContentView.swift` - Main interface with NavigationSplitView
- `CSVTableView.swift` - Spreadsheet-like table view with cell editing and selection
- `FormatConfigurationView.swift` - Format selection and configuration sheet

### Key Files
- `Info.plist` - App metadata and document type associations (supports CSV and TXT files)
- `Table Tool.entitlements` - Sandboxing permissions for file access
- `Images.xcassets/` - App icon and visual assets

### Test Structure (Legacy - Currently Broken)
- `Table_ToolTests.m` - Legacy Objective-C test suite (broken, references removed headers)
- `Reading Test Documents/` - 15 CSV test cases for parsing edge cases
- `Heuristic Test Documents/` - 18 test cases for format detection
- Tests need to be rewritten in Swift to work with the modernized codebase

## Key Features and Capabilities

### Key Features
- **Automatic Tabbing**: DocumentGroup provides native macOS tabbed windows
  - Open multiple CSV files then use ⌥⌘M to merge into tabs
  - Or drag one window into another to create tabs
- **Modern UI**: NavigationSplitView with sidebar and detail view
- **Spreadsheet-like Editing**: 
  - Single-click to select individual cells
  - Click-drag selection for multi-cell ranges
  - Single-click any cell (including empty ones) to edit inline
  - Enter to save, Escape to cancel
  - TAB key navigation: moves to next cell in row, then to first cell of next row
  - Arrow key navigation: ↑↓←→ moves between cells
  - Click outside table to clear selections
- **Column Resizing**: Drag column borders to adjust width, with minimum width protection
- **Format Detection**: Maintains heuristic CSV format detection
- **Format Configuration**: Clean GroupBox-based UI that works properly on macOS
- **Keyboard Shortcuts**: Cmd+R (add row), Cmd+C (add column), etc.
- **Window Commands**: ⌥⌘M (merge windows), ⌘⇧[ / ⌘⇧] (tab navigation)

### Architecture Changes
- **Removed**: All legacy Objective-C files, NSDocument, AppDelegate, main.m, XIB files
- **Pure Swift**: Complete Swift 6.0 implementation with modern SwiftUI patterns
- **Updated**: Info.plist uses modern UTType system
- **macOS 15+**: Modern deployment target

### Building the Modern Version
1. All Swift files are included in Xcode project
2. No legacy Objective-C files - completely removed from project
3. Build settings configured for Swift 6.0 and macOS 15+
4. Document types properly configured for CSV and text files

## Recent Fixes (2025-06-27)

**CSVTableView.swift Selection - RESOLVED:**
- ✅ Fixed gesture conflicts between tap and drag gestures
- ✅ Implemented location-based drag gesture calculation
- ✅ Eliminated single-click selection delays
- ✅ Added background tap gesture to clear selections
- ✅ Fixed visual state persistence issues after editing
- ✅ Escape key clears selections

**Navigation and Interaction Improvements:**
- ✅ Implemented TAB key navigation for logical cell traversal
- ✅ Added column resizing with draggable borders (jitter-free, snap-to-final)
- ✅ Dynamic column width management with minimum width constraints
- ✅ Hover cursor changes for resize handles
- ✅ Changed cell editing from double-click to single-click
- ✅ Added arrow key navigation (↑↓←→) for cell movement
- ✅ Narrowed sidebar default width (250px → 180px)
- ✅ Removed tip section from sidebar

**Known Issues:**
- **Column Resize Jitter**: ✅ RESOLVED (2025-06-27)
  - **Solution**: Snap-to-final approach - columns resize instantly when drag ends
  - **Behavior**: No live preview during drag, but completely jitter-free result
  - **Implementation**: Zero state changes during drag operation eliminates layout recalculation jitter
  - **User Experience**: Clean, smooth column resizing with visual cursor feedback during drag

**Technical Implementation:**
- Single `.gesture()` modifier with proper gesture prioritization
- Location-based drag calculation using `offsetX/offsetY` from start position
- 5-pixel drag threshold to distinguish taps from drags
- Background tap gesture on ScrollView to clear selections
- Simplified background color logic without editing state interference
- `ColumnResizeHandle` component with visual feedback and cursor management
- Dynamic width storage per column with automatic initialization
- TAB navigation: `focusedCell` state tracks current focus, moves logically through cells
- Arrow key navigation: Uses `ArrowDirection` enum, respects data boundaries and header settings
- Column resize: Snap-to-final approach - no state changes during drag, single atomic update on completion
- Single-click editing: Replaced double-click with single-click for immediate cell editing

**Current Implementation Details:**
- Column widths stored in `@State private var columnWidths: [CGFloat]`
- Resize handles are 4px wide invisible areas between columns
- Minimum column width constraint (50px) prevents unusably narrow columns
- All existing cell selection, editing, and TAB navigation works with dynamic widths

## Project Scope

The codebase follows a focused scope: **"great and simple CSV file editor and nothing more"**. 

Key principles from the project maintainers:
- Avoid adding features outside core CSV editing functionality
- No formatting options or features like formulas
- Focus on handling CSV format variations, encodings, and delimiters
- Maintain simplicity and ease of use
- Any new features must align with the core CSV editing mission