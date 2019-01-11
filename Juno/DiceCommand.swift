//
//  DiceCommand.swift
//  Juno
//
//  Created by Zachary Stegall on 1/11/19.
//  Copyright © 2019 Zachary Stegall. All rights reserved.
//

import Foundation
import XcodeKit

enum DicingType {
    case arguments
    case none
}

enum DiceCommandTypes: String {
    // TODO: when you decide you want all parentheses in a line or selection to be diced as a choice.
//    case die = "Die"
    case dice = "Dice"
    case tango = "DiceTango"
    case unknown
}

class DiceCommand: NSObject, XCSourceEditorCommand {

    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        var selections = invocation.buffer.selections as! [XCSourceTextRange]
        while let selection = selections.last {
            for lineIndex in (selection.start.line...selection.end.line).reversed() {
                let line = invocation.buffer.lines[lineIndex] as! String
                let diceType = dicingType(line)

                switch diceType {
                case .arguments:
                    let threshold = command(invocation) == .tango ? 2 : 0
                    diceArguments(invocation, line, lineIndex, threshold)
                case .none:
                    continue
                }
            }

            selections.removeLast()
        }

        completionHandler(nil)
    }

    func command(_ invocation: XCSourceEditorCommandInvocation) -> DiceCommandTypes {
        let command = String(invocation.commandIdentifier.split(separator: ".").last!)
        return DiceCommandTypes(rawValue: command) ?? .unknown
    }

    func dicingType(_ line: String) -> DicingType {
        let openParenthesesRange    = line.ranges(of: JunoHelpers.OpenParenthesis)
        let closedParenthesesRange  = line.ranges(of: JunoHelpers.ClosedParenthesis)

        if openParenthesesRange.count > 0 && closedParenthesesRange.count > 0 {
            return .arguments
        }

        return .none
    }

    func diceArguments(_ invocation: XCSourceEditorCommandInvocation, _ line: String, _ lineIndex: Int, _ threshold: Int) {
        let helpers = JunoHelpers()
        let (open, close) = helpers.parenthesisPairs(in: line).first!

        let name        = String(line[...open.lowerBound])
        let arguments   = String(line[open.upperBound..<close.lowerBound])
        let closing     = String(line[close.lowerBound...])

        guard helpers.argumentCount(in: arguments) >= threshold else {
            return
        }

        let namePrefixedWhitespaces = helpers.prefixedWhitespaces(name)
        let baseWhitespacePrefix = helpers.whitespaceString(repeatingCount: namePrefixedWhitespaces)
        let tab = helpers.whitespaceString(repeatingCount: JunoHelpers.TabLength)

        helpers.removeNonFormattedLine(in: invocation, at: lineIndex)
        var lineIndex = helpers.insertElement(name, in: invocation, at: lineIndex)
        lineIndex = helpers.insertArguments(arguments,
                                            in: invocation,
                                            at: lineIndex,
                                            beginningWith: "\(baseWhitespacePrefix)\(tab)")
        lineIndex = helpers.insertElement("\(baseWhitespacePrefix)\(closing)", in: invocation, at: lineIndex)
    }

}
