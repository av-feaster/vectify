import Foundation

enum SvgConversionHelpers {
    static func listSVGFiles(in directory: URL) -> [URL] {
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: directory.path) else { return [] }
        return names.filter { $0.lowercased().hasSuffix(".svg") }
            .sorted()
            .map { directory.appendingPathComponent($0) }
    }

    static func isValidSVG(at url: URL) -> (Bool, String) {
        guard url.pathExtension.lowercased() == "svg" else {
            return (false, "not an svg file")
        }
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? NSNumber, size.intValue > 0 else {
            return (false, "empty file")
        }
        guard let prefix = try? Data(contentsOf: url, options: [.mappedIfSafe]).prefix(65_536) else {
            return (false, "read failed")
        }
        var text = String(decoding: prefix, as: UTF8.self)
        text = text.trimmingCharacters(in: CharacterSet(charactersIn: "\u{feff} \t\r\n"))
        if !text.lowercased().contains("<svg") {
            return (false, "missing <svg> in file header")
        }
        return (true, "")
    }
}
