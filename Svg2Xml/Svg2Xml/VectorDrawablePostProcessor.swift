import Foundation

/// Mirrors `finalize_vector_xml_bytes` in `svg_icons_to_compose_resources.py`.
enum VectorDrawablePostProcessor {
    static func finalizeVectorXML(data: Data) throws -> Data {
        guard var text = String(data: data, encoding: .utf8) else {
            throw PostProcessError.notUTF8
        }
        if !text.contains("android:viewportWidth") {
            if let w = firstCapture(pattern: #"android:width="([\d.]+)dp""#, in: text),
               let h = firstCapture(pattern: #"android:height="([\d.]+)dp""#, in: text),
               let range = text.range(of: "<vector ") {
                let insert =
                    "<vector android:viewportWidth=\"\(w)\" android:viewportHeight=\"\(h)\" "
                text.replaceSubrange(range, with: insert)
            }
        }
        text = fixStrokeOnlyPathTags(text)
        return Data(text.utf8)
    }

    enum PostProcessError: Error {
        case notUTF8
    }

    private static func firstCapture(pattern: String, in text: String) -> String? {
        guard let re = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let full = NSRange(text.startIndex..., in: text)
        guard let m = re.firstMatch(in: text, options: [], range: full),
              m.numberOfRanges > 1,
              let r = Range(m.range(at: 1), in: text) else { return nil }
        return String(text[r])
    }

    private static func fixStrokeOnlyPathTags(_ text: String) -> String {
        guard let re = try? NSRegularExpression(pattern: #"<path\b[^/]*/>"#, options: []) else {
            return text
        }
        let full = NSRange(text.startIndex..., in: text)
        let matches = re.matches(in: text, options: [], range: full)
        guard !matches.isEmpty else { return text }
        var result = ""
        var last = text.startIndex
        for m in matches {
            guard let r = Range(m.range, in: text) else { continue }
            result += String(text[last..<r.lowerBound])
            var tag = String(text[r])
            if tag.contains("android:strokeColor") {
                tag = tag.replacingOccurrences(
                    of: ##"android:fillColor="#000000""##,
                    with: ##"android:fillColor="#00000000""##
                )
            }
            result += tag
            last = r.upperBound
        }
        result += String(text[last...])
        return result
    }

    /// Repair all `<vector>` XML files in a directory (non-recursive, `*.xml` in directory root).
    static func repairDrawables(in directory: URL) throws -> Int {
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: directory.path) else {
            return 0
        }
        var repaired = 0
        for name in names.sorted() where name.lowercased().hasSuffix(".xml") {
            let file = directory.appendingPathComponent(name)
            guard let raw = try? Data(contentsOf: file), raw.contains(Data("<vector".utf8)) else { continue }
            let fixed = try finalizeVectorXML(data: raw)
            if fixed != raw {
                try fixed.write(to: file, options: .atomic)
                repaired += 1
            }
        }
        return repaired
    }
}
