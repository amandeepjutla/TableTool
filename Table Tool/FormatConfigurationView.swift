//
//  FormatConfigurationView.swift
//  Table Tool
//
//  Created by Claude on 2025-06-27.
//  Copyright (c) 2025 Egger Apps. All rights reserved.
//

import SwiftUI
import Foundation

struct FormatConfigurationView: View {
    @Binding var document: CSVDocument
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempConfiguration: CSVConfiguration
    @State private var previewText = ""
    
    init(document: Binding<CSVDocument>) {
        self._document = document
        self._tempConfiguration = State(initialValue: document.wrappedValue.configuration)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("CSV Format Configuration")
                    .font(.headline)
                    .padding()
                Spacer()
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    
                    Button("Apply") {
                        document.configuration = tempConfiguration
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // CSV Format Section
                    GroupBox("CSV Format") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Column Separator:")
                                    .frame(width: 120, alignment: .leading)
                                TextField("Separator", text: $tempConfiguration.columnSeparator)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                                
                                Spacer()
                                
                                Text("Common:")
                                Button(",") { tempConfiguration.columnSeparator = "," }
                                    .buttonStyle(.bordered)
                                Button(";") { tempConfiguration.columnSeparator = ";" }
                                    .buttonStyle(.bordered)
                                Button("Tab") { tempConfiguration.columnSeparator = "\t" }
                                    .buttonStyle(.bordered)
                                Button("|") { tempConfiguration.columnSeparator = "|" }
                                    .buttonStyle(.bordered)
                            }
                            
                            HStack {
                                Text("Quote Character:")
                                    .frame(width: 120, alignment: .leading)
                                TextField("Quote", text: $tempConfiguration.quoteCharacter)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                                
                                Spacer()
                                
                                Text("Common:")
                                Button("\"") { tempConfiguration.quoteCharacter = "\"" }
                                    .buttonStyle(.bordered)
                                Button("'") { tempConfiguration.quoteCharacter = "'" }
                                    .buttonStyle(.bordered)
                            }
                            
                            HStack {
                                Text("Escape Character:")
                                    .frame(width: 120, alignment: .leading)
                                TextField("Escape", text: $tempConfiguration.escapeCharacter)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                                
                                Spacer()
                                
                                Text("Common:")
                                Button("\"") { tempConfiguration.escapeCharacter = "\"" }
                                    .buttonStyle(.bordered)
                                Button("\\") { tempConfiguration.escapeCharacter = "\\" }
                                    .buttonStyle(.bordered)
                            }
                            
                            HStack {
                                Text("Decimal Mark:")
                                    .frame(width: 120, alignment: .leading)
                                TextField("Decimal", text: $tempConfiguration.decimalMark)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                                
                                Spacer()
                                
                                Text("Common:")
                                Button(".") { tempConfiguration.decimalMark = "." }
                                    .buttonStyle(.bordered)
                                Button(",") { tempConfiguration.decimalMark = "," }
                                    .buttonStyle(.bordered)
                            }
                            
                            Toggle("First row as header", isOn: $tempConfiguration.firstRowAsHeader)
                        }
                        .padding()
                    }
                    
                    // Text Encoding Section
                    GroupBox("Text Encoding") {
                        HStack {
                            Text("Encoding:")
                            Picker("Encoding", selection: $tempConfiguration.encoding) {
                                ForEach(CSVConfiguration.supportedEncodings, id: \.encoding.rawValue) { encoding in
                                    Text(encoding.name)
                                        .tag(encoding.encoding)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 250)
                            Spacer()
                        }
                        .padding()
                    }
                    
                    // Preview Section
                    GroupBox("Preview") {
                        ScrollView {
                            Text(previewText)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(NSColor.textBackgroundColor))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .frame(height: 120)
                        .padding()
                    }
                }
                .padding()
            }
        }
        .frame(width: 650, height: 550)
        .onAppear {
            updatePreview()
        }
        .onChange(of: tempConfiguration) { _ in
            updatePreview()
        }
    }
    
    private func updatePreview() {
        let writer = CSVWriter(configuration: tempConfiguration)
        let sampleData = [
            ["Name", "Age", "City", "Salary"],
            ["John Doe", "25", "New York", "50,000.00"],
            ["Jane Smith", "30", "San Francisco", "75,500.50"],
            ["Bob Johnson", "35", "Chicago", "62,250.75"]
        ]
        previewText = writer.writeData(sampleData)
    }
}

#Preview {
    FormatConfigurationView(document: .constant(CSVDocument()))
}