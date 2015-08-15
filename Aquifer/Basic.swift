//
//  Basic.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/28/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

// roughly `Pipes.Prelude`

import Foundation
import Swiftz

public func once<UO, UI, DI, DO, FR>(v: () -> FR) -> Proxy<UO, UI, DI, DO, FR> {
    return Proxy(ProxyRepr.Pure(v))
}

public func repeat_<UO, UI, DO, FR>(v: () -> DO) -> Proxy<UO, UI, (), DO, FR> {
    return once(v) >~ cat()
}

public func replicate<UO, UI, DO>(v: () -> DO, n: Int) -> Proxy<UO, UI, (), DO, ()> {
    return once(v) >~ take(n)
}

public func take<DT>(n: Int) -> Proxy<(), DT, (), DT, ()> {
    if n <= 0 {
        return pure(())
    } else {
        return await() >>- { yield($0) >>- { _ in take(n - 1) } }
    }
}

public func takeWhile<DT>(predicate: DT -> Bool) -> Proxy<(), DT, (), DT, ()> {
    return await() >>- { v in
        if predicate(v) {
            return yield(v) >>- { _ in takeWhile(predicate) }
        } else {
            return pure(())
        }
    }
}

private func dropInner<DT>(n: Int) -> Proxy<(), DT, (), DT, ()> {
    if n <= 0 {
        return pure(())
    } else {
        return await() >>- { _ in dropInner(n - 1) }
    }
}

public func drop<DT, FR>(n: Int) -> Proxy<(), DT, (), DT, FR> {
    return dropInner(n) >>- { _ in cat() }
}

public func dropWhile<DT, FR>(predicate: DT -> Bool) -> Proxy<(), DT, (), DT, FR> {
    return await() >>- { v in
        if predicate(v) {
            return dropWhile(predicate)
        } else {
            return yield(v) >>- { _ in cat() }
        }
    }
}

public func concat<S: SequenceType, FR>() -> Proxy<(), S, (), S.Generator.Element, FR> {
    return for_(cat(), each)
}

public func drain<UI, DI, DO, FR>() -> Proxy<(), UI, DI, DO, FR> {
    return for_(cat()) { discard($0) }
}

public func map<UI, DO, FR>(f: UI -> DO) -> Proxy<(), UI, (), DO, FR> {
    return for_(cat()) { v in yield(f(v)) }
}

public func mapMany<UI, S: SequenceType, FR>(f: UI -> S) -> Proxy<(), UI, (), S.Generator.Element, FR> {
    return for_(cat()) { each(f($0)) }
}

public func filter<DT, FR>(predicate: DT -> Bool) -> Proxy<(), DT, (), DT, FR> {
    return for_(cat()) { v in
        if predicate(v) {
            return yield(v)
        } else {
            return pure(())
        }
    }
}

public func elemIndices<UI: Equatable, FR>(@autoclosure(escaping) x: () -> UI) -> Proxy<(), UI, (), Int, FR> {
    return findIndices { x() == $0 }
}

public func findIndicesInner<UI, FR>(predicate: UI -> Bool, _ n: Int) -> Proxy<(), UI, (), Int, FR> {
    return await() >>- {
        if predicate($0) {
            return yield(n) >>- { _ in findIndicesInner(predicate, n + 1) }
        } else {
            return findIndicesInner(predicate, n + 1)
        }
    }
}

public func findIndices<UI, FR>(predicate: UI -> Bool) -> Proxy<(), UI, (), Int, FR> {
    return findIndicesInner(predicate, 0)
}

public func scan<A, UI, DO, FR>(stepWith step: (A, UI) -> A, initializeWith initial: A, extractWith extractor: A -> DO) -> Proxy<(), UI, (), DO, FR> {
    return yield(extractor(initial)) >>- { _ in await() >>- { scan(stepWith: step, initializeWith: step(initial, $0), extractWith: extractor) } }
}

public func chain<DT, FR>(action: DT -> Void) -> Proxy<(), DT, (), DT, FR> {
    return for_(cat()) { action($0); return yield($0) }
}

public func description<UI: CustomStringConvertible, FR>() -> Proxy<(), UI, (), String, FR> {
    return map { $0.description }
}

public func debugDescription<UI: CustomDebugStringConvertible, FR>() -> Proxy<(), UI, (), String, FR> {
    return map { $0.debugDescription }
}

private func foldRepr<A, V, R>(p: ProxyRepr<X, (), (), V, ()>, stepWith step: (A, V) -> A, initializeWith initial: A, extractWith extractor: A -> R) -> R {
    switch p {
    case let .Request(uO, _): return closed(uO())
    case let .Respond(dO, fDI): return foldRepr(fDI(()), stepWith: step, initializeWith: step(initial, dO()), extractWith: extractor)
    case .Pure(_): return extractor(initial)
    }
}

public func fold<A, V, R>(p: Proxy<X, (), (), V, ()>, stepWith step: (A, V) -> A, initializeWith initial: A, extractWith extractor: A -> R) -> R {
    return foldRepr(p.repr, stepWith: step, initializeWith: initial, extractWith: extractor)
}

private func foldRetRepr<A, V, FR, R>(p: ProxyRepr<X, (), (), V, FR>, stepWith step: (A, V) -> A, initializeWith initial: A, extractWith extractor: A -> R) -> (R, FR) {
    switch p {
    case let .Request(uO, _): return closed(uO())
    case let .Respond(dO, fDI): return foldRetRepr(fDI(()), stepWith: step, initializeWith: step(initial, dO()), extractWith: extractor)
    case let .Pure(x): return (extractor(initial), x())
    }
}

public func foldRet<A, V, FR, R>(p: Proxy<X, (), (), V, FR>, stepWith step: (A, V) -> A, initializeWith initial: A, extractWith extractor: A -> R) -> (R, FR) {
    return foldRetRepr(p.repr, stepWith: step, initializeWith: initial, extractWith: extractor)
}

public func isEmpty<V>(p: Proxy<X, (), (), V, ()>) -> Bool {
    return next(p).isLeft
}

public func all<V>(p: Proxy<X, (), (), V, ()>, predicate: V -> Bool) -> Bool {
    return isEmpty(p >-> filter { !predicate($0) })
}

public func any<V>(p: Proxy<X, (), (), V, ()>, predicate: V -> Bool) -> Bool {
    return !isEmpty(p >-> filter(predicate))
}

public func not<FR>() -> Proxy<(), Bool, (), Bool, FR> {
    return map(!)
}

public func and(p: Proxy<X, (), (), Bool, ()>) -> Bool {
    return all(p) { b in b }
}

public func or(p: Proxy<X, (), (), Bool, ()>) -> Bool {
    return any(p) { b in b }
}

public func elem<V: Equatable>(p: Proxy<X, (), (), V, ()>, _ x: V) -> Bool {
    return any(p) { x == $0 }
}

public func notElem<V: Equatable>(p: Proxy<X, (), (), V, ()>, _ x: V) -> Bool {
    return all(p) { x != $0 }
}

public func find<V>(p: Proxy<X, (), (), V, ()>, _ predicate: V -> Bool) -> V? {
    return head(p >-> filter(predicate))
}

public func findIndex<V>(p: Proxy<X, (), (), V, ()>, _ predicate: V -> Bool) -> Int? {
    return head(p >-> findIndices(predicate))
}

public func head<V>(p: Proxy<X, (), (), V, ()>) -> V? {
    switch next(p) {
    case .Left(_): return nil
    case let .Right(k): return k.0
    }
}

private func lastInner<V>(x: V, _ p: Proxy<X, (), (), V, ()>) -> V? {
    switch next(p) {
    case .Left(_): return x
    case let .Right((dO, q)):
        return lastInner(dO, q)
    }
}

public func last<V>(p: Proxy<X, (), (), V, ()>) -> V? {
    switch next(p) {
    case .Left(_): return nil
    case let .Right((dO, q)):
        return lastInner(dO, q)
    }
}

public func length<V>(p: Proxy<X, (), (), V, ()>) -> Int {
    return fold(p, stepWith: { n, _ in n + 1 }, initializeWith: 0, extractWith: { $0 })
}

public func maximum<V: Comparable>(p: Proxy<X, (), (), V, ()>) -> V? {
    func step(x: V?, _ v: V) -> V? {
        if let w = x {
            return max(v, w)
        } else {
            return x
        }
    }
    return fold(p, stepWith: step, initializeWith: nil, extractWith: { $0 })
}

public func minimum<V: Comparable>(p: Proxy<X, (), (), V, ()>) -> V? {
    func step(x: V?, _ v: V) -> V? {
        if let w = x {
            return min(v, w)
        } else {
            return x
        }
    }
    return fold(p, stepWith: step, initializeWith: nil, extractWith: { $0 })
}

public func mconcat<V: Monoid>(p: Proxy<X, (), (), V, ()>) -> V {
    return fold(p, stepWith: { $0.op($1) }, initializeWith: V.mempty, extractWith: { $0 })
}

public func sum<V: NumericType>(p: Proxy<X, (), (), V, ()>) -> V {
    return fold(p, stepWith: { $0.plus($1) }, initializeWith: V.zero, extractWith: { $0 })
}

public func product<V: NumericType>(p: Proxy<X, (), (), V, ()>) -> V {
    return fold(p, stepWith: { $0.times($1) }, initializeWith: V.one, extractWith: { $0 })
}


private func toListRepr<V>(p: ProxyRepr<X, (), (), V, ()>) -> List<V> {
    switch p {
    case let .Request(uO, _): return closed(uO())
    case let .Respond(dO, fDI): return List(dO(), toListRepr(fDI(())))
    case .Pure(_): return []
    }
}

public func toList<V>(p: Proxy<X, (), (), V, ()>) -> List<V> {
    return toListRepr(p.repr)
}

public func zip<V0, V1, R>(p: Proxy<X, (), (), V0, R>, _ q: Proxy<X, (), (), V1, R>) -> Proxy<X, (), (), (V0, V1), R> {
    return zipWith(p, q) { ($0, $1) }
}

public func zipWith<V0, V1, V2, R>(p: Proxy<X, (), (), V0, R>, _ q: Proxy<X, (), (), V1, R>, _ f: (V0, V1) -> V2) -> Proxy<X, (), (), V2, R> {
    switch next(p) {
    case let .Left(x): return pure(x)
    case let .Right((dO0, r)):
        switch next(q) {
        case let .Left(y): return pure(y)
        case let .Right((dO1, s)):
            return yield(f(dO0, dO1)) >>- { _ in zipWith(r, s, f) }
        }
    }
}

// this seems to required higher-kinded types to implement, even though none appear in its signature
/*public func tee<V, R>(p: Proxy<(), V, (), X, R>) -> Proxy<(), V, (), V, R> {
}*/

// this seems to required higher-kinded types to implement, even though none appear in its signature
/*public func generalize<UT, UI, DO, FR>(p: Proxy<(), UI, (), DO, FR>) -> Proxy<UT, UI, UT, DO, FR> {
}*/
