import Foundation

public enum URLInput {
    /// Turns what someone typed into a URL that can be opened: trims whitespace
    /// and assumes https:// when there's no scheme ("github.com" becomes
    /// "https://github.com"). Nil for empty or unparseable input.
    public static func openable(_ input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil { return url }
        return URL(string: "https://" + trimmed)
    }
}
