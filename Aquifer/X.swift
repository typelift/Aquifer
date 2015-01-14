//
//  X.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/14/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

import Foundation
import Swiftz

/// The (nominally) empty type, implemented as a strictly self-recursive struct.
public struct X {
    internal let rec: Box<X>

    internal init(_ r: X) {
        rec = Box(r)
    }

    public func absurd<A>() -> A {
        return rec.value.absurd()
    }
}
