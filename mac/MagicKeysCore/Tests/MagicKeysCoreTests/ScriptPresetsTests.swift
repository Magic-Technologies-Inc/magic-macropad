import XCTest
@testable import MagicKeysCore

/// Runs the preset shell scripts against fake command-line tools in a sandbox,
/// so the tests never touch the real clipboard, Claude CLI, Finder, Terminal or git.
final class ScriptPresetsTests: XCTestCase {
    private var sandbox: URL!

    override func setUpWithError() throws {
        sandbox = FileManager.default.temporaryDirectory
            .appendingPathComponent("MagicKeysPresetTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: bin, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: sandbox.appendingPathComponent("Developer/your-project"), withIntermediateDirectories: true)

        try fakeTool("pbpaste", #"cat "$SANDBOX/clipboard""#)
        try fakeTool("pbcopy", #"cat > "$SANDBOX/clipboard""#)
        // Answers Finder's "insertion location" query; otherwise records what it
        // was asked to run (AppleScript source) apart from its plain arguments.
        try fakeTool("osascript", #"""
            case "$*" in
              *"insertion location"*) printf '%s\n' "$FAKE_FINDER_PATH"; exit 0 ;;
            esac
            prev=""
            for arg in "$@"; do
              if [ "$prev" = "-e" ]; then printf '%s\n' "$arg" >> "$SANDBOX/osascript-source"
              elif [ "$arg" != "-e" ] && [ "$arg" != "-" ]; then printf '%s\n' "$arg" >> "$SANDBOX/osascript-args"; fi
              prev="$arg"
            done
            if [ "$1" = "-" ]; then cat >> "$SANDBOX/osascript-source"; fi
            """#)
        try fakeTool("git", #"""
            case "$1" in
              diff) echo "diff --git a/README.md b/README.md" ;;
              commit) printf '%s' "$3" > "$SANDBOX/commit-message" ;;
            esac
            """#)
        try write("ORIGINAL", to: "clipboard")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: sandbox)
    }

    // MARK: AI · Clipboard

    func testClipboardPresetsLeaveTheClipboardAloneWhenClaudeFails() throws {
        try fakeTool("claude", #"cat > /dev/null; echo "API Error: Connection error." >&2; exit 1"#)
        XCTAssertFalse(clipboardPresets.isEmpty)
        for preset in clipboardPresets {
            XCTAssertNotEqual(try run(preset.script), 0, "\(preset.name) must report the failure")
            XCTAssertEqual(read("clipboard"), "ORIGINAL", "\(preset.name) overwrote the clipboard")
            XCTAssertNil(read("osascript-source"), "\(preset.name) announced success")
        }
    }

    func testClipboardPresetsLeaveTheClipboardAloneWhenClaudeIsMissing() throws {
        for preset in clipboardPresets {
            XCTAssertEqual(try run(preset.script), 127, preset.name)
            XCTAssertEqual(read("clipboard"), "ORIGINAL", preset.name)
            XCTAssertNil(read("osascript-source"), preset.name)
        }
    }

    func testClipboardPresetsRejectAnEmptyAnswer() throws {
        try fakeTool("claude", "cat > /dev/null")
        for preset in clipboardPresets {
            XCTAssertNotEqual(try run(preset.script), 0, preset.name)
            XCTAssertEqual(read("clipboard"), "ORIGINAL", preset.name)
        }
    }

    func testClipboardPresetsCopyClaudesAnswer() throws {
        try fakeTool("claude", #"cat > /dev/null; printf 'REWRITTEN\n'"#)
        for preset in clipboardPresets {
            try write("ORIGINAL", to: "clipboard")
            XCTAssertEqual(try run(preset.script), 0, preset.name)
            XCTAssertEqual(read("clipboard"), "REWRITTEN", "\(preset.name) should copy the answer without a trailing newline")
            XCTAssertTrue(read("osascript-source")?.contains("display notification") ?? false, preset.name)
        }
    }

    func testSeededImproveWritingIsThePreset() {
        let improve = ScriptPresets.improveWriting
        XCTAssertEqual(K1Config.makeSeeded().defaultProfile.keys[2].tripleTap,
                       .shellScript(script: improve.script, name: improve.name))
    }

    // MARK: AI · Coding

    func testNewClaudeSessionPassesTheFolderAsAnArgument() throws {
        let folder = #"/tmp/Bob's "Notes"'; echo INJECTED; '/"#
        XCTAssertEqual(try run(preset("New Claude Session Here").script, env: ["FAKE_FINDER_PATH": folder]), 0)
        XCTAssertFalse(read("osascript-source")?.contains("INJECTED") ?? true,
                       "the folder must not be spliced into AppleScript source")
        XCTAssertTrue(read("osascript-args")?.contains(folder) ?? false, "the folder should be passed as an argument")
    }

    func testAICommitPassesTheMessageAsAnArgument() throws {
        let message = #"fix: handle "quoted" args"#
        try fakeTool("claude", #"cat > /dev/null; printf '%s\n' 'fix: handle "quoted" args'"#)
        XCTAssertEqual(try run(preset("AI Commit").script), 0)
        XCTAssertEqual(read("commit-message"), message)
        XCTAssertFalse(read("osascript-source")?.contains(message) ?? true,
                       "the message must not be spliced into AppleScript source")
        XCTAssertTrue(read("osascript-args")?.contains(message) ?? false)
    }

    func testAICommitDoesNotCommitWhenClaudeFails() throws {
        try fakeTool("claude", "cat > /dev/null; exit 1")
        XCTAssertNotEqual(try run(preset("AI Commit").script), 0)
        XCTAssertNil(read("commit-message"))
    }

    func testAICommitDoesNotCommitAnEmptyMessage() throws {
        try fakeTool("claude", "cat > /dev/null")
        XCTAssertNotEqual(try run(preset("AI Commit").script), 0)
        XCTAssertNil(read("commit-message"))
    }

    // MARK: Naming

    func testPickingAnExampleFillsAnEmptyName() {
        XCTAssertEqual(ScriptPresets.name(afterPicking: preset("Empty Trash"), currentName: ""), "Empty Trash")
    }

    func testPickingAnotherExampleReplacesTheLastExamplesName() {
        let emptyTrash = preset("Empty Trash")
        XCTAssertEqual(ScriptPresets.name(afterPicking: emptyTrash, currentName: "Timestamp → Clipboard"), "Empty Trash")
        XCTAssertEqual(ScriptPresets.name(afterPicking: emptyTrash, currentName: "Improve Writing"), "Empty Trash")
    }

    func testPickingAnExampleKeepsANameTheUserTyped() {
        XCTAssertEqual(ScriptPresets.name(afterPicking: preset("Empty Trash"), currentName: "Clean up"), "Clean up")
    }

    // MARK: Helpers

    private var bin: URL { sandbox.appendingPathComponent("bin") }

    private var clipboardPresets: [ScriptPreset] {
        ScriptPresets.all.filter { $0.category == "AI · Clipboard" }
    }

    private func preset(_ name: String) -> ScriptPreset {
        guard let preset = ScriptPresets.all.first(where: { $0.name == name }) else {
            fatalError("no preset named \(name)")
        }
        return preset
    }

    private func fakeTool(_ name: String, _ body: String) throws {
        let url = bin.appendingPathComponent(name)
        try "#!/bin/sh\n\(body)\n".write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }

    private func write(_ text: String, to name: String) throws {
        try text.write(to: sandbox.appendingPathComponent(name), atomically: true, encoding: .utf8)
    }

    private func read(_ name: String) -> String? {
        try? String(contentsOf: sandbox.appendingPathComponent(name), encoding: .utf8)
    }

    /// Runs a script the way ActionEngine does, but with zsh's startup files
    /// skipped and PATH limited to the fakes plus the system basics.
    @discardableResult
    private func run(_ script: String, env extra: [String: String] = [:]) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-f", "-c", script]
        process.environment = ["PATH": "\(bin.path):/usr/bin:/bin", "HOME": sandbox.path, "SANDBOX": sandbox.path]
            .merging(extra) { $1 }
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }
}
