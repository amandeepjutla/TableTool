# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Table Tool is a macOS native application written in Objective-C using the Cocoa framework. It's a simple CSV editor designed to handle various CSV formats, encodings, and delimiters automatically.

## Development Commands

### Building
```bash
# Open in Xcode (primary development environment)
open "Table Tool.xcodeproj"

# Build from command line
xcodebuild -project "Table Tool.xcodeproj" -scheme "Table Tool" build

# Clean build
xcodebuild -project "Table Tool.xcodeproj" -scheme "Table Tool" clean
```

### Testing
```bash
# Run tests from command line
xcodebuild -project "Table Tool.xcodeproj" -scheme "Table Tool" test

# Run specific test
xcodebuild -project "Table Tool.xcodeproj" -scheme "Table Tool" -only-testing:Table_ToolTests test
```

## Architecture

### Core Components

**Document Architecture**: Follows NSDocument-based pattern with `Document.h/.m` as the main document class.

**CSV Processing Engine**:
- `CSVReader` - Parses CSV files with various formats
- `CSVWriter` - Exports CSV with different configurations  
- `CSVConfiguration` - Manages CSV format settings (delimiters, encoding, quotes)
- `CSVHeuristic` - Automatically detects CSV format using 11 different configuration attempts

**UI Controllers**:
- `TTFormatViewController` - Format selection and configuration panel
- `TTErrorViewController` - Error display and handling
- Interface files in `Base.lproj/` define the UI layout

### Key Files
- `AppDelegate.h/.m` - Standard Cocoa application lifecycle
- `main.m` - Application entry point
- `Constants.h/.m` - Application-wide constants
- `Info.plist` - App metadata and document type associations
- `Table Tool.entitlements` - Sandboxing and permissions

### Test Structure
- `Table_ToolTests.m` - Main test suite using XCTest framework
- `Reading Test Documents/` - 15 CSV test cases for parsing edge cases
- `Heuristic Test Documents/` - 18 test cases for format detection
- Tests cover encoding issues, malformed CSV, quote escaping, and delimiter detection

## SwiftUI Modernization (2025)

**New Architecture**: The app has been modernized to SwiftUI with tabbed document support:

### New Swift Files
- `TableToolApp.swift` - Main SwiftUI App with DocumentGroup (replaces AppDelegate)
- `CSVDocument.swift` - FileDocument conforming model (replaces NSDocument)
- `ContentView.swift` - Main interface with NavigationSplitView
- `CSVTableView.swift` - SwiftUI table view with editable cells
- `FormatConfigurationView.swift` - SwiftUI format configuration sheet
- `CSVConfiguration.swift` - Swift struct (replaces Objective-C class)
- `CSVReader.swift` - Swift CSV parser (replaces Objective-C)
- `CSVWriter.swift` - Swift CSV writer (replaces Objective-C)
- `CSVHeuristic.swift` - Swift format detection (replaces Objective-C)

### Key Features
- **Automatic Tabbing**: DocumentGroup provides native macOS tabbed windows
  - Open multiple CSV files then use ⌥⌘M to merge into tabs
  - Or drag one window into another to create tabs
- **Modern UI**: NavigationSplitView with sidebar and detail view
- **Spreadsheet-like Editing**: 
  - Single-click to select individual cells
  - Double-click any cell (including empty ones) to edit inline
  - Enter to save, Escape to cancel
  - Fixed-size grid layout for consistent interaction
- **Format Detection**: Maintains heuristic CSV format detection
- **Format Configuration**: Clean GroupBox-based UI that works properly on macOS
- **Keyboard Shortcuts**: Cmd+R (add row), Cmd+C (add column), etc.
- **Window Commands**: ⌥⌘M (merge windows), ⌘⇧[ / ⌘⇧] (tab navigation)

### Architecture Changes
- **Removed**: NSDocument, AppDelegate, main.m, XIB files
- **Updated**: Info.plist uses modern UTType system instead of NSDocumentClass
- **Swift 6.0**: Full Swift migration with proper error handling
- **macOS 15+**: Modern deployment target

### Building the Modern Version
1. All Swift files are included in Xcode project
2. Legacy Objective-C files remain for reference but are not compiled
3. Build settings configured for Swift 6.0 and macOS 15+
4. Document types properly configured for CSV and text files

## Legacy Notes

**Original Language**: Pure Objective-C with Cocoa frameworks (no external dependencies)
**Target**: macOS desktop application distributed via Mac App Store
**Build System**: Xcode project files (.xcodeproj)
**Legacy UI**: Interface Builder (.xib) with NSTableView for data display

The codebase follows a focused scope: "great and simple CSV file editor and nothing more" - avoid adding features outside core CSV editing functionality.