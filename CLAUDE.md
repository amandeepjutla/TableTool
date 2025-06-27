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

**Current Architecture**: The app has been fully modernized to SwiftUI with tabbed document support:

### Swift Files
- `TableToolApp.swift` - Main SwiftUI App with DocumentGroup
- `CSVDocument.swift` - FileDocument conforming model
- `ContentView.swift` - Main interface with NavigationSplitView
- `CSVTableView.swift` - SwiftUI table view with editable cells and drag selection
- `FormatConfigurationView.swift` - SwiftUI format configuration sheet
- `CSVConfiguration.swift` - Swift struct for CSV format settings
- `CSVReader.swift` - Swift CSV parser
- `CSVWriter.swift` - Swift CSV writer
- `CSVHeuristic.swift` - Swift format detection

### Key Features
- **Automatic Tabbing**: DocumentGroup provides native macOS tabbed windows
  - Open multiple CSV files then use ⌥⌘M to merge into tabs
  - Or drag one window into another to create tabs
- **Modern UI**: NavigationSplitView with sidebar and detail view
- **Spreadsheet-like Editing**: 
  - Single-click to select individual cells (has delay issue - needs optimization)
  - **Click-drag selection**: BROKEN - drag gesture not working properly, conflicts with tap gesture
  - Double-click any cell (including empty ones) to edit inline
  - Enter to save, Escape to cancel
  - Fixed-size grid layout for consistent interaction
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

## Known Issues (2025-06-27)

**CSVTableView.swift Selection Issues:**
1. **Click-drag selection is broken**: The drag gesture implementation conflicts with tap gestures. The simultaneousGesture approach doesn't work properly.
2. **Single-click delay**: There's a noticeable delay when selecting cells due to gesture conflicts between single tap, double tap, and drag.
3. **Drag gesture problems**: Using `value.translation.width/height` for calculating cell positions is incorrect - should use location-based approach.

**Recommended fixes:**
- Remove simultaneousGesture and implement proper gesture prioritization
- Use DragGesture with location-based cell position calculation instead of translation
- Optimize tap gesture handling to eliminate selection delay
- Consider using UIKit-style gesture recognizer patterns in SwiftUI

## Project Scope

The codebase follows a focused scope: "great and simple CSV file editor and nothing more" - avoid adding features outside core CSV editing functionality.