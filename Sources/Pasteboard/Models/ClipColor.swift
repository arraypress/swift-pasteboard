//
//  ClipColor.swift
//  Pasteboard
//
//  Created by David Sherlock on 2026.
//
//  A colour from the pasteboard, in sRGB bytes and a hex form.
//

import Foundation

/// A colour from the pasteboard, in sRGB.
public struct ClipColor: Codable, Sendable, Equatable {
    /// Red, 0–255.
    public let red: Int
    /// Green, 0–255.
    public let green: Int
    /// Blue, 0–255.
    public let blue: Int
    /// Opacity, 0–1.
    public let alpha: Double
    /// `#RRGGBB`.
    public var hex: String { String(format: "#%02X%02X%02X", red, green, blue) }

    /// A colour from sRGB components.
    public init(red: Int, green: Int, blue: Int, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}
