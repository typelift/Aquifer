//
//  FileIO.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/16/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

import Foundation
import Swiftz

public func readLines<UO, UI>(fromURL url: NSURL, withChunkSize chunkSize: Int = 64) -> Proxy<UO, UI, (), String, ()>? {
    if let stream: NSInputStream = NSInputStream(URL: url) {
        var buffer: [UInt8] = Array(count: chunkSize, repeatedValue: 0)
        buffer.withUnsafeMutableBufferPointer({ (inout ptr: UnsafeMutableBufferPointer<UInt8>) in
            stream.read(ptr.baseAddress, maxLength: chunkSize)
        })
    } else {
        return nil
    }
}

public func readLines<UO, UI>(fromFileAtPath path: String) -> Proxy<UO, UI, (), String, ()>? {
    if let url = NSURL(fileURLWithPath: path) {
        return readLines(fromURL: url)
    } else {
        return nil
    }
}
