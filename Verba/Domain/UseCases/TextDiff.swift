enum TextDiff {
    enum Segment: Equatable {
        case equal(String)
        case removed(String)
        case added(String)
    }

    static func wordDiff(original: String, revised: String) -> [Segment] {
        let originalWords = original.split(separator: " ").map(String.init)
        let revisedWords = revised.split(separator: " ").map(String.init)
        let n = originalWords.count
        let m = revisedWords.count

        guard n > 0 else {
            return revisedWords.isEmpty ? [] : [.added(revisedWords.joined(separator: " "))]
        }
        guard m > 0 else {
            return [.removed(originalWords.joined(separator: " "))]
        }

        var lengths = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        for i in stride(from: n - 1, through: 0, by: -1) {
            for j in stride(from: m - 1, through: 0, by: -1) {
                lengths[i][j] = originalWords[i] == revisedWords[j]
                    ? lengths[i + 1][j + 1] + 1
                    : max(lengths[i + 1][j], lengths[i][j + 1])
            }
        }

        enum Op: Equatable { case equal, removed, added }
        var operations: [(Op, String)] = []
        var i = 0
        var j = 0
        while i < n, j < m {
            if originalWords[i] == revisedWords[j] {
                operations.append((.equal, originalWords[i]))
                i += 1
                j += 1
            } else if lengths[i + 1][j] >= lengths[i][j + 1] {
                operations.append((.removed, originalWords[i]))
                i += 1
            } else {
                operations.append((.added, revisedWords[j]))
                j += 1
            }
        }
        while i < n {
            operations.append((.removed, originalWords[i]))
            i += 1
        }
        while j < m {
            operations.append((.added, revisedWords[j]))
            j += 1
        }

        var segments: [Segment] = []
        var currentOp: Op?
        var currentWords: [String] = []

        func flush() {
            guard let currentOp, currentWords.isEmpty == false else { return }
            let joined = currentWords.joined(separator: " ")
            switch currentOp {
            case .equal: segments.append(.equal(joined))
            case .removed: segments.append(.removed(joined))
            case .added: segments.append(.added(joined))
            }
        }

        for (op, word) in operations {
            if op == currentOp {
                currentWords.append(word)
            } else {
                flush()
                currentOp = op
                currentWords = [word]
            }
        }
        flush()

        return segments
    }
}
