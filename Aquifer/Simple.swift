//
//  Simple.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/26/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

// roughly `Pipes`

import Swiftz

/// Pull the first value out of the given pipe.
///
/// If the subsequent state of the pipe is `.Pure` or terminated, the result is `.Left` containing
/// the value.  Else the result is `.Right` containing the value and the next state of the pipe.
public func next<DO, FR>(p: Proxy<X, (), (), DO, FR>) -> Either<FR, (DO, Proxy<X, (), (), DO, FR>)> {
    switch p.repr {
    case let .Request(uO, _): return closed(uO())
    case let .Respond(dO, fDI): return .Right((dO(), Proxy(fDI(()))))
    case let .Pure(x): return .Left(x())
    }
}

/// Discards the value it is given.
///
/// The resulting pipe responds to all requests with `()`.
public func discard<UO, UI, DI, DO>(_: Any) -> Proxy<UO, UI, DI, DO, ()> {
    return Proxy(ProxyRepr.Pure { _ in () })
}

/// Converts a given sequence into a pipe that produces elements of the same.
public func each<UO, UI, S: SequenceType>(seq: S) -> Proxy<UO, UI, (), S.Generator.Element, ()> {
    return Proxy(eachRepr(seq.generate()))
}

/// Converts the argument list into a sequence and yields a pipe that produces elements of said
/// sequence.
public func each<UO, UI, V>(seq: V...) -> Proxy<UO, UI, (), V, ()> {
    return each(seq)
}

/// Produce a value.
public func yield<UO, UI, DO>(@autoclosure(escaping) dO: () -> DO) -> Proxy<UO, UI, (), DO, ()> {
    return respond(dO)
}

/// Consume a value.
public func await<UI, DI, DO>() -> Proxy<(), UI, DI, DO, UI> {
    return request(())
}

/// The identity pipe.
///
/// Like the Unix `cat` program, pushes any given input as output without modification.
public func cat<DT, FR>() -> Proxy<(), DT, (), DT, FR> {
    return pull(())
}

/// For each value `yield`ed in the given pipe and replaces it with the result of applying the
/// function.
public func for_<UO, UI, DI, DO, NI, NO, FR>(p: Proxy<UO, UI, DI, DO, FR>, _ f: DO -> Proxy<UO, UI, NI, NO, DI>) -> Proxy<UO, UI, NI, NO, FR> {
    return p |>> f
}

infix operator <~ {
associativity left
precedence 130
}

/// Composes two loops to yield one large loop.
public func <~ <IS, UO, UI, DI, DO, NI, NO, FR>(f: IS -> Proxy<UO, UI, DI, DO, FR>, g: DO -> Proxy<UO, UI, NI, NO, DI>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return f |>| g
}

infix operator ~> {
associativity right
precedence 130
}

/// Composes two loops to yield one large loop.
public func ~> <IS, UO, UI, DI, DO, NI, NO, FR>(f: DO -> Proxy<UO, UI, NI, NO, DI>, g: IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return g |>| f
}

infix operator ~< {
associativity left
precedence 140
}

/// Replaces each value `yielded` in the left pipe with the right pipe.
public func ~< <UO, UI, DI, DO, FR, NR>(p: Proxy<(), FR, DI, DO, NR>, q: Proxy<UO, UI, DI, DO, FR>) -> Proxy<UO, UI, DI, DO, NR> {
    return q >~ p
}

infix operator >~ {
associativity right
precedence 140
}

/// Replaces each value `yielded` in the right pipe with the left pipe.
public func >~ <UO, UI, DI, DO, FR, NR>(p: Proxy<UO, UI, DI, DO, FR>, q: Proxy<(), FR, DI, DO, NR>) -> Proxy<UO, UI, DI, DO, NR> {
    return { _ in p } >>| q
}

infix operator >-> {
associativity left
precedence 160
}

/// Compose | Composes two pipes by attaching the output of the first to the input of the second.
///
/// This operation is analogous to the Unix `|` operator.
public func >-> <UO, UI, DT, DI, DO, FR>(p: Proxy<UO, UI, (), DT, FR>, q: Proxy<(), DT, DI, DO, FR>) -> Proxy<UO, UI, DI, DO, FR> {
    return { _ in p } +>> q
}

infix operator <-< {
associativity right
precedence 160
}

/// Compose Backwards | Composes two pipes by attaching the output of the second to the input of the
/// first.
///
/// The operator is the flipped form of `>->`.
public func <-< <UO, UI, DT, DI, DO, FR>(p: Proxy<(), DT, DI, DO, FR>, q: Proxy<UO, UI, (), DT, FR>) -> Proxy<UO, UI, DI, DO, FR> {
    return q >-> p
}


/// Implementation Details Follow

private func eachRepr<UO, UI, G: GeneratorType>(var gen: G) -> ProxyRepr<UO, UI, (), G.Element, ()> {
    if let v = gen.next() {
        return ProxyRepr.Respond(const(v)) { _ in eachRepr(gen) }
    } else {
        return ProxyRepr.Pure(const(()))
    }
}
