import Foundation

public enum EditorCommand: Sendable {
    case indent
    case outdent
    case increaseHeading
    case decreaseHeading
    case toggleChecklist
    case toggleBulletedList
    case toggleNumberedList
    case toggleQuote
    case toggleCodeFence
    case insertTimestamp
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

        case .toggleBulletedList:
            for i in targetRange {
                let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("- ") {
                    lines[i] = lines[i].replacingOccurrences(of: "- ", with: "", options: [.anchored])
                } else {
                    lines[i] = "- " + lines[i]
                }
            }

        case .toggleNumberedList:
            for (offset, i) in targetRange.enumerated() {
                let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
                if trimmed.first?.isNumber == true,
                   trimmed.contains(". ")
                {
                    if let dot = lines[i].firstIndex(of: ".") {
                        let next = lines[i].index(after: dot)
                        let after = next < lines[i].endIndex ? lines[i].index(after: next) : lines[i].endIndex
                        if after <= lines[i].endIndex {
                            lines[i] = String(lines[i][after...])
                        }
                    }
                } else {
                    lines[i] = "\(offset + 1). " + lines[i]
                }
            }

        case .toggleQuote:
            for i in targetRange {
                let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("> ") {
                    lines[i] = lines[i].replacingOccurrences(of: "> ", with: "", options: [.anchored])
                } else {
                    lines[i] = "> " + lines[i]
                }
            }

        case .toggleCodeFence:
            let segment = targetRange.map { lines[$0] }.joined(separator: "\n")
            if segment.hasPrefix("```"), segment.hasSuffix("```") {
                var unwrapped = segment
                unwrapped = String(unwrapped.dropFirst(3))
                unwrapped = String(unwrapped.dropLast(3))
                let replacement = unwrapped.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
                lines.replaceSubrange(targetRange, with: replacement)
            } else {
                let wrapped = ["```"] + targetRange.map { lines[$0] } + ["```"]
                lines.replaceSubrange(targetRange, with: wrapped)
            }

        case .insertTimestamp:
            let stamp = Date.now.formatted(date: .abbreviated, time: .shortened)
            lines.append("[\(stamp)]")

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
