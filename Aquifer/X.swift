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

/// The (nominally) empty type, implemented as a strictly self-recursive struct.
public struct X {
    private let rec: Box<X>

    private init(_ r: X) {
        rec = { _ in r }
    }

    public func absurd<A>() -> A {
        return rec.value.absurd()
    }
}

public func closed<A>(x: X) -> A {
    return x.absurd()
}

/// Bottom is the only (non-`error`) inhabitent of X
public func infiniteLoop() -> X {
    return X(infiniteLoop())
}
