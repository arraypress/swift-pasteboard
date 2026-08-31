//
//  PasteboardTests.swift
//  Pasteboard
//
//  Created by David Sherlock on 2026.
//
//  These tests use the REAL general pasteboard — there is no other kind —
//  so whatever the person had copied is captured before and put back after,
//  flavour by flavour.
//

import AppKit
import XCTest
@testable import Pasteboard

final class PasteboardTests: XCTestCase {

    private var saved: [[(NSPasteboard.PasteboardType, Data)]] = []

    override func setUp() {
        super.setUp()
        saved = (NSPasteboard.general.pasteboardItems ?? []).map { item in
            item.types.compactMap { type in item.data(forType: type).map { (type, $0) } }
        }
    }

    override func tearDown() {
        let pb = NSPasteboard.general
        pb.clearContents()
        let items = saved.map { entry in
            let item = NSPasteboardItem()
            for (type, data) in entry { item.setData(data, forType: type) }
            return item
        }
        if !items.isEmpty { pb.writeObjects(items) }
        super.tearDown()
    }

    /// A 4×3 PNG drawn with CoreGraphics.
    private func syntheticPNG(width: Int = 4, height: Int = 3) -> Data {
        let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(CGColor(srgbRed: 0.9, green: 0.4, blue: 0.2, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
        return rep.representation(using: .png, properties: [:])!
    }

    func testTextRoundTripAndChangeCount() {
        let before = Pasteboard.changeCount
        let after = Pasteboard.write(text: "pb ✓ üñïçødé")
        XCTAssertGreaterThan(after, before, "a write bumps the change count")
        let clip = Pasteboard.read()
        XCTAssertEqual(clip.text, "pb ✓ üñïçødé")
        XCTAssertEqual(clip.primary, .text)
        XCTAssertFalse(clip.looksLikeURL)
        XCTAssertFalse(clip.isEmpty)
        XCTAssertTrue(clip.types.contains { $0.identifier == NSPasteboard.PasteboardType.string.rawValue })
    }

    func testURLDetection() {
        Pasteboard.write(text: "https://example.com/x?y=1")
        XCTAssertEqual(Pasteboard.read().url?.host, "example.com")
        Pasteboard.write(text: "not a url at all")
        XCTAssertNil(Pasteboard.read().url)
        Pasteboard.write(text: "ftp.example.com")   // no scheme — not a link
        XCTAssertNil(Pasteboard.read().url)
    }

    func testFilesRoundTrip() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("pb-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let a = dir.appendingPathComponent("a.txt"), b = dir.appendingPathComponent("b.txt")
        try Data("a".utf8).write(to: a)
        try Data("b".utf8).write(to: b)
        Pasteboard.write(files: [a, b])
        let clip = Pasteboard.read()
        XCTAssertEqual(clip.primary, .files, "files outrank the path string Finder also posts")
        XCTAssertEqual(Set(clip.files.map { ($0 as NSString).lastPathComponent }), ["a.txt", "b.txt"])
        XCTAssertEqual(clip.fileURLs.count, 2)
    }

    func testImageRoundTrip() throws {
        try Pasteboard.write(imageData: syntheticPNG())
        let clip = Pasteboard.read()
        XCTAssertEqual(clip.primary, .image)
        let image = try XCTUnwrap(clip.image)
        XCTAssertEqual(image.width, 4)
        XCTAssertEqual(image.height, 3)
        XCTAssertNotNil(NSBitmapImageRep(data: image.png), "the held bytes decode as an image")
        XCTAssertThrowsError(try Pasteboard.write(imageData: Data("not an image".utf8)))
    }

    func testHTMLWithFallbackReadsAsRichAndPlain() {
        Pasteboard.write(html: "<b>hi</b>", plainFallback: "hi")
        let clip = Pasteboard.read()
        XCTAssertEqual(clip.text, "hi")
        XCTAssertTrue(clip.hasHTML)
        XCTAssertEqual(clip.html, "<b>hi</b>")
        XCTAssertTrue(clip.kinds.contains(.richText))
        XCTAssertTrue(clip.kinds.contains(.text))
    }

    func testClearLeavesEmpty() {
        Pasteboard.write(text: "something")
        Pasteboard.clear()
        let clip = Pasteboard.read()
        XCTAssertTrue(clip.isEmpty)
        XCTAssertNil(clip.primary)
    }

    func testChangesStreamYieldsOnWrite() async {
        let stream = Pasteboard.changes(every: .milliseconds(40))
        Task {
            try? await Task.sleep(for: .milliseconds(120))
            Pasteboard.write(text: "watched!")
        }
        var seen: Clip?
        for await clip in stream {
            seen = clip
            break
        }
        XCTAssertEqual(seen?.text, "watched!")
    }

    func testImageDescriptionEncodesWithoutPixels() throws {
        try Pasteboard.write(imageData: syntheticPNG(width: 32, height: 8))
        let clip = Pasteboard.read()
        let data = try JSONEncoder().encode(clip)
        let text = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(text.contains("\"width\":32"))
        XCTAssertFalse(text.contains("iVBOR"), "no base64 PNG in the JSON description")
    }

    func testMeasuredRoundTrip() {
        // The numbers the README quotes.
        let runs = 200
        let start = Date()
        for i in 0..<runs {
            Pasteboard.write(text: "measure \(i)")
            _ = Pasteboard.read()
        }
        let perRoundTrip = Date().timeIntervalSince(start) / Double(runs) * 1000
        let png = syntheticPNG(width: 1920, height: 1080)
        let imageStart = Date()
        try? Pasteboard.write(imageData: png)
        let imageClip = Pasteboard.read()
        let imageMs = Date().timeIntervalSince(imageStart) * 1000
        print(String(format: "MEASured: text write+read %.2f ms; 1920×1080 PNG copy+read %.0f ms (%d KB png)",
                     perRoundTrip, imageMs, (imageClip.image?.bytes ?? 0) / 1024))
        XCTAssertLessThan(perRoundTrip, 50)
    }

    /// The kind order is a contract: most specific first, `.other` only
    /// when nothing readable remains, empty stays empty.
    func testKindOrderingIsMostSpecificFirst() {
        XCTAssertEqual(KindOrdering.kinds(hasFiles: true, hasImage: true, hasText: true, hasRich: true, hasColor: false, hasOtherTypes: true),
                       [.files, .image, .text, .richText])
        XCTAssertEqual(KindOrdering.kinds(hasFiles: false, hasImage: false, hasText: false, hasRich: false, hasColor: false, hasOtherTypes: true), [.other])
        XCTAssertTrue(KindOrdering.kinds(hasFiles: false, hasImage: false, hasText: false, hasRich: false, hasColor: false, hasOtherTypes: false).isEmpty)
    }
}
