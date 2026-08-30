# Swift Pasteboard

The macOS pasteboard, read and written as values.

```swift
import Pasteboard

let clip = Pasteboard.read()
switch clip.primary {
case .text:  print(clip.text ?? "")
case .image: try clip.image?.png.write(to: out)
case .files: print(clip.files.joined(separator: "\n"))
default:     print(clip.types.map(\.identifier))
}

Pasteboard.write(text: "hello")
try Pasteboard.write(imageAt: screenshot)
Pasteboard.write(files: [reportURL])

for await clip in Pasteboard.changes() {
    print(clip.changeCount, clip.text ?? "…")
}
```

## Features

- 📋 **One read, everything interpreted** — a `Clip` carries the text, HTML/RTF presence, the image (held as PNG with its pixel size), copied file paths, a colour, and the raw type list with byte counts for whatever else is there. Nothing on the pasteboard is invisible.
- 🖼️ **Images normalised to PNG** — whatever flavour they arrived in; writes put up PNG *and* TIFF, the pair virtually every app can paste.
- 🔗 **Link detection** — `clip.url` when the text is one token with a real scheme, so "is this a copied link?" is one accessor.
- 📁 **File references** — read what Finder's ⌘C put up; write them back the same way.
- 👀 **A change stream** — `changes(every:)` is an `AsyncStream<Clip>` polling the change count, the way every clipboard manager does it; cancel the task to stop.
- 🧾 **JSON-honest** — a `Clip` encodes as a *description*: an image encodes as width × height × bytes, never two megabytes of base64.
- 🧹 **Writes clear first** — every write replaces the pasteboard, which is what a copy means and what every app expects.

## Measured

Text write + read round-trips in **0.21 ms**; a 1920×1080 PNG copies and reads back in **27 ms**. Nine tests run against the real pasteboard — and capture what you had copied first, flavour by flavour, and put it back after.

## Requirements

macOS 14+, Swift 6. AppKit only — the pasteboard *is* AppKit, so this library is Mac-only by nature.

## License

MIT — see [LICENSE](LICENSE).
