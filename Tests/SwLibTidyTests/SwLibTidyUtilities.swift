/**
 *  SwLibTidyUtilities.swift
 *   Part of the SwLibTidy wrapper library for tidy-html5 ("CLibTidy").
 *   See https://github.com/htacg/tidy-html5
 *
 *   Copyright © 2017-2021 by HTACG. All rights reserved.
 *   Created by Jim Derry 2017; copyright assigned to HTACG. Permission to use
 *   this source code per the W3C Software Notice and License:
 *   https://www.w3.org/Consortium/Legal/2002/copyright-software-20021231
 *
 *   Purpose
 *    Provide some basic utilities for the unit tests.
 */

import Foundation
import XCTest
import SwLibTidy


// MARK: - Shuffling Arrays


/**
 *  Shuffles the contents of this collection.
 *  Contributed by Nate Cook from Stack Overflow.
 */
extension MutableCollection {

    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }

        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: Int = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}


/**
 *  Returns an array with the contents of this sequence, shuffled.
 *  Contributed by Nate Cook from Stack Overflow.
 */
extension Sequence {

    func shuffled() -> [Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}


// MARK: - Random Option Values


/*
 *  Returns x random words in an optional array of string. The words are provided
 *  by macOS in /usr/share/dict/words, and we will return nil if this can't be
 *  loaded.
 */
public func random_words( _ x: Int ) -> [String]? {

    guard
        let wordsString = try? String(contentsOfFile: "/usr/share/dict/words")
    else { return nil }

    let words = wordsString.components(separatedBy: .newlines)
    var result: [String] = [];

    for _ in 1...x {
        result.append( words[Int( arc4random_uniform( UInt32(words.count) ) )] )
    }

    return result;
}


/*
 * Returns a string with a random doctype from the doctypes that Tidy recognizes.
 */
public func random_doctype() -> String {

    let words = [ "html5", "omit", "auto", "strict", "transitional" ];

    return words[ Int( arc4random_uniform( UInt32(words.count) ) ) ]
}


/*
 *  Returns an array of x random strings for use with the `mute` option. These
 *  are from CLibTidy `tidyenum.h`, defined in the `FOREACH_REPORT_MSG` macro.
 *  The test is fragile if CLibTidy removes any of these strings.
 */
public func random_mute( _ x: Int ) -> [String] {

    let words = [ "ADDED_MISSING_CHARSET",
                  "ANCHOR_NOT_UNIQUE",
                  "APOS_UNDEFINED",
                  "ATTR_VALUE_NOT_LCASE",
                  "ATTRIBUTE_IS_NOT_ALLOWED",
                  "ATTRIBUTE_VALUE_REPLACED",
                  "BACKSLASH_IN_URI",
                  "BAD_ATTRIBUTE_VALUE_REPLACED",
                  "BAD_ATTRIBUTE_VALUE",
                  "BAD_CDATA_CONTENT",
                  "BAD_CDATA_CONTENT",
                  "BAD_SUMMARY_HTML5",
                  "BAD_SURROGATE_LEAD",
                  "BAD_SURROGATE_PAIR",
                  "BAD_SURROGATE_TAIL",
                  "CANT_BE_NESTED",
                  "COERCE_TO_ENDTAG",
                  "CONTENT_AFTER_BODY",
                  "CUSTOM_TAG_DETECTED",
                  "DISCARDING_UNEXPECTED",
                  "DOCTYPE_AFTER_TAGS",
                  "DUPLICATE_FRAMESET",
                  "ELEMENT_NOT_EMPTY",
                  "ELEMENT_VERS_MISMATCH_ERROR",
                  "ELEMENT_VERS_MISMATCH_WARN",
                  "ENCODING_MISMATCH",
                  "ESCAPED_ILLEGAL_URI",
                  "FILE_CANT_OPEN",
                  "FILE_CANT_OPEN_CFG",
                  "FILE_NOT_FILE",
                  "FIXED_BACKSLASH",
                  "FOUND_STYLE_IN_BODY",
                  "ID_NAME_MISMATCH",
                  "ILLEGAL_NESTING",
                  "ILLEGAL_URI_CODEPOINT",
                  "ILLEGAL_URI_REFERENCE",
                  "INSERTING_AUTO_ATTRIBUTE",
                  "INSERTING_TAG",
                  "INVALID_ATTRIBUTE",
                  "INVALID_NCR",
                  "INVALID_SGML_CHARS",
                  "INVALID_UTF8",
                  "INVALID_UTF16",
                  "INVALID_XML_ID",
                  "JOINING_ATTRIBUTE",
                  "MALFORMED_COMMENT",
                  "MALFORMED_COMMENT_DROPPING",
                  "MALFORMED_COMMENT_EOS",
                  "MALFORMED_COMMENT_WARN",
                  "MALFORMED_DOCTYPE",
                  "MISMATCHED_ATTRIBUTE_ERROR",
                  "MISMATCHED_ATTRIBUTE_WARN",
                  "MISSING_ATTR_VALUE",
                  "MISSING_ATTRIBUTE",
                  "MISSING_DOCTYPE",
                  "MISSING_ENDTAG_BEFORE",
                  "MISSING_ENDTAG_FOR",
                  "MISSING_ENDTAG_OPTIONAL",
                  "MISSING_IMAGEMAP",
                  "MISSING_QUOTEMARK",
                  "MISSING_QUOTEMARK_OPEN",
                  "MISSING_SEMICOLON_NCR",
                  "MISSING_SEMICOLON",
                  "MISSING_STARTTAG",
                  "MISSING_TITLE_ELEMENT",
                  "MOVED_STYLE_TO_HEAD",
                  "NESTED_EMPHASIS",
                  "NESTED_QUOTATION",
                  "NEWLINE_IN_URI",
                  "NOFRAMES_CONTENT",
                  "NON_MATCHING_ENDTAG",
                  "OBSOLETE_ELEMENT",
                  "OPTION_REMOVED",
                  "OPTION_REMOVED_APPLIED",
                  "OPTION_REMOVED_UNAPPLIED",
                  "PREVIOUS_LOCATION",
                  "PROPRIETARY_ATTR_VALUE",
                  "PROPRIETARY_ATTRIBUTE",
                  "PROPRIETARY_ELEMENT",
                  "REMOVED_HTML5",
                  "REPEATED_ATTRIBUTE",
                  "REPLACING_ELEMENT",
                  "REPLACING_UNEX_ELEMENT",
                  "SPACE_PRECEDING_XMLDECL",
                  "STRING_CONTENT_LOOKS",
                  "STRING_ARGUMENT_BAD",
                  "STRING_DOCTYPE_GIVEN",
                  "STRING_MISSING_MALFORMED",
                  "STRING_MUTING_TYPE",
                  "STRING_NO_SYSID",
                  "STRING_UNKNOWN_OPTION",
                  "SUSPECTED_MISSING_QUOTE",
                  "TAG_NOT_ALLOWED_IN",
                  "TOO_MANY_ELEMENTS_IN",
                  "TOO_MANY_ELEMENTS",
                  "TRIM_EMPTY_ELEMENT",
                  "UNESCAPED_AMPERSAND",
                  "UNEXPECTED_END_OF_FILE_ATTR",
                  "UNEXPECTED_END_OF_FILE",
                  "UNEXPECTED_ENDTAG_ERR",
                  "UNEXPECTED_ENDTAG_IN",
                  "UNEXPECTED_ENDTAG",
                  "UNEXPECTED_EQUALSIGN",
                  "UNEXPECTED_GT",
                  "UNEXPECTED_QUOTEMARK",
                  "UNKNOWN_ELEMENT_LOOKS_CUSTOM",
                  "UNKNOWN_ELEMENT",
                  "UNKNOWN_ENTITY",
                  "USING_BR_INPLACE_OF",
                  "VENDOR_SPECIFIC_CHARS",
                  "WHITE_IN_URI",
                  "XML_DECLARATION_DETECTED",
                  "XML_ID_SYNTAX"
    ]

    var result: [String] = [];

    for _ in 1...x {
        result.append( words[Int( arc4random_uniform( UInt32(words.count) ) )] );
    }

    return result
}


// MARK: - Printing Helpers


/**
 *  Prints what's given with a horizontal rule and optional heading.
 */
public func printhr( _ value: String?, _ header: String? = nil ) {

    let text = header ?? ""
    let hr_size = 78
    let lt_size = (hr_size - text.count) / 2 - 1
    let rt_size = lt_size + ( text.count % 2 )
    let hr_left = String( repeating: "-", count: lt_size )
    let hr_right = String( repeating: "-", count: rt_size )

    if text == "" {
        print( "\(String( repeating: "-", count: hr_size ))" )
    } else {
        print( "\(hr_left) \(text) \(hr_right)" )
    }

    print( value ?? "" )

    print( "\(String( repeating: "-", count: hr_size ))" )
}


/**
 *  Dumps what's given with a horizontal rule and optional heading.
 */
public func printhr( _ value: Any, _ header: String? = nil ) {

    let text = header ?? ""
    let hr_size = 78
    let lt_size = (hr_size - text.count) / 2 - 1
    let rt_size = lt_size + ( text.count % 2 )
    let hr_left = String( repeating: "-", count: lt_size )
    let hr_right = String( repeating: "-", count: rt_size )

    if text == "" {
        print( "\(String( repeating: "-", count: hr_size ))" )
    } else {
        print( "\(hr_left) \(text) \(hr_right)" )
    }

    dump( value )

    print( "\(String( repeating: "-", count: hr_size ))" )
}


// MARK: - Assertion Helpers


/**
 *  A supplemental assert equal function that provides a (semi-) automatic message,
 *  greatly cleaning up all of the strings in the test cases.
 */
public func JSDAssertEqual<T: Equatable>( _ expect: T, _ result: T, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    let mssg: String
    if message == "" {
        mssg = "Expected \(expect) but got \(result)."
    } else {
        mssg = String( format: message, String(describing: expect), String(describing: result) )
    }
    XCTAssert( expect == result, mssg, file: file, line: line )
}


/**
 *  A supplemental assert equal function that provides a (semi-) automatic message,
 *  greatly cleaning up all of the strings in the test cases.
 */
public func JSDAssertTrue( _ result: Swift.Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) {

    return JSDAssertEqual( true, result, message, file: file, line: line )
}


/**
 *  A supplemental assert equal function that provides a (semi-) automatic message,
 *  greatly cleaning up all of the strings in the test cases.
 */
public func JSDAssertFalse( _ result: Swift.Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) {

    return JSDAssertEqual( false, result, message, file: file, line: line )
}


/**
 *  A supplemental assert to determine if an (optional) string has a given
 *  prefix, and provides a (semi-) automatic message, greatly cleaning up all of
 *  the strings in the test cases.
 */
public func JSDAssertHasPrefix( _ expect: String?, _ result: String?, _ message: String = "", file: StaticString = #file, line: UInt = #line) {

    let mssg: String
    if message == "" {
        mssg = "Expected the string to start with \(expect ?? "nil"), but got \(result ?? "nil")."
    } else {
        mssg = String( format: message, String(describing: expect), String(describing: result) )
    }

    if let expect = expect {
        XCTAssert( result?.hasPrefix(expect) ?? false, mssg, file: file, line: line )
    } else {
        XCTFail( mssg, file: file, line: line )
    }
}


/**
 *  A supplemental assert to determine if an (optional) string has a given
 *  suffix, and provides a (semi-) automatic message, greatly cleaning up all of
 *  the strings in the test cases.
 */
public func JSDAssertHasSuffix( _ expect: String?, _ result: String?, _ message: String = "", file: StaticString = #file, line: UInt = #line) {

    let mssg: String
    if message == "" {
        mssg = "Expected the string to end with \(expect ?? "nil"), but got \(result ?? "nil")."
    } else {
        mssg = String( format: message, String(describing: expect), String(describing: result) )
    }

    if let expect = expect {
        XCTAssert( result?.hasSuffix(expect) ?? false, mssg, file: file, line: line )
    } else {
        XCTFail( mssg, file: file, line: line )
    }
}


// MARK: - Testing Classes


/**
 *  This alternate to TidyConfigReport will be used in a test case just to
 *  demonstrate that user-supplied classes can be used instead of the default.
 */
@objc public class AlternateTidyConfigReport: NSObject, SwLibTidyConfigReportProtocol {

    public var option: String = ""
    public var value: String = ""
    public var document: TidyDoc

    public required init(withValue: String, forOption: String, ofDocument: TidyDoc) {

        document = ofDocument
        option = forOption;
        value = "---\(withValue)---";
        super.init()
    }
}

/**
 *  A sample class to handle TidyDelegateProtocol methods during testing.
 */
public class SampleTidyDelegate: SwLibTidyDelegateProtocol {

    /* We will set this from the test case in order to pass the expectation. */
    var asyncTidyReportsUnknownOption: XCTestExpectation?
    var asyncTidyReportsOptionChanged: XCTestExpectation?
    var asyncTidyReportsMessage: XCTestExpectation?
    var asyncTidyReportsPrettyPrinting: XCTestExpectation?

    public func tidyReports( unknownOption: SwLibTidyConfigReportProtocol ) -> Swift.Bool {
        guard let expectation = asyncTidyReportsUnknownOption else {
            XCTFail("Delegate failed; did you remember to set asyncExpectation?")
            return false
        }
        expectation.fulfill()
        return true
    }

    public func tidyReports( optionChanged: TidyOption, forTidyDoc: TidyDoc ) {
        guard let expectation = asyncTidyReportsOptionChanged else {
            XCTFail("Delegate failed; did you remember to set asyncExpectation?")
            return
        }
        expectation.fulfill()
        return
    }

    public func tidyReports( message: SwLibTidyMessageProtocol ) -> Swift.Bool {
        guard let expectation = asyncTidyReportsMessage else {
            XCTFail("Delegate failed; did you remember to set asyncExpectation?")
            return false
        }
        expectation.fulfill()
        return true
    }

    public func tidyReports( pprint: SwLibTidyPPProgressProtocol ) {
        guard let expectation = asyncTidyReportsPrettyPrinting else {
            XCTFail("Delegate failed; did you remember to set asyncExpectation?")
            return
        }
        expectation.fulfill()
        return
    }


}
