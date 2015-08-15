//
//  Grouping.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/18/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

// roughly `Pipes.Group`

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

    internal init(@autoclosure(escaping) _ r: () -> GroupedProducerRepr<V, R>) {
        _repr = r
    }

    internal var repr: GroupedProducerRepr<V, R> {
        return _repr()
    }
}

public func wrap<V, R>(@autoclosure(escaping) p: () -> Proxy<X, (), (), V, GroupedProducer<V, R>>) -> GroupedProducer<V, R> {
    return GroupedProducer(GroupedProducerRepr.More { _ in p().fmap { q in q.repr } })
}

public func wrap<V, R>(@autoclosure(escaping) p: () -> Proxy<X, (), (), V, R>) -> GroupedProducer<V, R> {
    return wrap(p().fmap { pure($0) })
}

public func delay<V, R>(@autoclosure(escaping) p: () -> GroupedProducer<V, R>) -> GroupedProducer<V, R> {
    return GroupedProducer(p().repr)
}

public func next<V, R>(p: GroupedProducer<V, R>) -> Either<R, Proxy<X, (), (), V, GroupedProducer<V, R>>> {
    switch p.repr {
    case let .End(x): return .Left(x())
    case let .More(q): return .Right({ GroupedProducer($0) } <^> q())
    }
}

public func discard<V>(_: Any) -> GroupedProducer<V, ()> {
    return GroupedProducer(GroupedProducerRepr.End { _ in () })
}

extension GroupedProducer/*: Functor*/ {
    /*public typealias B = Any*/

    public func fmap<N>(f: R -> N) -> GroupedProducer<V, N> {
        return GroupedProducer<V, N>(self.repr.fmap(f))
    }
}

public func <^> <V, R, N>(f: R -> N, p: GroupedProducer<V, R>) -> GroupedProducer<V, N> {
    return p.fmap(f)
}

extension GroupedProducer/*: Pointed*/ {
    public static func pure(x: R) -> GroupedProducer<V, R> {
        return Aquifer.pure(x)
    }
}

public func pure<V, R>(@autoclosure(escaping) x: () -> R) -> GroupedProducer<V, R> {
    return GroupedProducer(GroupedProducerRepr.End(x))
}

extension GroupedProducer/*: Applicative*/ {
    public func ap<N>(f: GroupedProducer<V, R -> N>) -> GroupedProducer<V, N> {
        return GroupedProducer<V, N>(self.repr.ap(f.repr))
    }
}

public func <*> <V, R, N>(f: GroupedProducer<V, R -> N>, p: GroupedProducer<V, R>) -> GroupedProducer<V, N> {
    return p.ap(f)
}

extension GroupedProducer/*: Monad*/ {
    public func bind<N>(f: R -> GroupedProducer<V, N>) -> GroupedProducer<V, N> {
        return GroupedProducer<V, N>(self.repr.bind { f($0).repr })
    }
}

public func >>- <V, R, N>(p: GroupedProducer<V, R>, f: R -> GroupedProducer<V, N>) -> GroupedProducer<V, N> {
    return p.bind(f)
}

public func flatten<V, R>(p: GroupedProducer<V, GroupedProducer<V, R>>) -> GroupedProducer<V, R> {
    return p.bind { q in q }
}

private func groupsByRepr<V, R>(p: Proxy<X, (), (), V, R>, _ equals: (V, V) -> Bool) -> GroupedProducerRepr<V, R> {
    switch next(p) {
    case let .Left(x): return GroupedProducerRepr.End { _ in x }
    case let .Right((dO, q)):
        return GroupedProducerRepr.More { _ in { r in groupsByRepr(r, equals) } <^> (span(yield(dO) >>- { _ in q }) { v in equals(dO, v) }) }
    }
}

public func groupsBy<V, R>(p: Proxy<X, (), (), V, R>, _ equals: (V, V) -> Bool) -> GroupedProducer<V, R> {
    return GroupedProducer(groupsByRepr(p, equals))
}

public func groups<V: Equatable, R>(p: Proxy<X, (), (), V, R>) -> GroupedProducer<V, R> {
    return groupsBy(p) { v0, v1 in v0 == v1  }
}

private func chunksOfRepr<V, R>(p: Proxy<X, (), (), V, R>, _ n: Int) -> GroupedProducerRepr<V, R> {
    switch next(p) {
    case let .Left(x): return GroupedProducerRepr.End { _ in x }
    case let .Right((dO, q)):
        return GroupedProducerRepr.More { _ in { r in chunksOfRepr(q, n) } <^> splitAt(yield(dO) >>- { _ in q }, n) }
    }
}

public func chunksOf<V, R>(p: Proxy<X, (), (), V, R>, _ n: Int) -> GroupedProducer<V, R> {
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

private func intercalatesRepr<V, R>(sep: Proxy<X, (), (), V, ()>, _ p: GroupedProducerRepr<V, R>) -> Proxy<X, (), (), V, R> {
    switch p {
    case let .End(x): return pure(x())
    case let .More(q): return q() >>- { intercalatesReprInner(sep, $0) }
    }
}

private func intercalatesReprInner<V, R>(sep: Proxy<X, (), (), V, ()>, _ p: GroupedProducerRepr<V, R>) -> Proxy<X, (), (), V, R> {
    switch p {
    case let .End(x): return pure(x())
    case let .More(q): return sep >>- { _ in q() >>- { intercalatesReprInner(sep, $0) } }
    }
}

public func intercalates<V, R>(sep: Proxy<X, (), (), V, ()>, _ p: GroupedProducer<V, R>) -> Proxy<X, (), (), V, R> {
    return intercalatesRepr(sep, p.repr)
}

private func takesRepr<V>(p: GroupedProducerRepr<V, ()>, _ n: Int) -> GroupedProducerRepr<V, ()> {
    if n > 0 {
        switch p {
        case let .End(x): return GroupedProducerRepr.End(x)
        case let .More(q): return GroupedProducerRepr.More { _ in q().fmap { takesRepr($0, n - 1) } }
        }
    } else {
        return GroupedProducerRepr.End { _ in () }
    }
}

public func takes<V>(p: GroupedProducer<V, ()>, _ n: Int) -> GroupedProducer<V, ()> {
    return GroupedProducer(takesRepr(p.repr, n))
}

private func takesRetRepr<V, R>(p: GroupedProducerRepr<V, R>, _ n: Int) -> GroupedProducerRepr<V, R> {
    if n > 0 {
        switch p {
        case let .End(x): return GroupedProducerRepr.End(x)
        case let .More(q): return GroupedProducerRepr.More { _ in q().fmap { takesRetRepr($0, n - 1) } }
        }
    } else {
        return takesRetReprInner(p)
    }
}

private func takesRetReprInner<V, R>(p: GroupedProducerRepr<V, R>) -> GroupedProducerRepr<V, R> {
    switch p {
    case let .End(x): return GroupedProducerRepr.End(x)
    case let .More(q): return takesRetReprInner(runEffect(for_(q()) { discard($0) }))
    }
}

public func takesRet<V, R>(p: GroupedProducer<V, R>, _ n: Int) -> GroupedProducer<V, R> {
    return GroupedProducer(takesRetRepr(p.repr, n))
}

private func dropsRepr<V, R>(p: GroupedProducerRepr<V, R>, _ n: Int) -> GroupedProducerRepr<V, R> {
    if n <= 0 {
        return p
    } else {
        switch p {
        case let .End(x): return .End(x)
        case let .More(q): return dropsRepr(runEffect(for_(q()) { discard($0) }), n - 1)
        }
    }
}

public func drops<V, R>(p: GroupedProducer<V, R>, _ n: Int) -> GroupedProducer<V, R> {
    return GroupedProducer(dropsRepr(p.repr, n))
}
