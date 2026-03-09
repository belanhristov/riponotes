import Foundation

public enum EditorCommand: Sendable {
    case indent
    case outdent
    case increaseHeading
    case decreaseHeading
    case toggleChecklist
    case insertDivider(afterLine: Int?)
}

public enum EditorToolbarError: Error {
    case invalidLineRange
}

public struct EditorToolbarService: Sendable {
    public init() {}

    public func apply(
        _ command: EditorCommand,
        to text: String,
        lineRange: ClosedRange<Int>? = nil
    ) throws -> String {
        var lines = text.components(separatedBy: "\n")
        if lines.isEmpty { lines = [""] }

        let targetRange = try normalizedRange(lineRange, lineCount: lines.count)

        switch command {
        case .indent:
            for i in targetRange {
                lines[i] = "    " + lines[i]
            }

        case .outdent:
            for i in targetRange {
                lines[i] = outdented(lines[i])
            }

        case .increaseHeading:
            for i in targetRange {
                lines[i] = increasedHeading(lines[i])
            }

        case .decreaseHeading:
            for i in targetRange {
                lines[i] = decreasedHeading(lines[i])
            }

        case .toggleChecklist:
            for i in targetRange {
                let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("- [ ] ") {
                    lines[i] = lines[i].replacingOccurrences(of: "- [ ] ", with: "", options: [.anchored])
                } else {
                    lines[i] = "- [ ] " + lines[i]
                }
            }

        case let .insertDivider(afterLine):
            let divider = "---"
            if let afterLine {
                guard afterLine >= 1, afterLine <= lines.count else {
                    throw EditorToolbarError.invalidLineRange
                }
                lines.insert(divider, at: afterLine)
            } else {
                lines.append(divider)
            }
        }

        return lines.joined(separator: "\n")
    }

    private func normalizedRange(_ range: ClosedRange<Int>?, lineCount: Int) throws -> ClosedRange<Int> {
        if let range {
            guard range.lowerBound >= 1, range.upperBound <= lineCount, range.lowerBound <= range.upperBound else {
                throw EditorToolbarError.invalidLineRange
            }
            return (range.lowerBound - 1)...(range.upperBound - 1)
        }
        return 0...(max(lineCount - 1, 0))
    }

    private func outdented(_ line: String) -> String {
        if line.hasPrefix("    ") {
            return String(line.dropFirst(4))
        }
        if line.hasPrefix("\t") {
            return String(line.dropFirst())
        }
        return line
    }

    private func increasedHeading(_ line: String) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let prefixCount = trimmed.prefix { $0 == "#" }.count
        if prefixCount == 0 {
            return "# " + line
        }
        if prefixCount >= 6 {
            return line
        }
        return "#" + line
    }

    private func decreasedHeading(_ line: String) -> String {
        if line.hasPrefix("# ") {
            return String(line.dropFirst(2))
        }
        if line.hasPrefix("##") {
            return String(line.dropFirst())
        }
        return line
    }
}
