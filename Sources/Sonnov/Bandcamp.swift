import Foundation

struct Track {
    let title: String
    let url: URL
}

struct Album {
    let title: String
    let artURL: URL?
    let pageURL: URL
    let tracks: [Track]
}

enum BandcampError: Error {
    case parse
    case noAlbums
}

enum Bandcamp {
    static let base = URL(string: "https://sonnovdrone.bandcamp.com")!

    static func randomAlbum() async throws -> Album {
        let page = try await fetch(base.appendingPathComponent("music"))
        let paths = try albumPaths(in: page)
        // A few albums may have no streamable tracks; try a handful of picks.
        for path in paths.shuffled().prefix(5) {
            let url = URL(string: path, relativeTo: base)!.absoluteURL
            if let album = try? await album(at: url), !album.tracks.isEmpty {
                return album
            }
        }
        throw BandcampError.noAlbums
    }

    private static func albumPaths(in page: String) throws -> [String] {
        guard let json = attribute("data-client-items", in: page),
              let items = try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [[String: Any]]
        else { throw BandcampError.parse }
        return items.compactMap { item in
            item["type"] as? String == "album" ? item["page_url"] as? String : nil
        }
    }

    private static func album(at url: URL) async throws -> Album {
        let page = try await fetch(url)
        guard let json = attribute("data-tralbum", in: page),
              let root = try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any],
              let infos = root["trackinfo"] as? [[String: Any]]
        else { throw BandcampError.parse }
        let tracks: [Track] = infos
            .sorted { ($0["track_num"] as? Int ?? 0) < ($1["track_num"] as? Int ?? 0) }
            .compactMap { info in
                guard let file = info["file"] as? [String: String],
                      let src = file["mp3-128"], let url = URL(string: src) else { return nil }
                return Track(title: info["title"] as? String ?? "", url: url)
            }
        let current = root["current"] as? [String: Any]
        let art = (root["art_id"] as? NSNumber).flatMap {
            URL(string: "https://f4.bcbits.com/img/a\($0)_16.jpg")
        }
        return Album(title: current?["title"] as? String ?? "", artURL: art, pageURL: url, tracks: tracks)
    }

    private static func fetch(_ url: URL) async throws -> String {
        let (data, _) = try await URLSession.shared.data(from: url)
        return String(decoding: data, as: UTF8.self)
    }

    /// Extracts and HTML-unescapes the value of a double-quoted attribute.
    private static func attribute(_ name: String, in html: String) -> String? {
        guard let start = html.range(of: "\(name)=\"") else { return nil }
        let rest = html[start.upperBound...]
        guard let end = rest.firstIndex(of: "\"") else { return nil }
        return unescape(String(rest[..<end]))
    }

    private static func unescape(_ text: String) -> String {
        var out = text
        let regex = try! NSRegularExpression(pattern: "&#(x[0-9a-fA-F]+|[0-9]+);")
        for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).reversed() {
            let code = (text as NSString).substring(with: match.range(at: 1))
            let value = code.hasPrefix("x") ? UInt32(code.dropFirst(), radix: 16) : UInt32(code)
            if let value, let scalar = Unicode.Scalar(value) {
                out = (out as NSString).replacingCharacters(in: match.range, with: String(Character(scalar)))
            }
        }
        // NSString replacement is code-unit based; Swift's String would miss an
        // entity followed by a combining character.
        let named = ["&quot;": "\"", "&lt;": "<", "&gt;": ">", "&amp;": "&"]
        let result = NSMutableString(string: out)
        for (entity, char) in named {
            result.replaceOccurrences(of: entity, with: char, options: .literal,
                                      range: NSRange(location: 0, length: result.length))
        }
        return result as String
    }
}
