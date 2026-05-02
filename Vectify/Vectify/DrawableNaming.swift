import Foundation

/// Ports `icon_base_from_stem`, `normalize_android_drawable_base`, and `allocate_output_xml` from the Python script.
enum DrawableNaming {
    static func iconBase(fromStemLower stem: String) -> String {
        if stem.hasPrefix("ic_") { return stem }
        if stem.hasPrefix("ice") { return "ic_" + stem }
        if stem.hasPrefix("icon") { return "ic_" + stem }
        if stem.count > 2, stem.hasPrefix("ic") {
            let idx = stem.index(stem.startIndex, offsetBy: 2)
            if stem[idx] != "_" {
                return "ic_" + String(stem[stem.index(stem.startIndex, offsetBy: 2)...])
            }
        }
        return "ic_" + stem
    }

    /// Returns normalized base or `nil` and an error message.
    static func normalizeAndroidDrawableBase(_ iconBase: String) -> (String?, String) {
        var s = iconBase.lowercased()
        s = s.replacingOccurrences(of: #"[^a-z0-9_]+"#, with: "_", options: .regularExpression)
        s = s.replacingOccurrences(of: #"_{2,}"#, with: "_", options: .regularExpression)
        s = s.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        if s.isEmpty { return (nil, "empty resource name after normalization") }
        if let first = s.unicodeScalars.first, CharacterSet.decimalDigits.contains(first) {
            s = "ic_" + s
        }
        guard let re = try? NSRegularExpression(pattern: #"^[a-z][a-z0-9_]*$"#),
              re.firstMatch(in: s, options: [], range: NSRange(s.startIndex..., in: s)) != nil
        else {
            return (nil, "invalid resource name after normalization: \(iconBase)")
        }
        if s.count > 200 { return (nil, "resource name too long") }
        return (s, "")
    }

    /// Picks `ic_name.xml` or `ic_name_1.xml`, … in `drawableDir`.
    static func allocateOutputXML(
        drawableDir: URL,
        stemLower: String,
        force: Bool
    ) -> (URL?, String, Bool) {
        let rawBase = iconBase(fromStemLower: stemLower)
        let (iconBase, err) = normalizeAndroidDrawableBase(rawBase)
        guard let base = iconBase else { return (nil, err, false) }
        let primary = drawableDir.appendingPathComponent("\(base).xml", isDirectory: false)
        if force { return (primary, "", false) }
        if !FileManager.default.fileExists(atPath: primary.path) {
            return (primary, "", false)
        }
        var n = 1
        while n <= 10_000 {
            let candidate = drawableDir.appendingPathComponent("\(base)_\(n).xml", isDirectory: false)
            if !FileManager.default.fileExists(atPath: candidate.path) {
                return (candidate, "", true)
            }
            n += 1
        }
        return (nil, "could not allocate free name for \(base)", false)
    }
}
