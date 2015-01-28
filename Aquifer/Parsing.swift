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

public func draw<V, I>() -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, V?> {
    return get() >>- { p in
        switch next(p) {
        case let .Left(x): return { _ in nil } <^> put(pure(x.value))
        case let .Right(k):
            let (dO, q) = k.value
            return { _ in dO } <^> put(q)
        }
    }
}

public func skip<V, I>() -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, Bool> {
    return { if let _ = $0 { return true } else { return false } } <^> draw()
}

private func drawAllInner<V, I>(diffAs: List<V> -> List<V>) -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, List<V>> {
    return draw() >>- {
        if let v = $0 {
            return drawAllInner(diffAs • curry(List.cons)(v))
        } else {
            return pure(diffAs([]))
        }
    }
}

public func drawAll<V, I>() -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, List<V>> {
    return drawAllInner { v in v }
}

public func skipAll<V, I>() -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, ()> {
    return draw() >>- { if let _ = $0 { return skipAll() } else { return pure(()) } }
}

public func unDraw<V, I>(x: V) -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, ()> {
    return modify { p in yield(x) >>- { _ in p } }
}

public func peek<V, I>() -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, V?> {
    return draw() >>- { k in if let v = k { return { _ in k } <^> unDraw(v) } else { return pure(k) } }
}

public func isEndOfInput<V, I>() -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, Bool> {
    return { if let _ = $0 { return true } else { return false } } <^> peek()
}

public func foldAll<A, V, I, R>(stepWith step: (A, V) -> A, initializeWith initial: A, extractWith extractor: A -> R) -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, R> {
    return draw() >>- {
        if let v = $0 {
            return foldAll(stepWith: step, initializeWith: step(initial, v), extractWith: extractor)
        } else {
            return pure(extractor(initial))
        }
    }
}

/*public func toParser<V, I, R>(p: Proxy<(), V?, (), X, R>) -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, Bool> {
}*/

public func toParser<V, I, R>(endless p: Proxy<(), V, (), X, X>) -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, ()> {
    return IxState { q in ((), pure(runEffect(q >-> ({ closed($0) } <^> p)))) }
}
