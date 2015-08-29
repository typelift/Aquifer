//
//  Grouping.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/18/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

// roughly `Pipes.Group`

import Swiftz

/// A producer that uses the Free Monad Transformer (unrepresentable in Swift) to delimit groupings
/// of produced values.
///
/// Ideally:
///
///    typealias GroupedProducer<V, R> = Free<Producer<V, $0>, R>
public struct GroupedProducer<V, R> {
    private let _repr : () -> GroupedProducerRepr<V, R>

    internal init(@autoclosure(escaping) _ r : () -> GroupedProducerRepr<V, R>) {
        _repr = r
    }

    internal var repr: GroupedProducerRepr<V, R> {
        return _repr()
    }
}

/// Wraps a `Producer<V, GroupedProducer<V, R>>` in a `GroupedProducer`.
public func wrap<V, R>(@autoclosure(escaping) p : () -> Producer<V, GroupedProducer<V, R>>.T) -> GroupedProducer<V, R> {
    return GroupedProducer(GroupedProducerRepr.More { _ in p().fmap { q in q.repr } })
}

/// Wraps a `Producer<V, R>` in a `GroupedProducer`.
public func wrap<V, R>(@autoclosure(escaping) p : () -> Producer<V, R>.T) -> GroupedProducer<V, R> {
    return wrap(p().fmap { pure($0) })
}

/// Forces a `GroupedProducer` to evaluate lazily.
public func delay<V, R>(@autoclosure(escaping) p : () -> GroupedProducer<V, R>) -> GroupedProducer<V, R> {
    return GroupedProducer(p().repr)
}

/// Pull the first value out of the given `GroupedProducer`.
///
/// If the subsequent state of the `Producer` is a single value or termination, the result is 
/// `.Left` containing the value.  Otherwise the result is `.Right` containing the value and the 
/// next state of the `Producer`.
public func next<V, R>(p : GroupedProducer<V, R>) -> Either<R, Producer<V, GroupedProducer<V, R>>.T> {
    switch p.repr {
    case let .End(x): return .Left(x())
    case let .More(q): return .Right({ GroupedProducer($0) } <^> q())
    }
}

/// Returns a `GroupedProducer` that discards all incoming values.
public func discard<V>(_ : Any) -> GroupedProducer<V, ()> {
    return GroupedProducer(GroupedProducerRepr.End { _ in () })
}

/// Splits a 'Producer' into a `GroupedProducer` using the given equality predicate.
public func groupsBy<V, R>(p : Producer<V, R>.T, _ equals : (V, V) -> Bool) -> GroupedProducer<V, R> {
    return GroupedProducer(groupsByRepr(p, equals))
}

/// Splits a 'Producer' into a `GroupedProducer`.
public func groups<V : Equatable, R>(p : Producer<V, R>.T) -> GroupedProducer<V, R> {
    return groupsBy(p) { v0, v1 in v0 == v1  }
}

/// Splits a 'Producer' into a `GroupedProducer` of runs of a given length.
public func chunksOf<V, R>(p : Producer<V, R>.T, _ n : Int) -> GroupedProducer<V, R> {
    return GroupedProducer(chunksOfRepr(p, n))
}

/// Joins a `GroupedProducer` into a single 'Producer'.
public func concats<V, R>(p : GroupedProducer<V, R>) -> Producer<V, R>.T {
    return concatsRepr(p.repr)
}

/// Joins a `GroupedProducer` into a single 'Producer' by intercalating a 'Producer' in between them.
public func intercalates<V, R>(sep : Producer<V, ()>.T, _ p : GroupedProducer<V, R>) -> Producer<V, R>.T {
    return intercalatesRepr(sep, p.repr)
}

/// Returns a `GroupedProducer` that only takes the first `n` elements of the given 
/// `GroupedProducer`.
public func takes<V>(p : GroupedProducer<V, ()>, _ n : Int) -> GroupedProducer<V, ()> {
    return GroupedProducer(takesRepr(p.repr, n))
}

/// Returns a `GroupedProducer` that only takes the first `n` elements of the given
/// `GroupedProducer`.
///
/// Like `takes` but preserves the return value of the `GroupedProducer`.
public func takesRet<V, R>(p : GroupedProducer<V, R>, _ n : Int) -> GroupedProducer<V, R> {
    return GroupedProducer(takesRetRepr(p.repr, n))
}

/// Returns a `GroupedProducer` that removes the first `n` elements of the given `GroupedProducer`.
public func drops<V, R>(p : GroupedProducer<V, R>, _ n : Int) -> GroupedProducer<V, R> {
    return GroupedProducer(dropsRepr(p.repr, n))
}

extension GroupedProducer/*: Functor*/ {
    /*public typealias B = Any*/

    public func fmap<N>(f : R -> N) -> GroupedProducer<V, N> {
        return GroupedProducer<V, N>(self.repr.fmap(f))
    }
}

public func <^> <V, R, N>(f : R -> N, p : GroupedProducer<V, R>) -> GroupedProducer<V, N> {
    return p.fmap(f)
}

extension GroupedProducer/*: Pointed*/ {
    public static func pure(x : R) -> GroupedProducer<V, R> {
        return Aquifer.pure(x)
    }
}

public func pure<V, R>(@autoclosure(escaping) x : () -> R) -> GroupedProducer<V, R> {
    return GroupedProducer(GroupedProducerRepr.End(x))
}

extension GroupedProducer/*: Applicative*/ {
    public func ap<N>(f : GroupedProducer<V, R -> N>) -> GroupedProducer<V, N> {
        return GroupedProducer<V, N>(self.repr.ap(f.repr))
    }
}

public func <*> <V, R, N>(f : GroupedProducer<V, R -> N>, p : GroupedProducer<V, R>) -> GroupedProducer<V, N> {
    return p.ap(f)
}

extension GroupedProducer/*: Monad*/ {
    public func bind<N>(f : R -> GroupedProducer<V, N>) -> GroupedProducer<V, N> {
        return GroupedProducer<V, N>(self.repr.bind { f($0).repr })
    }
}

public func >>- <V, R, N>(p : GroupedProducer<V, R>, f : R -> GroupedProducer<V, N>) -> GroupedProducer<V, N> {
    return p.bind(f)
}

/// Flattens a `GroupedProducer` of `GroupedProducers` by one level.
public func flatten<V, R>(p : GroupedProducer<V, GroupedProducer<V, R>>) -> GroupedProducer<V, R> {
    return p.bind { q in q }
}

// MARK: - Implementation Details Follow

internal enum GroupedProducerRepr<V, R> {
    case End(() -> R)
    case More(() -> Producer<V, GroupedProducerRepr<V, R>>.T)
    
    internal func fmap<N>(f : R -> N) -> GroupedProducerRepr<V, N> {
        switch self {
        case let .End(x): return GroupedProducerRepr<V, N>.End { _ in f(x()) }
        case let .More(p): return GroupedProducerRepr<V, N>.More { _ in { q in q.fmap(f) } <^> p() }
        }
    }
    
    internal func ap<N>(f : GroupedProducerRepr<V, R -> N>) -> GroupedProducerRepr<V, N> {
        switch (self, f) {
        case let (.End(x), .End(g)): return GroupedProducerRepr<V, N>.End { _ in g()(x()) }
        case let (.More(p), .End(g)): return GroupedProducerRepr<V, N>.More { _ in p().fmap { q in q.fmap(g()) } }
        case let (_, .More(g)): return GroupedProducerRepr<V, N>.More { _ in g().fmap { h in self.ap(h) } }
        }
    }
    
    internal func bind<N>(f : R -> GroupedProducerRepr<V, N>) -> GroupedProducerRepr<V, N> {
        switch self {
        case let .End(x): return f(x())
        case let .More(p): return GroupedProducerRepr<V, N>.More { _ in p().fmap { q in q.bind(f) } }
        }
    }
}

private func groupsByRepr<V, R>(p : Producer<V, R>.T, _ equals : (V, V) -> Bool) -> GroupedProducerRepr<V, R> {
    switch next(p) {
    case let .Left(x): return GroupedProducerRepr.End { _ in x }
    case let .Right((dO, q)):
        return GroupedProducerRepr.More { _ in { r in groupsByRepr(r, equals) } <^> (span(yield(dO) >>- { _ in q }) { v in equals(dO, v) }) }
    }
}

private func chunksOfRepr<V, R>(p : Producer<V, R>.T, _ n : Int) -> GroupedProducerRepr<V, R> {
    switch next(p) {
    case let .Left(x): return GroupedProducerRepr.End { _ in x }
    case let .Right((dO, q)):
        return GroupedProducerRepr.More { _ in { r in chunksOfRepr(q, n) } <^> splitAt(yield(dO) >>- { _ in q }, n) }
    }
}

private func concatsRepr<V, R>(p : GroupedProducerRepr<V, R>) -> Producer<V, R>.T {
    switch p {
    case let .End(x): return pure(x())
    case let .More(q): return q() >>- concatsRepr
    }
}

private func intercalatesRepr<V, R>(sep : Producer<V, ()>.T, _ p : GroupedProducerRepr<V, R>) -> Producer<V, R>.T {
    switch p {
    case let .End(x): return pure(x())
    case let .More(q): return q() >>- { intercalatesReprInner(sep, $0) }
    }
}

private func intercalatesReprInner<V, R>(sep : Producer<V, ()>.T, _ p : GroupedProducerRepr<V, R>) -> Producer<V, R>.T {
    switch p {
    case let .End(x): return pure(x())
    case let .More(q): return sep >>- { _ in q() >>- { intercalatesReprInner(sep, $0) } }
    }
}

private func takesRepr<V>(p : GroupedProducerRepr<V, ()>, _ n : Int) -> GroupedProducerRepr<V, ()> {
    if n > 0 {
        switch p {
        case let .End(x): return GroupedProducerRepr.End(x)
        case let .More(q): return GroupedProducerRepr.More { _ in q().fmap { takesRepr($0, n - 1) } }
        }
    } else {
        return GroupedProducerRepr.End { _ in () }
    }
}

private func takesRetRepr<V, R>(p : GroupedProducerRepr<V, R>, _ n : Int) -> GroupedProducerRepr<V, R> {
    if n > 0 {
        switch p {
        case let .End(x): return GroupedProducerRepr.End(x)
        case let .More(q): return GroupedProducerRepr.More { _ in q().fmap { takesRetRepr($0, n - 1) } }
        }
    } else {
        return takesRetReprInner(p)
    }
}

private func takesRetReprInner<V, R>(p : GroupedProducerRepr<V, R>) -> GroupedProducerRepr<V, R> {
    switch p {
    case let .End(x): return GroupedProducerRepr.End(x)
    case let .More(q): return takesRetReprInner(runEffect(for_(q()) { discard($0) }))
    }
}

private func dropsRepr<V, R>(p : GroupedProducerRepr<V, R>, _ n : Int) -> GroupedProducerRepr<V, R> {
    if n <= 0 {
        return p
    } else {
        switch p {
        case let .End(x): return .End(x)
        case let .More(q): return dropsRepr(runEffect(for_(q()) { discard($0) }), n - 1)
        }
    }
}
