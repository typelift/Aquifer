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

    internal func fmap<N>(f: R -> N) -> GroupedProducerRepr<V, N> {
        switch self {
        case let .End(x): return GroupedProducerRepr<V, N>.End { _ in f(x()) }
        case let .More(p): return GroupedProducerRepr<V, N>.More { _ in { q in q.fmap(f) } <^> p() }
        }
    }

    internal func ap<N>(f: GroupedProducerRepr<V, R -> N>) -> GroupedProducerRepr<V, N> {
        switch (self, f) {
        case let (.End(x), .End(g)): return GroupedProducerRepr<V, N>.End { _ in g()(x()) }
        case let (.More(p), .End(g)): return GroupedProducerRepr<V, N>.More { _ in p().fmap { q in q.fmap(g()) } }
        case let (_, .More(g)): return GroupedProducerRepr<V, N>.More { _ in g().fmap { h in self.ap(h) } }
        }
    }

    internal func bind<N>(f: R -> GroupedProducerRepr<V, N>) -> GroupedProducerRepr<V, N> {
        switch self {
        case let .End(x): return f(x())
        case let .More(p): return GroupedProducerRepr<V, N>.More { _ in p().fmap { q in q.bind(f) } }
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

public func wrap<V, R>(p: @autoclosure () -> Proxy<X, (), (), V, GroupedProducer<V, R>>) -> GroupedProducer<V, R> {
    return GroupedProducer(GroupedProducerRepr.More { _ in p().fmap { q in q.repr } })
}

public func wrap<V, R>(p: @autoclosure () -> Proxy<X, (), (), V, R>) -> GroupedProducer<V, R> {
    return wrap(p().fmap { pure($0) })
}

public func delay<V, R>(p: @autoclosure () -> GroupedProducer<V, R>) -> GroupedProducer<V, R> {
    return GroupedProducer(p().repr)
}

extension GroupedProducer: Functor {
    public typealias B = Any

    public func fmap<N>(f: R -> N) -> GroupedProducer<V, N> {
        return GroupedProducer<V, N>(repr.fmap(f))
    }
}

public func <^><V, R, N>(f: R -> N, p: GroupedProducer<V, R>) -> GroupedProducer<V, N> {
    return p.fmap(f)
}

public prefix func <^><V, R, N>(p: GroupedProducer<V, R>) -> (R -> N) -> GroupedProducer<V, N> {
    return { f in f <^> p }
}

public postfix func <^><V, R, N>(f: R -> N) -> GroupedProducer<V, R> -> GroupedProducer<V, N> {
    return { p in f <^> p }
}

extension GroupedProducer: Pointed {
    public static func pure(x: R) -> GroupedProducer<V, R> {
        return Aquifer.pure(x)
    }
}

public func pure<V, R>(x: @autoclosure () -> R) -> GroupedProducer<V, R> {
    return GroupedProducer(GroupedProducerRepr.End(x))
}

extension GroupedProducer: Applicative {
    public func ap<N>(f: GroupedProducer<V, R -> N>) -> GroupedProducer<V, N> {
        return GroupedProducer<V, N>(self.repr.ap(f.repr))
    }
}

public func <*><V, R, N>(f: GroupedProducer<V, R -> N>, p: GroupedProducer<V, R>) -> GroupedProducer<V, N> {
    return p.ap(f)
}

public prefix func <*><V, R, N>(p: GroupedProducer<V, R>) -> GroupedProducer<V, R -> N> -> GroupedProducer<V, N> {
    return { f in f <*> p }
}

public postfix func <*><V, R, N>(f: GroupedProducer<V, R -> N>) -> GroupedProducer<V, R> -> GroupedProducer<V, N> {
    return { p in f <*> p }
}

extension GroupedProducer: Monad {
    public func bind<N>(f: R -> GroupedProducer<V, N>) -> GroupedProducer<V, N> {
        return GroupedProducer<V, N>(repr.bind { f($0).repr })
    }
}

public func >>-<V, R, N>(p: GroupedProducer<V, R>, f: R -> GroupedProducer<V, N>) -> GroupedProducer<V, N> {
    return p.bind(f)
}

public prefix func >>-<V, R, N>(f: R -> GroupedProducer<V, N>) -> GroupedProducer<V, R> -> GroupedProducer<V, N> {
    return { p in p >>- f }
}

public postfix func >>-<V, R, N>(p: GroupedProducer<V, R>) -> (R -> GroupedProducer<V, N>) -> GroupedProducer<V, N> {
    return { f in p >>- f }
}

public func flatten<V, R>(p: GroupedProducer<V, GroupedProducer<V, R>>) -> GroupedProducer<V, R> {
    return p.bind { q in q }
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

private func intercalatesRepr<V, R>(sep: Proxy<X, (), (), V, ()>, p: GroupedProducerRepr<V, R>) -> Proxy<X, (), (), V, R> {
    switch p {
    case let .End(x): return pure(x())
    case let .More(q): return q() >>- { intercalatesReprInner(sep, $0) }
    }
}

private func intercalatesReprInner<V, R>(sep: Proxy<X, (), (), V, ()>, p: GroupedProducerRepr<V, R>) -> Proxy<X, (), (), V, R> {
    switch p {
    case let .End(x): return pure(x())
    case let .More(q): return sep >>- { _ in q() >>- { intercalatesReprInner(sep, $0) } }
    }
}

public func intercalates<V, R>(sep: Proxy<X, (), (), V, ()>, p: GroupedProducer<V, R>) -> Proxy<X, (), (), V, R> {
    return intercalatesRepr(sep, p.repr)
}

private func takesRepr<V>(p: GroupedProducerRepr<V, ()>, n: Int) -> GroupedProducerRepr<V, ()> {
    if n > 0 {
        return GroupedProducerRepr.More { _ in
            switch p {
            case let .End(x): return pure(GroupedProducerRepr.End(x))
            case let .More(q): return pure(GroupedProducerRepr.More { _ in q().fmap { takesRepr($0, n - 1) } })
            }
        }
    } else {
        return GroupedProducerRepr.End { _ in () }
    }
}

public func takes<V>(p: GroupedProducer<V, ()>, n: Int) -> GroupedProducer<V, ()> {
    return GroupedProducer(takesRepr(p.repr, n))
}
