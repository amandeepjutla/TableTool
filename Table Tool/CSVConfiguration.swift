//
//  CSVConfiguration.swift
//  Table Tool
//
//  Created by Claude on 2025-06-27.
//  Copyright (c) 2025 Egger Apps. All rights reserved.
//

import Foundation

struct CSVConfiguration: Codable, Equatable {
    var encoding: String.Encoding
    var columnSeparator: String
    var quoteCharacter: String  
    var escapeCharacter: String
    var decimalMark: String
    var firstRowAsHeader: Bool
    
    init() {
        self.encoding = .utf8
        self.columnSeparator = ","
        self.quoteCharacter = "\""
        self.escapeCharacter = "\""
        self.decimalMark = "."
        self.firstRowAsHeader = false
    }
    
    static let supportedEncodings: [(name: String, encoding: String.Encoding)] = [
        ("Unicode (UTF-8)", .utf8),
        ("Western (Mac OS Roman)", .macOSRoman),
        ("Western (Windows Latin 1)", .windowsCP1252),
        ("Chinese (GBK)", String.Encoding(rawValue: 0x80000632)),
        ("Central European (ISO Latin 2)", .isoLatin2),
        ("Central European (Windows Latin 2)", String.Encoding(rawValue: 0xf)),
        ("Cyrillic (Windows)", String.Encoding(rawValue: 0xb)),
        ("Greek (Windows)", String.Encoding(rawValue: 0x10)),
        ("Turkish (Windows)", String.Encoding(rawValue: 0x14)),
        ("Hebrew (Windows)", String.Encoding(rawValue: 0x11)),
        ("Arabic (Windows)", String.Encoding(rawValue: 0x12)),
        ("Baltic (Windows)", String.Encoding(rawValue: 0x13)),
        ("Vietnamese (Windows)", String.Encoding(rawValue: 0x15)),
        ("Thai (Windows)", String.Encoding(rawValue: 0x16))
    ]
}

// MARK: - Codable conformance for String.Encoding
extension CSVConfiguration {
    enum CodingKeys: String, CodingKey {
        case encodingRawValue = "encoding"
        case columnSeparator
        case quoteCharacter
        case escapeCharacter
        case decimalMark
        case firstRowAsHeader
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let encodingRawValue = try container.decode(UInt.self, forKey: .encodingRawValue)
        self.encoding = String.Encoding(rawValue: encodingRawValue)
        self.columnSeparator = try container.decode(String.self, forKey: .columnSeparator)
        self.quoteCharacter = try container.decode(String.self, forKey: .quoteCharacter)
        self.escapeCharacter = try container.decode(String.self, forKey: .escapeCharacter)
        self.decimalMark = try container.decode(String.self, forKey: .decimalMark)
        self.firstRowAsHeader = try container.decode(Bool.self, forKey: .firstRowAsHeader)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(encoding.rawValue, forKey: .encodingRawValue)
        try container.encode(columnSeparator, forKey: .columnSeparator)
        try container.encode(quoteCharacter, forKey: .quoteCharacter)
        try container.encode(escapeCharacter, forKey: .escapeCharacter)
        try container.encode(decimalMark, forKey: .decimalMark)
        try container.encode(firstRowAsHeader, forKey: .firstRowAsHeader)
    }
}