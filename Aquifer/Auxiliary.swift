//
//  Auxiliary.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/29/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

// roughly `Pipes.Extras`

import Foundation
import Swiftz

public func arr<A, B, R>(f: A -> B) -> Proxy<(), A, (), B, R> {
    return map(f)
}

private func leftInner<A, B, C>() -> Proxy<(), Either<A, C>, (), Either<B, C>, A> {
    return await() >>- {
        switch $0 {
        case let .Left(x): return pure(x)
        case let .Right(y): return yield(Either.Right(y)) >>- { _ in leftInner() }
        }
    }
}

public func left<A, B, C, R>(p: Proxy<(), A, (), B, R>) -> Proxy<(), Either<A, C>, (), Either<B, C>, R> {
    return leftInner() >~ for_(p) { v in yield(Either.Left(v)) }
}

private func rightInner<A, B, C>() -> Proxy<(), Either<C, A>, (), Either<C, B>, A> {
    return await() >>- {
        switch $0 {
        case let .Left(x): return yield(Either.Left(x)) >>- { _ in rightInner() }
        case let .Right(y): return pure(y)
        }
    }
}

public func right<A, B, C, R>(p: Proxy<(), A, (), B, R>) -> Proxy<(), Either<C, A>, (), Either<C, B>, R> {
    return rightInner() >~ for_(p) { v in yield(Either.Right(v)) }
}

infix operator +++ {
associativity left
precedence 180
}

public func +++ <A, B, C, D, R>(p: Proxy<(), A, (), B, R>, q: Proxy<(), C, (), D, R>) -> Proxy<(), Either<A, C>, (), Either<B, D>, R> {
    return left(p) >-> right(q)
}

public func mapInput<UO, UI, DI, DO, NI, FR>(p: Proxy<UO, UI, DI, DO, FR>, _ f: NI -> UI) -> Proxy<UO, NI, DI, DO, FR> {
    return { request($0).fmap(f) } >>| p
}

public func mapOutput<UO, UI, DI, DO, NO, FR>(p: Proxy<UO, UI, DI, DO, FR>, _ f: DO -> NO) -> Proxy<UO, UI, DI, NO, FR> {
    return p |>> { v in respond(f(v)) }
}

public func scan1i<DT, FR>(stepWith step: (DT, DT) -> DT) -> Proxy<(), DT, (), DT, FR> {
    return scan1(stepWith: step, initializeWith: identity, extractWith: identity)
}

public func scan1<A, UI, DO, FR>(stepWith step: (A, UI) -> A, initializeWith initial: UI -> A, extractWith extractor: A -> DO) -> Proxy<(), UI, (), DO, FR> {
    return await() >>- { scan(stepWith: step, initializeWith: initial($0), extractWith: extractor) }
}
