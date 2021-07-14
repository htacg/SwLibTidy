/**
 *  SwLibTidy.swift
 *   Part of the SwLibTidy wrapper library for tidy-html5 ("CLibTidy").
 *   See https://github.com/htacg/tidy-html5
 *
 *   Copyright © 2017-2021 by HTACG. All rights reserved.
 *   Created by Jim Derry 2017; copyright assigned to HTACG. Permission to use
 *   this source code per the W3C Software Notice and License:
 *   https://www.w3.org/Consortium/Legal/2002/copyright-software-20021231
 *
 *   Purpose
 *     Provide a low-level, highly procedural wrapper to the nearly the entirety
 *     of CLibTidy in order to simplify the use of CLibTidy in Swift console and
 *     GUI applications, and as a basis for developing high-level, object-
 *     oriented classes for macOS and iOS. Its goals are to:
 *       - Use Swift-native types, including for the use of callbacks/closures
 *         and for the storage of context data. Although procedural, some minimal
 *         supplementary classes are used to abstract C data structures.
 *       - Provide arrays of information instead of depending on CLibTidy's
 *         iterator mechanism.
 *       - Maintain full compatibility with Objective-C (when wrapped into a
 *         class).
 *       - Maintain full compatibility with "Pure Swift" (no linkage to other
 *         than standard libraries and open-source Foundation), so that it can
 *         be used on other platforms. Note that this does not apply to derived
 *        classes, which are intended to be used in macOS and iOS.
 *       - Provide some additional tools and functionality useful within Swift.
 *
 *   Unsupported APIs
 *     Support for custom memory allocators is currently missing; CLibTidy will
 *     use its default memory allocators. Custom memory allocators, if needed,
 *     are best written in C for compatibility.
 *
 *     No support for custom input and output sources/sinks is present, and it's
 *     very unlikely that they would be needed for a modern, full-featured
 *     operating system. If needed, they are best written in C for compatibility.
 *
 *     TidyReportFilter and TidyReportCallback are not supported as being
 *     deprecated (although not yet marked as such in CLibTidy source). Instead,
 *     use the modern, extensible TidyMessageCallback features that this library
 *     wraps.
 *
 *     TidyMessage is completely abstracted into TidyMessageProtocol, and as
 *     such there's no pure access to CLibTidy's TidyMessage type. The related
 *     interrogation methods for TidyMessage type are therefore absent as well.
 *
 *     tidySaveString() is not supported; there's not really a use case in Swift;
 *     use tidySaveBuffer() instead.
 *
 *     tidyParseBuffer() is not supported; there's no really a use case in Swift;
 *     use tidyParseString() instead.
 *
 *     getWindowsLanguageList() replaces the CLibTidy version to return a
 *     dictionary of Windows->POSIX mappings. As such, related functions are
 *     not needed and so not included.
 *
 *   Localization API
 *     CLibTidy will attempt to set its language automatically based on your
 *     environment, although you can use the localization API to force a
 *     specific language. Regardless of Tidy's operating language, the API
 *     also provides Default versions of every string guaranteed to be in
 *     the native, `en` locale. This is useful if your application is providing
 *     its own localized strings, and you need a Tidy string for lookup.
 *     Upstream CLibTidy's source includes gettext compatible `.po` files that
 *     can be converted to `.strings` if needed.
 *
 *   Reference Notes
 *     There's no substitute for reading the source code, particularly CLibTidy
 *     public header files in order to understand all of the possible C enum
 *     values and their meanings.
 */

import Foundation
@_exported import CLibTidy


//*****************************************************************************
// MARK: - Globals
// Globals used within this file.
//*****************************************************************************


/** Enforce a minimum LibTidy version for compatibility. */
private let MINIMUM_LIBTIDY_VERSION = "5.9.2"


//*****************************************************************************
// MARK: - Type Definitions
//*****************************************************************************


//-----------------------------------------------------------------------------
// MARK: Opaque Types
// Instances of these types are returned by LibTidy API functions, however
// they are opaque; you cannot see into them, and must use accessor functions
// to access the contents.
//-----------------------------------------------------------------------------


/**
 *  Instances of this represent a Tidy document, which encapsulates everything
 *  there is to know about a single Tidy session. Many of the API functions
 *  return instance of TidyDoc, or expect instances as parameters.
 */
public typealias TidyDoc = CLibTidy.TidyDoc

/**
 *  Instances of this represent a Tidy configuration option, which contains
 *  useful data about these options. Functions related to configuration options
 *  return or accept instances of this type.
 */

public typealias TidyOption = CLibTidy.TidyOption

/**
 *  Single nodes of a TidyDocument are represented by this datatype. It can be
 *  returned by various API functions, or accepted as a function argument.
 */
public typealias TidyNode = CLibTidy.TidyNode

/**
 * Attributes of a TidyNode are represented by this data type. The public API
 * functions related to attributes work with this type.
 */
public typealias TidyAttr = CLibTidy.TidyAttr

/**
 *  Indicates the classification of a TidyMessage.
 */
public typealias TidyReportLevel = CLibTidy.TidyReportLevel

/**
 *  A native TidyMessage.
 */
public typealias TidyMessage = CLibTidy.TidyMessage

/**
 *  The parameter type for a given parameter composing a TidyMessage.
 */
public typealias TidyFormatParameterType = CLibTidy.TidyFormatParameterType

/**
 *  A particular argument of a TidyMessage.
 */
public typealias TidyMessageArgument = CLibTidy.TidyMessageArgument


//-----------------------------------------------------------------------------
// MARK: CLibTidy Exposure
// These type definitions expose CLibTidy types as Swift types without having
// to import CLibTidy.
//-----------------------------------------------------------------------------


/**
 * Known HTML attributes.
 */
public typealias TidyAttrId = CLibTidy.TidyAttrId

/**
 *  Categories of Tidy configuration options, which are used mostly by user
 *  interfaces to sort Tidy options into related groups.
 */
public typealias TidyConfigCategory = CLibTidy.TidyConfigCategory

/**
 *  Node types.
 */
public typealias TidyNodeType = CLibTidy.TidyNodeType

/**
 * Configuration option values and their descriptions.
 */
public typealias TidyOptionId = CLibTidy.TidyOptionId

/**
 * A Tidy configuration option can have one of these data types.
 */
public typealias TidyOptionType = CLibTidy.TidyOptionType

/**
 *  The enumeration contains a list of every possible string that Tidy and the
 *  console application can output, _except_ for strings from the following
 *  enumerations:
 *  - `TidyOptionId`
 *  - `TidyConfigCategory`
 *  - `TidyReportLevel`
 *
 *  They are used as keys internally within Tidy, and have corresponding text
 *  keys that are used in message callback filters (these are defined in
 *  `tidyStringsKeys[]`).
 */
public typealias tidyStrings = CLibTidy.tidyStrings

/**
 *  Known HTML element types.
 */
public typealias TidyTagId = CLibTidy.TidyTagId


//*****************************************************************************
// MARK: - Basic Operations
//*****************************************************************************


//-----------------------------------------------------------------------------
// MARK: Instantiation and Destruction
//-----------------------------------------------------------------------------


/**
 *  The primary creation of a document instance. Instances of a `TidyDoc` are used
 *  throughout the API as a token to represent a particular document. When done
 *  using a `TidyDoc` instance, be sure to `tidyRelease(myTidyDoc)` in order
 *  to free related memory.
 *
 *  - returns:
 *      Returns a `TidyDoc` instance.
 */
public func tidyCreate() -> TidyDoc? {

    /* Perform CLibTidy version checking, because we count on some of the
     * newer API's.
     */
    let versionCurrent: String = tidyLibraryVersion()

    let vaMin = MINIMUM_LIBTIDY_VERSION.components(separatedBy: ".").map { Int($0) ?? 0 }
    let vaCurrent = versionCurrent.components(separatedBy: ".").map { Int($0) ?? 0 }

    if vaCurrent.lexicographicallyPrecedes(vaMin) {
        debugPrint("LibTidy: oldest recommended version is \(MINIMUM_LIBTIDY_VERSION), but you have linked against \(versionCurrent).")
    }

    /* This is the only real "wrapper" part! */
    guard let tdoc = CLibTidy.tidyCreate() else { return nil }

    /* Create some extra storage to attach to Tidy's AppData. */
    let appData = ApplicationData()

    /* Convert it to a pointer that we can store, increasing the retain count. */
    let ptr = UnsafeMutableRawPointer(Unmanaged.passRetained(appData).toOpaque())

    /* Attach it to Tidy's AppData for safe-keeping. */
    CLibTidy.tidySetAppData(tdoc, ptr)


    /* Now we're going to usurp all of Tidy's callbacks so that we can use them
     * for our own purposes, such as building Swift-like data structures that
     * can avoid the need for user callbacks, as well as for calling delegate
     * methods. The user can still specify a callback, but our internal
     * callbacks will call them.
     */

    guard yes == CLibTidy.tidySetConfigCallback(tdoc, { tdoc, option, value in

        guard
            let option = option,
            let value = value,
            let tdoc = tdoc,
            let ptrStorage = CLibTidy.tidyGetAppData(tdoc)
        else { return no }

        let strOption = String(cString: option)
        let strValue = String(cString: value)

        let storage: ApplicationData = Unmanaged<ApplicationData>
            .fromOpaque(ptrStorage)
            .takeUnretainedValue()

        /* Use the class specified in .configRecordClass to populate the
           array. This allows clients to substitute their own class instead
           of forcing TidyConfigReport.
         */
        let userClass = storage.configRecordClass
        let record = userClass.init(withValue: strValue, forOption: strOption, ofDocument: tdoc)
        storage.configCallbackRecords.append(record)


        /* Fire the user's desired callback, if applicable. */
        var result = no
        if let callback = storage.configCallback {
            result = callback(record) ? yes : no
        } else {
            result = no
        }

        /* If there's a delegate, then call the delegate method. We want to
           return CLibTidy.yes if the option was handled, so consider the
           existing result.
         */
        if let local_result = storage.delegate?.tidyReports(unknownOption: record) {
            let native_result = result == yes ? true : false
            /* Either the callback or delegate indicate they've handled it. */
            result = (local_result || native_result) ? yes : no
        }

        return result

    }) else { tidyRelease(tdoc); return nil }


    guard yes == CLibTidy.tidySetConfigChangeCallback(tdoc, { tdoc, option in

        guard
            let tdoc = tdoc,
            let option = option,
            let ptrStorage = CLibTidy.tidyGetAppData(tdoc)
        else { return }

        let storage: ApplicationData = Unmanaged<ApplicationData>
            .fromOpaque(ptrStorage)
            .takeUnretainedValue()

        if let callback = storage.configChangeCallback {
            callback(tdoc, option)
        }

        /* If there's a delegate, then call the delegate method. */
        storage.delegate?.tidyReports(optionChanged: option, forTidyDoc: tdoc)

    }) else { tidyRelease(tdoc); return nil }


    guard yes == CLibTidy.tidySetMessageCallback(tdoc, { tmessage in

        guard
            let tmessage = tmessage,
            let tdoc = CLibTidy.tidyGetMessageDoc(tmessage),
            let ptrStorage = CLibTidy.tidyGetAppData(tdoc)
        else { return yes }

        let storage = Unmanaged<ApplicationData>
            .fromOpaque(ptrStorage)
            .takeUnretainedValue()

        /* Use the class specified in .messageRecordClass to populate the
         * array. This allows clients to substitute their own class instead
         * of forcing TidyConfigReport.
         */
        let userClass = storage.messageRecordClass
        let record = userClass.init(withMessage: tmessage)
        storage.messageCallbackRecords.append(record)


        /* Fire the user's desired callback, if applicable. */
        var result = no
        if let callback = storage.messageCallback {
            result = callback(record) ? yes : no
        } else {
            result = yes
        }

        /* If there's a delegate, then call the delegate method. If we
         * return true, CLibTidy will output the message in its buffer.
         * Since this is going to CLibTidy, we're looking for yes or no.
         */
        if let local_result = storage.delegate?.tidyReports(message: record) {
            let native_result = result == yes ? true : false
            /* Either the callback or delegate can filter the message. */
            result = (local_result && native_result) ? yes : no
        }

        return result

    }) else { tidyRelease(tdoc); return nil }


    guard yes == CLibTidy.tidySetPrettyPrinterCallback(tdoc, { tdoc, line, col, destLine in

        guard
            let tdoc = tdoc,
            let ptrStorage = CLibTidy.tidyGetAppData(tdoc)
        else { return }

        let storage = Unmanaged<ApplicationData>
            .fromOpaque(ptrStorage)
            .takeUnretainedValue()


        /* Use the class specified in .ppRecordClass to populate the array
         * This allows clients to substitute their own class instead of
         * forcing TidyPPProgressReport.
         */
        let userClass = storage.ppRecordClass
        let record = userClass.init(withLine: line, column: col, destLine: destLine, forDocument: tdoc)
        storage.ppCallbackRecords.append(record)


        /* Fire the user's desired callback, if applicable. */
        if let callback = storage.ppCallback {
            callback(record)
        }

        /* If there's a delegate, then call the delegate method. */
        storage.delegate?.tidyReports(pprint: record)

    }) else { tidyRelease(tdoc); return nil }

    return tdoc
}


/**
 *  Free all memory and release the `TidyDoc`. The `TidyDoc` cannot be used after
 *  this call.
 *
 *  - parameters:
 *    - tdoc: The `TidyDoc` to free.
 */


public func tidyRelease(_ tdoc: TidyDoc) {

    /* Release our auxilliary structure. */
    if let ptr = CLibTidy.tidyGetAppData(tdoc) {

        /* Decreasing the retain count should cause it to release everything
         * it holds, and to deallocate.
         */
        let _: ApplicationData = Unmanaged<ApplicationData>
            .fromOpaque(ptr)
            .takeRetainedValue()
    }

    CLibTidy.tidyRelease(tdoc)
}


//-----------------------------------------------------------------------------
// MARK: Host Application Data
//-----------------------------------------------------------------------------


/**
 *  Allows the host application to store a reference to an object instance with
 *  each `TidyDoc` instance. This can be useful for callbacks, such as saving a
 *  reference to `self` within the Tidy document. Because callbacks in Swift can
 *  only call back to a global function (not an instance method), it will be
 *  useful to know (in your callback) which instance of your class generated the
 *  callback.
 *
 *  - parameters:
 *    - tdoc: The `TidyDoc` for which you are setting the reference.
 *    - appData: A reference to self.
 */
public func tidySetAppData(_ tdoc: TidyDoc, _ appData: AnyObject) {

    /* Turn our opaque reference to an ApplicationData into a real instance. */
    guard let ptrStorage = CLibTidy.tidyGetAppData(tdoc) else { return }

    let storage: ApplicationData = Unmanaged<ApplicationData>
        .fromOpaque(ptrStorage)
        .takeUnretainedValue()

    storage.appData = appData
}


/**
 *  Returns the reference previously stored with `tidySetAppData()`.
 *
 *  - parameters:
 *    - tdoc: document where data has been stored.
 *  - returns:
 *      The reference to the object previously stored.
 */
public func tidyGetAppData(_ tdoc: TidyDoc) -> AnyObject? {

    // Let's turn our opaque reference to an ApplicationData into an instance.
    guard let ptrStorage = CLibTidy.tidyGetAppData(tdoc) else { return nil }

    let storage: ApplicationData = Unmanaged<ApplicationData>
        .fromOpaque(ptrStorage)
        .takeUnretainedValue()

    return storage.appData
}


//-----------------------------------------------------------------------------
// MARK: CLibTidy Version Information
//-----------------------------------------------------------------------------


/**
 *  Get the release date for the current library.
 *
 *  - returns:
 *      The string representing the release date.
 */
public func tidyReleaseDate() -> String {

    String(cString: CLibTidy.tidyReleaseDate())
}


/**
 *  Get the version number for the current library.
 *
 *  - returns:
 *      The string representing the version number.
 */
public func tidyLibraryVersion() -> String {

    String(cString: CLibTidy.tidyLibraryVersion())
}


/**
 *  Get the platform name from the current library.
 *
 *  - returns:
 *      An string indicating the platform on which LibTidy was built, or a
 *      null string.
 */
public func tidyPlatform() -> String {

    guard let platform = CLibTidy.tidyPlatform() else { return "" }

    return String(cString: platform)
}


//-----------------------------------------------------------------------------
// MARK: Diagnostics and Repair Status
//-----------------------------------------------------------------------------


/**
 *  Get status of current document.
 *
 *  - parameters:
 *    - tdoc: An instance of a `TidyDoc` to query.
 *  - returns:
 *      Returns the highest of `2` indicating that errors were present in the
 *      docment, `1` indicating warnings, and `0` in the case of everything
 *      being okay.
 */
public func tidyStatus(_ tdoc: TidyDoc) -> Int {

    Int(CLibTidy.tidyStatus(tdoc))
}


/**
 *  Gets the version of HTML that was output, as an integer, times 100. For
 *  example, HTML5 will return 500; HTML4.0.1 will return 401.
 *
 *  - parameters:
 *    - tdoc: An instance of a `TidyDoc` to query.
 *  - returns:
 *      Returns the HTML version number (x100).
 */
public func tidyDetectedHtmlVersion(_ tdoc: TidyDoc) -> Int {

    Int(CLibTidy.tidyDetectedHtmlVersion(tdoc))
}


/**
 *  Indicates whether the output document is or isn't XHTML.
 *
 *  - parameters:
 *    - tdoc: An instance of a `TidyDoc` to query.
 *  - returns:
 *      Returns `true` if the document is an XHTML type.
 */
public func tidyDetectedXhtml(_ tdoc: TidyDoc) -> Swift.Bool {

    CLibTidy.tidyDetectedXhtml(tdoc) == yes ? true : false
}


/**
 *  Indicates whether or not the input document was XML. If `TidyXml` tags is
 *  true, or there was an XML declaration in the input document, then this
 *  function will return `true`.
 *
 *  - parameters:
 *    - tdoc: An instance of a `TidyDoc` to query.
 *  - returns:
 *      Returns `true` if the input document was XML.
 */
public func tidyDetectedGenericXml(_ tdoc: TidyDoc) -> Swift.Bool {

    CLibTidy.tidyDetectedGenericXml(tdoc) == yes ? true : false
}


/**
 *  Indicates the number of `TidyError` messages that were generated. For any
 *  value greater than `0`, output is suppressed unless `TidyForceOutput` is set.
 *
 *  - parameters
 *    - tdoc: An instance of a `TidyDoc` to query.
 *  - returns:
 *      Returns the number of `TidyError` messages that were generated.
 */
public func tidyErrorCount(_ tdoc: TidyDoc) -> UInt {

    UInt(CLibTidy.tidyErrorCount(tdoc))
}


/**
 *  Indicates the number of `TidyWarning` messages that were generated.
 *
 *  - parameters:
 *    - tdoc: An instance of a `TidyDoc` to query.
 *  - returns:
 *      Returns the number of `TidyWarning` messages that were generated.
 */
public func tidyWarningCount(_ tdoc: TidyDoc) -> UInt {

    UInt(CLibTidy.tidyWarningCount(tdoc))
}


/**
 *  Indicates the number of `TidyAccess` messages that were generated.
 *
 *  - parameters:
 *    - tdoc: An instance of a `TidyDoc` to query.
 *  - returns:
 *      Returns the number of `TidyAccess` messages that were generated.
 */
public func tidyAccessWarningCount(_ tdoc: TidyDoc) -> UInt {

    UInt(CLibTidy.tidyAccessWarningCount(tdoc))
}


/**
 *  Indicates the number of configuration error messages that were generated.
 *
 *  - parameters:
 *    - tdoc: An instance of a `TidyDoc` to query.
 *  - returns:
 *      Returns the number of configuration error messages that were generated.
 */
public func tidyConfigErrorCount(_ tdoc: TidyDoc) -> UInt {

    UInt(CLibTidy.tidyConfigErrorCount(tdoc))
}


/**
 *  Write more complete information about errors to current error sink.
 *
 *  - parameters:
 *    - tdoc: An instance of a `TidyDoc` to query.
 */
public func tidyErrorSummary(_ tdoc: TidyDoc) {

    CLibTidy.tidyErrorSummary(tdoc)
}


/**
 *  Write more general information about markup to current error sink.
 *
 *  - parameters:
 *    - tdoc: An instance of a `TidyDoc` to query.
 */
public func tidyGeneralInfo(_ tdoc: TidyDoc) {

    CLibTidy.tidyGeneralInfo(tdoc)
}


//*****************************************************************************
// MARK: - Configuration, File, and Encoding Operations
//*****************************************************************************


//-----------------------------------------------------------------------------
// MARK: File Operations
//-----------------------------------------------------------------------------


/**
 *  Load an ASCII Tidy configuration file and set the configuration per its
 *  contents.
 *
 *  - parameters:
 *    - tdoc: The `TidyDoc` to which to apply the configuration.
 *    - configFile: The complete path to the file to load.
 *  - returns:
 *      Returns `0` upon success, or any other value if there was an error.
 */
public func tidyLoadConfig(_ tdoc: TidyDoc, _ configFile: String) -> Int {

    Int(CLibTidy.tidyLoadConfig(tdoc, configFile))
}


/**
 *  Load a Tidy configuration file with the specified character encoding, and
 *  set the configuration per its contents.
 *
 *  - parameters:
 *    - tdoc: The `TidyDoc` to which to apply the configuration.
 *    - configFile: The complete path to the file to load.
 *    - charenc: The encoding to use. See struct `_enc2iana` for valid values.
 *  - returns:
 *      Returns `0` upon success, or any other value if there was an error.
 */
public func tidyLoadConfigEnc(_ tdoc: TidyDoc, _ configFile: String, _ charenc: String) -> Int {

    Int(CLibTidy.tidyLoadConfigEnc(tdoc, configFile, charenc))
}


/**
 *  Determine whether or not a particular file exists. On Unix systems, the use
 *  of the tilde to represent the user's home directory is supported.
 *
 *  - parameters:
 *    - tdoc: The `TidyDoc` on whose behalf you are checking.
 *    - filename: The path to the file whose existence you wish to check.
 *  - returns:
 *      Returns `true` or `false`, indicating whether or not the file exists.
 */
public func tidyFileExists(_ tdoc: TidyDoc, _ filename: String) -> Swift.Bool {

    CLibTidy.tidyFileExists(tdoc, filename) == yes ? true : false
}


//-----------------------------------------------------------------------------
// MARK: Character Encoding
//-----------------------------------------------------------------------------


/**
 *  Set the input/output character encoding for parsing markup. Valid values
 *  include `ascii`, `latin1`, `raw`, `utf8`, `iso2022`, `mac`, `win1252`,
 *  `utf16le`, `utf16be`, `utf16`, `big5`, and `shiftjis`. These values are not
 *  case sensitive.
 *
 *  - Note: This is the *not* same as using `TidySetInCharEncoding()` and
 *      `TidySetOutCharEncoding()` to set the same value. Consult the option
 *      documentation.
 *
 *  - parameters:
 *    - tdoc: The `TidyDoc` for which you are setting the encoding.
 *    - encnam: The encoding name as described above.
 *  - returns:
 *      Returns `0` upon success, or a system standard error number `EINVAL`.
 */
public func tidySetCharEncoding(_ tdoc: TidyDoc, _ encnam: String) -> Int {

    Int(CLibTidy.tidySetCharEncoding(tdoc, encnam))
}


/**
 *  Set the input encoding for parsing markup.  Valid values include `ascii`,
 *  `latin1`, `raw`, `utf8`, `iso2022`, `mac`, `win1252`, `utf16le`, `utf16be`,
 *  `utf16`, `big5`, and `shiftjis`. These values are not case sensitive.
 *
 *  - parameters:
 *    - tdoc: The `TidyDoc` for which you are setting the encoding.
 *    - encnam: The encoding name as described above.
 *  - returns:
 *      Returns `0` upon success, or a system standard error number `EINVAL`.
 */
public func tidySetInCharEncoding(_ tdoc: TidyDoc, _ encnam: String) -> Int {

    Int(CLibTidy.tidySetInCharEncoding(tdoc, encnam))
}


/**
 *  Set the output encoding for writing markup.  Valid values include `ascii`,
 *  `latin1`, `raw`, `utf8`, `iso2022`, `mac`, `win1252`, `utf16le`, `utf16be`,
 *  `utf16`, `big5`, and `shiftjis`. These values are not case sensitive.
 *
 *  - Note: Changing this value _after_ processing a document will _not_ change
 *      the results present in any buffers.
 *
 *  - parameters:
 *    - tdoc: The `TidyDoc` for which you are setting the encoding.
 *    - encnam: The encoding name as described above.
 *  - returns:
 *      Returns `0` upon success, or a system standard error number `EINVAL`.
 */
public func tidySetOutCharEncoding(_ tdoc: TidyDoc, _ encnam: String) -> Int {

    Int(CLibTidy.tidySetOutCharEncoding(tdoc, encnam))
}


//-----------------------------------------------------------------------------
// MARK: Configuration Callback Functions
//-----------------------------------------------------------------------------


/**
 *  This typealias represents the required signature for your provided callback
 *  function should you wish to register one with `tidySetConfigCallback()`. Your
 *  callback function will be provided with the following parameters.
 *
 *  - Note: This signature varies from LibTidy's signature in order to provide
 *      a simple class-based record rather than a list of parameters.
 *
 *  - parameters:
 *    - report: An instance of a class conforming toTidyConfigReportProtocol,
 *        which contains the report data.
 *  - returns:
 *      Your callback function will return `true` if it handles the provided
 *      option, or `false` if it does not. In the latter case, Tidy will issue an
 *      error indicating the unknown configuration option.
 */
public typealias TidyConfigCallback = (_ report: SwLibTidyConfigReportProtocol) -> Swift.Bool


/**
 *  Applications using TidyLib may want to augment command-line and configuration
 *  file options. Setting this callback allows a LibTidy application developer to
 *  examine command-line and configuration file options after LibTidy has examined
 *  them and failed to recognize them.
 *
 *  # See also:
 *  - `tidyConfigRecords(forTidyDoc:)`
 *  - `<TidyDelegateProtocol>tidyReports(unknownOption:)`
 *
 *  - parameters:
 *    - tdoc: The document to apply the callback to.
 *    - swiftCallback: The name of a function of type `TidyConfigCallback` to
 *        serve as your callback.
 *  - returns:
 *      Returns `true` upon success.
 */
public func tidySetConfigCallback(_ tdoc: TidyDoc, _ swiftCallback: @escaping TidyConfigCallback) -> Swift.Bool {

    /* Let's turn our opaque reference to an ApplicationData into an instance. */
    guard let ptrStorage = CLibTidy.tidyGetAppData(tdoc) else { return false }

    let storage: ApplicationData = Unmanaged<ApplicationData>
        .fromOpaque(ptrStorage)
        .takeUnretainedValue()

    storage.configCallback = swiftCallback

    return true
}


/**
 *  This typealias represents the required signature for your provided callback
 *  function should you wish to register one with tidySetConfigChangeCallback().
 *  Your callback function will be provided with the following parameters.
 *
 *  - parameters:
 *    - tdoc: The document instance for which the callback was invoked.
 *    - option: The option that will be changed.
 */
public typealias TidyConfigChangeCallback = (_ tdoc: TidyDoc, _ option: TidyOption) -> Void


/**
 *  Applications using TidyLib may want to be informed when changes to options
 *  are made. Temporary changes made internally by Tidy are not reported, but
 *  permanent changes made by Tidy (such as indent-spaces or output-encoding)
 *  will be reported.
 *
 *  # See also:
 *  - `<TidyDelegateProtocol>tidyReports(optionChanged:forTidyDoc:)`
 *
 *  - parameters:
 *    - tdoc: The document to apply the callback to.
 *    - swiftCallback: The name of a function of type TidyConfigChangeCallback() to
 *        serve as your callback.
 *  - returns:
 *      Returns true upon success setting the callback.
 */
public func tidySetConfigChangeCallback(_ tdoc: TidyDoc, _ swiftCallback: @escaping TidyConfigChangeCallback) -> Swift.Bool {

    // Let's turn our opaque reference to an ApplicationData into an instance.
    guard let ptrStorage = CLibTidy.tidyGetAppData(tdoc) else { return false }

    let storage: ApplicationData = Unmanaged<ApplicationData>
        .fromOpaque(ptrStorage)
        .takeUnretainedValue()

    storage.configChangeCallback = swiftCallback

    return true
}


//-----------------------------------------------------------------------------
// MARK: Option ID Discovery
//-----------------------------------------------------------------------------


/**
 *  Get ID of given Option
 *
 *  - parameters:
 *    - opt: An instance of a `TidyOption` to query.
 *  - returns:
 *      The `TidyOptionId` of the given option.
 */
public func tidyOptGetId(_ opt: TidyOption) -> TidyOptionId? {

    let optId = CLibTidy.tidyOptGetId(opt)

    return optId == N_TIDY_OPTIONS ? nil : optId
}


/**
 *  Returns the `TidyOptionId` (C enum value) by providing the name of a Tidy
 *  configuration option.
 *
 *  - parameters:
 *    - optnam: The name of the option ID to retrieve.
 *  - returns:
 *      The `TidyOptionId` of the given `optname`.
 */
public func tidyOptGetIdForName(_ optnam: String) -> TidyOptionId? {

    let optId = CLibTidy.tidyOptGetIdForName(optnam)

    return optId == N_TIDY_OPTIONS ? nil : optId
}


// MARK: Getting Instances of Tidy Options


/**
 *  Returns an array of `TidyOption` tokens containing each Tidy option, which are
 *  an opaque type that can be interrogated with other LibTidy functions.
 *
 *  - Note: This function will return *not* internal-only option types designated
 *      `TidyInternalCategory`; you should *never* use these anyway.
 *
 *  - Note: This Swift array replaces the CLibTidy functions `tidyGetOptionList()`
 *      and `TidyGetNextOption()`, as it is much more natural to deal with Swift
 *      array types when using Swift.
 *
 *  - parameters:
 *    - tdoc: The tidy document for which to retrieve options.
 *  - returns:
 *      Returns an array of `TidyOption` opaque tokens.
 */
public func tidyGetOptionList(_ tdoc: TidyDoc) -> [TidyOption] {

    var it: TidyIterator? = CLibTidy.tidyGetOptionList(tdoc)

    var result: [TidyOption] = []

    while it != nil {

        if let opt = CLibTidy.tidyGetNextOption(tdoc, &it) {
            if tidyOptGetCategory(opt) != TidyInternalCategory {
                result.append(opt)
            }
        }
    }

    return result
}


/**
 *  Retrieves an instance of `TidyOption` given a valid `TidyOptionId`.
 *
 *  - parameters:
 *    - tdoc: The document for which you are retrieving the option.
 *    - optId: The `TidyOptionId` to retrieve.
 *  - returns:
 *      An instance of `TidyOption` matching the provided `TidyOptionId`.
 */
public func tidyGetOption(_ tdoc: TidyDoc, _ optId: TidyOptionId) -> TidyOption? {

    /* CLibTidy can return garbage on this call, so check it ourselves. */
    if optId.rawValue <= TidyUnknownOption.rawValue || optId.rawValue >= N_TIDY_OPTIONS.rawValue {
        return nil
    }

    return CLibTidy.tidyGetOption(tdoc, optId)
}


/**
 *  Returns an instance of `TidyOption` by providing the name of a Tidy
 *  configuration option.
 *
 *  - parameters:
 *    - tdoc: The document for which you are retrieving the option.
 *    - optnam: The name of the Tidy configuration option.
 *  - returns:
 *      The `TidyOption` of the given `optname`.
 */
public func tidyGetOptionByName(_ tdoc: TidyDoc, _ optnam: String) -> TidyOption? {

    CLibTidy.tidyGetOptionByName(tdoc, optnam)
}


//-----------------------------------------------------------------------------
// MARK: Information About Options
//-----------------------------------------------------------------------------


/**
 *  Get name of given option
 *
 *  - parameters:
 *    - opt: An instance of a `TidyOption` to query.
 *  - returns:
 *      The name of the given option.
 */
public func tidyOptGetName(_ opt: TidyOption) -> String {

    String(cString: CLibTidy.tidyOptGetName(opt))
}


/**
 *  Get datatype of given option
 *
 *  - parameters:
 *    - opt: An instance of a TidyOption to query.
 *  - returns:
 *      The `TidyOptionType` of the given option.
 */
public func tidyOptGetType(_ opt: TidyOption) -> TidyOptionType {

    CLibTidy.tidyOptGetType(opt)
}


/**
 *  Indicates whether or not an option is a list of values
 *
 *  - parameters:
 *    - opt: An instance of a TidyOption to query.
 *  - returns:
 *      Returns true or false indicating whether or not the value is a list.
 */
public func tidyOptionIsList(_ opt: TidyOption) -> Swift.Bool {

    CLibTidy.tidyOptionIsList(opt) == yes ? true : false
}


/**
 *  Get category of given option
 *
 *  - parameters:
 *    - opt: An instance of a `TidyOption` to query.
 *  - returns:
 *      The `TidyConfigCategory` of the specified option.
 */
public func tidyOptGetCategory(_ opt: TidyOption) -> TidyConfigCategory {

    CLibTidy.tidyOptGetCategory(opt)
}


/**
 *  Get default value of given option as a string
 *
 *  - parameters:
 *    - opt: An instance of a `TidyOption` to query.
 *  - returns:
 *      A string indicating the default value of the specified option.
 */
public func tidyOptGetDefault(_ opt: TidyOption) -> String {

    if let result = CLibTidy.tidyOptGetDefault(opt) {
        return String(cString: result)
    }

    return ""
}


/**
 *  Get default value of given option as an unsigned integer
 *
 *  - parameters:
 *    - opt: An instance of a `TidyOption` to query.
 *  - returns:
 *      An unsigned integer indicating the default value of the specified option.
 */
public func tidyOptGetDefaultInt(_ opt: TidyOption) -> UInt {

    UInt(CLibTidy.tidyOptGetDefaultInt(opt))
}


/**
 *  Get default value of given option as a Boolean value
 *
 *  - parameters:
 *    - opt: An instance of a `TidyOption` to query.
 *  - returns:
 *      A boolean indicating the default value of the specified option.
 */
public func tidyOptGetDefaultBool(_ opt: TidyOption) -> Swift.Bool {

    tidyOptGetDefaultBool(opt) == yes ? true : false
}


/**
 *  Returns on array of strings indicating the available picklist values for the
 *  given `TidyOption`.
 *
 *  - Note: This Swift array replaces the CLibTidy functions `tidyOptGetPickList()`
 *      and `tidyOptGetNextPick()`, as it is much more natural to deal with Swift
 *      array types when using Swift.
 *
 *  - parameters:
 *    - opt: An instance of a `TidyOption` to query.
 *  - returns:
 *      An array of strings with the picklist values, if any.
 */
public func tidyOptGetPickList(_ opt: TidyOption) -> [String] {

    var it: TidyIterator? = CLibTidy.tidyOptGetPickList(opt)

    var result: [String] = []

    while it != nil {

        if let pick = CLibTidy.tidyOptGetNextPick(opt, &it) {
            result.append(String(cString: pick))
        }
    }

    return result
}


//-----------------------------------------------------------------------------
// MARK: Option Value Functions
//-----------------------------------------------------------------------------


/**
 *  Get the current value of the `TidyOptionId` for the given document.
 *
 *  - Note: The `optId` *must* have a `TidyOptionType` of `TidyString`.
 *
 *  - parameters:
 *    - tdoc: The tidy document whose option value you wish to check.
 *    - optId: The option ID whose value you wish to check.
 *  - returns:
 *      The string value of the given optId.
 */
public func tidyOptGetValue(_ tdoc: TidyDoc, _ optId: TidyOptionId) -> String {

    if let result = CLibTidy.tidyOptGetValue(tdoc, optId) {
        return String(cString: result)
    }

    return ""
}


/**
 *  Set the option value as a string.
 *
 *  - Note: The optId *must* have a `TidyOptionType` of `TidyString`.
 *
 *  - parameters
 *    - tdoc: The tidy document for which to set the value.
 *    - optId: The `TidyOptionId` of the value to set.
 *    - val: The string value to set.
 *  - returns:
 *      Returns a bool indicating success or failure.
 */
public func tidyOptSetValue(_ tdoc: TidyDoc, _ optId: TidyOptionId, _ val: String) -> Swift.Bool {

    CLibTidy.tidyOptSetValue(tdoc, optId, val) == yes ? true : false
}


/**
 *  Set named option value as a string, regardless of the `TidyOptionType`.
 *
 *  - Note: This is good setter if you are unsure of the type.
 *
 *  - parameters:
 *    - tdoc: The tidy document for which to set the value.
 *    - optnam: The name of the option to set; this is the string value from the
 *        UI, e.g., `error-file`.
 *    - val: The value to set, as a string.
 *  - returns:
 *      Returns a bool indicating success or failure.
 */
public func tidyOptParseValue(_ tdoc: TidyDoc, _ optnam: String, _ val: String) -> Swift.Bool {

    CLibTidy.tidyOptParseValue(tdoc, optnam, val) == yes ? true : false
}


/**
 *  Get current option value as an integer.
 *
 *  - Note: This function returns an integer value, which in C is compatible with
 *      every C enum. C enums don't come across well in Swift, but it's still very
 *      important that they be used versus any raw integer value. This protects
 *      Swift code from C enum value changes. In Swift, the C enums' integer
 *      values should be used as such: TidySortAttrNone.rawValue
 *
 *  - parameters:
 *    - tdoc: The tidy document for which to get the value.
 *    - optId: The option ID to get.
 *  - returns:
 *      Returns the integer value of the specified option.
 */
public func tidyOptGetInt(_ tdoc: TidyDoc, _ optId: TidyOptionId) -> UInt {

    UInt(CLibTidy.tidyOptGetInt(tdoc, optId))
}


/**
 *  Set option value as an integer.
 *
 *  - Note: This function accepts an integer value, which in C is compatible with
 *      every C enum. C enums don't come across well in Swift, but it's still very
 *      important that they be used versus any raw integer value. This protects
 *      Swift code from C enum value changes. In Swift, the C enums' integer
 *      values should be used as such: TidySortAttrNone.rawValue
 *
 *  - parameters
 *    - tdoc: The tidy document for which to set the value.
 *    - optId: The option ID to set.
 *    - val: The value to set.
 *  - returns:
 *      Returns a bool indicating success or failure.
 */
public func tidyOptSetInt(_ tdoc: TidyDoc, _ optId: TidyOptionId, _ val: UInt32) -> Swift.Bool {

    CLibTidy.tidyOptSetInt(tdoc, optId, UInt(val)) == yes ? true : false
}


/**
 *  Get current option value as a Boolean.
 *
 *  - parameters:
 *    - tdoc: The tidy document for which to get the value.
 *    - optId: The option ID to get.
 *  - returns:
 *      Returns a bool indicating the value.
 */
public func tidyOptGetBool(_ tdoc: TidyDoc, _ optId: TidyOptionId) -> Swift.Bool {

    CLibTidy.tidyOptGetBool(tdoc, optId) == yes ? true : false
}


/**
 *  Set option value as a Boolean.
 *
 *  - parameters:
 *    - tdoc: The tidy document for which to set the value.
 *    - optId: The option ID to set.
 *    - val: The value to set.
 *  - returns:
 *      Returns a bool indicating success or failure.
 */
public func tidyOptSetBool(_ tdoc: TidyDoc, _ optId: TidyOptionId, _ val: Swift.Bool) -> Swift.Bool {

    CLibTidy.tidyOptSetBool(tdoc, optId, val == true ? yes : no) == yes ? true : false
}


/**
 *  Reset option to default value by ID.
 *
 *  - parameters:
 *    - tdoc: The tidy document for which to reset the value.
 *    - opt: The option ID to reset.
 *  - returns:
 *      Returns a bool indicating success or failure.
 */
public func tidyOptResetToDefault(_ tdoc: TidyDoc, _ opt: TidyOptionId) -> Swift.Bool {

    CLibTidy.tidyOptResetToDefault(tdoc, opt) == yes ? true : false
}


/**
 *  Reset all options to their default values.
 *
 *  - parameters:
 *    - tdoc: The tidy document for which to reset all values.
 *  - returns:
 *      Returns a bool indicating success or failure.
 */
public func tidyOptResetAllToDefault(_ tdoc: TidyDoc) -> Swift.Bool {

    CLibTidy.tidyOptResetAllToDefault(tdoc) == yes ? true : false
}


/**
 *  Take a snapshot of current config settings. These settings are stored within
 *  the tidy document. Note, however, that snapshots do not reliably survive the
 *  the `tidyParseXXX()` process, as Tidy uses the snapshot mechanism in order to
 *  store the current configuration right at the beginning of the parsing process.
 *
 *  - parameters:
 *    - tdoc: The tidy document for which to take a snapshot.
 *  - returns:
 *      Returns a bool indicating success or failure.
 */
public func tidyOptSnapshot(_ tdoc: TidyDoc) -> Swift.Bool {

    CLibTidy.tidyOptSnapshot(tdoc) == yes ? true : false
}


/**
 *  Apply a snapshot of config settings to a document.
 *
 *  - parameters:
 *    - tdoc: The tidy document for which to apply a snapshot.
 *  - returns:
 *      Returns a bool indicating success or failure.
 */
public func tidyOptResetToSnapshot(_ tdoc: TidyDoc) -> Swift.Bool {

    CLibTidy.tidyOptResetToSnapshot(tdoc) == yes ? true : false
}


/**
 *  Any settings different than default?
 *
 *  - parameters:
 *    - tdoc: The tidy document to check.
 *  - returns:
 *      Returns a bool indicating whether or not a difference exists.
 */
public func tidyOptDiffThanDefault(_ tdoc: TidyDoc) -> Swift.Bool {

    CLibTidy.tidyOptDiffThanDefault(tdoc) == yes ? true : false
}


/**
 *  Any settings different than snapshot?
 *
 *  - parameters:
 *    - tdoc: The tidy document to check.
 *  - returns:
 *      Returns a bool indicating whether or not a difference exists.
 */
public func tidyOptDiffThanSnapshot(_ tdoc: TidyDoc) -> Swift.Bool {

    CLibTidy.tidyOptDiffThanSnapshot(tdoc) == yes ? true : false
}


/**
 *  Copy current configuration settings from one document to another. Note that
 *  the destination document's existing settings will be stored as that document's
 *  snapshot prior to having its option values overwritten by the source
 *  document's settings.
 *
 *  - parameters:
 *    - tdocTo: The destination tidy document.
 *    - tdocFrom: The source tidy document.
 *  - returns:
 *      Returns a bool indicating success or failure.
 */
public func tidyOptCopyConfig(_ tdocTo: TidyDoc, _ tdocFrom: TidyDoc) -> Swift.Bool {

    CLibTidy.tidyOptCopyConfig(tdocTo, tdocFrom) == yes ? true : false
}


/**
 *  Get character encoding name. Used with `TidyCharEncoding`,
 *  `TidyOutCharEncoding`, and `TidyInCharEncoding`.
 *
 *  - parameters:
 *    - tdoc: The tidy document to query.
 *    - optId: The option ID whose value to check.
 *  - returns:
 *      The encoding name as a string for the specified option.
 */
public func tidyOptGetEncName(_ tdoc: TidyDoc, _ optId: TidyOptionId) -> String {

    String(cString: CLibTidy.tidyOptGetEncName(tdoc, optId))
}


/**
 *  Get the current pick list value for the option ID, which can be useful for
 *  enum types.
 *
 *  - parameters:
 *    - tdoc: The tidy document to query.
 *    - optId: The option ID whose value to check.
 *  - returns:
 *      Returns a string indicating the current value of the given option.
 */
public func tidyOptGetCurrPick(_ tdoc: TidyDoc, _ optId: TidyOptionId) -> String {

    String(cString: CLibTidy.tidyOptGetCurrPick(tdoc, optId))
}


/**
 *  Returns on array of strings, where each string indicates a user-declared tag,
 *  including autonomous custom tags detected when `TidyUseCustomTags` is not set
 *  to `no`.
 *
 *  - Note: This Swift array replaces the CLibTidy `tidyOptGetDeclTagList()`
 *      and `tidyOptGetNextDeclTag()` functions, as it is much more natural to
 *      deal with Swift array types when using Swift.
 *
 *  - parameters
 *    - tdoc: The `TidyDoc` for which to get user-declared tags.
 *    - optId: The option ID matching the type of tag to retrieve. This
 *        limits the scope of the tags to one of `TidyInlineTags`, `TidyBlockTags`,
 *        `TidyEmptyTags`, `TidyPreTags`. Note that autonomous custom tags (if
 *        used) are added to one of these option types, depending on the value of
 *        `TidyUseCustomTags`.
 *  - returns:
 *      An array of strings with the tag names, if any.
 */
public func tidyOptGetDeclTagList(_ tdoc: TidyDoc, forOptionId optId: TidyOptionId) -> [String] {

    var it: TidyIterator? = CLibTidy.tidyOptGetDeclTagList(tdoc)

    var result: [String] = []

    while it != nil {

        if let tag = CLibTidy.tidyOptGetNextDeclTag(tdoc, optId, &it) {
            result.append(String(cString: tag))
        }
    }

    /* The native iterator works backwords, so reverse the result so that
     * the array represents the string order. */
    return result.reversed()
}


/**
 *  Returns on array of strings, where each string indicates a prioritized
 *  attribute.
 *
 *  - Note: This Swift array replaces the CLibTidy `tidyOptGetPriorityAttrList()`
 *      and `tidyOptGetNextPriorityAttr()` functions, as it is much more natural
 *      to deal with Swift array types when using Swift.
 *
 *  - parameters
 *    - tdoc: The `TidyDoc` for which to get prioritized attributes.
 *  - returns:
 *      An array of strings with the attribute names, if any.
 */
public func tidyOptGetPriorityAttrList(_ tdoc: TidyDoc) -> [String] {

    var it: TidyIterator? = CLibTidy.tidyOptGetPriorityAttrList(tdoc)

    var result: [String] = []

    while it != nil {

        if let attr = CLibTidy.tidyOptGetNextPriorityAttr(tdoc, &it) {
            result.append(String(cString: attr))
        }
    }

    return result
}


/**
 *  Returns on array of strings, where each string indicates a type name for a
 *  muted message.
 *
 *  - Note: This Swift array replaces the CLibTidy `tidyOptGetMutedMessageList()`
 *      and `tidyOptGetNextMutedMessage()` functions, as it is much more natural
 *      to deal with Swift array types when using Swift.
 *
 *  - parameters
 *    - tdoc: The `TidyDoc` for which to get user-declared tags.
 *  - returns:
 *      An array of strings with the muted message names, if any.
 */
public func tidyOptGetMutedMessageList(_ tdoc: TidyDoc) -> [String] {

    var it: TidyIterator? = CLibTidy.tidyOptGetMutedMessageList(tdoc)

    var result: [String] = []

    while it != nil {

        if let message = CLibTidy.tidyOptGetNextMutedMessage(tdoc, &it) {
            result.append(String(cString: message))
        }
    }

    return result
}


//-----------------------------------------------------------------------------
// MARK: Option Documentation
//-----------------------------------------------------------------------------


/**
 *  Get the description of the specified option.
 *
 *  - parameters:
 *    - tdoc: The tidy document to query.
 *    - opt: The option ID of the option.
 *  - returns:
 *      Returns a string containing a description of the given option.
 */
public func tidyOptGetDoc(_ tdoc: TidyDoc, _ opt: TidyOption) -> String {

    String(cString: CLibTidy.tidyOptGetDoc(tdoc, opt))
}


/**
 *  Returns on array of `TidyOption`, where array element consists of options
 *  related to the given option ID.
 *
 *  - Note: This Swift array replaces the CLibTidy `tidyOptGetDocLinksList()`
 *      and `tidyOptGetNextDocLinks()` functions, as it is much more natural to
 *      deal with Swift array types when using Swift.
 *
 *  - parameters
 *    - tdoc: The `TidyDoc` for which to get user-declared tags.
 *    - optId: The option ID for which to retrieve related options.
 *  - returns:
 *      An array of `TidyOption` instances, if any.
 */
public func tidyOptGetDocLinksList(_ tdoc: TidyDoc, _ opt: TidyOption) -> [TidyOption] {

    var it: TidyIterator? = CLibTidy.tidyOptGetDocLinksList(tdoc, opt)

    var result: [TidyOption] = []

    while it != nil {

        if let opt = CLibTidy.tidyOptGetNextDocLinks(tdoc, &it) {
            result.append(opt)
        }
    }

    return result
}


//*****************************************************************************
// MARK: - I/O and Messages
//  Tidy provides flexible I/O. By default, Tidy will define, create and use
//  instances of input and output handlers for standard C buffered I/O (i.e.,
//  `FILE* stdin`, `FILE* stdout`, and `FILE* stderr` for content input,
//  content output and diagnostic output, respectively. A `FILE* cfgFile`
//  input handler will be used for config files. Command line options will
//  just be set directly.
//*****************************************************************************



/**
 *  This typealias provides a type for dealing with non-standard input and output
 *  streams in Swift. In general you can set CLibTidy's input streams and then
 *  forget them, however if you wish to contribute additional I/O with these
 *  non-standard streams, you will have to do it with a C-type API.
 */
public typealias CFilePointer = UnsafeMutablePointer<FILE>


//-----------------------------------------------------------------------------
// MARK: - Emacs-compatible reporting support
//-----------------------------------------------------------------------------


/**
 *  Set the file path to use for reports when `TidyEmacs` is being used. This
 *  function provides a proper interface for using the hidden, internal-only
 *  `TidyEmacsFile` configuration option.
 *
 *  - Note: This is useful if you work with Emacs and prefer Tidy's report
 *      output to be in a form that is easy for Emacs to parse
 *
 *  - parameters:
 *    - tdoc: The tidy document for which you are setting the `filePath`.
 *    - filePath: The path of the document that should be reported.
 */
public func tidySetEmacsFile(_ tdoc: TidyDoc, _ filePath: String) {

    CLibTidy.tidySetEmacsFile(tdoc, filePath)
}

/**
 *  Get the file path to use for reports when `TidyEmacs` is being used. This
 *  function provides a proper interface for using the hidden, internal-only
 *  `TidyEmacsFile` configuration option.
 *
 *  - parameters:
 *    - tdoc: The tidy document for which you want to fetch the file path.
 *  - returns:
 *      Returns a string indicating the file path.
 */
public func tidyGetEmacsFile(_ tdoc: TidyDoc) -> String {

    String(cString: CLibTidy.tidyGetEmacsFile(tdoc))
}


//-----------------------------------------------------------------------------
// MARK: Error Sink
//-----------------------------------------------------------------------------


/**
 *  Set error sink to named file.
 *
 *  - parameters:
 *    - tdoc: The document to set.
 *    - errfilname: The file path to send output.
 *  - returns:
 *      Returns a file handle.
 */
@discardableResult public func tidySetErrorFile(_ tdoc: TidyDoc, _ errfilnam: String) -> CFilePointer? {

    CLibTidy.tidySetErrorFile(tdoc, errfilnam)
}


/**
 *  Set error sink to given buffer.
 *
 *  - parameters:
 *    - tdoc: The document to set.
 *    - errbuf: An instance of TidyBuffer to provide output.
 *  - returns:
 *      Returns 0 upon success or a standard error number.
 */
public func tidySetErrorBuffer(_ tdoc: TidyDoc, errbuf: SwLibTidyBufferProtocol) -> Int {

    Int(CLibTidy.tidySetErrorBuffer(tdoc, errbuf.tidyBuffer))
}


//-----------------------------------------------------------------------------
// MARK: Error and Message Callbacks
//  A sophisticated and extensible callback to filter or collect messages
//  reported by Tidy. Note that unlike the older filters, this callback exposes
//  *all* output that LibTidy emits (excluding the console application, which
//  is a client of LibTidy).
//-----------------------------------------------------------------------------


/**
 *  This typealias represents the required signature for your provided callback
 *  function should you wish to register one with tidySetMessageCallback().
 *  Your callback function will be provided with the following parameters.
 *
 *  - parameters:
 *    - record: An instance conforming to TidyMessageProtocol.
 *  - returns: Your callback function will return `true` if Tidy should include the
 *      report in its own output sink, or `false` if Tidy should suppress it.
 */
public typealias TidyMessageCallback = (_ record: SwLibTidyMessageProtocol) -> Swift.Bool


/**
 *  This function informs Tidy to use the specified callback to send reports.
 *
 *  # See also:
 *  - `tidyMessageRecords(forTidyDoc:)`
 *  - `<TidyDelegateProtocol>tidyReports(message:)`
 *
 *  - parameters:
 *    - tdoc: The tidy document for which the callback applies.
 *    - filtCallback: A pointer to your callback function of type
 *        `TidyMessageCallback`.
 *  - returns:
 *      A boolean indicating success or failure setting the callback.
 */
public func tidySetMessageCallback(_ tdoc: TidyDoc, _ swiftCallback: @escaping TidyMessageCallback) -> Swift.Bool {

    // Let's turn our opaque reference to an ApplicationData into an instance.
    guard let ptrStorage = CLibTidy.tidyGetAppData(tdoc) else { return false }

    let storage: ApplicationData = Unmanaged<ApplicationData>
        .fromOpaque(ptrStorage)
        .takeUnretainedValue()

    storage.messageCallback = swiftCallback

    return true
}


//*****************************************************************************
// MARK: Printing
//  LibTidy applications can somewhat track the progress of the tidying process
//  by using this provided callback. It relates where something in the source
//  document ended up in the output.
//*****************************************************************************



/**
 *  This typedef represents the required signature for your provided callback
 *  function should you wish to register one with tidySetPrettyPrinterCallback().
 *  Your callback function will be provided with the following parameters.
 *
 *  - parameters:
 *    - report: An instance conforming to TidyPPProgessProtocol.
 *  - returns:
 *      Your callback function will return `true` if Tidy should include the report
 *      report in its own output sink, or `false` if Tidy should suppress it.
 */

public typealias TidyPPProgress = (_ report: SwLibTidyPPProgressProtocol) -> Void


/**
 *  This function informs Tidy to use the specified callback for tracking the
 *  pretty-printing process progress.
 *
 *  # See also:
 *  - `tidyPPProgressRecords(forTidyDoc:)`
 *  - `<TidyDelegateProtocol>tidyReports(pprint:)`
 *
 *  - parameters:
 *    - tdoc: The `TidyDoc` for which you are setting the callback.
 *    - callback: The function to be called.
 *  - returns:
 *      True or false indicating the success or failure of setting the callback.
 */
public func tidySetPrettyPrinterCallback(_ tdoc: TidyDoc, _ callback: @escaping TidyPPProgress) -> Swift.Bool {

    // Let's turn our opaque reference to an ApplicationData into an instance.
    guard let ptrStorage = CLibTidy.tidyGetAppData(tdoc) else { return false }

    let storage: ApplicationData = Unmanaged<ApplicationData>
        .fromOpaque(ptrStorage)
        .takeUnretainedValue()

    storage.ppCallback = callback

    return true
}


//*****************************************************************************
// MARK: - Document Parse
//  Functions for parsing markup from a given input source, as well as string
//  and filename functions for added convenience. HTML/XHTML version determined
//  from input.
//*****************************************************************************


/**
 *  Parse markup in named file.
 *
 *  - parameters:
 *    - tdoc: The tidy document to use for parsing.
 *    - filename: The path and filename to parse.
 *  - returns:
 *      Returns the highest of `2` indicating that errors were present in the
 *      document, `1` indicating warnings, and `0` in the case of everything being
 *      okay.
 */
public func tidyParseFile(_ tdoc: TidyDoc, _ filename: String) -> Int {

    Int(CLibTidy.tidyParseFile(tdoc, filename))
}


/**
 *  Parse markup from the standard input.
 *
 *  - parameters:
 *    - tdoc: The tidy document to use for parsing.
 *  - returns:
 *      Returns the highest of `2` indicating that errors were present in the
 *      docment, `1` indicating warnings, and `0` in the case of everything being
 *      okay.
 */
public func tidyParseStdin(_ tdoc: TidyDoc) -> Int {

    Int(CLibTidy.tidyParseStdin(tdoc))
}


/**
 *  Parse markup in given string.
 *  - returns: Returns the highest of `2` indicating that errors were present in
 *      the docment, `1` indicating warnings, and `0` in the case of
 *      everything being okay.
 */
public func tidyParseString(_ tdoc: TidyDoc, _ content: String) -> Int {

    Int(CLibTidy.tidyParseString(tdoc, content))
}



//*****************************************************************************
// MARK: - Clean, Diagnostics, and Repair
//  After parsing the document, you can use these functions to attempt cleanup,
//  repair, get additional diagnostics, and determine the document type.
//*****************************************************************************


/**
 *  Execute configured cleanup and repair operations on parsed markup.
 *
 *  - parameters:
 *    - tdoc: The tidy document to use.
 *  - returns:
 *      An integer representing the status.
 */
public func tidyCleanAndRepair(_ tdoc: TidyDoc) -> Int {

    Int(CLibTidy.tidyCleanAndRepair(tdoc))
}


/**
 *  Add additional diagnostics information into the current error output sink.
 *
 *  - precondition: You must call `tidyCleanAndRepair()` before using this
 *      function.
 *
 *  - parameters:
 *    - tdoc: The tidy document to use.
 *  - returns:
 *      An integer representing the status.
 */
public func tidyRunDiagnostics(_ tdoc: TidyDoc) -> Int {

    Int(CLibTidy.tidyRunDiagnostics(tdoc))
}


/**
 *  Reports the document type into the output sink.
 *
 *  - parameters:
 *    - tdoc: The tidy document to use.
 *  - returns:
 *      An integer representing the status.
 */
public func tidyReportDoctype(_ tdoc: TidyDoc) -> Int {

    Int(CLibTidy.tidyReportDoctype(tdoc))
}


//*****************************************************************************
// MARK: - Document Save Functions
//  Save currently parsed document to the given output sink. File name
//  and string/buffer functions provided for convenience.
//*****************************************************************************


/**
 *  Save the tidy document to the named file.
 *
 *  - parameters:
 *    - tdoc: The tidy document to save.
 *    - filenam: The destination file name.
 *  - returns:
 *      An integer representing the status.
 */
public func tidySaveFile(_ tdoc: TidyDoc, _ filename: String) -> Int {

    Int(CLibTidy.tidySaveFile(tdoc, filename))
}


/**
 *  Save the tidy document to standard output (FILE*).
 *
 *  - parameters:
 *    - tdoc: The tidy document to save.
 *  - returns:
 *      An integer representing the status.
 */
public func tidySaveStdout(_ tdoc: TidyDoc) -> Int {

    Int(CLibTidy.tidySaveStdout(tdoc))
}


/**
 *  Save the tidy document to given TidyBuffer object.
 *
 *  - parameters:
 *    - tdoc: The tidy document to save.
 *    - buf: The buffer to place the output.
 *  - returns:
 *      An integer representing the status.
 */
public func tidySaveBuffer(_ tdoc: TidyDoc, _ buf: SwLibTidyBufferProtocol) -> Int {

    Int(CLibTidy.tidySaveBuffer(tdoc, buf.tidyBuffer))
}


/**
 *  Save current settings to named file. Only writes non-default values.
 *
 *  - Note: The configuration file will be written with Tidy's `output-encoding`
 *      and `newline` settings.
 *
 *  - parameters:
 *    - tdoc: The tidy document to save.
 *    - cfgfil: The filename to save the configuration to.
 *  - returns:
 *      An integer representing the status.
 */
public func tidyOptSaveFile(_ tdoc: TidyDoc, _ cfgfil: String) -> Int {

    Int(CLibTidy.tidyOptSaveFile(tdoc, cfgfil))
}


//*****************************************************************************
// MARK: - Document Tree
//   A parsed (and optionally repaired) document is represented by Tidy as a
//   tree, much like a W3C DOM. This tree may be traversed using these
//   functions. The following snippet gives a basic idea how these functions
//   can be used.
//
//   @code{.c}
//   void dumpNode( TidyNode tnod, int indent ) {
//     TidyNode child;
//
//     for ( child = tidyGetChild(tnod); child; child = tidyGetNext(child) ) {
//       ctmbstr name;
//       switch ( tidyNodeGetType(child) ) {
//       case TidyNode_Root:       name = "Root";                    break;
//       case TidyNode_DocType:    name = "DOCTYPE";                 break;
//       case TidyNode_Comment:    name = "Comment";                 break;
//       case TidyNode_ProcIns:    name = "Processing Instruction";  break;
//       case TidyNode_Text:       name = "Text";                    break;
//       case TidyNode_CDATA:      name = "CDATA";                   break;
//       case TidyNode_Section:    name = "XML Section";             break;
//       case TidyNode_Asp:        name = "ASP";                     break;
//       case TidyNode_Jste:       name = "JSTE";                    break;
//       case TidyNode_Php:        name = "PHP";                     break;
//       case TidyNode_XmlDecl:    name = "XML Declaration";         break;
//
//       case TidyNode_Start:
//       case TidyNode_End:
//       case TidyNode_StartEnd:
//       default:
//         name = tidyNodeGetName( child );
//         break;
//       }
//       assert( name != NULL );
//       printf( "\%*.*sNode: \%s\\n", indent, indent, " ", name );
//       dumpNode( child, indent + 4 );
//     }
//   }
//
//   void dumpDoc( TidyDoc tdoc ) {
//     dumpNode( tidyGetRoot(tdoc), 0 );
//   }
//
//   void dumpBody( TidyDoc tdoc ) {
//     dumpNode( tidyGetBody(tdoc), 0 );
//   }
//   @endcode
//
//   @{
//*****************************************************************************


//-----------------------------------------------------------------------------
// MARK: Nodes for Document Sections
//-----------------------------------------------------------------------------


/**
 *  Get the root node.
 *
 *  - parameters:
 *    - tdoc: The document to query.
 *  - returns:
 *      Returns a tidy node.
 */
public func tidyGetRoot(_ tdoc: TidyDoc) -> TidyNode? {

    CLibTidy.tidyGetRoot(tdoc)
}


/**
 *  Get the HTML node.
 *
 *  - parameters:
 *    - tdoc: The document to query.
 *  - returns:
 *      Returns a tidy node.
 */
public func tidyGetHtml(_ tdoc: TidyDoc) -> TidyNode? {

    CLibTidy.tidyGetHtml(tdoc)
}


/**
 *  Get the HEAD node.
 *
 *  - parameters:
 *    - tdoc: The document to query.
 *  - returns:
 *      Returns a tidy node.
 */
public func tidyGetHead(_ tdoc: TidyDoc) -> TidyNode? {

    CLibTidy.tidyGetHead(tdoc)
}


/**
 *  Get the BODY node.
 *
 *  - parameters:
 *    - tdoc: The document to query.
 *  - returns:
 *      Returns a tidy node.
 */
public func tidyGetBody(_ tdoc: TidyDoc) -> TidyNode? {

    CLibTidy.tidyGetBody(tdoc)
}


//-----------------------------------------------------------------------------
// MARK: Relative Nodes
//-----------------------------------------------------------------------------


/**
 *  Get the parent of the indicated node.
 *
 *  - parameters:
 *    - tnod: The node to query.
 *  - returns:
 *      Returns a tidy node.
 */
public func tidyGetParent(_ tnod: TidyNode) -> TidyNode? {

    CLibTidy.tidyGetParent(tnod)
}


/**
 *  Get the child of the indicated node.
 *
 *  - parameters:
 *    - tnod: The node to query.
 *  - returns:
 *      Returns a tidy node.
 */
public func tidyGetChild(_ tnod: TidyNode) -> TidyNode? {

    CLibTidy.tidyGetChild(tnod)
}


/**
 *  Get the next sibling node.
 *
 *  - parameters:
 *    - tnod: The node to query.
 *  - returns:
 *      Returns a tidy node.
 */
public func tidyGetNext(_ tnod: TidyNode) -> TidyNode? {

    CLibTidy.tidyGetNext(tnod)
}


/**
 *  Get the previous sibling node.
 *
 *  - parameters:
 *    - tnod: The node to query.
 *  - returns:
 *      Returns a tidy node.
 */
public func tidyGetPrev(_ tnod: TidyNode) -> TidyNode? {

    CLibTidy.tidyGetPrev(tnod)
}


//-----------------------------------------------------------------------------
// MARK: Miscellaneous Node Functions
//-----------------------------------------------------------------------------


/**
 *  Remove the indicated node.
 *
 *  - parameters:
 *    - tdoc: The tidy document from which to remove the node.
 *    - tnod: The node to remove.
 *  - returns:
 *      Returns the next tidy node.
 */
public func tidyDiscardElement(_ tdoc: TidyDoc, _ tnod: TidyNode) -> TidyNode? {

    CLibTidy.tidyDiscardElement(tdoc, tnod)
}


//-----------------------------------------------------------------------------
// MARK: Node Attribute Functions
//-----------------------------------------------------------------------------


/**
 *  Get the first attribute.
 *
 *  - parameters:
 *    - tnod: The node for which to get attributes.
 *  - returns:
 *      Returns an instance of TidyAttr.
 */
public func tidyAttrFirst(_ tnod: TidyNode) -> TidyAttr? {

    CLibTidy.tidyAttrFirst(tnod)
}


/**
 *  Get the next attribute.
 *
 *  - parameters:
 *    - tattr: The current attribute, so the next one can be returned.
 *  - returns:
 *      Returns and instance of TidyAttr.
 */
public func tidyAttrNext(_ tattr: TidyAttr) -> TidyAttr? {

    CLibTidy.tidyAttrNext(tattr)
}


/**
 *  Get the name of a TidyAttr instance.
 *  - parameters:
 *    - tattr: The tidy attribute to query.
 *  - returns:
 *      Returns a string indicating the name of the attribute.
 */
public func tidyAttrName(_ tattr: TidyAttr) -> String {

    String(cString: CLibTidy.tidyAttrName(tattr))
}


/**
 *  Get the value of a TidyAttr instance.
 *
 *  - parameters:
 *    - tattr: The tidy attribute to query.
 *  - returns: Returns a string indicating the value of the attribute.
 */
public func tidyAttrValue(_ tattr: TidyAttr) -> String {

    if let result = CLibTidy.tidyAttrValue(tattr) {
        return String(cString: result)
    }
    return ""
}


/**
 *  Discard an attribute.
 *
 *  - parameters:
 *    - tdoc: The tidy document from which to discard the attribute.
 *    - tnod: The node from which to discard the attribute.
 *    - tattr: The attribute to discard.
 */
public func tidyAttrDiscard(_ tdoc: TidyDoc, _ tnod: TidyNode, _ tattr: TidyAttr) {

    CLibTidy.tidyAttrDiscard(tdoc, tnod, tattr)
}


/**
 *  Get the attribute ID given a tidy attribute.
 *
 *  - parameters:
 *    - tattr: The attribute to query.
 *  - returns:
 *      Returns the TidyAttrId of the given attribute.
 */
public func tidyAttrGetId(_ tattr: TidyAttr) -> TidyAttrId {

    CLibTidy.tidyAttrGetId(tattr)
}


/**
 *  Indicates whether or not a given attribute is an event attribute.
 *
 *  - parameters:
 *    - tattr: The attribute to query.
 *  - returns:
 *      Returns a bool indicating whether or not the attribute is an event.
 */
public func tidyAttrIsEvent(_ tattr: TidyAttr) -> Swift.Bool {

    CLibTidy.tidyAttrIsEvent(tattr) == yes ? true : false
}


/**
 *  Get an instance of TidyAttr by specifying an attribute ID.
 *
 *  - parameters:
 *    - tnod: The node to query.
 *    - attId: The attribute ID to find.
 *  - returns:
 *      Returns a TidyAttr instance.
 */
public func tidyAttrGetById(_ tnod: TidyNode, _ attId: TidyAttrId) -> TidyAttr? {

    CLibTidy.tidyAttrGetById(tnod, attId)
}


//-----------------------------------------------------------------------------
// MARK: Additional Node Interrogation
//-----------------------------------------------------------------------------


/**
 *  Get the type of node.
 *
 *  - parameters:
 *    - tnod: The node to query.
 *  - returns:
 *      Returns the type of node as TidyNodeType.
 */
public func tidyNodeGetType(_ tnod: TidyNode) -> TidyNodeType {

    CLibTidy.tidyNodeGetType(tnod)
}


/**
 *  Get the name of the node.
 *
 *  - parameters:
 *    - tnod: The node to query.
 *  - returns:
 *      Returns a string indicating the name of the node.
 */
public func tidyNodeGetName(_ tnod: TidyNode) -> String {

    if let result = CLibTidy.tidyNodeGetName(tnod) {
        return String(cString: result)
    }
    return ""
}


/**
 *  Indicates whether or not a node is a text node.
 *
 *  - parameters:
 *    - tnod: The node to query.
 *  - returns:
 *      Returns a bool indicating whether or not the node is a text node.
 */
public func tidyNodeIsText(_ tnod: TidyNode) -> Swift.Bool {

    CLibTidy.tidyNodeIsText(tnod) == yes ? true : false
}


/**
 *  Indicates whether or not the node is a propriety type.
 *
 *  - parameters:
 *    - tdoc: The document to query.
 *    - tnod: The node to query.
 *  - returns:
 *      Returns a bool indicating whether or not the node is a proprietary type.
 */
public func tidyNodeIsProp(_ tdoc: TidyDoc, _ tnod: TidyNode) -> Swift.Bool {

    CLibTidy.tidyNodeIsProp(tdoc, tnod) == yes ? true : false
}


/**
 *  Indicates whether or not a node represents an HTML header element, such
 *  as h1, h2, etc.
 *
 *  - parameters:
 *    - tnod: The node to query.
 *  - returns:
 *      Returns a bool indicating whether or not the node is an HTML header.
 */
public func tidyNodeIsHeader(_ tnod: TidyNode) -> Swift.Bool {

    CLibTidy.tidyNodeIsHeader(tnod) == yes ? true : false
}


/**
 *  Indicates whether or not the node has text.
 *
 *  - parameters:
 *    - tdoc: The document to query.
 *    - tnod: The node to query.
 *  - returns:
 *      Returns the type of node as TidyNodeType.
 */
public func tidyNodeHasText(_ tdoc: TidyDoc, _ tnod: TidyNode) -> Swift.Bool {

    CLibTidy.tidyNodeHasText(tdoc, tnod) == yes ? true : false
}


/**
 *  Gets the text of a node and places it into the given TidyBuffer.
 *
 *  - parameters:
 *    - tdoc: The document to query.
 *    - tnod: The node to query.
 *    - buf: [out] A TidyBuffer used to receive the node's text.
 *  - returns:
 *      Returns a bool indicating success or not.
 */
public func tidyNodeGetText(_ tdoc: TidyDoc, _ tnod: TidyNode, _ buf: SwLibTidyBufferProtocol) -> Swift.Bool {

    CLibTidy.tidyNodeGetText(tdoc, tnod, buf.tidyBuffer) == yes ? true : false
}


/**
 *  Gets the text of a node and returns it as a string.
 *
 *  - Note:
 *      This signature is a convenience addition to CLibTidy for SwLibTidy.
 *
 *  - parameters:
 *    - tdoc: The document to query.
 *    - tnod: The node to query.
 *  - returns:
 *      Returns a string with the node's text.
 */
public func tidyNodeGetText(_ tdoc: TidyDoc, _ tnod: TidyNode) -> String {

    let buffer = SwLibTidyBuffer()
    if CLibTidy.tidyNodeGetText(tdoc, tnod, buffer.tidyBuffer) == yes {
        if let result = buffer.StringValue() {
            return result
        }
    }
    return ""
}


/**
 *  Get the value of the node. This copies the unescaped value of this node into
 *  the given TidyBuffer as UTF-8.
 *
 *  - parameters:
 *    - tdoc: The document to query.
 *    - tnod: The node to query.
 *    - buf: [out] A TidyBuffer used to receive the node's text.
 *  - returns:
 *      Returns a bool indicating success or not.
 */
public func tidyNodeGetValue(_ tdoc: TidyDoc, _ tnod: TidyNode, _ buf: SwLibTidyBufferProtocol) -> Swift.Bool {

    CLibTidy.tidyNodeGetValue(tdoc, tnod, buf.tidyBuffer) == yes ? true : false
}


/**
 *  Get the value of the node. This copies the unescaped value of this node into
 *  the given TidyBuffer as UTF-8.
 *
 *  - Note:
 *      This signature is a convenience addition to CLibTidy for SwLibTidy.
 *
 *  - parameters:
 *    - tdoc: The document to query.
 *    - tnod: The node to query.
 *  - returns:
 *      Returns a string with the node's value, on nil if the node type doesn't
 *      have a value.
 */
public func tidyNodeGetValue(_ tdoc: TidyDoc, _ tnod: TidyNode) -> String? {

    let buffer = SwLibTidyBuffer()
    if CLibTidy.tidyNodeGetValue(tdoc, tnod, buffer.tidyBuffer) == yes {
        if let result = buffer.StringValue() {
            return result
        } else {
            return "" /* null string if value allowed, but no value. */
        }
    }
    return nil /* This node can't have a value. */
}


/**
 *  Get the tag ID of the node.
 *
 *  - parameters:
 *    - tnod: The node to query.
 *  - returns:
 *      Returns the tag ID of the node as TidyTagId.
 */
public func tidyNodeGetId(_ tnod: TidyNode) -> TidyTagId {

    CLibTidy.tidyNodeGetId(tnod)
}


/**
 *  Get the line number where the node occurs.
 *
 *  - parameters:
 *    - tnod: The node to query.
 *  - returns:
 *      Returns the line number.
 */
public func tidyNodeLine(_ tnod: TidyNode) -> UInt {

    UInt(CLibTidy.tidyNodeLine(tnod))
}


/**
 *  Get the column location of the node.
 *
 *  - parameters:
 *    - tnod: The node to query.
 *  - returns:
 *      Returns the column location of the node.
 */
public func tidyNodeColumn(_ tnod: TidyNode) -> UInt {

    UInt(CLibTidy.tidyNodeColumn(tnod))
}


//*****************************************************************************
// MARK: - Message Key Management
//  These functions serve to manage message codes, i.e., codes that are used
//  Tidy and communicated via its callback filters to represent reports and
//  dialogue that Tidy emits.
//
//  - Note: These codes only reflect complete messages, and are specifically
//      distinct from the internal codes that are used to lookup individual
//      strings for localization purposes.
//*****************************************************************************


/**
 *  Given a message code, return the text key that represents it.
 *
 *  - Note: despite the name of this method, it's used to fetch the message key
 *      for *any* of Tidy's messages. Because the messages have origins from
 *      different enums in the original C source code, this method can only take
 *      a UInt. Although you should always use enums rather than raw values, in
 *      this case you must use EnumLabel.rawValue.
 *
 *  - parameters:
 *    - code: The message code to lookup.
 *  - returns:
 *      The string representing the error code.
 */
public func tidyErrorCodeAsKey(_ code: UInt32) -> String {

    String(cString: CLibTidy.tidyErrorCodeAsKey(uint(code)))
}


/**
 *  Given a text key representing a message code, return the UInt that
 *  represents it.
 *
 *  - Note: We establish that for external purposes, the API will ensure that
 *      string keys remain consistent. *Never* count on the integer value
 *      of a message code. Always use this function to ensure that the
 *      integer is valid if you need one.
 *
 *  - parameters:
 *    - code: The string representing the error code.
 *  - returns:
 *      Returns an integer that represents the error code, which can be
 *      used to lookup Tidy's built-in strings. If the provided string does
 *      not have a matching message code, then UINT_MAX will be returned.
 */
public func tidyErrorCodeFromKey(_ code: String) -> UInt32 {

    UInt32(CLibTidy.tidyErrorCodeFromKey(code))
}

/**
 *  Returns on array of `UInt`, where each `UInt` represents an message code
 *  available in Tidy. These `UInt` values map to message codes in one CLibTidy's
 *  various enumerations. In general, you must never count on these values, and
 *  always use the enum label. This utility is generally only useful for
 *  documentation purposes.
 *
 *  - Note: This Swift array replaces the CLibTidy `getErrorCodeList()` and
 *      `getNextErrorCode()` functions, as it is much more natural to deal with
 *      Swift array types when using Swift.
 *
 *  - returns:
 *      An array of `UInt`, if any.
 */
public func getErrorCodeList() -> [UInt] {

    var it: TidyIterator? = CLibTidy.getErrorCodeList()

    var result: [UInt] = []

    while it != nil {
        result.append(UInt(CLibTidy.getNextErrorCode(&it)))
    }

    return result
}


//*****************************************************************************
// MARK: - Localization Support -
//  These functions help manage localization in Tidy. Note that these implement
//  native CLibTidy localization; you'd probably want to implement your own
//  mechanism to use native macOS localization.
//*****************************************************************************


//-----------------------------------------------------------------------------
// MARK: Tidy's Locale
//-----------------------------------------------------------------------------


/**
 *  Tells Tidy to use a different language for output.
 *
 *  - parameters:
 *    - languageCode: A Windows or POSIX language code, and must match a
 *          `TIDY_LANGUAGE` for an installed language.
 *  - returns:
 *      Indicates that a setting was applied, but not necessarily the specific
 *      request, i.e., true indicates a language and/or region was applied. If
 *      `es_mx` is requested but not installed, and `es` is installed, then `es`
 *      will be selected and this function will return `true`. However the opposite
 *      is not true; if `es` is requested but not present, Tidy will not try to
 *      select from the `es_XX` variants.
 */
public func tidySetLanguage(_ languageCode: String) -> Swift.Bool {

    CLibTidy.tidySetLanguage(languageCode) == yes ? true : false
}


/**
 *  Gets the current language used by Tidy.
 *
 *  - returns:
 *      Returns a string indicating the currently set language.
 */
public func tidyGetLanguage() -> String {

    String(cString: CLibTidy.tidyGetLanguage())
}


/**
 *  Returns a dictionary of mappings between Windows legacy locale names to
 *  POSIX locale names.
 *
 *  - Note: This Swift array replaces the CLibTidy functions
 *      `getWindowsLanguageList()` and `getNextWindowsLanguage()`, as it is much
 *      more natural to deal with Swift array types when using Swift.
 *
 *  - returns:
 *      Returns a dictionary with key names representing a Windows locale name,
 *      and values representing the equivalent POSIX locale. Note that this
 *      relationship may be many to one, in that multiple Windows locale names
 *      refer to the same POSIX mapping.
 */
public func getWindowsLanguageList() -> [String: String] {

    var it: TidyIterator? = CLibTidy.getWindowsLanguageList()
    var result = [String: String]()

    while it != nil {
        if let mapItem = CLibTidy.getNextWindowsLanguage(&it) {
            let winName = String(cString: CLibTidy.TidyLangWindowsName(mapItem))
            let nixName = String(cString: CLibTidy.TidyLangPosixName(mapItem))
            result[winName] = nixName
        }
    }

    return result
}


//-----------------------------------------------------------------------------
// MARK: Getting Localized Strings
//-----------------------------------------------------------------------------


/**
 *  Provides a string given `messageType` in the current localization for
 *  `quantity`. Some strings have one or more plural forms, and this function
 *  will ensure that the correct singular or plural form is returned for the
 *  specified quantity.
 *
 *  - parameters:
 *    - messageType: The message type.
 *    - quantity: The quantity.
 *  - returns:
 *      Returns the desired string.
 */
public func tidyLocalizedStringN(_ messageType: tidyStrings, _ quantity: UInt) -> String {

    /* The actual method doesn't take this type, but a uint. */
    String(cString: CLibTidy.tidyLocalizedStringN(uint(messageType.rawValue), uint(quantity)))
}


/**
 *  Provides a string given `messageType` in the current localization for the
 *  single case.
 *
 *  - parameters:
 *    - messageType: The message type.
 *  - returns:
 *      Returns the desired string.
 */
public func tidyLocalizedString(_ messageType: tidyStrings) -> String {

    /* The actual method doesn't take this type, but a uint. */
    String(cString: CLibTidy.tidyLocalizedString(uint(messageType.rawValue)))
}


/**
 *  Provides a string given `messageType` in the default localization (which
 *  is `en`).
 *
 *  - parameters:
 *    - messageType: The message type.
 *  - returns:
 *      Returns the desired string.
 */
public func tidyDefaultString(_ messageType: tidyStrings) -> String {

    String(cString: CLibTidy.tidyDefaultString(uint(messageType.rawValue)))
}


/**
 *  Returns an array of `UInt`, each of which serves as a key to a CLibTidy string.
 *
 *  - Note: These are provided for documentation generation purposes, and probably
 *      aren't of much use to the average LibTidy implementor. This list includes
 *      _every_ localizable string in Tidy, including strings that are used
 *      internally to build other strings, which are NOT part of the API. It is
 *      suggested that you use getErrorCodeList() for all public API strings.
 *
 *  - Note: This Swift array replaces the CLibTidy functions `getStringKeyList()`
 *      and `getNextStringKey()`, as it is much more natural to deal with Swift
 *      array types when using Swift.
 *
 *  - returns:
 *      Returns an array of `UInt`.
 */
public func getStringKeyList() -> [UInt] {

    var it: TidyIterator? = CLibTidy.getStringKeyList()

    var result: [UInt] = []

    while it != nil {
        result.append(UInt(CLibTidy.getNextStringKey(&it)))
    }

    return result
}


//-----------------------------------------------------------------------------
// MARK: Available Languages
//-----------------------------------------------------------------------------


/**
 *  Returns an array of `String`, each of which indicates an installed CLibTidy
 *  language.
 *
 *  - Note: This Swift array replaces the CLibTidy functions
 *    `getInstalledLanguageList()` and `getNextInstalledLanguage()`, as it is much
 *    more natural to deal with Swift array types when using Swift.
 *
 *  - returns:
 *      Returns an array of `String`.
 */
public func getInstalledLanguageList() -> [String] {

    var it: TidyIterator? = CLibTidy.getInstalledLanguageList()

    var result: [String] = []

    while it != nil {

        if let opt = CLibTidy.getNextInstalledLanguage(&it) {
            result.append(String(cString: opt))
        }
    }

    return result
}


//*****************************************************************************
// MARK: - Convenience and Delegate Methods
//*****************************************************************************


/**
 *  Set the delegate for an instance of TidyDoc.
 */
public func tidySetDelegate(anObject: SwLibTidyDelegateProtocol, forTidyDoc: TidyDoc) {

    guard
        let ptrStorage = CLibTidy.tidyGetAppData(forTidyDoc)
    else { return }

    let storage = Unmanaged<ApplicationData>
        .fromOpaque(ptrStorage)
        .takeUnretainedValue()

    storage.delegate = anObject
}

/**
 *  Returns an array of objects containing everything that could have been passed
 *  to the ConfigCallback. This convenience method avoids having to use your own
 *  callback or delegate method to collect this data.
 *
 *  - parameters:
 *    - forTidyDoc: the document for which you want to retrieve unrecognized
 *      configuration records.
 *  - returns:
 *      Returns an array of objects conforming to the TidyConfigReportProtocol,
 *      by default, of type TidyConfigReport. You can instruct SwLibTidy to use
 *      a different class via setTidyConfigRecords(toClass:forTidyDoc:).
 */
public func tidyConfigRecords(forTidyDoc: TidyDoc) -> [SwLibTidyConfigReportProtocol] {

    guard
        let ptrStorage = CLibTidy.tidyGetAppData(forTidyDoc)
    else { return [] }

    let storage = Unmanaged<ApplicationData>
        .fromOpaque(ptrStorage)
        .takeUnretainedValue()

    return storage.configCallbackRecords
}


/**
 *  Allows you to set an alternate class to be used in the tidyConfigRecords()
 *  array. The alternate class must conform to TidyConfigReportProtocol, and
 *  might be used if you want a class to provide more sophisticated management
 *  of these unrecognized options.
 *
 *  - parameters:
 *    - forTidyDoc: The TidyDoc for which you are setting the class.
 *    - toClass: The class that you want to use to collect unrecognized options.
 *  - returns:
 *      Returns true or false indicating whether or not the class could be set.
 */
public func setTidyConfigRecords(toClass: SwLibTidyConfigReportProtocol.Type, forTidyDoc: TidyDoc) -> Swift.Bool {

    guard
        let ptrStorage = CLibTidy.tidyGetAppData(forTidyDoc)
    else { return false }

    let storage = Unmanaged<ApplicationData>
        .fromOpaque(ptrStorage)
        .takeUnretainedValue()

    storage.configRecordClass = toClass
    return true
}


/**
 *  Returns an array of every TidyMessage that was generated during every stage
 *  of a TidyDoc life-cycle. This convenience method allows you to access this
 *  data without having to use a callback or delegate method.
 *
 *  - parameters:
 *    - forTidyDoc: the document for which you want to retrieve messages.
 *  - returns:
 *      Returns an array of objects conforming to the TidyMessageProtocol, by
 *      default, of type TidyMessageContainer. You can instruct SwLibTidy to use
 *      a different class via setTidyMessageRecords(toClass:forTidyDoc:).
 */
public func tidyMessageRecords(forTidyDoc: TidyDoc) -> [SwLibTidyMessageProtocol] {

    guard
        let ptrStorage = CLibTidy.tidyGetAppData(forTidyDoc)
    else { return [] }

    let storage = Unmanaged<ApplicationData>
        .fromOpaque(ptrStorage)
        .takeUnretainedValue()

    return storage.messageCallbackRecords
}


/**
 *  Allows you to set an alternate class to be used in the tidyMessageRecords()
 *  array. The alternate class must conform to TidyMessageProtocol, and might be
 *  used if you want a class to provide more sophisticated management of messages.
 *
 *  - parameters:
 *    - forTidyDoc: The TidyDoc for which you are setting the class.
 *    - toClass: The class that you want to use to collect messages.
 *  - returns:
 *      Returns true or false indicating whether or not the class could be set.
 */
public func setTidyMessageRecords(toClass: SwLibTidyMessageProtocol.Type, forTidyDoc: TidyDoc) -> Swift.Bool {

    guard
        let ptrStorage = CLibTidy.tidyGetAppData(forTidyDoc)
    else { return false }

    let storage = Unmanaged<ApplicationData>
        .fromOpaque(ptrStorage)
        .takeUnretainedValue()

    storage.messageRecordClass = toClass
    return true
}


/**
 *  Returns an array of every Pretty Printing Progress update that was generated
 *  during the pretty printing process. This convenience method allows you to
 *  access this data without having to use a callback or delegate method.
 *
 *  - parameters:
 *    - forTidyDoc: the document for which you want to retrieve data.
 *  - returns:
 *      Returns an array of objects conforming to the TidyPPProgressProtocol, by
 *      default, of type TidyPPProgressReport. You can instruct SwLibTidy to use
 *      a different class via setTidyPPProgressRecords(toClass:forTidyDoc:).
 */
public func tidyPPProgressRecords(forTidyDoc: TidyDoc) -> [SwLibTidyPPProgressProtocol] {

    guard
        let ptrStorage = CLibTidy.tidyGetAppData(forTidyDoc)
    else { return [] }

    let storage = Unmanaged<ApplicationData>
        .fromOpaque(ptrStorage)
        .takeUnretainedValue()

    return storage.ppCallbackRecords
}


/**
 *  Allows you to set an alternate class to be used in the tidyPPProgressRecords()
 *  array. The alternate class must conform to TidyPPProgressProtocol, and might be
 *  used if you want a class to provide more sophisticated management of reports.
 *
 *  - parameters:
 *    - forTidyDoc: The TidyDoc for which you are setting the class.
 *    - toClass: The class that you want to use to collect data.
 *  - returns:
 *      Returns true or false indicating whether or not the class could be set.
 */
public func setTidyPPProgressRecords(toClass: SwLibTidyPPProgressProtocol.Type, forTidyDoc: TidyDoc) -> Swift.Bool {

    guard
        let ptrStorage = CLibTidy.tidyGetAppData(forTidyDoc)
    else { return false }

    let storage = Unmanaged<ApplicationData>
        .fromOpaque(ptrStorage)
        .takeUnretainedValue()

    storage.ppRecordClass = toClass
    return true
}


//*****************************************************************************
// MARK: - Private -
//*****************************************************************************


/**
 *  An instance of this class is retained by CLibTidy's AppData, and is used to
 *  store additional pointers that we cannot store in CLibTidy directly. It
 *  serves as a global variable store for each instance of a TidyDocument.
 */
private class ApplicationData {

    var appData: AnyObject?
    var delegate: SwLibTidyDelegateProtocol?

    var configCallback: TidyConfigCallback?
    var configCallbackRecords: [SwLibTidyConfigReportProtocol]
    var configRecordClass: SwLibTidyConfigReportProtocol.Type

    var configChangeCallback: TidyConfigChangeCallback?

    var messageCallback: TidyMessageCallback?
    var messageCallbackRecords: [SwLibTidyMessageProtocol]
    var messageRecordClass: SwLibTidyMessageProtocol.Type

    var ppCallback: TidyPPProgress?
    var ppCallbackRecords: [SwLibTidyPPProgressProtocol]
    var ppRecordClass: SwLibTidyPPProgressProtocol.Type

    init() {
        self.appData = nil
        self.delegate = nil

        self.configCallback = nil
        self.configCallbackRecords = []
        self.configRecordClass = SwLibTidyConfigReport.self

        self.configChangeCallback = nil

        self.messageCallback = nil
        self.messageCallbackRecords = []
        self.messageRecordClass = SwLibTidyMessage.self

        self.ppCallback = nil
        self.ppCallbackRecords = []
        self.ppRecordClass = SwLibTidyPPProgressReport.self
    }
}
