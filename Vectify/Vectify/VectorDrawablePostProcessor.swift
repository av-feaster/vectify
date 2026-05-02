import Foundation

/// Mirrors `finalize_vector_xml_bytes` in `svg_icons_to_compose_resources.py`.
enum VectorDrawablePostProcessor {

    enum DrawableRepairStatus: String, Sendable {
        case pending
        case unchanged
        case fixed
        case failed
    }

    struct DrawableRepairOutcome: Identifiable, Sendable, Equatable {
        var id: String { fileName }
        let fileName: String
        var status: DrawableRepairStatus
        var changelog: String
    }

    enum PostProcessError: Error {
        case notUTF8
    }

    /// Non-recursive: `*.xml` in `directory` whose contents contain `<vector`.
    static func listVectorDrawableXMLFiles(in directory: URL) throws -> [String] {
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: directory.path) else {
            return []
        }
        return names
            .filter { $0.lowercased().hasSuffix(".xml") }
            .sorted()
            .filter { name in
                let file = directory.appendingPathComponent(name)
                guard let raw = try? Data(contentsOf: file), raw.contains(Data("<vector".utf8)) else { return false }
                return true
            }
    }

    static func finalizeVectorXML(data: Data) throws -> Data {
        try finalizeVectorXMLDetailed(data: data).data
    }

    /// Returns transformed XML and human-readable change descriptions (empty if identical to input).
    static func finalizeVectorXMLDetailed(data: Data) throws -> (data: Data, changeDescriptions: [String]) {
        guard var text = String(data: data, encoding: .utf8) else {
            throw PostProcessError.notUTF8
        }
        var messages: [String] = []

        if !text.contains("android:viewportWidth") {
            if let widthDp = firstCapture(pattern: #"android:width="([\d.]+)dp""#, in: text),
               let heightDp = firstCapture(pattern: #"android:height="([\d.]+)dp""#, in: text),
               let range = text.range(of: "<vector ") {
                let insert =
                    "<vector android:viewportWidth=\"\(widthDp)\" android:viewportHeight=\"\(heightDp)\" "
                var next = text
                next.replaceSubrange(range, with: insert)
                if next != text {
                    text = next
                    messages.append("Added missing viewport (\(widthDp)×\(heightDp) dp)")
                }
            }
        }

        let beforeStroke = text
        text = fixStrokeOnlyPathTags(text)
        if text != beforeStroke {
            messages.append("Corrected stroke-fill parity on path tags")
        }

        return (Data(text.utf8), messages)
    }

    /// Per-file outcomes; writes to disk only when bytes change. Same discovery rules as `repairDrawables(in:)`.
    static func repairDrawablesDetailed(in directory: URL) throws -> [DrawableRepairOutcome] {
        let fm = FileManager.default
        let names = try listVectorDrawableXMLFiles(in: directory)
        var outcomes: [DrawableRepairOutcome] = []
        outcomes.reserveCapacity(names.count)

        for name in names {
            let file = directory.appendingPathComponent(name)
            do {
                let raw = try Data(contentsOf: file)
                let (fixed, messages) = try finalizeVectorXMLDetailed(data: raw)
                if fixed == raw {
                    outcomes.append(
                        DrawableRepairOutcome(
                            fileName: name,
                            status: .unchanged,
                            changelog: "No changes needed"
                        )
                    )
                } else {
                    try fixed.write(to: file, options: .atomic)
                    let changelog: String
                    if messages.isEmpty {
                        changelog = "Updated VectorDrawable XML"
                    } else {
                        changelog = messages.joined(separator: " · ")
                    }
                    outcomes.append(
                        DrawableRepairOutcome(
                            fileName: name,
                            status: .fixed,
                            changelog: changelog
                        )
                    )
                }
            } catch PostProcessError.notUTF8 {
                outcomes.append(
                    DrawableRepairOutcome(
                        fileName: name,
                        status: .failed,
                        changelog: "File is not valid UTF-8"
                    )
                )
            } catch {
                outcomes.append(
                    DrawableRepairOutcome(
                        fileName: name,
                        status: .failed,
                        changelog: error.localizedDescription
                    )
                )
            }
        }
        return outcomes
    }

    /// Repair all `<vector>` XML files in a directory (non-recursive, `*.xml` in directory root).
    static func repairDrawables(in directory: URL) throws -> Int {
        try repairDrawablesDetailed(in: directory).filter { $0.status == .fixed }.count
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
}
