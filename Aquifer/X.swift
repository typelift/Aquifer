//
//  X.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/14/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

import Foundation
import Swiftz

/// The (nominally) empty type, implemented as a semi-strictly self-recursive struct.
public struct X {
    private let rec: () -> X

    internal init(_ r: X) {
        rec = { _ in r }
    }

    public func absurd<A>() -> A {
        return rec().absurd()
    }
}


/// Bottom is the only inhabitent of X
public func infiniteLoop() -> X {
    return X(infiniteLoop())
}
