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
///
///            UO
///             |
///        +----|----+
///        |    |    |
///    UO <=====/   <== DI
///        |         |
///    UI ======\   ==> DO
///        |    |    |
///        +----|----+
///             v
///             UI
public func request<UO, UI, DI, DO>(@autoclosure(escaping) uO: () -> UO) -> Proxy<UO, UI, DI, DO, UI> {
    return Proxy(ProxyRepr.Request(uO) { x in ProxyRepr.Pure { _ in x } })
}

/// Send a value downstream and block waiting for a reply.
///
///          DO
///           |
///      +----|----+
///      |    |    |
/// UO <===  \ / ==== DI
///      |    X    |
/// UI ===>  / \ ===> DO
///      |    |    |
///      +----|----+
///           v
///           DI
public func respond<UO, UI, DI, DO>(@autoclosure(escaping) dO: () -> DO) -> Proxy<UO, UI, DI, DO, DI> {
    return Proxy(ProxyRepr.Respond(dO) { x in ProxyRepr.Pure { _ in x} })
}

/// Forward requests followed by responses.
///
///            UT
///             |
///        +----|----+
///        |    v    |
///    UT <============ UT
///        |         |
///    DT ============> DT
///        |    |    |
///        +----|----+
///             v
///             FR
public func pull<UT, DT, FR>(@autoclosure(escaping) uT: () -> UT) -> Proxy<UT, DT, UT, DT, FR> {
    return Proxy(pullRepr(uT))
}

/// Forward responses followed by requests.
///
///            DT
///             |
///        +----|----+
///        |    v    |
///    UT <============ UT
///        |         |
///    DT ============> DT
///        |    |    |
///        +----|----+
///             v
///             FR
public func push<UT, DT, FR>(@autoclosure(escaping) dT: () -> DT) -> Proxy<UT, DT, UT, DT, FR> {
    return Proxy(pushRepr(dT))
}

// MARK: - Respond Category

/// Compose Unfolds | Composes two unfolds.
public func |>| <IS, UO, UI, DI, DO, NI, NO, FR>(f: IS -> Proxy<UO, UI, DI, DO, FR>, g: DO -> Proxy<UO, UI, NI, NO, DI>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return { f($0) |>> g }
}

/// Compose Unfolds Backwards | Composes two unfolds.
public func |<| <IS, UO, UI, DI, DO, NI, NO, FR>(f: DO -> Proxy<UO, UI, NI, NO, DI>, g: IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return g |>| f
}

/// replaces each 'respond' in @p@ with @f@.
///
///
///
///                              /===> b
///                             /      |
///     +---------+            /  +----|----+            +-----------+
///     |         |           /   |    v    |            |           |
/// x' <==       <== b' <==\ / x'<==       <== c'    x' <==         <== c'
///     |    f    |         X     |    g    |     =      | f '>>|' g |
/// x  ==>       ==> b  ===/ \ x ==>       ==> c     x  ==>         ==> c'
///     |    |    |           \   |    |    |            |     |     |
///     +----|----+            \  +----|----+            +-----|-----+
///          v                  \      v                       v
///          a'                  \==== b'                      a'
public func |>> <UO, UI, DI, DO, NI, NO, FR>(p: Proxy<UO, UI, DI, DO, FR>, f: DO -> Proxy<UO, UI, NI, NO, DI>) -> Proxy<UO, UI, NI, NO, FR> {
    return Proxy(p.repr.respondBind { f($0).repr })
}

/// replaces each 'request' in @p@ with @f@.
public func <<| <UO, UI, DI, DO, NI, NO, FR>(f: DO -> Proxy<UO, UI, NI, NO, DI>, p: Proxy<UO, UI, DI, DO, FR>) -> Proxy<UO, UI, NI, NO, FR> {
    return p |>> f
}

// MARK: - Request Category

/// Compose two unfolds, creating a new unfold
public func >|> <IS, UO, UI, DI, DO, NO, NI, FR>(f: IS -> Proxy<UO, UI, DI, DO, FR>, g: UO -> Proxy<NO, NI, DI, DO, UI>) -> IS -> Proxy<NO, NI, DI, DO, FR> {
    return { f($0) |<< g }
}

/// Compose two unfolds, creating a new unfold
public func <|< <IS, UO, UI, DI, DO, NO, NI, FR>(f: UO -> Proxy<NO, NI, DI, DO, UI>, g: IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<NO, NI, DI, DO, FR> {
    return g >|> f
}

/// replaces each 'request' in @p@ with @f@.
///
///          b'<=====\
///          |        \
///     +----|----+    \         +---------+            +-----------+
///     |    v    |     \        |         |            |           |
/// a' <==       <== y'  \== b' <==       <== y'    a' <==         <== y'
///     |    f    |              |    g    |     =      | f '>>|' g |
/// a  ==>       ==> y   /=> b  ==>       ==> y     a  ==>         ==> y
///     |    |    |     /        |    |    |            |     |     |
///     +----|----+    /         +----|----+            +-----|-----+
///          v        /               v                       v
///          b ======/                c                       c
public func >>| <UO, UI, DI, DO, NO, NI, FR>(f: UO -> Proxy<NO, NI, DI, DO, UI>, p: Proxy<UO, UI, DI, DO, FR>) -> Proxy<NO, NI, DI, DO, FR> {
    return p |<< f
}

/// replaces each 'request' in @p@ with @f@.
public func |<< <UO, UI, DI, DO, NO, NI, FR>(p: Proxy<UO, UI, DI, DO, FR>, f: UO -> Proxy<NO, NI, DI, DO, UI>) -> Proxy<NO, NI, DI, DO, FR> {
    return Proxy(p.repr.requestBind { f($0).repr })
}

// MARK: - Push Category

/// Connect-Upstream | Connect push-based streams.
///
/// Given two pipes awaiting upstream input, and with compatible upstream and downstream interfaces,
/// produces a pipe awaiting upstream input to be passed through the former pipe then down through
/// the latter pipe.
public func >~> <UO, UI, DI, DO, NI, NO, FR>(f: UI -> Proxy<UO, UI, DI, DO, FR>, g: DO -> Proxy<DI, DO, NI, NO, FR>) -> UI -> Proxy<UO, UI, NI, NO, FR> {
    return { f($0) >>~ g }
}

/// Connect-Upstream | Like Connect-Upstream but backwards.
public func <~< <UO, UI, DI, DO, NI, NO, FR>(f: DO -> Proxy<DI, DO, NI, NO, FR>, g: UI -> Proxy<UO, UI, DI, DO, FR>) -> UI -> Proxy<UO, UI, NI, NO, FR> {
    return g >~> f
}

/// Pair-Up | Given a pipe of upstream responses and a pipe requesting upstream responses, pairs
/// each request with a response and unblocks the waiting pipe.
public func >>~ <UO, UI, DI, DO, NI, NO, FR>(p: Proxy<UO, UI, DI, DO, FR>, f: DO -> Proxy<DI, DO, NI, NO, FR>) -> Proxy<UO, UI, NI, NO, FR> {
    return Proxy(p.repr.pushBind { f($0).repr })
}

/// Pair-Up | Like Pair-Up but backwards.
public func ~<< <UO, UI, DI, DO, NI, NO, FR>(f: DO -> Proxy<DI, DO, NI, NO, FR>, p: Proxy<UO, UI, DI, DO, FR>) -> Proxy<UO, UI, NI, NO, FR> {
    return p >>~ f
}

// MARK: - Pull Category

/// Connect-Downstream | Connect pull-based streams
///
/// Given two pipes awaiting downstream input, and with compatible downstream and upstream
/// interfaces, produces a pipe awaiting downstream input to be passed through the former pipe then
/// up through the latter pipe.
public func >+> <IS, UO, UI, DI, DO, NO, NI, FR>(f: UO -> Proxy<NO, NI, UO, UI, FR>, g: IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<NO, NI, DI, DO, FR> {
    return g <+< f
}

/// Connect-Downstream | Like Connect-Downstream but backwards.
public func <+< <IS, UO, UI, DI, DO, NO, NI, FR>(f: IS -> Proxy<UO, UI, DI, DO, FR>, g: UO -> Proxy<NO, NI, UO, UI, FR>) -> IS -> Proxy<NO, NI, DI, DO, FR> {
    return { f($0) <<+ g }
}

/// Pair-Down | Given an upstream pipe requesting a downstream response and a downstream pipe of
/// responses, pairs each request with a response and unblocks the waiting pipe.
public func +>> <UO, UI, DI, DO, NO, NI, FR>(f: UO -> Proxy<NO, NI, UO, UI, FR>, p: Proxy<UO, UI, DI, DO, FR>) -> Proxy<NO, NI, DI, DO, FR> {
    return p <<+ f
}

/// Pair-Down | Like Pair-Down but backwards.
public func <<+ <UO, UI, DI, DO, NO, NI, FR>(p: Proxy<UO, UI, DI, DO, FR>, f: UO -> Proxy<NO, NI, UO, UI, FR>) -> Proxy<NO, NI, DI, DO, FR> {
    return Proxy(p.repr.pullBind { f($0).repr })
}

// MARK: - Implementation Details Follow

private func pushRepr<UT, DT, FR>(dT: () -> DT) -> ProxyRepr<UT, DT, UT, DT, FR> {
    return ProxyRepr.Respond(dT) { uT in ProxyRepr.Request({ _ in uT }) { x in pushRepr { _ in x } } }
}

private func pullRepr<UT, DT, FR>(uT: () -> UT) -> ProxyRepr<UT, DT, UT, DT, FR> {
    return ProxyRepr.Request(uT) { dT in ProxyRepr.Respond({ _ in dT }) { x in pullRepr { _ in x } } }
}
