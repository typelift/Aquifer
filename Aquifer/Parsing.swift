//
//  Parsing.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/27/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

import Foundation
import Swiftz

public func span<V, R>(p: Proxy<X, (), (), V, R>, predicate: V -> Bool) -> Proxy<X, (), (), V, Proxy<X, (), (), V, R>> {
    switch next(p) {
    case let .Left(x): return pure(pure(x.value))
    case let .Right(k):
        let (dO, q) = k.value
        if predicate(dO) {
            return yield(dO) >>- { _ in span(p, predicate) }
        } else {
            return pure(yield(dO) >>- { _ in q })
        }
    }
}
