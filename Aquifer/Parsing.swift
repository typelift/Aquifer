//
//  Parsing.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/27/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

// roughly `Pipes.Parse`

import Swiftz
import Focus

/// Splits the Producer into two Producers, where the outer Producer is the longest consecutive 
/// group of elements that satisfy the given predicate.
public func span<V, R>(p: Proxy<X, (), (), V, R>, _ predicate: V -> Bool) -> Proxy<X, (), (), V, Proxy<X, (), (), V, R>> {
    switch next(p) {
    case let .Left(x): return pure(pure(x))
    case let .Right((dO, q)):
        if predicate(dO) {
            return yield(dO) >>- { _ in span(p, predicate) }
        } else {
            return pure(yield(dO) >>- { _ in q })
        }
    }
}

/// Splits the Producer into two Producers, where the outer Producer is the longest consecutive
/// group of elements that do not satisfy the given predicate.
public func extreme<V, R>(p: Proxy<X, (), (), V, R>, _ predicate: V -> Bool) -> Proxy<X, (), (), V, Proxy<X, (), (), V, R>> {
    return span(p, (!) • predicate)
}

/// Splits a Producer into two Producers after a fixed number of elements
public func splitAt<V, R>(p: Proxy<X, (), (), V, R>, _ n: Int) -> Proxy<X, (), (), V, Proxy<X, (), (), V, R>> {
    if n <= 0 {
        return pure(p)
    } else {
        switch next(p) {
        case let .Left(x): return pure(pure(x))
        case let .Right((dO, q)):
            return yield(dO) >>- { _ in splitAt(q, n - 1) }
        }
    }
}

/// Splits a Producer into two Producers after the first group of elements that are equal according
/// to the equality predicate.
public func groupBy<V, R>(p: Proxy<X, (), (), V, R>, _ equals: (V, V) -> Bool) -> Proxy<X, (), (), V, Proxy<X, (), (), V, R>> {
    switch next(p) {
    case let .Left(x): return pure(pure(x))
    case let .Right((dO, q)):
        return span(yield(dO) >>- { _ in q }) { v in equals(dO, v) }
    }
}

/// Splits a Producer into two Producers after the first group of elements that are equal.
public func group<V: Equatable, R>(p: Proxy<X, (), (), V, R>) -> Proxy<X, (), (), V, Proxy<X, (), (), V, R>> {
    return groupBy(p) { v0, v1 in v0 == v1 }
}

/// Draws one element from the underlying Producer, returning `.None` if the Producer is empty
public func draw<V, I>() -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, V?> {
    return get() >>- { p in
        switch next(p) {
        case let .Left(x): return { _ in nil } <^> put(pure(x))
        case let .Right((dO, q)):
            return { _ in dO } <^> put(q)
        }
    }
}

/// Skips one element of the underlying Producer.  The final result of the returned pipe is `true`
/// if the operation was successful or `false` if the pipe was empty.
public func skip<V, I>() -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, Bool> {
    return { if let _ = $0 { return true } else { return false } } <^> draw()
}

/// Draw all elements from the underlying Producer
public func drawAll<V, I>() -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, List<V>> {
    return drawAllInner { v in v }
}

/// Drops all elements from the underlying Producer
public func skipAll<V, I>() -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, ()> {
    return draw() >>- { if let _ = $0 { return skipAll() } else { return pure(()) } }
}

/// Push back an element onto the underlying Producer
public func unDraw<V, I>(x: V) -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, ()> {
    return modify { p in yield(x) >>- { _ in p } }
}

/// Checks the first element of the pipe, but uses `unDraw` to push the element back so that it is 
/// available for the next `draw` command.
public func peek<V, I>() -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, V?> {
    return draw() >>- { k in if let v = k { return { _ in k } <^> unDraw(v) } else { return pure(k) } }
}

/// Returns whether the underlying Producer is empty
public func isEndOfInput<V, I>() -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, Bool> {
    return { if let _ = $0 { return true } else { return false } } <^> peek()
}

/// Fold all input values.
public func foldAll<A, V, I, R>(stepWith step: (A, V) -> A, initializeWith initial: A, extractWith extractor: A -> R) -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, R> {
    return draw() >>- {
        if let v = $0 {
            return foldAll(stepWith: step, initializeWith: step(initial, v), extractWith: extractor)
        } else {
            return pure(extractor(initial))
        }
    }
}

// this seems to required higher-kinded types to implement, even though none appear in its signature
/*public func toParser<V, I, R>(p: Proxy<(), V?, (), X, R>) -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, R> {
}*/

/// Convert a never-ending Consumer to a Parser
public func toParser<V, I>(endless p: Proxy<(), V, (), X, X>) -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, ()> {
    return IxState { q in ((), pure(runEffect(q >-> ({ closed($0) } <^> p)))) }
}

/// Implementation Details Follow

private func drawAllInner<V, I>(diffAs: List<V> -> List<V>) -> IxState<Proxy<X, (), (), V, I>, Proxy<X, (), (), V, I>, List<V>> {
    return draw() >>- {
        if let v = $0 {
            return drawAllInner(diffAs • curry(List.cons)(v))
        } else {
            return pure(diffAs([]))
        }
    }
}

