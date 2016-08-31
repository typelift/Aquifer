//
//  Proxy.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/13/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

// roughly `Pipes.Internal`

import Swiftz

/// A bidirectional channel for information.
///
/// A `Proxy` is so named because it can represent many different kinds of information flows.  There
/// are 6 overarching specific types that a `Proxy` can represent, each with separate semantics.
///
/// An effectful computation.
///
/// `Effect`s neither await nor yield.
public typealias Effect<Result> = Proxy<Never, (), (), Never, Result>
/// A computation that yields values of type `B`.
///
/// `Producer`s can only yield.
public typealias Producer<B, Result> = Proxy<Never, (), (), B, Result>
/// A computation that can await values of type `A` and yield values of type `B`.
///
/// `Pipe`s can both await and yield.
public typealias Pipe<A, B, Result> = Proxy<(), A, (), B, Result>
/// A computation that can await values of type `A`.
///
/// `Consumer`s can only await.
public typealias Consumer<A, Result> = Proxy<(), A, (), Never, Result>
/// Sends requests of type `RequestT` and recieves responses of type `RespondT`.
///
/// `Client`s only request and never respond.
public typealias Client<RequestT, RespondT, Result> = Proxy<RequestT, RespondT, (), Never, Result>
/// Receives values of type `ReceiveT` and responds with values of type `RespondT`.
///
/// `Server`s only respond and never request.
public typealias Server<ReceiveT, RespondT, Result> = Proxy<Never, (), ReceiveT, RespondT, Result>
///
/// The type parameters are as follows:
///
/// UO - upstream   output
/// UI - upstream   input
/// DI — downstream input
/// DO — downstream output
/// FR — final      result
///
/// Which can be represented diagrammatically by:
///
///               Upstream | Downstream
///                   +---------+
///                   |         |
///  Upstream Output <==       <== Downstream Input
///                   |         |
///  Upstream Input  ==>       ==> Downstream Output
///                   |    |    |
///                   +----|----+
///                        v
///                   Final Results
public struct Proxy<UO, UI, DI, DO, FR> {
	fileprivate let _repr : () -> ProxyRepr<UO, UI, DI, DO, FR>

	internal init( _ r : @autoclosure @escaping () -> ProxyRepr<UO, UI, DI, DO, FR>) {
		_repr = r
	}

	internal var repr : ProxyRepr<UO, UI, DI, DO, FR> {
		return _repr()
	}

	/// Returns the pipe dual to the receiver.  That is, `awaits`s become `yield`s and vice-versa.
	public func reflect() -> Proxy<DO, DI, UI, UO, FR> {
		return Proxy<DO, DI, UI, UO, FR>(self.repr.reflect())
	}
}

/// Forces a pipe to evaluate its contents lazily.
public func delay<UO, UI, DI, DO, FR>( _ p : @autoclosure @escaping () -> Proxy<UO, UI, DI, DO, FR>) -> Proxy<UO, UI, DI, DO, FR> {
	return Proxy(p().repr)
}

extension Proxy/*: Functor*/ {
	/*typealias B = Any*/

	/// Yields a pipe that applies the given function to its final result.
	public func fmap<NR>(_ f : @escaping (FR) -> NR) -> Proxy<UO, UI, DI, DO, NR> {
		return Proxy<UO, UI, DI, DO, NR>(self.repr.fmap(f))
	}
}

public func <^> <UO, UI, DI, DO, FR, NR>(f : @escaping (FR) -> NR, p : Proxy<UO, UI, DI, DO, FR>) -> Proxy<UO, UI, DI, DO, NR> {
	return p.fmap(f)
}

extension Proxy/*: Pointed*/ {
	/// Yields a pipe that responds to all requests with the given value.
	public static func pure(_ x : FR) -> Proxy<UO, UI, DI, DO, FR> {
		return Aquifer.pure(x)
	}
}

/// Yields a pipe that responds to all requests with the given value.
public func pure<UO, UI, DI, DO, FR>( _ x : @autoclosure @escaping () -> FR) -> Proxy<UO, UI, DI, DO, FR> {
	return Proxy(ProxyRepr.pure(x))
}

extension Proxy/*: Applicative*/ {
	/// Yields a pipe that responds with result of applying each function yielded in the given pipe
	/// to the values yielded in the receiver.
	public func ap<NR>(_ f : Proxy<UO, UI, DI, DO, (FR) -> NR>) -> Proxy<UO, UI, DI, DO, NR> {
		return Proxy<UO, UI, DI, DO, NR>(self.repr.ap(f.repr))
	}
}

public func <*> <UO, UI, DI, DO, FR, NR>(f : Proxy<UO, UI, DI, DO, (FR) -> NR>, p : Proxy<UO, UI, DI, DO, FR>) -> Proxy<UO, UI, DI, DO, NR> {
	return p.ap(f)
}

extension Proxy/*: Monad*/ {
	/// Yields a pipe that responds with the result of applying the function to each value yielded
	/// in the receiver then concatenating the results of each produced pipe.
	public func bind<NR>(_ f : @escaping (FR) -> Proxy<UO, UI, DI, DO, NR>) -> Proxy<UO, UI, DI, DO, NR> {
		return Proxy<UO, UI, DI, DO, NR>(self.repr.bind { f($0).repr })
	}
}

public func >>- <UO, UI, DI, DO, FR, NR>(p : Proxy<UO, UI, DI, DO, FR>, f : @escaping (FR) -> Proxy<UO, UI, DI, DO, NR>) -> Proxy<UO, UI, DI, DO, NR> {
	return p.bind(f)
}

public func >>->> <A, B, C, UI, UO, DI, DO>(m1 : @escaping (A) -> Proxy<UI, UO, DI, DO, B>, m2 : @escaping (B) -> Proxy<UI, UO, DI, DO, C>) -> ((A) -> Proxy<UI, UO, DI, DO, C>) {
	return { r in
		return m1(r) >>- m2
	}
}

public func <<-<< <A, B, C, UI, UO, DI, DO>(m2 : @escaping (B) -> Proxy<UI, UO, DI, DO, C>, m1 : @escaping (A) -> Proxy<UI, UO, DI, DO, B>) -> ((A) -> Proxy<UI, UO, DI, DO, C>) {
	return { r in
		return m1(r) >>- m2
	}
}

/// Flattens a Pipe that yields pipes by one level.
public func flatten<UO, UI, DI, DO, FR>(_ p : Proxy<UO, UI, DI, DO, Proxy<UO, UI, DI, DO, FR>>) -> Proxy<UO, UI, DI, DO, FR> {
	return p.bind { q in q }
}

/// Runs a self-contained "Effect" and yields a final value.
public func runEffect<FR>(_ p : Effect<FR>) -> FR {
	switch p.repr {
	case .request(_, _): fatalError("Blocking faulty request \(p)")
	case .respond(_, _): fatalError("Blocking faulty response \(p)")
	case let .pure(x): return x()
	}
}

// MARK: - Implementation Details Follow

/// The underlying implementation in Pipes.Internal.
///
/// The type parameters are as follows:
/// UO - upstream   output
/// UI - upstream   input
/// DI — downstream input
/// DO — downstream output
/// FR — final      result
internal enum ProxyRepr<UO, UI, DI, DO, FR> {
	/// Request a value from upstream.
	case request(() -> UO, (UI) -> ProxyRepr<UO, UI, DI, DO, FR>)
	/// Respond with a value downstream.
	case respond(() -> DO, (DI) -> ProxyRepr<UO, UI, DI, DO, FR>)
	/// Yields the value as a final result for all requests.
	case pure(() -> FR)

	internal func fmap<NR>(_ f : @escaping (FR) -> NR) -> ProxyRepr<UO, UI, DI, DO, NR> {
		switch self {
		case let .request(uO, fUI): return ProxyRepr<UO, UI, DI, DO, NR>.request(uO) { fUI($0).fmap(f) }
		case let .respond(dO, fDI): return ProxyRepr<UO, UI, DI, DO, NR>.respond(dO) { fDI($0).fmap(f) }
		case let .pure(x): return ProxyRepr<UO, UI, DI, DO, NR>.pure { _ in f(x()) }
		}
	}

	internal func ap<NR>(_ f : ProxyRepr<UO, UI, DI, DO, (FR) -> NR>) -> ProxyRepr<UO, UI, DI, DO, NR> {
		switch f {
		case let .request(uO, fUI): return ProxyRepr<UO, UI, DI, DO, NR>.request(uO) { self.ap(fUI($0)) }
		case let .respond(dO, fDI): return ProxyRepr<UO, UI, DI, DO, NR>.respond(dO) { self.ap(fDI($0)) }
		case let .pure(g): return self.fmap(g())
		}
	}

	internal func bind<NR>(_ f : @escaping (FR) -> ProxyRepr<UO, UI, DI, DO, NR>) -> ProxyRepr<UO, UI, DI, DO, NR> {
		switch self {
		case let .request(uO, fUI): return ProxyRepr<UO, UI, DI, DO, NR>.request(uO) { fUI($0).bind(f) }
		case let .respond(dO, fDI): return ProxyRepr<UO, UI, DI, DO, NR>.respond(dO) { fDI($0).bind(f) }
		case let .pure(x): return f(x())
		}
	}

	internal func reflect() -> ProxyRepr<DO, DI, UI, UO, FR> {
		switch self {
		case let .request(uO, fUI): return ProxyRepr<DO, DI, UI, UO, FR>.respond(uO) { fUI($0).reflect() }
		case let .respond(dO, fDI): return ProxyRepr<DO, DI, UI, UO, FR>.request(dO) { fDI($0).reflect() }
		case let .pure(x): return ProxyRepr<DO, DI, UI, UO, FR>.pure(x)
		}
	}

	internal func respondBind<NI, NO>(_ f : @escaping (DO) -> ProxyRepr<UO, UI, NI, NO, DI>) -> ProxyRepr<UO, UI, NI, NO, FR> {
		switch self {
		case let .request(uO, fUI): return ProxyRepr<UO, UI, NI, NO, FR>.request(uO) { fUI($0).respondBind(f) }
		case let .respond(dO, fDI): return f(dO()).bind { fDI($0).respondBind(f) }
		case let .pure(x): return ProxyRepr<UO, UI, NI, NO, FR>.pure(x)
		}
	}

	internal func requestBind<NO, NI>(_ f : @escaping (UO) -> ProxyRepr<NO, NI, DI, DO, UI>) -> ProxyRepr<NO, NI, DI, DO, FR> {
		switch self {
		case let .request(uO, fUI): return f(uO()).bind { fUI($0).requestBind(f) }
		case let .respond(dO, fDI): return ProxyRepr<NO, NI, DI, DO, FR>.respond(dO) { fDI($0).requestBind(f) }
		case let .pure(x): return ProxyRepr<NO, NI, DI, DO, FR>.pure(x)
		}
	}

	internal func pushBind<NI, NO>(_ f : @escaping (DO) -> ProxyRepr<DI, DO, NI, NO, FR>) -> ProxyRepr<UO, UI, NI, NO, FR> {
		switch self {
		case let .request(uO, fUI): return ProxyRepr<UO, UI, NI, NO, FR>.request(uO) { pushBindExt(fUI($0), f) }
		case let .respond(dO, fDI): return pullBindExt(f(dO()), fDI)
		case let .pure(x): return ProxyRepr<UO, UI, NI, NO, FR>.pure(x)
		}
	}

	internal func pullBind<NO, NI>(_ f : @escaping (UO) -> ProxyRepr<NO, NI, UO, UI, FR>) -> ProxyRepr<NO, NI, DI, DO, FR> {
		switch self {
		case let .request(uO, fUI): return pushBindExt(f(uO()), fUI)
		case let .respond(dO, fDI): return ProxyRepr<NO, NI, DI, DO, FR>.respond(dO) { pullBindExt(fDI($0), f) }
		case let .pure(x): return ProxyRepr<NO, NI, DI, DO, FR>.pure(x)
		}
	}
}

private func pushBindExt<UO, UI, DI, DO, NI, NO, FR>(_ p : ProxyRepr<UO, UI, DI, DO, FR>, _ f : @escaping (DO) -> ProxyRepr<DI, DO, NI, NO, FR>) -> ProxyRepr<UO, UI, NI, NO, FR> {
	return p.pushBind(f)
}

private func pullBindExt<UO, UI, DI, DO, NI, NO, FR>(_ p : ProxyRepr<UO, UI, DI, DO, FR>, _ f : @escaping (UO) -> ProxyRepr<NO, NI, UO, UI, FR>) -> ProxyRepr<NO, NI, DI, DO, FR> {
	return p.pullBind(f)
}

