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
    case Request(Box<UO>, Box<UI> -> ProxyRepr<UO, UI, DI, DO, FR>)
    case Respond(Box<DO>, Box<DI> -> ProxyRepr<UO, UI, DI, DO, FR>)
    case Pure(Box<FR>)

    internal func observe() -> ProxyRepr<UO, UI, DI, DO, FR> {
        switch self {
        case let Request(uO, fUI): return Request(uO) { fUI($0).observe() }
        case let Respond(dO, fDI): return Respond(dO) { fDI($0).observe() }
        case Pure(_): return self
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

    public func observe() -> Proxy<UO, UI, DI, DO, FR> {
        return Proxy(repr.observe())
    }
}
