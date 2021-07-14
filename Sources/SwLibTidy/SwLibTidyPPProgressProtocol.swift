/**
 *  SwLibTidyPPProgressProtocol.swift
 *   Part of the SwLibTidy wrapper library for tidy-html5 ("CLibTidy").
 *   See https://github.com/htacg/tidy-html5
 *
 *   Copyright © 2017-2021 by HTACG. All rights reserved.
 *   Created by Jim Derry 2017; copyright assigned to HTACG. Permission to use
 *   this source code per the W3C Software Notice and License:
 *   https://www.w3.org/Consortium/Legal/2002/copyright-software-20021231
 *
 *   Purpose
 *     This protocol and class define and implement an object for the
 *     collection of pretty printing progress report data, which establishes
 *     a spatial relationship between items in the input document and items
 *     in the output document.
 */

/**
 *  This protocol defines an interface for the collection of pretty printing
 *  progress report data, which establishes a spatial relationship between
 *  items in the input document and items in the output document.
 */
public protocol SwLibTidyPPProgressProtocol {

    /**
     *  The document from which the message originates.
     */
    var document: TidyDoc { get }

    /**
     *  The line in the source document.
     */
    var sourceLine: UInt32 { get }

    /**
     *  The column in the source document.
     */
    var sourceColumn: UInt32 { get }

    /**
     *  The line in the destination document.
     */
    var destLine: UInt32 { get }

    /** Create an instance with these data. */
    init(withLine: UInt32, column: UInt32, destLine: UInt32, forDocument: TidyDoc)
}


/**
 *  A default implementation of the `SwLibTidyPPProgressProtocol`.
 */
public class SwLibTidyPPProgressReport: SwLibTidyPPProgressProtocol {

    public var document: TidyDoc
    public var sourceLine: UInt32 = 0
    public var sourceColumn: UInt32 = 0
    public var destLine: UInt32 = 0

    public required init(withLine: UInt32, column: UInt32, destLine: UInt32, forDocument: TidyDoc) {

        self.document = forDocument
        self.sourceLine = withLine
        self.sourceColumn = column
        self.destLine = destLine
    }
}


