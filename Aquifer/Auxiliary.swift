//
//  Auxiliary.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/29/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

// roughly `Pipes.Extras`

import Foundation
import Swiftz

public func arr<A, B, R>(f: A -> B) -> Proxy<(), A, (), B, R> {
    return map(f)
}
