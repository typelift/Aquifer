//
//  FileIO.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/16/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

import Foundation
import Swiftz

public func readLines<UO, UI>(fromURL url: NSURL) -> Proxy<UO, UI, (), String, ()>? {
}

public func readLines<UO, UI>(fromFileAtPath path: String) -> Proxy<UO, UI, (), String, ()>? {
    if let url = NSURL(fileURLWithPath: path) {
        return readLines(fromURL: url)
    } else {
        return nil
    }
}
