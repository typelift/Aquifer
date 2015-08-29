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
///     typealias Effect<Result> = Proxy<X, (), (), X, Result>
///
/// A computation that yields values of type `B`.
///
///     typealias Producer<B, Result> = Proxy<X, (), (), B, Result>
///
/// A computation that can await values of type `A` and yield values of type `B`.
///
///     typealias Pipe<A, B, Result> = Proxy<(), A, (), B, Result>
///
/// A computation that can await values of type `A`.
///
///     typealias Consumer<A, Result> = Proxy<(), A, (), X, Result>
///
/// Sends requests of type `RequestT` and recieves responses of type `RespondT`.
///
///     typealias Client<RequestT, RespondT, Result> = Proxy<RequestT, RespondT, (), X, Result>
///
/// Receives values of type `ReceiveT` and responds with values of type `RespondT`.
///
///     typealias Server<ReceiveT, RespondT, Result> = Proxy<X, (), ReceiveT, RespondT, Result>
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
    private let _repr : () -> ProxyRepr<UO, UI, DI, DO, FR>

    internal init(@autoclosure(escaping) _ r: () -> ProxyRepr<UO, UI, DI, DO, FR>) {
        _repr = r
    }

    internal var repr: ProxyRepr<UO, UI, DI, DO, FR> {
        return _repr()
    }
    
    /// Returns the pipe dual to the receiver.  That is, `awaits`s become `yield`s and vice-versa.
    public func reflect() -> Proxy<DO, DI, UI, UO, FR> {
        return Proxy<DO, DI, UI, UO, FR>(self.repr.reflect())
    }
}

/// An effectful computation.
///
/// `Effect`s neither await nor yield.
public enum Effect<Result> {
    public typealias T = Proxy<X, (), (), X, Result>
}

/// A computation that yields values of type `B`.
///
/// `Producer`s can only yield.
public enum Producer<B, Result> {
    public typealias T = Proxy<X, (), (), B, Result>
}

/// A computation that can await values of type `A` and yield values of type `B`.
///
/// `Pipe`s can both await and yield.
public enum Pipe<A, B, Result> {
    public typealias T = Proxy<(), A, (), B, Result>
}

/// A computation that can await values of type `A`.
///
/// `Consumer`s can only await.
public enum Consumer<A, Result> {
    public typealias T = Proxy<(), A, (), X, Result>
}

/// Sends requests of type `RequestT` and recieves responses of type `RespondT`.
///
/// `Client`s only request and never respond.
public enum Client<RequestT, RespondT, Result> {
    public typealias T = Proxy<RequestT, RespondT, (), X, Result>
}

/// Receives values of type `ReceiveT` and responds with values of type `RespondT`.
///
/// `Server`s only respond and never request.
public enum Server<ReceiveT, RespondT, Result> {
    public typealias T = Proxy<X, (), ReceiveT, RespondT, Result>
}

/// Forces a pipe to evaluate its contents lazily.
public func delay<UO, UI, DI, DO, FR>(@autoclosure(escaping) p: () -> Proxy<UO, UI, DI, DO, FR>) -> Proxy<UO, UI, DI, DO, FR> {
    return Proxy(p().repr)
}

extension Proxy/*: Functor*/ {
    /*typealias B = Any*/

    /// Yields a pipe that applies the given function to its final result.
    public func fmap<NR>(f: FR -> NR) -> Proxy<UO, UI, DI, DO, NR> {
        return Proxy<UO, UI, DI, DO, NR>(self.repr.fmap(f))
    }
}

public func <^> <UO, UI, DI, DO, FR, NR>(f: FR -> NR, p: Proxy<UO, UI, DI, DO, FR>) -> Proxy<UO, UI, DI, DO, NR> {
    return p.fmap(f)
}

extension Proxy/*: Pointed*/ {
    /// Yields a pipe that responds to all requests with the given value.
    public static func pure(x: FR) -> Proxy<UO, UI, DI, DO, FR> {
        return Aquifer.pure(x)
    }
}

/// Yields a pipe that responds to all requests with the given value.
public func pure<UO, UI, DI, DO, FR>(@autoclosure(escaping) x: () -> FR) -> Proxy<UO, UI, DI, DO, FR> {
    return Proxy(ProxyRepr.Pure(x))
}

extension Proxy/*: Applicative*/ {
    /// Yields a pipe that responds with result of applying each function yielded in the given pipe
    /// to the values yielded in the receiver.
    public func ap<NR>(f: Proxy<UO, UI, DI, DO, FR -> NR>) -> Proxy<UO, UI, DI, DO, NR> {
        return Proxy<UO, UI, DI, DO, NR>(self.repr.ap(f.repr))
    }
}

public func <*> <UO, UI, DI, DO, FR, NR>(f: Proxy<UO, UI, DI, DO, FR -> NR>, p: Proxy<UO, UI, DI, DO, FR>) -> Proxy<UO, UI, DI, DO, NR> {
    return p.ap(f)
}

extension Proxy/*: Monad*/ {
    /// Yields a pipe that responds with the result of applying the function to each value yielded
    /// in the receiver then concatenating the results of each produced pipe.
    public func bind<NR>(f: FR -> Proxy<UO, UI, DI, DO, NR>) -> Proxy<UO, UI, DI, DO, NR> {
        return Proxy<UO, UI, DI, DO, NR>(self.repr.bind { f($0).repr })
    }
}

public func >>- <UO, UI, DI, DO, FR, NR>(p: Proxy<UO, UI, DI, DO, FR>, f: FR -> Proxy<UO, UI, DI, DO, NR>) -> Proxy<UO, UI, DI, DO, NR> {
    return p.bind(f)
}

/// Flattens a Pipe that yields pipes by one level.
public func flatten<UO, UI, DI, DO, FR>(p: Proxy<UO, UI, DI, DO, Proxy<UO, UI, DI, DO, FR>>) -> Proxy<UO, UI, DI, DO, FR> {
    return p.bind { q in q }
}

/// Runs a self-contained "Effect" and yields a final value. 
public func runEffect<FR>(p: Effect<FR>.T) -> FR {
    switch p.repr {
    case let .Request(uO, _): return closed(uO())
    case let .Respond(dO, _): return closed(dO())
    case let .Pure(x): return x()
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
    case Request(() -> UO, UI -> ProxyRepr<UO, UI, DI, DO, FR>)
    /// Respond with a value downstream.
    case Respond(() -> DO, DI -> ProxyRepr<UO, UI, DI, DO, FR>)
    /// Yields the value as a final result for all requests.
    case Pure(() -> FR)
    
    internal func fmap<NR>(f: FR -> NR) -> ProxyRepr<UO, UI, DI, DO, NR> {
        switch self {
        case let .Request(uO, fUI): return ProxyRepr<UO, UI, DI, DO, NR>.Request(uO) { fUI($0).fmap(f) }
        case let .Respond(dO, fDI): return ProxyRepr<UO, UI, DI, DO, NR>.Respond(dO) { fDI($0).fmap(f) }
        case let .Pure(x): return ProxyRepr<UO, UI, DI, DO, NR>.Pure { _ in f(x()) }
        }
    }
    
    internal func ap<NR>(f: ProxyRepr<UO, UI, DI, DO, FR -> NR>) -> ProxyRepr<UO, UI, DI, DO, NR> {
        switch f {
        case let .Request(uO, fUI): return ProxyRepr<UO, UI, DI, DO, NR>.Request(uO) { self.ap(fUI($0)) }
        case let .Respond(dO, fDI): return ProxyRepr<UO, UI, DI, DO, NR>.Respond(dO) { self.ap(fDI($0)) }
        case let .Pure(g): return self.fmap(g())
        }
    }
    
    internal func bind<NR>(f: FR -> ProxyRepr<UO, UI, DI, DO, NR>) -> ProxyRepr<UO, UI, DI, DO, NR> {
        switch self {
        case let .Request(uO, fUI): return ProxyRepr<UO, UI, DI, DO, NR>.Request(uO) { fUI($0).bind(f) }
        case let .Respond(dO, fDI): return ProxyRepr<UO, UI, DI, DO, NR>.Respond(dO) { fDI($0).bind(f) }
        case let .Pure(x): return f(x())
        }
    }
    
    internal func reflect() -> ProxyRepr<DO, DI, UI, UO, FR> {
        switch self {
        case let .Request(uO, fUI): return ProxyRepr<DO, DI, UI, UO, FR>.Respond(uO) { fUI($0).reflect() }
        case let .Respond(dO, fDI): return ProxyRepr<DO, DI, UI, UO, FR>.Request(dO) { fDI($0).reflect() }
        case let .Pure(x): return ProxyRepr<DO, DI, UI, UO, FR>.Pure(x)
        }
    }
    
    internal func respondBind<NI, NO>(f: DO -> ProxyRepr<UO, UI, NI, NO, DI>) -> ProxyRepr<UO, UI, NI, NO, FR> {
        switch self {
        case let .Request(uO, fUI): return ProxyRepr<UO, UI, NI, NO, FR>.Request(uO) { fUI($0).respondBind(f) }
        case let .Respond(dO, fDI): return f(dO()).bind { fDI($0).respondBind(f) }
        case let .Pure(x): return ProxyRepr<UO, UI, NI, NO, FR>.Pure(x)
        }
    }
    
    internal func requestBind<NO, NI>(f: UO -> ProxyRepr<NO, NI, DI, DO, UI>) -> ProxyRepr<NO, NI, DI, DO, FR> {
        switch self {
        case let .Request(uO, fUI): return f(uO()).bind { fUI($0).requestBind(f) }
        case let .Respond(dO, fDI): return ProxyRepr<NO, NI, DI, DO, FR>.Respond(dO) { fDI($0).requestBind(f) }
        case let .Pure(x): return ProxyRepr<NO, NI, DI, DO, FR>.Pure(x)
        }
    }
    
    internal func pushBind<NI, NO>(f: DO -> ProxyRepr<DI, DO, NI, NO, FR>) -> ProxyRepr<UO, UI, NI, NO, FR> {
        switch self {
        case let .Request(uO, fUI): return ProxyRepr<UO, UI, NI, NO, FR>.Request(uO) { pushBindExt(fUI($0), f) }
        case let .Respond(dO, fDI): return pullBindExt(f(dO()), fDI)
        case let .Pure(x): return ProxyRepr<UO, UI, NI, NO, FR>.Pure(x)
        }
    }
    
    internal func pullBind<NO, NI>(f: UO -> ProxyRepr<NO, NI, UO, UI, FR>) -> ProxyRepr<NO, NI, DI, DO, FR> {
        switch self {
        case let .Request(uO, fUI): return pushBindExt(f(uO()), fUI)
        case let .Respond(dO, fDI): return ProxyRepr<NO, NI, DI, DO, FR>.Respond(dO) { pullBindExt(fDI($0), f) }
        case let .Pure(x): return ProxyRepr<NO, NI, DI, DO, FR>.Pure(x)
        }
    }
}

private func pushBindExt<UO, UI, DI, DO, NI, NO, FR>(p: ProxyRepr<UO, UI, DI, DO, FR>, _ f: DO -> ProxyRepr<DI, DO, NI, NO, FR>) -> ProxyRepr<UO, UI, NI, NO, FR> {
    return p.pushBind(f)
}

private func pullBindExt<UO, UI, DI, DO, NI, NO, FR>(p: ProxyRepr<UO, UI, DI, DO, FR>, _
    f: UO -> ProxyRepr<NO, NI, UO, UI, FR>) -> ProxyRepr<NO, NI, DI, DO, FR> {
        return p.pullBind(f)
}

