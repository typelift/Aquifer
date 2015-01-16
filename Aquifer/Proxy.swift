//
//  Proxy.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/13/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

import Foundation
import Swiftz

internal enum ProxyRepr<UO, UI, DI, DO, FR> {
    case Request(() -> UO, UI -> ProxyRepr<UO, UI, DI, DO, FR>)
    case Respond(() -> DO, DI -> ProxyRepr<UO, UI, DI, DO, FR>)
    case Pure(() -> FR)

    internal func fmap<NR>(f: FR -> NR) -> ProxyRepr<UO, UI, DI, DO, NR> {
        switch self {
        case let Request(uO, fUI): return ProxyRepr<UO, UI, DI, DO, NR>.Request(uO) { fUI($0).fmap(f) }
        case let Respond(dO, fDI): return ProxyRepr<UO, UI, DI, DO, NR>.Respond(dO) { fDI($0).fmap(f) }
        case let Pure(x): return ProxyRepr<UO, UI, DI, DO, NR>.Pure { _ in f(x()) }
        }
    }

    internal func ap<NR>(f: ProxyRepr<UO, UI, DI, DO, FR -> NR>) -> ProxyRepr<UO, UI, DI, DO, NR> {
        switch f {
        case let Request(uO, fUI): return ProxyRepr<UO, UI, DI, DO, NR>.Request(uO) { self.ap(fUI($0)) }
        case let Respond(dO, fDI): return ProxyRepr<UO, UI, DI, DO, NR>.Respond(dO) { self.ap(fDI($0)) }
        case let Pure(g): return self.fmap(g())
        }
    }

    internal func bind<NR>(f: FR -> ProxyRepr<UO, UI, DI, DO, NR>) -> ProxyRepr<UO, UI, DI, DO, NR> {
        switch self {
        case let Request(uO, fUI): return ProxyRepr<UO, UI, DI, DO, NR>.Request(uO) { fUI($0).bind(f) }
        case let Respond(dO, fDI): return ProxyRepr<UO, UI, DI, DO, NR>.Respond(dO) { fDI($0).bind(f) }
        case let Pure(x): return f(x())
        }
    }

    internal func reflect() -> ProxyRepr<DO, DI, UI, UO, FR> {
        switch self {
        case let Request(uO, fUI): return ProxyRepr<DO, DI, UI, UO, FR>.Respond(uO) { fUI($0).reflect() }
        case let Respond(dO, fDI): return ProxyRepr<DO, DI, UI, UO, FR>.Request(dO) { fDI($0).reflect() }
        case let Pure(x): return ProxyRepr<DO, DI, UI, UO, FR>.Pure(x)
        }
    }

    internal func respondBind<NI, NO>(f: DO -> ProxyRepr<UO, UI, NI, NO, DI>) -> ProxyRepr<UO, UI, NI, NO, FR> {
        switch self {
        case let Request(uO, fUI): return ProxyRepr<UO, UI, NI, NO, FR>.Request(uO) { fUI($0).respondBind(f) }
        case let Respond(dO, fDI): return f(dO()).bind { fDI($0).respondBind(f) }
        case let Pure(x): return ProxyRepr<UO, UI, NI, NO, FR>.Pure(x)
        }
    }

    internal func requestBind<NO, NI>(f: UO -> ProxyRepr<NO, NI, DI, DO, UI>) -> ProxyRepr<NO, NI, DI, DO, FR> {
        switch self {
        case let Request(uO, fUI): return f(uO()).bind { fUI($0).requestBind(f) }
        case let Respond(dO, fDI): return ProxyRepr<NO, NI, DI, DO, FR>.Respond(dO) { fDI($0).requestBind(f) }
        case let Pure(x): return ProxyRepr<NO, NI, DI, DO, FR>.Pure(x)
        }
    }

    internal func pushBind<NI, NO>(f: DO -> ProxyRepr<DI, DO, NI, NO, FR>) -> ProxyRepr<UO, UI, NI, NO, FR> {
        switch self {
        case let Request(uO, fUI): return ProxyRepr<UO, UI, NI, NO, FR>.Request(uO) { pushBindExt(fUI($0), f) }
        case let Respond(dO, fDI): return pullBindExt(f(dO()), fDI)
        case let Pure(x): return ProxyRepr<UO, UI, NI, NO, FR>.Pure(x)
        }
    }

    internal func pullBind<NO, NI>(f: UO -> ProxyRepr<NO, NI, UO, UI, FR>) -> ProxyRepr<NO, NI, DI, DO, FR> {
        switch self {
        case let Request(uO, fUI): return pushBindExt(f(uO()), fUI)
        case let Respond(dO, fDI): return ProxyRepr<NO, NI, DI, DO, FR>.Respond(dO) { pullBindExt(fDI($0), f) }
        case let Pure(x): return ProxyRepr<NO, NI, DI, DO, FR>.Pure(x)
        }
    }
}

private func pushBindExt<UO, UI, DI, DO, NI, NO, FR>(p: ProxyRepr<UO, UI, DI, DO, FR>, f: DO -> ProxyRepr<DI, DO, NI, NO, FR>) -> ProxyRepr<UO, UI, NI, NO, FR> {
    return p.pushBind(f)
}

private func pullBindExt<UO, UI, DI, DO, NI, NO, FR>(p: ProxyRepr<UO, UI, DI, DO, FR>, f: UO -> ProxyRepr<NO, NI, UO, UI, FR>) -> ProxyRepr<NO, NI, DI, DO, FR> {
    return p.pullBind(f)
}

/// A bidirectional channel for information.
///
/// The type parameters are as follows:
/// UO - upstream   output
/// UI - upstream   input
/// DI — downstream input
/// DO — downstream output
/// FR — final      result
public struct Proxy<UO, UI, DI, DO, FR> {
    private let _repr: () -> ProxyRepr<UO, UI, DI, DO, FR>

    internal init(_ r: @autoclosure () -> ProxyRepr<UO, UI, DI, DO, FR>) {
        _repr = r
    }

    internal var repr: ProxyRepr<UO, UI, DI, DO, FR> {
        return _repr()
    }
}

extension Proxy: Functor {
    typealias B = Any

    public func fmap<NR>(f: FR -> NR) -> Proxy<UO, UI, DI, DO, NR> {
        return Proxy<UO, UI, DI, DO, NR>(repr.fmap(f))
    }
}

public func <^><UO, UI, DI, DO, FR, NR>(f: FR -> NR, p: Proxy<UO, UI, DI, DO, FR>) -> Proxy<UO, UI, DI, DO, NR> {
    return p.fmap(f)
}

public prefix func <^><UO, UI, DI, DO, FR, NR>(p: Proxy<UO, UI, DI, DO, FR> ) -> (FR -> NR) -> Proxy<UO, UI, DI, DO, NR> {
    return { f in p.fmap(f) }
}

public postfix func <^><UO, UI, DI, DO, FR, NR>(f: FR -> NR) -> Proxy<UO, UI, DI, DO, FR> -> Proxy<UO, UI, DI, DO, NR> {
    return { p in p.fmap(f) }
}

extension Proxy: Pointed {
    public static func pure(x: FR) -> Proxy<UO, UI, DI, DO, FR> {
        return Proxy(ProxyRepr.Pure { _ in x })
    }
}

public func pure<UO, UI, DI, DO, FR>(x: FR) -> Proxy<UO, UI, DI, DO, FR> {
    return Proxy.pure(x)
}

extension Proxy: Applicative {
    public func ap<NR>(f: Proxy<UO, UI, DI, DO, FR -> NR>) -> Proxy<UO, UI, DI, DO, NR> {
        return Proxy<UO, UI, DI, DO, NR>(repr.ap(f.repr))
    }
}

public func <*><UO, UI, DI, DO, FR, NR>(f: Proxy<UO, UI, DI, DO, FR -> NR>, p: Proxy<UO, UI, DI, DO, FR>) -> Proxy<UO, UI, DI, DO, NR> {
    return p.ap(f)
}

public prefix func <*><UO, UI, DI, DO, FR, NR>(p: Proxy<UO, UI, DI, DO, FR>) -> Proxy<UO, UI, DI, DO, FR -> NR> -> Proxy<UO, UI, DI, DO, NR> {
    return { f in p.ap(f) }
}

public postfix func <*><UO, UI, DI, DO, FR, NR>(f: Proxy<UO, UI, DI, DO, FR -> NR>) -> Proxy<UO, UI, DI, DO, FR> -> Proxy<UO, UI, DI, DO, NR> {
    return { p in p.ap(f) }
}

extension Proxy: Monad {
    public func bind<NR>(f: FR -> Proxy<UO, UI, DI, DO, NR>) -> Proxy<UO, UI, DI, DO, NR> {
        return Proxy<UO, UI, DI, DO, NR>(repr.bind { f($0).repr })
    }
}

public func >>-<UO, UI, DI, DO, FR, NR>(p: Proxy<UO, UI, DI, DO, FR>, f: FR -> Proxy<UO, UI, DI, DO, NR>) -> Proxy<UO, UI, DI, DO, NR> {
    return p.bind(f)
}

public prefix func >>-<UO, UI, DI, DO, FR, NR>(f: FR -> Proxy<UO, UI, DI, DO, NR>) -> Proxy<UO, UI, DI, DO, FR> -> Proxy<UO, UI, DI, DO, NR> {
    return { p in p.bind(f) }
}

public postfix func >>-<UO, UI, DI, DO, FR, NR>(p: Proxy<UO, UI, DI, DO, FR>) -> (FR -> Proxy<UO, UI, DI, DO, NR>) -> Proxy<UO, UI, DI, DO, NR> {
    return { f in p.bind(f) }
}

extension Proxy {
    public func reflect() -> Proxy<DO, DI, UI, UO, FR> {
        return Proxy<DO, DI, UI, UO, FR>(repr.reflect())
    }
}

internal func closed<A>(x: () -> X) -> A {
    return x().absurd()
}

public func runEffect<FR>(p: Proxy<X, (), (), X, FR>) -> FR {
    switch p.repr {
    case let .Request(uO, _): return closed(uO)
    case let .Respond(dO, _): return closed(dO)
    case let .Pure(x): return x()
    }
}
