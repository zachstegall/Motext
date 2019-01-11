import XcodeKit

struct JunoHelpers {

    static var TabLength = 4
    static var OpenParenthesis = "("
    static var ClosedParenthesis = ")"

    func parenthesisPairs(in string: String) -> [(open: Range<String.Index>, close: Range<String.Index>)] {
        let opened  = string.ranges(of: JunoHelpers.OpenParenthesis)
        let closed  = string.ranges(of: JunoHelpers.ClosedParenthesis)
        let all     = (opened + closed).sorted { return $0.lowerBound < $1.lowerBound }

        var stack = [(String, Int)]()
        var pairs = [(open: Range<String.Index>, close: Range<String.Index>)]()

        for (index, parenthesisRange) in all.enumerated() {
            if opened.contains(parenthesisRange) {
                stack.append((JunoHelpers.OpenParenthesis, index))
                continue
            } else if closed.contains(parenthesisRange) {
                stack.append((JunoHelpers.ClosedParenthesis, index))
            }

            if stack.count >= 2, stack[stack.endIndex - 2].0 == JunoHelpers.OpenParenthesis {
                let closed = stack.popLast()!
                let opened = stack.popLast()!
                pairs.append((all[opened.1], all[closed.1]))
            }
        }

        return pairs.sorted { return $0.0.lowerBound < $1.0.lowerBound }
    }

    func prefixedWhitespaces(_ string: String) -> Int {
        var spaces = 0
        var index = string.startIndex
        while string[index] == " " {
            spaces += 1
            index = string.index(after: index)
        }
        return spaces
    }

    func whitespaceString(repeatingCount count: Int) -> String {
        return String(repeating: " ", count: count)
    }

    func removeNonFormattedLine(in invocation: XCSourceEditorCommandInvocation, at lineIndex: Int) {
        invocation.buffer.lines.removeObject(at: lineIndex)
    }

    func insertElement(_ string: String, in invocation: XCSourceEditorCommandInvocation, at lineIndex: Int) -> Int {
        invocation.buffer.lines.insert(string, at: lineIndex)
        return lineIndex + 1
    }

    func insertArguments(_ arguments: String,
                         in invocation: XCSourceEditorCommandInvocation,
                         at lineIndex: Int,
                         beginningWith spacing: String) -> Int {
        var lineIndex = lineIndex
        let splitArguments = arguments.split(separator: ",")
        for (index, argument) in splitArguments.enumerated() {
            let comma = index < splitArguments.count - 1 ? "," : ""
            let string = "\(spacing)\(argument.trimmingCharacters(in: CharacterSet.whitespaces))\(comma)"
            lineIndex = insertElement(string, in: invocation, at: lineIndex)
        }

        return lineIndex
    }

    func argumentCount(in string: String) -> Int {
        return argumentSplit(in: string).count
    }

    func argumentSplit(in string: String) -> [String.SubSequence] {
        return string.split(separator: ",")
    }

}
