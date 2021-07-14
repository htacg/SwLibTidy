//
//  main.swift
//  console
//
//  Created by Jim Derry on 2021/7/13.
//  Copyright © 2021 Jim Derry. All rights reserved.
//

import Foundation
import SwLibTidy


/* If the linked Tidy is older than the mininum supported, then
   a console message will be output when the TidyDoc is created. */
if let tdoc: TidyDoc = tidyCreate() {
    tidyRelease( tdoc )
    NSLog("tidyCreate succeeded.")
} else {
    NSLog("tidyCreate failed.")
}

/* Simply print some LibTidy details. */
NSLog("LibTidy \(tidyLibraryVersion()) released on \(tidyReleaseDate()) for \(tidyPlatform()).")
