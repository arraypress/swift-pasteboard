//
//  ClipImage.swift
//  Pasteboard
//
//  Created by David Sherlock on 2026.
//
//  An image from the pasteboard, held as PNG; its JSON is a description,
//  never two megabytes of base64.
//

import Foundation

/// An image from the pasteboard, held as PNG.
///
/// Encodes as its dimensions and size only — a JSON description should say
/// what the image is, not carry two megabytes of base64.
public struct ClipImage: Sendable, Equatable {
    /// The image as PNG bytes, whatever flavour it arrived in.
    public let png: Data
    /// Pixels across.
    public let width: Int
    /// Pixels down.
    public let height: Int
    /// The PNG's size in bytes.
    public let bytes: Int

    /// An image from its PNG bytes and pixel size.
    public init(png: Data, width: Int, height: Int) {
        self.png = png
        self.width = width
        self.height = height
        self.bytes = png.count
    }
}

extension ClipImage: Codable {
    enum CodingKeys: String, CodingKey { case width, height, bytes }

    /// Decodes the description only; the pixels are not carried by JSON.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        png = Data()
        width = try c.decode(Int.self, forKey: .width)
        height = try c.decode(Int.self, forKey: .height)
        bytes = try c.decode(Int.self, forKey: .bytes)
    }
}
