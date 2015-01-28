//
//  IO.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/28/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

// part of `Pipes.Prelude`

import Foundation
import Swiftz

public func stdinLn<UO, UI>() -> Proxy<UO, UI, (), String, ()> {
    return fromHandle(NSFileHandle.fileHandleWithStandardInput())
}

public func fromHandle<UO, UI>(handle: NSFileHandle) -> Proxy<UO, UI, (), String, ()> {
    if handle.isAtEndOfFile {
        return pure(())
    } else {
        return yield(handle.readLine) >>- { _ in fromHandle(handle) }
    }
}

public func repeat<UO, UI, DO, FR>(v: @autoclosure () -> DO) -> Proxy<UO, UI, (), DO, FR> {
    return pure(v) >~ cat()
}

public func replicate<UO, UI, DO, FR>(v: @autoclosure () -> DO, n: Int) -> Proxy<UO, UI, (), DO, FR> {
    return pure(v) >~ take(n)
}

public
