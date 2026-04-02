//
//  BuddyReader.swift
//  CodeIsland
//
//  Reads Claude Code buddy data from ~/.claude.json and computes
//  deterministic bones (species, rarity, stats) using native wyhash.
//  No Bun dependency required.
//

import Combine
import Foundation
import SwiftUI

// MARK: - Color hex extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Buddy Types

enum BuddyRarity: String, Sendable {
    case common, uncommon, rare, epic, legendary
    var displayName: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .common: return Color(hex: "9CA3AF")
        case .uncommon: return Color(hex: "4ADE80")
        case .rare: return Color(hex: "60A5FA")
        case .epic: return Color(hex: "A78BFA")
        case .legendary: return Color(hex: "FBBF24")
        }
    }
    var stars: String {
        switch self {
        case .common: return "★"
        case .uncommon: return "★★"
        case .rare: return "★★★"
        case .epic: return "★★★★"
        case .legendary: return "★★★★★"
        }
    }
}

struct BuddyStats: Sendable {
    let debugging: Int
    let patience: Int
    let chaos: Int
    let wisdom: Int
    let snark: Int
}

enum BuddySpecies: String, CaseIterable, Sendable {
    case duck, goose, blob, cat, dragon, octopus, owl, penguin, turtle, snail
    case ghost, axolotl, capybara, cactus, robot, rabbit, mushroom, chonk
    case unknown

    var emoji: String {
        switch self {
        case .duck: return "🦆"
        case .goose: return "🪿"
        case .cat: return "🐱"
        case .rabbit: return "🐰"
        case .owl: return "🦉"
        case .penguin: return "🐧"
        case .turtle: return "🐢"
        case .snail: return "🐌"
        case .dragon: return "🐉"
        case .octopus: return "🐙"
        case .axolotl: return "🦎"
        case .ghost: return "👻"
        case .robot: return "🤖"
        case .blob: return "🫧"
        case .cactus: return "🌵"
        case .mushroom: return "🍄"
        case .chonk: return "🐈"
        case .capybara: return "🦫"
        case .unknown: return "🐾"
        }
    }
}

struct BuddyInfo: Sendable {
    let name: String
    let personality: String
    let species: BuddySpecies
    let rarity: BuddyRarity
    let stats: BuddyStats
    let eye: String
    let hat: String
    let isShiny: Bool
    let hatchedAt: Date?
}

// MARK: - Buddy Reader

class BuddyReader: ObservableObject {
    static let shared = BuddyReader()

    @Published var buddy: BuddyInfo?

    private init() {
        reload()
    }

    func reload() {
        let configPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude.json")
        guard let data = try? Data(contentsOf: configPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let companion = json["companion"] as? [String: Any],
              let name = companion["name"] as? String,
              let personality = companion["personality"] as? String else {
            buddy = nil
            return
        }

        let hatchedAt: Date? = (companion["hatchedAt"] as? Double).map {
            Date(timeIntervalSince1970: $0 / 1000.0)
        }

        // Get userId for deterministic bones computation
        let userId: String
        if let oauth = json["oauthAccount"] as? [String: Any],
           let uuid = oauth["accountUuid"] as? String {
            userId = uuid
        } else if let uid = json["userID"] as? String {
            userId = uid
        } else {
            userId = "anon"
        }

        // Read salt from Claude Code binary (supports patched installs)
        let salt = Self.readSalt()

        // Compute bones using native wyhash (matches Bun.hash exactly)
        let bones = Self.computeBones(userId: userId, salt: salt)

        buddy = BuddyInfo(
            name: name,
            personality: personality,
            species: bones.species,
            rarity: bones.rarity,
            stats: bones.stats,
            eye: bones.eye,
            hat: bones.hat,
            isShiny: bones.isShiny,
            hatchedAt: hatchedAt
        )
    }

    // MARK: - Salt Detection

    private static let originalSalt = "friend-2026-401"

    private static func readSalt() -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let versionsDir = "\(home)/.local/share/claude/versions"

        // Find latest Claude binary
        guard let versions = try? FileManager.default.contentsOfDirectory(atPath: versionsDir) else {
            return originalSalt
        }

        let binaries = versions
            .filter { !$0.contains(".bak") && !$0.contains(".anybuddy") }
            .sorted { $0.compare($1, options: .numeric) == .orderedDescending }

        let origBytes = Data(originalSalt.utf8)

        // Check ALL versions — a patched older version means user customized their buddy
        for binary in binaries {
            let binaryPath = "\(versionsDir)/\(binary)"
            guard let binaryData = try? Data(contentsOf: URL(fileURLWithPath: binaryPath)) else { continue }

            // If original salt found, this version is unpatched — skip, check older ones
            if binaryData.range(of: origBytes) != nil { continue }

            // This version was patched — extract the new salt from its backup
            let bakCandidates = ["\(binaryPath).anybuddy-bak", "\(binaryPath).bak"]
            for bakPath in bakCandidates {
                guard let bakData = try? Data(contentsOf: URL(fileURLWithPath: bakPath)) else { continue }
                if let range = bakData.range(of: origBytes) {
                    let offset = range.lowerBound
                    let end = offset + origBytes.count
                    guard end <= binaryData.count else { continue }
                    let patchedBytes = binaryData[offset..<end]
                    if let patchedSalt = String(data: Data(patchedBytes), encoding: .utf8),
                       patchedSalt.allSatisfy({ $0.isASCII && !$0.isNewline }) {
                        return patchedSalt
                    }
                }
            }
        }

        return originalSalt
    }

    // MARK: - Bones Computation (Mulberry32 + WyHash)

    private struct Bones {
        let species: BuddySpecies
        let rarity: BuddyRarity
        let stats: BuddyStats
        let eye: String
        let hat: String
        let isShiny: Bool
    }

    /// Mulberry32 PRNG — same as Claude Code's implementation
    private struct Mulberry32 {
        var state: UInt32

        init(seed: UInt32) {
            self.state = seed
        }

        mutating func next() -> Double {
            state &+= 0x6D2B79F5
            var t = state
            t = (t ^ (t >> 15)) &* (t | 1)
            t = (t &+ ((t ^ (t >> 7)) &* (t | 61))) ^ t
            let result = (t ^ (t >> 14))
            return Double(result) / 4294967296.0
        }
    }

    private static func computeBones(userId: String, salt: String) -> Bones {
        let key = userId + salt
        let hash = WyHash.hash(key)
        let seed = UInt32(hash & 0xFFFFFFFF)
        var rng = Mulberry32(seed: seed)

        // Species
        let speciesAll: [BuddySpecies] = [.duck, .goose, .blob, .cat, .dragon, .octopus, .owl, .penguin, .turtle, .snail, .ghost, .axolotl, .capybara, .cactus, .robot, .rabbit, .mushroom, .chonk]
        let species = speciesAll[Int(floor(rng.next() * Double(speciesAll.count)))]

        // Rarity
        let rarityWeights: [(BuddyRarity, Int)] = [(.common, 60), (.uncommon, 25), (.rare, 10), (.epic, 4), (.legendary, 1)]
        var roll = rng.next() * 100.0
        var rarity: BuddyRarity = .common
        for (r, w) in rarityWeights {
            roll -= Double(w)
            if roll < 0 { rarity = r; break }
        }

        // Eye
        let eyes = ["·", "✦", "×", "◉", "@", "°"]
        let eye = eyes[Int(floor(rng.next() * Double(eyes.count)))]

        // Hat
        let hats = ["none", "crown", "tophat", "propeller", "halo", "wizard", "beanie", "tinyduck"]
        let hat = rarity == .common ? "none" : hats[Int(floor(rng.next() * Double(hats.count)))]

        // Shiny
        let isShiny = rng.next() < 0.01

        // Stats
        let statNames = ["DEBUGGING", "PATIENCE", "CHAOS", "WISDOM", "SNARK"]
        let rarityFloor: [BuddyRarity: Int] = [.common: 5, .uncommon: 15, .rare: 25, .epic: 35, .legendary: 50]
        let statFloor = rarityFloor[rarity] ?? 5

        let peak = statNames[Int(floor(rng.next() * Double(statNames.count)))]
        var dump = statNames[Int(floor(rng.next() * Double(statNames.count)))]
        while dump == peak { dump = statNames[Int(floor(rng.next() * Double(statNames.count)))] }

        var statValues = [String: Int]()
        for name in statNames {
            if name == peak {
                statValues[name] = min(100, statFloor + 50 + Int(floor(rng.next() * 30)))
            } else if name == dump {
                statValues[name] = max(1, statFloor - 10 + Int(floor(rng.next() * 15)))
            } else {
                statValues[name] = statFloor + Int(floor(rng.next() * 40))
            }
        }

        return Bones(
            species: species,
            rarity: rarity,
            stats: BuddyStats(
                debugging: statValues["DEBUGGING"] ?? 0,
                patience: statValues["PATIENCE"] ?? 0,
                chaos: statValues["CHAOS"] ?? 0,
                wisdom: statValues["WISDOM"] ?? 0,
                snark: statValues["SNARK"] ?? 0
            ),
            eye: eye,
            hat: hat,
            isShiny: isShiny
        )
    }
}
