//
//  Simple.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/26/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

import Foundation
import Swiftz

public func next<DO, FR>(p: Proxy<X, (), (), DO, FR>) -> Either<FR, (DO, Proxy<X, (), (), DO, FR>)> {
    switch p.repr {
    case let .Request(uO, _): return closed(uO)
    case let .Respond(dO, fDI): return .Right(Box((dO(), Proxy(fDI(())))))
    case let .Pure(x): return .Left(Box(x()))
    }
}

private func eachRepr<G: GeneratorType>(var gen: G) -> ProxyRepr<X, (), (), G.Element, ()> {
    if let v = gen.next() {
        return ProxyRepr.Respond(const(v)) { _ in eachRepr(gen) }
    } else {
        return ProxyRepr.Pure(const(()))
    }
}

public func each<S: SequenceType>(seq: S) -> Proxy<X, (), (), S.Generator.Element, ()> {
    return Proxy(eachRepr(seq.generate()))
}

public func each<V>(seq: V...) -> Proxy<X, (), (), V, ()> {
    return each(seq)
}

public func yield<UO, UI, DO>(dO: @autoclosure () -> DO) -> Proxy<UO, UI, (), DO, ()> {
    return respond(dO)
}

public func await<UI, DI, DO>() -> Proxy<(), UI, DI, DO, UI> {
    return request(())
}

public func cat<DT, FR>() -> Proxy<(), DT, (), DT, FR> {
    return pull(())
}

public func for_<UO, UI, DI, DO, NI, NO, FR>(p: Proxy<UO, UI, DI, DO, FR>, f: DO -> Proxy<UO, UI, NI, NO, DI>) -> Proxy<UO, UI, NI, NO, FR> {
    return p |>> f
}

infix operator <~ {
associativity left
precedence 130
}

public func <~<IS, UO, UI, DI, DO, NI, NO, FR>(f: IS -> Proxy<UO, UI, DI, DO, FR>, g: DO -> Proxy<UO, UI, NI, NO, DI>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return f |>| g
}

prefix operator <~ {}

public prefix func <~<IS, UO, UI, DI, DO, NI, NO, FR>(g: DO -> Proxy<UO, UI, NI, NO, DI>) -> (IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return { f in f |>| g }
}

postfix operator <~ {}

public postfix func <~<IS, UO, UI, DI, DO, NI, NO, FR>(f: IS -> Proxy<UO, UI, DI, DO, FR>) -> (DO -> Proxy<UO, UI, NI, NO, DI>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return { g in f |>| g }
}

infix operator ~> {
associativity right
precedence 130
}

public func ~><IS, UO, UI, DI, DO, NI, NO, FR>(f: DO -> Proxy<UO, UI, NI, NO, DI>, g: IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return g |>| f
}

prefix operator ~> {}

public prefix func ~><IS, UO, UI, DI, DO, NI, NO, FR>(g: IS -> Proxy<UO, UI, DI, DO, FR>) -> (DO -> Proxy<UO, UI, NI, NO, DI>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return { f in g |>| f }
}

postfix operator ~> {}

public postfix func |<|<IS, UO, UI, DI, DO, NI, NO, FR>(f: DO -> Proxy<UO, UI, NI, NO, DI>) -> (IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return { g in g |>| f }
}

infix operator ~< {
associativity left
precedence 140
}

prefix operator ~< {}

postfix operator ~< {}

infix operator >~ {
associativity right
precedence 140
}

prefix operator >~ {}

postfix operator >~ {}

infix operator >~> {
associativity left
precedence 160
}

prefix operator >-> {}

postfix operator >-> {}

infix operator <-< {
associativity right
precedence 160
}

prefix operator <-< {}

postfix operator <-< {}
