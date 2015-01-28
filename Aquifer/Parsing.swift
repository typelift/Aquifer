//
//  Parsing.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/27/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

// roughly 'Pipes.Parse'

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

public func splitAt<V, R>(p: Proxy<X, (), (), V, R>, n: Int) -> Proxy<X, (), (), V, Proxy<X, (), (), V, R>> {
    if n <= 0 {
        return pure(p)
    } else {
        switch next(p) {
        case let .Left(x): return pure(pure(x.value))
        case let .Right(k):
            let (dO, q) = k.value
            return yield(dO) >>- { _ in splitAt(q, n - 1) }
        }
    }
}

public func groupBy<V, R>(p: Proxy<X, (), (), V, R>, equals: (V, V) -> Bool) -> Proxy<X, (), (), V, Proxy<X, (), (), V, R>> {
    switch next(p) {
    case let .Left(x): return pure(pure(x.value))
    case let .Right(k):
        let (dO, q) = k.value
        return span(yield(dO) >>- { _ in q }) { v in equals(dO, v) }
    }
}

public func group<V: Equatable, R>(p: Proxy<X, (), (), V, R>) -> Proxy<X, (), (), V, Proxy<X, (), (), V, R>> {
    return groupBy(p) { v0, v1 in v0 == v1 }
}
