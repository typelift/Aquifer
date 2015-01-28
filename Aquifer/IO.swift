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
    return pure(())
}
