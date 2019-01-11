//
//  SliceCommand.swift
//  Juno
//
//  Created by Zachary Stegall on 1/11/19.
//  Copyright © 2019 Zachary Stegall. All rights reserved.
//

import Foundation
import XcodeKit

enum SlicingType {
    case arguments
    case none
}

class SliceCommand: NSObject, XCSourceEditorCommand {

    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        var selections = invocation.buffer.selections as! [XCSourceTextRange]
        while let selection = selections.last {
            for lineIndex in (selection.start.line...selection.end.line).reversed() {
                let line = invocation.buffer.lines[lineIndex] as! String
                let sliceType = slicingType(line)

                switch sliceType {
                case .arguments:
                    let threshold = 2
                    sliceArguments(invocation, line, lineIndex, threshold)
                case .none:
                    continue
                }
            }

            selections.removeLast()
        }

        completionHandler(nil)
    }

    func slicingType(_ line: String) -> SlicingType {
        let openParenthesesRange    = line.ranges(of: JunoHelpers.OpenParenthesis)
        let closedParenthesesRange  = line.ranges(of: JunoHelpers.ClosedParenthesis)

        if openParenthesesRange.count > 0 && closedParenthesesRange.count > 0 {
            return .arguments
        }

        return .none
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
