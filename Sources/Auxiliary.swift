//
//  Auxiliary.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/29/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

// roughly `Pipes.Extras`

import Swiftz
#if !XCODE_BUILD
	import Operadics
	import Swiftx
#endif

/// Lifts an arrow into a pipe by connecting its inputs to the upstream input and its outputs to the
/// downstream output of the pipe.
public func arr<A, B, R>(_ f : @escaping (A) -> B) -> Pipe<A, B, R> {
	return map(f)
}

/// Returns a pipe that acts like `left` from Control.Arrow.
///
/// Values sent along the upstream input in a `.Left` will appear downstream in a `.Left` after the
/// pipe has operated on them.  Values appearing along the upstream input in a `.Right` will appear
/// downstream in a `.Right` unchanged.
public func left<A, B, C, R>(_ p : Pipe<A, B, R>) -> Pipe<Either<A, C>, Either<B, C>, R> {
	return leftInner() >~~ for_(p) { v in yield(Either.Left(v)) }
}

/// Returns a pipe that acts like `right` from Control.Arrow.
///
/// Values sent along the upstream input in a `.Right` will appear downstream in a `.Right` after
/// the pipe has operated on them.  Values appearing along the upstream input in a `.Left` will
/// appear downstream in a `.Left` unchanged.
public func right<A, B, C, R>(_ p : Pipe<A, B, R>) -> Pipe<Either<C, A>, Either<C, B>, R> {
	return rightInner() >~~ for_(p) { v in yield(Either.Right(v)) }
}

/// Returns a pipe that acts like `+++` from Control.Arrow.
///
/// `.Left` values fed to the pipe's upstream input will appear downstream as `.Left`s that have
/// been operated on by the first pipe.  `.Right` values fed to the pipe's upstream input will
/// appear downstream as `.Right`s that have been operated on by the second pipe.
public func +++ <A, B, C, D, R>(p : Pipe<A, B, R>, q : Pipe<C, D, R>) -> Pipe<Either<A, C>, Either<B, D>, R> {
	return left(p) >-> right(q)
}

/// Returns a pipe that applies the given function to its upstream input.
public func mapInput<UO, UI, DI, DO, NI, FR>(_ p : Proxy<UO, UI, DI, DO, FR>, _ f : @escaping (NI) -> UI) -> Proxy<UO, NI, DI, DO, FR> {
	return { request($0).fmap(f) } >>| p
}

/// Returns a pipe that applies the given function to its downstream output.
public func mapOutput<UO, UI, DI, DO, NO, FR>(_ p : Proxy<UO, UI, DI, DO, FR>, _ f : @escaping (DO) -> NO) -> Proxy<UO, UI, DI, NO, FR> {
	return p |>> { v in respond(f(v)) }
}

/// Yields a pipe that produces left-scanned values with the given step function.
public func scan1i<DT, FR>(stepWith step : @escaping (DT, DT) -> DT) -> Pipe<DT, DT, FR> {
	return scan1(stepWith: step, initializeWith: identity, extractWith: identity)
}

/// Yields a pipe that produces left-scanned values with the given step function.  The pipe is not
/// required to have an initial value, but one is expected to be produced by the `initial` function.
public func scan1<A, UI, DO, FR>(stepWith step : @escaping (A, UI) -> A, initializeWith initial : @escaping (UI) -> A, extractWith extractor : @escaping (A) -> DO) -> Pipe<UI, DO, FR> {
	return await() >>- { scan(stepWith: step, initializeWith: initial($0), extractWith: extractor) }
}

// MARK: - Implementation Details Follow

private func leftInner<A, B, C>() -> Pipe<Either<A, C>, Either<B, C>, A> {
	return await() >>- {
		switch $0 {
		case let .Left(x): return pure(x)
		case let .Right(y): return yield(Either.Right(y)) >>- { _ in leftInner() }
		}
	}
}


private func rightInner<A, B, C>() -> Pipe<Either<C, A>, Either<C, B>, A> {
	return await() >>- {
		switch $0 {
		case let .Left(x): return yield(Either.Left(x)) >>- { _ in rightInner() }
		case let .Right(y): return pure(y)
		}
	}
}

