//
//  Simple.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/26/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

// roughly `Pipes`

import Swiftz

/// Pull the first value out of the given `Pipe`.
///
/// If the subsequent state of the `Pipe` is a single value or termination, the result is `.Left`
/// containing the value.  Otherwise the result is `.Right` containing the value and the next state
/// of the pipe.
public func next<DO, FR>(_ p : Producer<DO, FR>) -> Either<FR, (DO, Producer<DO, FR>)> {
	switch p.repr {
	case .request(_, _): fatalError("Blocking faulty request \(p)")
	case let .respond(dO, fDI): return .Right((dO(), Proxy(fDI(()))))
	case let .pure(x): return .Left(x())
	}
}

/// Discards the given value and returns a pipe that responds to requests with `()`.
public func discard<UO, UI, DI, DO>(_ : Any) -> Proxy<UO, UI, DI, DO, ()> {
	return Proxy(ProxyRepr.pure { _ in () })
}

/// Converts a given sequence into a pipe that produces elements of the same.
public func each<UO, UI, S : Sequence>(_ seq : S) -> Proxy<UO, UI, (), S.Iterator.Element, ()> {
	return Proxy(eachRepr(seq.makeIterator()))
}

/// Produce a value.
public func yield<UO, UI, DO>(_ dO : @autoclosure @escaping () -> DO) -> Proxy<UO, UI, (), DO, ()> {
	return respond(dO)
}

/// Consume a value.
public func await<UI, DI, DO>() -> Proxy<(), UI, DI, DO, UI> {
	return request(())
}

/// The identity `Pipe`.
///
/// Like the Unix `cat` program, pushes any given input as output without modification.
public func cat<DT, FR>() -> Pipe<DT, DT, FR> {
	return pull(())
}

/// Iterates over each value in the given pipe and replaces it with the result of applying the
/// given function.
public func for_<UO, UI, DI, DO, NI, NO, FR>(_ p : Proxy<UO, UI, DI, DO, FR>, _ f : @escaping (DO) -> Proxy<UO, UI, NI, NO, DI>) -> Proxy<UO, UI, NI, NO, FR> {
	return p |>> f
}

/// Into | Composes two loops to yield one large loop.
///
/// The corresponding operator in `pipes` is `~>`.
public func ~~> <IS, UO, UI, DI, DO, NI, NO, FR>(f : @escaping (IS) -> Proxy<UO, UI, DI, DO, FR>, g : @escaping (DO) -> Proxy<UO, UI, NI, NO, DI>) -> (IS) -> Proxy<UO, UI, NI, NO, FR> {
	return f |>| g
}

/// Into | Composes two loops to yield one large loop.
///
/// The corresponding operator in `pipes` is `<~`.
public func <~~ <IS, UO, UI, DI, DO, NI, NO, FR>(f : @escaping (DO) -> Proxy<UO, UI, NI, NO, DI>, g : @escaping (IS) -> Proxy<UO, UI, DI, DO, FR>) -> (IS) -> Proxy<UO, UI, NI, NO, FR> {
	return g |>| f
}

/// Replaces each value `yielded` in the left pipe with the right pipe.
///
/// The corresponding operator in `pipes` is `~<`.
public func ~~< <UO, UI, DI, DO, FR, NR>(p : Proxy<(), FR, DI, DO, NR>, q : Proxy<UO, UI, DI, DO, FR>) -> Proxy<UO, UI, DI, DO, NR> {
	return q >~~ p
}

/// Replaces each value `yielded` in the right pipe with the left pipe.
///
/// The corresponding operator in `pipes` is `>~`.
public func >~~ <UO, UI, DI, DO, FR, NR>(p : Proxy<UO, UI, DI, DO, FR>, q : Proxy<(), FR, DI, DO, NR>) -> Proxy<UO, UI, DI, DO, NR> {
	return { _ in p } >>| q
}

/// Compose | Composes two pipes by attaching the output of the first to the input of the second.
///
/// This operation is analogous to the Unix `|` operator.
public func >-> <UO, UI, DI, DO, DDI, DDO, FR>(p : Proxy<UO, UI, DI, DO, FR>, q : Proxy<DI, DO, DDI, DDO, FR>) -> Proxy<UO, UI, DDI, DDO, FR> {
	return { _ in p } +>> q
}

/// Compose Backwards | Composes two pipes by attaching the output of the second to the input of the
/// first.
///
/// The operator is the flipped form of `>->`.
public func <-< <UO, UI, DI, DO, DDI, DDO, FR>(p : Proxy<DI, DO, DDI, DDO, FR>, q : Proxy<UO, UI, DI, DO, FR>) -> Proxy<UO, UI, DDI, DDO, FR> {
	return q >-> p
}


// MARK: - Implementation Details Follow

private func eachRepr<UO, UI, G : IteratorProtocol>(_ gen : G) -> ProxyRepr<UO, UI, (), G.Element, ()> {
	var gen = gen
	if let v = gen.next() {
		return ProxyRepr.respond(const(v)) { _ in eachRepr(gen) }
	} else {
		return ProxyRepr.pure(const(()))
	}
}
