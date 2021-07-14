/**
 *  SwLibTidyBufferProtocol.swift
 *   Part of the SwLibTidy wrapper library for tidy-html5 ("CLibTidy").
 *   See https://github.com/htacg/tidy-html5
 *
 *   Copyright © 2017-2021 by HTACG. All rights reserved.
 *   Created by Jim Derry 2017; copyright assigned to HTACG. Permission to use
 *   this source code per the W3C Software Notice and License:
 *   https://www.w3.org/Consortium/Legal/2002/copyright-software-20021231
 *
 *   Purpose
 *     This protocol and class define and implement an abstraction to the
 *     CLibTidy `TidyBuffer` that is more useful in Swift.
 */

import Foundation
import CLibTidy


public typealias TidyBufferPtr = UnsafeMutablePointer<CLibTidy.TidyBuffer>
public typealias TidyRawBuffer = UnsafeMutablePointer<byte>

/**
 *  This protocol describes an interface for objects that CLibTidy can use for
 *  performing the majority of its input/output operations. Unless using standard
 *  I/O or files, Tidy inherently requires the use of C buffers in order to
 *  perform its I/O, and objects implementing this protocol satisfy Tidy's
 *  requirement while also abstracting most of the C pointer handling and unsafe
 *  types that are involved in such.
 *
 *  Conforming objects are also required to provide accessors and functions that
 *  enable accessing the raw, stored data. Because we are dealing with dynamic
 *  memory, this object can only exist as an instance of a class.
 */
public protocol SwLibTidyBufferProtocol: AnyObject {

    /**
     *  An accessor to the underlying `TidyBuffer` type from CLibTidy.
     */
    var tidyBuffer: TidyBufferPtr { get }


    /**
     *  An accessor to the underlying raw data buffer used by CLibTidy. When
     *  using non-UTF8 buffers, you will want to convert this data into a
     *  string or other representation yourself with the correct encoding.
     */
    var rawBuffer: UnsafeMutablePointer<byte> { get }


    /**
     *  Provides an accessor to the underlying raw buffer's data size.
     */
    var rawBufferSize: UInt { get }


    /**
     *  Provides the contents of the buffer as a string decoded according to
     *  the specifed CLibTidy encoding type passed via `usingTidyEncoding:`
     *  Tidy's buffer may contain representations in other than UTF8 format
     *  as specified by `output-encoding`. Decoding will be performed by Cocoa,
     *  and not CLibTidy.
     *
     *  - parameters:
     *    - usingTidyEncoding: The CLibTidy encoding type. Valid values include
     *      `ascii`, `latin1`, `utf8`, `iso2022`, `mac`, `win1252`, `utf16le`,
     *      `utf16be`, `utf16`, `big5`, and `shiftjis`. These values are not
     *      case sensitive. `raw` is not supported.
     *  - returns:
     *    Returns an optional string with the decoded content.
     */
    func StringValue(usingTidyEncoding: String) -> String?


    /**
     *  Provides the contents of the buffer as a string decoded according to
     *  the `output-encoding` setting of the provided TidyDoc.
     *
     *  - parameters:
     *    - usingTidyDoc: The `output-encoding` setting of the given TidyDoc will
     *      be used to determine how the buffer is translated into a string. In
     *      general this should only be used for the document output buffer, as all
     *      other Tidy output is always UTF8.
     *  - returns:
     *      Returns an optional string with the decoded content.
     */
    func StringValue(usingTidyDoc: TidyDoc) -> String?
}


/**
 *  A default implementation of the `SwLibTidyBufferProtocol`.
 */
public class SwLibTidyBuffer: SwLibTidyBufferProtocol {

    public var tidyBuffer: TidyBufferPtr


    public var rawBuffer: UnsafeMutablePointer<byte> {
        tidyBuffer.pointee.bp
    }


    public var rawBufferSize: UInt {
        UInt(tidyBuffer.pointee.size)
    }


    public init() {
        tidyBuffer = TidyBufferPtr.allocate(capacity: MemoryLayout<TidyBufferPtr>.size)
        tidyBufInit(tidyBuffer)
    }


    deinit {
        tidyBufFree(tidyBuffer)
        free(tidyBuffer)
    }


    public func StringValue(usingTidyEncoding: String = "utf8") -> String? {

        guard
            rawBufferSize > 0,
            let encoding = encoding(forTidyEncoding: usingTidyEncoding)
        else { return nil }

        let theData = Data(bytes: rawBuffer, count: Int(rawBufferSize))

        return Swift.String(data: theData, encoding: encoding)
    }


    public func StringValue(usingTidyDoc: TidyDoc) -> String? {

        let tidyEncoding = String(cString: CLibTidy.tidyOptGetValue(usingTidyDoc, CLibTidy.TidyOutCharEncoding))
        return StringValue(usingTidyEncoding: tidyEncoding)
    }


    /**
     *  Convert the Tidy document encoding string to a macOS type.
     */
    private func encoding(forTidyEncoding: String) -> String.Encoding? {

        let cfEnc = CFStringEncodings.big5
        let nsEnc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEnc.rawValue))
        let big5encoding = Swift.String.Encoding(rawValue: nsEnc)

        // swiftformat:disable consecutiveSpaces indent spaceAroundOperators
        switch forTidyEncoding {
            case "ascii"    : return Swift.String.Encoding.ascii
            case "latin1"   : return Swift.String.Encoding.isoLatin1
            case "utf8"     : return Swift.String.Encoding.utf8
            case "iso2022"  : return Swift.String.Encoding.iso2022JP
            case "mac"      : return Swift.String.Encoding.macOSRoman
            case "win1252"  : return Swift.String.Encoding.windowsCP1252
            case "utf16le"  : return Swift.String.Encoding.utf16LittleEndian
            case "utf16be"  : return Swift.String.Encoding.utf16BigEndian
            case "utf16"    : return Swift.String.Encoding.utf16
            case "big5"     : return big5encoding
            case "shiftjis" : return Swift.String.Encoding.shiftJIS
        default             : return nil
        }
    }
}
