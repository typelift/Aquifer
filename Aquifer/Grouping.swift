//
//  Grouping.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/18/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

import Foundation
import Swiftz

internal enum GroupedProducerRepr<V, R> {
    case End(() -> R)
    case More(() -> Proxy<X, (), (), V, GroupedProducerRepr<V, R>>)

    internal func fmapRepr<N>(f: R -> N) -> GroupedProducerRepr<V, N> {
        switch self {
        case let .End(x): return GroupedProducerRepr<V, N>.End { _ in f(x()) }
        case let .More(p): return GroupedProducerRepr<V, N>.More { _ in { q in q.fmapRepr(f) } <^> p() }
        }
    }
}

public struct GroupedProducer<V, R> {
    private let _repr: () -> GroupedProducerRepr<V, R>

    internal init(_ r: @autoclosure () -> GroupedProducerRepr<V, R>) {
        _repr = r
    }

    internal var repr: GroupedProducerRepr<V, R> {
        return _repr()
    }
}

public func delay<V, R>(p: @autoclosure () -> GroupedProducer<V, R>) -> GroupedProducer<V, R> {
    return GroupedProducer(p().repr)
}

extension GroupedProducer: Functor {
    public typealias B = Any

    public func fmap<N>(f: R -> N) -> GroupedProducer<V, N> {
        return GroupedProducer<V, N>(repr.fmapRepr(f))
    }
}

public func <^><V, R, N>(f: R -> N, p: GroupedProducer<V, R>) -> GroupedProducer<V, N> {
    return p.fmap(f)
}

private func groupsByRepr<V, R>(p: Proxy<X, (), (), V, R>, equals: (V, V) -> Bool) -> GroupedProducerRepr<V, R> {
    switch next(p) {
    case let .Left(x): return GroupedProducerRepr.End { _ in x.value }
    case let .Right(k):
        let (dO, q) = k.value
        return GroupedProducerRepr.More { _ in { r in groupsByRepr(r, equals) } <^> (span(yield(dO) >>- { _ in q }) { v in equals(dO, v) }) }
    }
}

public func groupsBy<V, R>(p: Proxy<X, (), (), V, R>, equals: (V, V) -> Bool) -> GroupedProducer<V, R> {
    return GroupedProducer(groupsByRepr(p, equals))
}

public func groups<V: Equatable, R>(p: Proxy<X, (), (), V, R>) -> GroupedProducer<V, R> {
    return groupsBy(p) { v0, v1 in v0 == v1  }
}

private func chunksOfRepr<V, R>(p: Proxy<X, (), (), V, R>, n: Int) -> GroupedProducerRepr<V, R> {
    switch next(p) {
    case let .Left(x): return GroupedProducerRepr.End { _ in x.value }
    case let .Right(k):
        let (dO, q) = k.value
        return GroupedProducerRepr.More { _ in { r in chunksOfRepr(q, n) } <^> splitAt(yield(dO) >>- { _ in q }, n) }
    }
}

public func chunksOf<V, R>(p: Proxy<X, (), (), V, R>, n: Int) -> GroupedProducer<V, R> {
    return GroupedProducer(chunksOfRepr(p, n))
}

private func concatsRepr<V, R>(p: GroupedProducerRepr<V, R>) -> Proxy<X, (), (), V, R> {
    switch p {
    case let .End(x): return pure(x())
    case let .More(q): return q() >>- concatsRepr
    }
}

public func concats<V, R>(p: GroupedProducer<V, R>) -> Proxy<X, (), (), V, R> {
    return concatsRepr(p.repr)
}
