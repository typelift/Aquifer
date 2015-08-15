//
//  X.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/14/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

// part of `Pipes.Internal`

import Foundation
import Swiftz

/// The (nominally) empty type, implemented as a semi-strictly self-recursive struct.
public struct X {
    private let rec: () -> X

    private init(_ x: () -> X) {
        rec = x
    }

    public func absurd<A>() -> A {
        return rec().absurd()
    }
}

public func closed<A>(x: X) -> A {
    return x.absurd()
}
