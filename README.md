<div align="center">

<img src="ClaudeIsland/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" width="128" height="128" alt="CodeIsland" />

# CodeIsland

**Your AI agents live in the notch.**

This is a passion project built purely out of personal interest. It is **free and open-source** with no commercial intentions whatsoever. I welcome everyone to try it out, report bugs, share it with your colleagues, and contribute code. Let's build something great together!

这是一个纯粹出于个人兴趣开发的项目，**完全免费开源**，没有任何商业目的。欢迎大家试用、提 Bug、推荐给身边的同事使用，也欢迎贡献代码。一起把它做得更好！

English | [中文](README.zh-CN.md)

[![GitHub stars](https://img.shields.io/github/stars/xmqywx/CodeIsland?style=social)](https://github.com/xmqywx/CodeIsland/stargazers)

[![Website](https://img.shields.io/badge/website-xmqywx.github.io%2FCodeIsland-7c3aed?style=flat-square)](https://xmqywx.github.io/CodeIsland/)
[![Release](https://img.shields.io/github/v/release/xmqywx/CodeIsland?style=flat-square&color=4ADE80)](https://github.com/xmqywx/CodeIsland/releases)
[![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple)](https://github.com/xmqywx/CodeIsland/releases)
[![License](https://img.shields.io/badge/license-CC%20BY--NC%204.0-green?style=flat-square)](LICENSE.md)

**If you find this useful, please give it a star! It keeps us motivated to improve.**

**如果觉得好用，请点个 Star 支持一下！这是我们持续更新的最大动力。**

</div>

---

A native macOS app that turns your MacBook's notch into a real-time control surface for AI coding agents. Monitor sessions, approve permissions, jump to terminals, and hang out with your Claude Code buddy — all without leaving your flow.

## Features

### Dynamic Island Notch

The collapsed notch shows everything at a glance:

- **Animated buddy** — your Claude Code `/buddy` pet rendered as 16x16 pixel art with wave/dissolve/reassemble animation
- **Status dot** — color indicates state:
  - 🟦 Cyan = working
  - 🟧 Amber = needs approval
  - 🟩 Green = done / waiting for input
  - 🟣 Purple = thinking
  - 🔴 Red = error, or session unattended >60s
  - 🟠 Orange = session unattended >30s
- **Project name + status** — carousel rotates task title, tool action, project name
- **Session count** — `×3` badge showing active sessions
- **Pixel Cat Mode** — toggle to show the hand-drawn pixel cat instead of your buddy

### Session List

Expand the notch to see all your Claude Code sessions:

- **Pixel cat face** per session with state-specific expressions (blink, eye-dart, heart eyes on done, X eyes on error)
- **Auto-detected terminal** — shows Ghostty, Warp, iTerm2, cmux, Terminal, VS Code, Cursor, etc.
- **Task title** — displays your first message or Claude's summary, not just the folder name
- **Duration badge** — how long each session has been running
- **Golden jump button** — click to jump to the exact terminal tab (via cmux/Ghostty AppleScript)
- **Glow dots** with gradient dividers — minimal, clean design
- **Hover effects** — row highlight + golden terminal icon

### Claude Code Buddy Integration

Full integration with Claude Code's `/buddy` companion system:

- **Accurate stats** — species, rarity, eye style, hat, shiny status, and all 5 stats (DEBUGGING, PATIENCE, CHAOS, WISDOM, SNARK) computed using the exact same Bun.hash + Mulberry32 algorithm as Claude Code
- **Dynamic salt detection** — reads the actual salt from your Claude Code binary, supports patched installs (any-buddy compatible)
- **ASCII art sprite** — all 18 buddy species rendered as animated ASCII art with idle animation sequence (blink, fidget), matching Claude Code's terminal display
- **Buddy card** — left-right layout: ASCII sprite + name on the left, ASCII stat bars `[████████░░]` + personality on the right
- **Rarity stars** — ★ Common to ★★★★★ Legendary with color coding
- **18 species supported** — duck, goose, blob, cat, dragon, octopus, owl, penguin, turtle, snail, ghost, axolotl, capybara, cactus, robot, rabbit, mushroom, chonk

### GitHub Copilot CLI Hook Support

CodeIsland now includes built-in hook config for GitHub Copilot CLI:

- Hook config is shipped in `.github/hooks/codeisland.json`
- The same `codeisland-state.py` pipeline is reused, so Copilot CLI sessions can be shown in CodeIsland
- Supported Copilot hook events include `sessionStart`, `sessionEnd`, `userPromptSubmitted`, `preToolUse`, `postToolUse`, `agentStop`, `subagentStop`, and `errorOccurred`

### Permission Approval

Approve or deny Claude Code's permission requests right from the notch:

- **Code diff preview** — see exactly what will change before allowing (green/red line highlighting)
- **File path display** — warning icon + tool name + file being modified
- **Deny/Allow buttons** — with keyboard hint labels
- **Hook-based protocol** — responses sent via Unix socket, no terminal switching needed

### Pixel Cat Companion

A hand-drawn pixel cat with 6 animated states:

| State | Expression |
|-------|-----------|
| Idle | Black eyes, gentle blink every 90 frames |
| Working | Eyes dart left/center/right (reading code) |
| Needs You | Eyes + right ear twitches |
| Thinking | Closed eyes, breathing nose |
| Error | Red X eyes |
| Done | Green heart eyes + green tint overlay |

### 8-bit Sound System

Chiptune alerts for every event:

| Event | Default |
|-------|---------|
| Session start | ON |
| Processing begins | OFF |
| Needs approval | ON |
| Approval granted | ON |
| Approval denied | ON |
| Session complete | ON |
| Error | ON |
| Context compacting | OFF |

Each sound can be toggled individually. Global mute and volume control available.

### Project Grouping

Toggle between flat list and project-grouped view:

- Sessions automatically grouped by working directory
- Collapsible project headers with active count
- Chevron icons for expand/collapse

## Settings

| Setting | Description |
|---------|-------------|
| **Screen** | Choose which display shows the notch (Auto, Built-in, or specific monitor) |
| **Notification Sound** | Select alert sound style |
| **Group by Project** | Toggle between flat list and project-grouped sessions |
| **Pixel Cat Mode** | Switch notch icon between pixel cat and buddy emoji animation |
| **Language** | Auto (system) / English / 中文 |
| **Launch at Login** | Start CodeIsland automatically when you log in |
| **Hooks** | Install/uninstall Claude Code hooks in `~/.claude/settings.json` and Copilot hooks in `~/.copilot/hooks/codeisland.json` |
| **Accessibility** | Grant accessibility permission for terminal window focusing |

## Terminal Support

CodeIsland auto-detects your terminal from the process tree:

| Terminal | Detection | Jump-to-Tab |
|----------|-----------|-------------|
| cmux | Auto | AppleScript (by working directory) |
| Ghostty | Auto | AppleScript (by working directory) |
| Warp | Auto | Activate only (no tab API) |
| iTerm2 | Auto | AppleScript |
| Terminal.app | Auto | Activate |
| Alacritty | Auto | Activate |
| Kitty | Auto | Activate |
| WezTerm | Auto | Activate |
| VS Code | Auto | Activate |
| Cursor | Auto | Activate |
| Zed | Auto | Activate |

> **Recommended: [cmux](https://cmux.io)** — A modern terminal multiplexer built on Ghostty. CodeIsland works best with cmux: precise workspace-level jumping, AskUserQuestion quick reply via `cmux send`, and smart popup suppression per workspace tab. If you manage multiple Claude Code sessions, cmux + CodeIsland is the ideal combo.
>
> **推荐搭配 [cmux](https://cmux.io)** — 基于 Ghostty 的现代终端复用器。CodeIsland 与 cmux 配合最佳：精确到 workspace 级别的跳转、AskUserQuestion 快捷回复、智能弹出抑制。多 Claude Code 会话管理的理想组合。

## Install

**Download** the latest `.dmg` from [Releases](https://github.com/xmqywx/CodeIsland/releases), open it, drag to Applications.

> **macOS Gatekeeper warning:** If you see "Code Island is damaged and can't be opened", run this in Terminal:
> ```bash
> sudo xattr -rd com.apple.quarantine /Applications/Code\ Island.app
> ```

### Build from Source

```bash
git clone https://github.com/xmqywx/CodeIsland.git
cd CodeIsland
xcodebuild -project ClaudeIsland.xcodeproj -scheme ClaudeIsland \
  -configuration Release CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  DEVELOPMENT_TEAM="" build
```

### Requirements

- macOS 14+ (Sonoma)
- MacBook with notch (floating mode on external displays)
- [Bun](https://bun.sh) for accurate buddy stats (optional, falls back to basic info)

## How It Works

1. **Zero config** — on first launch, CodeIsland installs hooks into `~/.claude/settings.json` and `~/.copilot/hooks/codeisland.json`
2. **Hook events** — a Python script (`codeisland-state.py`) sends session state to the app via Unix socket (`/tmp/codeisland.sock`)
3. **Permission approval** — for `PermissionRequest` events, the socket stays open until you click Allow/Deny, then sends the decision back to Claude Code
4. **Buddy data** — reads `~/.claude.json` for name/personality, runs `buddy-bones.js` with Bun for accurate species/rarity/stats
5. **Terminal jump** — uses AppleScript to find and focus the correct terminal tab by matching working directory

## GitHub Online Packaging CI

This repository now includes GitHub Actions packaging CI at `.github/workflows/package.yml`:

- Runs on `macos-14`
- Builds unsigned Release app with `xcodebuild`
- Packages the `.app` into a `.zip`
- Uploads the package as a workflow artifact

## i18n

CodeIsland supports English and Chinese with automatic system locale detection. Override in Settings > Language.

## Contributing

Contributions are welcome! Here's how:

1. **Report bugs** — [Open an issue](https://github.com/xmqywx/CodeIsland/issues) with steps to reproduce
2. **Submit a PR** — Fork the repo, create a branch, make your changes, and open a Pull Request
3. **Suggest features** — Open an issue tagged `enhancement`

I will personally review and merge all PRs. Please keep changes focused and include a clear description.

## 参与贡献

欢迎参与！方式如下：

1. **提交 Bug** — 在 [Issues](https://github.com/xmqywx/CodeIsland/issues) 中描述问题和复现步骤
2. **提交 PR** — Fork 本仓库，新建分支，修改后提交 Pull Request
3. **建议功能** — 在 Issues 中提出，标记为 `enhancement`

我会亲自 Review 并合并所有 PR。请保持改动聚焦，附上清晰的说明。

## Contact / 联系方式

Have questions or want to chat? Reach out!

有问题或想交流？欢迎联系！

- **Email / 邮箱**: xmqywx@gmail.com

<img src="docs/wechat-qr-kris.jpg" width="180" alt="WeChat - Kris" />  <img src="docs/wechat-qr.jpg" width="180" alt="WeChat - Carey" />

## Credits

Forked from [Claude Island](https://github.com/farouqaldori/claude-island) by farouqaldori. Rebuilt with pixel cat animations, buddy integration, cmux support, i18n, and minimal glow-dot design.

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=xmqywx/CodeIsland&type=Date)](https://star-history.com/#xmqywx/CodeIsland&Date)

## License

CC BY-NC 4.0 — free for personal use, no commercial use.
