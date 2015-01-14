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
    case Request(() -> UO, (() -> UI) -> ProxyRepr<UO, UI, DI, DO, FR>)
    case Respond(() -> DO, (() -> DI) -> ProxyRepr<UO, UI, DI, DO, FR>)
    case Pure(() -> FR)

    internal func observe() -> ProxyRepr<UO, UI, DI, DO, FR> {
        switch self {
        case let Request(uO, fUI): return Request(uO) { fUI($0).observe() }
        case let Respond(dO, fDI): return Respond(dO) { fDI($0).observe() }
        case Pure(_): return self
        }
    }

    internal func fmap<NR>(f: FR -> NR) -> ProxyRepr<UO, UI, DI, DO, NR> {
        switch self {
        case let Request(uO, fUI): return ProxyRepr<UO, UI, DI, DO, NR>.Request(uO) { fUI($0).fmap(f) }
        case let Respond(dO, fDI): return ProxyRepr<UO, UI, DI, DO, NR>.Respond(dO) { fDI($0).fmap(f) }
        case let Pure(x): return ProxyRepr<UO, UI, DI, DO, NR>.Pure { _ in f(x()) }
        }
    }
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
    private let repr: ProxyRepr<UO, UI, DI, DO, FR>

    internal init(_ r: ProxyRepr<UO, UI, DI, DO, FR>) {
        repr = r
    }

    /// This resets the internal representation, losing some minor performance in
    /// favor of more strictly obeying the Monad laws.
    ///
    /// This is used sparingly internally to make sure certain higher-order
    /// functions act properly.  Users may invoke this function to get
    /// back a Proxy that behaves identically to the original, but is internally
    /// reduced to a "canonical" representation.
    public func observe() -> Proxy<UO, UI, DI, DO, FR> {
        return Proxy(repr.observe())
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
