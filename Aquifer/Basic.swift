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

public func repeat<UO, UI, DO, FR>(v: () -> DO) -> Proxy<UO, UI, (), DO, FR> {
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
    return for_(cat(), discard)
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

public func elemIndices<UI: Equatable, FR>(x: @autoclosure () -> UI) -> Proxy<(), UI, (), Int, FR> {
    return findIndices { x() == $0 }
}

public func findIndicesInner<UI, FR>(predicate: UI -> Bool, n: Int) -> Proxy<(), UI, (), Int, FR> {
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

public func description<UI: Printable, FR>() -> Proxy<(), UI, (), String, FR> {
    return map { $0.description }
}

public func debugDescription<UI: DebugPrintable, FR>() -> Proxy<(), UI, (), String, FR> {
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
    case let .Request(uO, fUI): return closed(uO())
    case let .Respond(dO, fDI): return foldRetRepr(fDI(()), stepWith: step, initializeWith: step(initial, dO()), extractWith: extractor)
    case let .Pure(x): return (extractor(initial), x())
    }
}

public func foldRet<A, V, FR, R>(p: Proxy<X, (), (), V, FR>, stepWith step: (A, V) -> A, initializeWith initial: A, extractWith extractor: A -> R) -> (R, FR) {
    return foldRetRepr(p.repr, stepWith: step, initializeWith: initial, extractWith: extractor)
}
