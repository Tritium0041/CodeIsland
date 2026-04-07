//
//  HookInstaller.swift
//  ClaudeIsland
//
//  Auto-installs Claude Code hooks on app launch
//

import Foundation

struct HookInstaller {
    private static let hookScriptCommandPath = "~/.claude/hooks/codeisland-state.py"
    private static let defaultCopilotHookTimeoutSec = 10
    private static let preToolUseCopilotHookTimeoutSec = 300
    private static let supportedCopilotHookEvents: Set<String> = [
        "sessionStart",
        "sessionEnd",
        "userPromptSubmitted",
        "preToolUse",
        "postToolUse",
        "agentStop",
        "subagentStop",
        "errorOccurred"
    ]

    /// Install hook script and update settings.json on app launch
    static func installIfNeeded() {
        let claudeDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude")
        let settings = claudeDir.appendingPathComponent("settings.json")
        let pythonScript = hookScriptURL()
        let hooksDir = pythonScript.deletingLastPathComponent()

        try? FileManager.default.createDirectory(
            at: hooksDir,
            withIntermediateDirectories: true
        )

        if let bundled = Bundle.main.url(forResource: "codeisland-state", withExtension: "py") {
            try? FileManager.default.removeItem(at: pythonScript)
            try? FileManager.default.copyItem(at: bundled, to: pythonScript)
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: pythonScript.path
            )
        }

        updateClaudeSettings(at: settings)
        installCopilotHooks()
    }

    private static func updateClaudeSettings(at settingsURL: URL) {
        var json: [String: Any] = [:]
        if let data = try? Data(contentsOf: settingsURL),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            json = existing
        }

        let python = detectPython()
        let command = "\(python) \(hookScriptCommandPath)"
        let hookEntry: [[String: Any]] = [["type": "command", "command": command]]
        let hookEntryWithTimeout: [[String: Any]] = [["type": "command", "command": command, "timeout": 86400]]
        let withMatcher: [[String: Any]] = [["matcher": "*", "hooks": hookEntry]]
        let withMatcherAndTimeout: [[String: Any]] = [["matcher": "*", "hooks": hookEntryWithTimeout]]
        let withoutMatcher: [[String: Any]] = [["hooks": hookEntry]]
        let preCompactConfig: [[String: Any]] = [
            ["matcher": "auto", "hooks": hookEntry],
            ["matcher": "manual", "hooks": hookEntry]
        ]

        var hooks = json["hooks"] as? [String: Any] ?? [:]

        let hookEvents: [(String, [[String: Any]])] = [
            ("UserPromptSubmit", withoutMatcher),
            ("PreToolUse", withMatcher),
            ("PostToolUse", withMatcher),
            ("PermissionRequest", withMatcherAndTimeout),
            ("Notification", withMatcher),
            ("Stop", withoutMatcher),
            ("SubagentStop", withoutMatcher),
            ("SessionStart", withoutMatcher),
            ("SessionEnd", withoutMatcher),
            ("PreCompact", preCompactConfig),
        ]

        for (event, config) in hookEvents {
            if var existingEvent = hooks[event] as? [[String: Any]] {
                let hasOurHook = existingEvent.contains { entry in
                    if let entryHooks = entry["hooks"] as? [[String: Any]] {
                        return entryHooks.contains { h in
                            let cmd = h["command"] as? String ?? ""
                            return cmd.contains("codeisland-state.py")
                        }
                    }
                    return false
                }
                if !hasOurHook {
                    existingEvent.append(contentsOf: config)
                    hooks[event] = existingEvent
                }
            } else {
                hooks[event] = config
            }
        }

        json["hooks"] = hooks

        if let data = try? JSONSerialization.data(
            withJSONObject: json,
            options: [.prettyPrinted, .sortedKeys]
        ) {
            try? data.write(to: settingsURL)
        }
    }

    private static func installCopilotHooks() {
        let copilotHooksDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".copilot")
            .appendingPathComponent("hooks")
        let copilotHookFile = copilotHooksDir.appendingPathComponent("codeisland.json")

        try? FileManager.default.createDirectory(
            at: copilotHooksDir,
            withIntermediateDirectories: true
        )

        let python = detectPython()
        let hookConfig: [String: Any] = [
            "version": 1,
            "hooks": copilotHooks(pythonExecutable: python)
        ]

        if let data = try? JSONSerialization.data(
            withJSONObject: hookConfig,
            options: [.prettyPrinted, .sortedKeys]
        ) {
            try? data.write(to: copilotHookFile)
        }
    }

    /// Check if hooks are currently installed
    static func isInstalled() -> Bool {
        // Keep backward compatibility: if either system is configured, treat hooks as installed.
        isClaudeInstalled() || isCopilotInstalled()
    }

    private static func isClaudeInstalled() -> Bool {
        let settings = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude")
            .appendingPathComponent("settings.json")
        guard let data = try? Data(contentsOf: settings),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = json["hooks"] as? [String: Any] else {
            return false
        }

        for (_, value) in hooks {
            if let entries = value as? [[String: Any]] {
                for entry in entries {
                    if let entryHooks = entry["hooks"] as? [[String: Any]] {
                        for hook in entryHooks {
                            if let cmd = hook["command"] as? String,
                               cmd.contains("codeisland-state.py") {
                                return true
                            }
                        }
                    }
                }
            }
        }
        return false
    }

    private static func isCopilotInstalled() -> Bool {
        let copilotHookFile = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".copilot")
            .appendingPathComponent("hooks")
            .appendingPathComponent("codeisland.json")

        guard let data = try? Data(contentsOf: copilotHookFile),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = json["hooks"] as? [String: Any] else {
            return false
        }

        // Copilot format: hooks = { "sessionStart": [...], "preToolUse": [...], ... }
        for (_, value) in hooks {
            if let entries = value as? [[String: Any]] {
                for entry in entries {
                    let command = entry["bash"] as? String ?? ""
                    if command.contains("codeisland-state.py") {
                        return true
                    }
                }
            }
        }
        return false
    }

    /// Uninstall hooks from settings.json and remove script
    static func uninstall() {
        let claudeDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude")
        let settings = claudeDir.appendingPathComponent("settings.json")
        let pythonScript = hookScriptURL()

        try? FileManager.default.removeItem(at: pythonScript)

        guard let data = try? Data(contentsOf: settings),
              var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              var hooks = json["hooks"] as? [String: Any] else {
            return
        }

        for (event, value) in hooks {
            if var entries = value as? [[String: Any]] {
                entries.removeAll { entry in
                    if let entryHooks = entry["hooks"] as? [[String: Any]] {
                        return entryHooks.contains { hook in
                            let cmd = hook["command"] as? String ?? ""
                            return cmd.contains("codeisland-state.py")
                        }
                    }
                    return false
                }

                if entries.isEmpty {
                    hooks.removeValue(forKey: event)
                } else {
                    hooks[event] = entries
                }
            }
        }

        if hooks.isEmpty {
            json.removeValue(forKey: "hooks")
        } else {
            json["hooks"] = hooks
        }

        if let data = try? JSONSerialization.data(
            withJSONObject: json,
            options: [.prettyPrinted, .sortedKeys]
        ) {
            try? data.write(to: settings)
        }

        let copilotHookFile = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".copilot")
            .appendingPathComponent("hooks")
            .appendingPathComponent("codeisland.json")
        try? FileManager.default.removeItem(at: copilotHookFile)
    }

    private static func detectPython() -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["python3"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                return "python3"
            }
        } catch {}

        return "python"
    }

    private static func copilotHookCommand(pythonExecutable: String, eventName: String, timeoutSec: Int) -> [String: Any] {
        // Copilot CLI hooks use command entries with `type`, `bash`, and `timeoutSec`.
        guard supportedCopilotHookEvents.contains(eventName) else {
            return ["type": "command", "bash": ":", "timeoutSec": timeoutSec]
        }

        let safePython = (pythonExecutable == "python3" || pythonExecutable == "python") ? pythonExecutable : "python3"
        let scriptPath = hookScriptURL().path
        let escapedScriptPath = scriptPath.replacingOccurrences(of: "'", with: "'\"'\"'")

        guard let payloadData = try? JSONSerialization.data(withJSONObject: ["hook_event_name": eventName]) else {
            return ["type": "command", "bash": ":", "timeoutSec": timeoutSec]
        }

        let payloadBase64 = payloadData.base64EncodedString()
        let bashCommand = "\(safePython) -c \"import base64,sys;sys.stdout.buffer.write(base64.b64decode('\(payloadBase64)'))\" | \(safePython) '\(escapedScriptPath)'"
        return ["type": "command", "bash": bashCommand, "timeoutSec": timeoutSec]
    }

    private static func copilotHooks(pythonExecutable: String) -> [String: Any] {
        return [
            "sessionStart": [copilotHookCommand(pythonExecutable: pythonExecutable, eventName: "sessionStart", timeoutSec: defaultCopilotHookTimeoutSec)],
            "sessionEnd": [copilotHookCommand(pythonExecutable: pythonExecutable, eventName: "sessionEnd", timeoutSec: defaultCopilotHookTimeoutSec)],
            "userPromptSubmitted": [copilotHookCommand(pythonExecutable: pythonExecutable, eventName: "userPromptSubmitted", timeoutSec: defaultCopilotHookTimeoutSec)],
            "preToolUse": [copilotHookCommand(pythonExecutable: pythonExecutable, eventName: "preToolUse", timeoutSec: preToolUseCopilotHookTimeoutSec)],
            "postToolUse": [copilotHookCommand(pythonExecutable: pythonExecutable, eventName: "postToolUse", timeoutSec: defaultCopilotHookTimeoutSec)],
            "agentStop": [copilotHookCommand(pythonExecutable: pythonExecutable, eventName: "agentStop", timeoutSec: defaultCopilotHookTimeoutSec)],
            "subagentStop": [copilotHookCommand(pythonExecutable: pythonExecutable, eventName: "subagentStop", timeoutSec: defaultCopilotHookTimeoutSec)],
            "errorOccurred": [copilotHookCommand(pythonExecutable: pythonExecutable, eventName: "errorOccurred", timeoutSec: defaultCopilotHookTimeoutSec)]
        ]
    }

    private static func hookScriptURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude")
            .appendingPathComponent("hooks")
            .appendingPathComponent("codeisland-state.py")
    }
}
