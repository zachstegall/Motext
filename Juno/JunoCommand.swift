//
//  JunoCommand.swift
//  Juno
//
//  Created by Stegall, Zach on 1/11/19.
//  Copyright © 2019 Zachary Stegall. All rights reserved.
//

import Foundation
import XcodeKit

enum SplitType {
    case arguments
    case none
}

enum JunoCommandType: String {
    // TODO: when you decide you want all parentheses in a line or selection to be diced as a choice.
//    case die = "Die"
    case slice = "Slice"
    case dice = "Dice"
    case tango = "DiceTango"
    case unknown
}

class JunoCommand: NSObject, XCSourceEditorCommand {

    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        let commandType = command(invocation)
        guard commandType != .unknown else {
            completionHandler(nil)
            return
        }

        var selections = invocation.buffer.selections as! [XCSourceTextRange]
        while let selection = selections.last {
            for lineIndex in (selection.start.line...selection.end.line).reversed() {
                let line = invocation.buffer.lines[lineIndex] as! String
                let splitType = splittingType(line)

                switch splitType {
                case .arguments:
                    let threshold = argumentThreshold(commandType)
                    switch commandType {
                    case .slice:
                        sliceArguments(invocation, line, lineIndex, threshold)
                    default:
                        diceArguments(invocation, line, lineIndex, threshold)
                    }

                case .none:
                    continue
                }
            }

            selections.removeLast()
        }

        completionHandler(nil)
    }

    func command(_ invocation: XCSourceEditorCommandInvocation) -> JunoCommandType {
        let command = String(invocation.commandIdentifier.split(separator: ".").last!)
        return JunoCommandType(rawValue: command) ?? .unknown
    }

    func argumentThreshold(_ commandType: JunoCommandType) -> Int {
        switch commandType {
        case .slice, .tango: return 2
        case .dice, .unknown: return 0
        }
    }

    func splittingType(_ line: String) -> SplitType {
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

    func sliceArguments(_ invocation: XCSourceEditorCommandInvocation, _ line: String, _ lineIndex: Int, _ threshold: Int) {
        let helpers = JunoHelpers()
        let (open, close) = helpers.parenthesisPairs(in: line).first!

        let name        = String(line[...open.lowerBound])
        let closing     = String(line[close.lowerBound...])
        let arguments   = String(line[open.upperBound..<close.lowerBound]) + closing

        let allArguments = helpers.argumentSplit(in: arguments)
        guard allArguments.count >= threshold else {
            return
        }

        let comma = allArguments.count >= 2 ? "," : ""
        let firstElement = name + allArguments[0] + comma
        let baseWhitespacePrefix = helpers.whitespaceString(repeatingCount: name.count)

        helpers.removeNonFormattedLine(in: invocation, at: lineIndex)
        var lineIndex = helpers.insertElement(firstElement, in: invocation, at: lineIndex)

        if allArguments.count >= 2 {
            lineIndex = helpers.insertArguments(allArguments[1...].joined(separator: ","),
                                                in: invocation,
                                                at: lineIndex,
                                                beginningWith: "\(baseWhitespacePrefix)")
        }
    }

}
