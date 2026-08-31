//
//  Pasteboard.swift
//  Pasteboard
//
//  Created by David Sherlock on 2026.
//
//  The general pasteboard, read and written as values. A read interprets
//  every flavour it knows — text, HTML/RTF, image, file URLs, colour — and
//  reports the rest by type and size, so nothing on the pasteboard is
//  invisible. Writes always clear first: that is how the pasteboard is
//  meant to be used, and what every app expects of a copy.
//

import AppKit
import Foundation

/// The general pasteboard, as reads and writes of ``Clip`` values.
public enum Pasteboard {

    /// The pasteboard's change count — bumped by every write, from any app.
    public static var changeCount: Int { NSPasteboard.general.changeCount }

    // MARK: Read

    /// Everything currently on the general pasteboard.
    public static func read() -> Clip {
        let pb = NSPasteboard.general
        let types = (pb.types ?? []).map {
            ClipType(identifier: $0.rawValue, bytes: pb.data(forType: $0)?.count ?? 0)
        }
        let text = pb.string(forType: .string)
        let html = pb.string(forType: .html)
        let hasRTF = pb.data(forType: .rtf) != nil

        let files = (pb.readObjects(forClasses: [NSURL.self],
                                    options: [.urlReadingFileURLsOnly: true]) as? [URL]) ?? []

        var image: ClipImage?
        if let data = pb.data(forType: .png) ?? pb.data(forType: .tiff),
           let rep = NSBitmapImageRep(data: data) {
            // Whatever flavour it arrived in, hold it as PNG.
            let png = rep.representation(using: .png, properties: [:]) ?? data
            image = ClipImage(png: png, width: rep.pixelsWide, height: rep.pixelsHigh)
        }

        var color: ClipColor?
        if let read = NSColor(from: pb), let srgb = read.usingColorSpace(.sRGB) {
            color = ClipColor(red: Int((srgb.redComponent * 255).rounded()),
                              green: Int((srgb.greenComponent * 255).rounded()),
                              blue: Int((srgb.blueComponent * 255).rounded()),
                              alpha: Double(srgb.alphaComponent))
        }

        let kinds = KindOrdering.kinds(hasFiles: !files.isEmpty, hasImage: image != nil,
                                       hasText: text != nil, hasRich: html != nil || hasRTF,
                                       hasColor: color != nil, hasOtherTypes: !types.isEmpty)

        return Clip(kinds: kinds, text: text, hasHTML: html != nil, hasRTF: hasRTF, html: html,
                    image: image, files: files.map(\.path), color: color, types: types,
                    changeCount: pb.changeCount)
    }

    // MARK: Write

    /// Puts plain text on the pasteboard, replacing what was there.
    /// - Returns: The new change count.
    @discardableResult
    public static func write(text: String) -> Int {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        return pb.changeCount
    }

    /// Puts an image on the pasteboard as PNG and TIFF — the pair virtually
    /// every app can paste — replacing what was there.
    /// - Parameter imageData: Any encoding AppKit decodes (PNG, JPEG, HEIC, …).
    /// - Returns: The new change count.
    @discardableResult
    public static func write(imageData: Data) throws -> Int {
        guard let rep = NSBitmapImageRep(data: imageData) else { throw PasteboardError.notAnImage }
        let pb = NSPasteboard.general
        pb.clearContents()
        if let png = rep.representation(using: .png, properties: [:]) { pb.setData(png, forType: .png) }
        if let tiff = rep.tiffRepresentation { pb.setData(tiff, forType: .tiff) }
        return pb.changeCount
    }

    /// Puts the image in a file on the pasteboard; see ``write(imageData:)``.
    @discardableResult
    public static func write(imageAt url: URL) throws -> Int {
        try write(imageData: Data(contentsOf: url))
    }

    /// Puts file references on the pasteboard — what Finder's Copy does —
    /// replacing what was there.
    /// - Returns: The new change count.
    @discardableResult
    public static func write(files: [URL]) -> Int {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects(files as [NSURL])
        return pb.changeCount
    }

    /// Puts HTML on the pasteboard, with a plain-text fallback for the apps
    /// that only paste text, replacing what was there.
    /// - Returns: The new change count.
    @discardableResult
    public static func write(html: String, plainFallback: String? = nil) -> Int {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(html, forType: .html)
        if let plainFallback { pb.setString(plainFallback, forType: .string) }
        return pb.changeCount
    }

    /// Empties the pasteboard.
    public static func clear() {
        NSPasteboard.general.clearContents()
    }

    // MARK: Watch

    /// Every change to the pasteboard, as it happens.
    ///
    /// The pasteboard has no notification, so this polls the change count —
    /// the same way every clipboard manager does — and reads a ``Clip`` when
    /// it moves. Cancel the consuming task to stop.
    ///
    /// - Parameter interval: How often to look. A quarter second is prompt
    ///   without being busywork.
    public static func changes(every interval: Duration = .milliseconds(250)) -> AsyncStream<Clip> {
        AsyncStream { continuation in
            let task = Task {
                var last = NSPasteboard.general.changeCount
                while !Task.isCancelled {
                    try? await Task.sleep(for: interval)
                    let now = NSPasteboard.general.changeCount
                    if now != last {
                        last = now
                        continuation.yield(read())
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
