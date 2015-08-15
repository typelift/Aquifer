//
//  Operators.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/14/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

// roughly `Pipes.Core`

import Swiftz

/// Send a value upstream and block waiting for a reply.
public func request<UO, UI, DI, DO>(@autoclosure(escaping) uO: () -> UO) -> Proxy<UO, UI, DI, DO, UI> {
    return Proxy(ProxyRepr.Request(uO) { x in ProxyRepr.Pure { _ in x } })
}

/// Send a value downstream and block waiting for a reply.
public func respond<UO, UI, DI, DO>(@autoclosure(escaping) dO: () -> DO) -> Proxy<UO, UI, DI, DO, DI> {
    return Proxy(ProxyRepr.Respond(dO) { x in ProxyRepr.Pure { _ in x} })
}

/// Forward responses followed by requests.
public func push<UT, DT, FR>(@autoclosure(escaping) dT: () -> DT) -> Proxy<UT, DT, UT, DT, FR> {
    return Proxy(pushRepr(dT))
}

/// Forward requests followed by responses.
public func pull<UT, DT, FR>(@autoclosure(escaping) uT: () -> UT) -> Proxy<UT, DT, UT, DT, FR> {
    return Proxy(pullRepr(uT))
}

infix operator |>> {
associativity left
precedence 120
}

/// For | Loops over all downstream values in the given pipe replacing them with the pipe given by
/// the application of the given function.
public func |>> <UO, UI, DI, DO, NI, NO, FR>(p: Proxy<UO, UI, DI, DO, FR>, f: DO -> Proxy<UO, UI, NI, NO, DI>) -> Proxy<UO, UI, NI, NO, FR> {
    return Proxy(p.repr.respondBind { f($0).repr })
}

infix operator <<| {
associativity right
precedence 120
}

/// For | Loops over all downstream values in the given pipe replacing them with the pipe given by
/// the application of the given function.
public func <<| <UO, UI, DI, DO, NI, NO, FR>(f: DO -> Proxy<UO, UI, NI, NO, DI>, p: Proxy<UO, UI, DI, DO, FR>) -> Proxy<UO, UI, NI, NO, FR> {
    return p |>> f
}

infix operator |>| {
associativity right
precedence 130
}

/// Compose Unfolds | Composes two unfolds.
public func |>| <IS, UO, UI, DI, DO, NI, NO, FR>(f: IS -> Proxy<UO, UI, DI, DO, FR>, g: DO -> Proxy<UO, UI, NI, NO, DI>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return { f($0) |>> g }
}

infix operator |<| {
associativity left
precedence 140
}

/// Compose Unfolds Backwards | Composes two unfolds.
public func |<| <IS, UO, UI, DI, DO, NI, NO, FR>(f: DO -> Proxy<UO, UI, NI, NO, DI>, g: IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return g |>| f
}

infix operator >>| {
associativity right
precedence 130
}

infix operator >|> {
associativity right
precedence 140
}

/// Compose two unfolds, creating a new unfold
public func >|> <IS, UO, UI, DI, DO, NO, NI, FR>(f: IS -> Proxy<UO, UI, DI, DO, FR>, g: UO -> Proxy<NO, NI, DI, DO, UI>) -> IS -> Proxy<NO, NI, DI, DO, FR> {
    return { f($0) |<< g }
}

infix operator <|< {
associativity left
precedence 130
}

/// Compose two unfolds, creating a new unfold
public func <|< <IS, UO, UI, DI, DO, NO, NI, FR>(f: UO -> Proxy<NO, NI, DI, DO, UI>, g: IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<NO, NI, DI, DO, FR> {
    return g >|> f
}

/// replaces each 'request' in @p@ with @f@.
public func >>| <UO, UI, DI, DO, NO, NI, FR>(f: UO -> Proxy<NO, NI, DI, DO, UI>, p: Proxy<UO, UI, DI, DO, FR>) -> Proxy<NO, NI, DI, DO, FR> {
    return p |<< f
}

infix operator |<< {
associativity left
precedence 130
}

/// replaces each 'request' in @p@ with @f@.
public func |<< <UO, UI, DI, DO, NO, NI, FR>(p: Proxy<UO, UI, DI, DO, FR>, f: UO -> Proxy<NO, NI, DI, DO, UI>) -> Proxy<NO, NI, DI, DO, FR> {
    return Proxy(p.repr.requestBind { f($0).repr })
}

infix operator +>> {
associativity right
precedence 150
}

/// Pair-Up | pairs each 'request' in @p@ with a 'respond' in @f@.
public func +>> <UO, UI, DI, DO, NO, NI, FR>(f: UO -> Proxy<NO, NI, UO, UI, FR>, p: Proxy<UO, UI, DI, DO, FR>) -> Proxy<NO, NI, DI, DO, FR> {
    return p <<+ f
}

infix operator <<+ {
associativity left
precedence 150
}

/// Pair-Up | pairs each 'request' in @p@ with a 'respond' in @f@.
public func <<+ <UO, UI, DI, DO, NO, NI, FR>(p: Proxy<UO, UI, DI, DO, FR>, f: UO -> Proxy<NO, NI, UO, UI, FR>) -> Proxy<NO, NI, DI, DO, FR> {
    return Proxy(p.repr.pullBind { f($0).repr })
}

infix operator >>~ {
associativity left
precedence 160
}

/// Pair-Up | Pairs each 'respond' in @p@ with an 'request' in @f@.
public func >>~ <UO, UI, DI, DO, NI, NO, FR>(p: Proxy<UO, UI, DI, DO, FR>, f: DO -> Proxy<DI, DO, NI, NO, FR>) -> Proxy<UO, UI, NI, NO, FR> {
    return Proxy(p.repr.pushBind { f($0).repr })
}

infix operator ~<< {
associativity right
precedence 160
}

/// Pair-Up | Pairs each 'respond' in @p@ with an 'request' in @f@.
public func ~<< <UO, UI, DI, DO, NI, NO, FR>(f: DO -> Proxy<DI, DO, NI, NO, FR>, p: Proxy<UO, UI, DI, DO, FR>) -> Proxy<UO, UI, NI, NO, FR> {
    return p >>~ f
}

infix operator >+> {
associativity left
precedence 160
}

/// Connect | Connect pull-based streams
public func >+> <IS, UO, UI, DI, DO, NO, NI, FR>(f: UO -> Proxy<NO, NI, UO, UI, FR>, g: IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<NO, NI, DI, DO, FR> {
    return g <+< f
}

infix operator <+< {
associativity right
precedence 160
}

/// Connect | Connect pull-based streams
public func <+< <IS, UO, UI, DI, DO, NO, NI, FR>(f: IS -> Proxy<UO, UI, DI, DO, FR>, g: UO -> Proxy<NO, NI, UO, UI, FR>) -> IS -> Proxy<NO, NI, DI, DO, FR> {
    return { f($0) <<+ g }
}

infix operator >~> {
associativity right
precedence 170
}

/// Connect | Connect push-based streams.
public func >~> <IS, UO, UI, DI, DO, NI, NO, FR>(f: IS -> Proxy<UO, UI, DI, DO, FR>, g: DO -> Proxy<DI, DO, NI, NO, FR>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return { f($0) >>~ g }
}

infix operator <~< {
associativity left
precedence 170
}

/// Connect | Connect push-based streams.
public func <~< <IS, UO, UI, DI, DO, NI, NO, FR>(f: DO -> Proxy<DI, DO, NI, NO, FR>, g: IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return g >~> f
}

/// Implementation Details follow

private func pushRepr<UT, DT, FR>(dT: () -> DT) -> ProxyRepr<UT, DT, UT, DT, FR> {
    return ProxyRepr.Respond(dT) { uT in ProxyRepr.Request({ _ in uT }) { x in pushRepr { _ in x } } }
}

private func pullRepr<UT, DT, FR>(uT: () -> UT) -> ProxyRepr<UT, DT, UT, DT, FR> {
    return ProxyRepr.Request(uT) { dT in ProxyRepr.Respond({ _ in dT }) { x in pullRepr { _ in x } } }
}
