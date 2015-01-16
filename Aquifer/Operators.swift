//
//  Operators.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/14/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

import Foundation
import Swiftz

public func respond<UO, UI, DI, DO>(dO: @autoclosure () -> DO) -> Proxy<UO, UI, DI, DO, DI> {
    return Proxy(ProxyRepr.Respond(dO) { x in ProxyRepr.Pure { _ in x} })
}

public func request<UO, UI, DI, DO>(uO: @autoclosure () -> UO) -> Proxy<UO, UI, DI, DO, UI> {
    return Proxy(ProxyRepr.Request(uO) { x in ProxyRepr.Pure { _ in x } })
}

internal func pushRepr<UT, DT, FR>(dT: () -> DT) -> ProxyRepr<UT, DT, UT, DT, FR> {
    return ProxyRepr.Respond(dT) { uT in ProxyRepr.Request({ _ in uT }) { x in pushRepr { _ in x } } }
}

public func push<UT, DT, FR>(dT: @autoclosure () -> DT) -> Proxy<UT, DT, UT, DT, FR> {
    return Proxy(pushRepr(dT))
}

internal func pullRepr<UT, DT, FR>(uT: () -> UT) -> ProxyRepr<UT, DT, UT, DT, FR> {
    return ProxyRepr.Request(uT) { dT in ProxyRepr.Respond({ _ in dT }) { x in pullRepr { _ in x } } }
}

public func pull<UT, DT, FR>(uT: @autoclosure () -> UT) -> Proxy<UT, DT, UT, DT, FR> {
    return Proxy(pullRepr(uT))
}

infix operator |>> {
associativity left
precedence 120
}

public func |>><UO, UI, DI, DO, NI, NO, FR>(p: Proxy<UO, UI, DI, DO, FR>, f: DO -> Proxy<UO, UI, NI, NO, DI>) -> Proxy<UO, UI, NI, NO, FR> {
    return Proxy(p.repr.respondBind { f($0).repr })
}

prefix operator |>> {}

public prefix func |>><UO, UI, DI, DO, NI, NO, FR>(f: DO -> Proxy<UO, UI, NI, NO, DI>) -> Proxy<UO, UI, DI, DO, FR> -> Proxy<UO, UI, NI, NO, FR> {
    return { p in p |>> f }
}

postfix operator |>> {}

public postfix func |>><UO, UI, DI, DO, NI, NO, FR>(p: Proxy<UO, UI, DI, DO, FR>) -> (DO -> Proxy<UO, UI, NI, NO, DI>) -> Proxy<UO, UI, NI, NO, FR> {
    return { f in p |>> f }
}

infix operator <<| {
associativity right
precedence 120
}

public func <<|<UO, UI, DI, DO, NI, NO, FR>(f: DO -> Proxy<UO, UI, NI, NO, DI>, p: Proxy<UO, UI, DI, DO, FR>) -> Proxy<UO, UI, NI, NO, FR> {
    return p |>> f
}

prefix operator <<| {}

public prefix func <<|<UO, UI, DI, DO, NI, NO, FR>(p: Proxy<UO, UI, DI, DO, FR>) -> (DO -> Proxy<UO, UI, NI, NO, DI>) -> Proxy<UO, UI, NI, NO, FR> {
    return { f in p |>> f }
}

postfix operator <<| {}

public postfix func <<|<UO, UI, DI, DO, NI, NO, FR>(f: DO -> Proxy<UO, UI, NI, NO, DI>) -> Proxy<UO, UI, DI, DO, FR> -> Proxy<UO, UI, NI, NO, FR> {
    return { p in p |>> f }
}

infix operator |>| {
associativity right
precedence 130
}

public func |>|<IS, UO, UI, DI, DO, NI, NO, FR>(f: IS -> Proxy<UO, UI, DI, DO, FR>, g: DO -> Proxy<UO, UI, NI, NO, DI>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return { f($0) |>> g }
}

prefix operator |>| {}

public prefix func |>|<IS, UO, UI, DI, DO, NI, NO, FR>(g: DO -> Proxy<UO, UI, NI, NO, DI>) -> (IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return { f in f |>| g }
}

postfix operator |>| {}

public postfix func |>|<IS, UO, UI, DI, DO, NI, NO, FR>(f: IS -> Proxy<UO, UI, DI, DO, FR>) -> (DO -> Proxy<UO, UI, NI, NO, DI>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return { g in f |>| g }
}

infix operator >>| {
associativity right
precedence 130
}

public func >>|<UO, UI, DI, DO, NO, NI, FR>(p: Proxy<UO, UI, DI, DO, FR>, f: UO -> Proxy<NO, NI, DI, DO, UI>) -> Proxy<NO, NI, DI, DO, FR> {
    return Proxy(p.repr.requestBind { f($0).repr })
}

prefix operator >>| {}

public prefix func >>|<UO, UI, DI, DO, NO, NI, FR>(f: UO -> Proxy<NO, NI, DI, DO, UI>) -> Proxy<UO, UI, DI, DO, FR> -> Proxy<NO, NI, DI, DO, FR> {
    return { p in p >>| f }
}

postfix operator >>| {}

public postfix func >>|<UO, UI, DI, DO, NO, NI, FR>(p: Proxy<UO, UI, DI, DO, FR>) -> (UO -> Proxy<NO, NI, DI, DO, UI>) -> Proxy<NO, NI, DI, DO, FR> {
    return { f in p >>| f }
}

infix operator <|< {
associativity left
precedence 130
}

public func <|<<IS, UO, UI, DI, DO, NO, NI, FR>(f: UO -> Proxy<NO, NI, DI, DO, UI>, g: IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<NO, NI, DI, DO, FR> {
    return g >|> f
}

prefix operator <|< {}

public prefix func <|<<IS, UO, UI, DI, DO, NO, NI, FR>(f: UO -> Proxy<NO, NI, DI, DO, UI>) -> (IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<NO, NI, DI, DO, FR> {
    return { g in g >|> f }
}

postfix operator <|< {}

public postfix func <|<<IS, UO, UI, DI, DO, NO, NI, FR>(g: IS -> Proxy<UO, UI, DI, DO, FR>) -> (UO -> Proxy<NO, NI, DI, DO, UI>) -> IS -> Proxy<NO, NI, DI, DO, FR> {
    return { f in g >|> f }
}

infix operator |<< {
associativity left
precedence 130
}

public func |<<<UO, UI, DI, DO, NO, NI, FR>(f: UO -> Proxy<NO, NI, DI, DO, UI>, p: Proxy<UO, UI, DI, DO, FR>) -> Proxy<NO, NI, DI, DO, FR> {
    return p >>| f
}

prefix operator |<< {}

public prefix func |<<<UO, UI, DI, DO, NO, NI, FR>(p: Proxy<UO, UI, DI, DO, FR>) -> (UO -> Proxy<NO, NI, DI, DO, UI>) -> Proxy<NO, NI, DI, DO, FR> {
    return { f in p >>| f }
}

postfix operator |<< {}

public postfix func |<<<UO, UI, DI, DO, NO, NI, FR>(f: UO -> Proxy<NO, NI, DI, DO, UI>) -> Proxy<UO, UI, DI, DO, FR> -> Proxy<NO, NI, DI, DO, FR> {
    return { p in p >>| f }
}

infix operator |<| {
associativity left
precedence 140
}

public func |<|<IS, UO, UI, DI, DO, NI, NO, FR>(f: DO -> Proxy<UO, UI, NI, NO, DI>, g: IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return g |>| f
}

prefix operator |<| {}

public prefix func |<|<IS, UO, UI, DI, DO, NI, NO, FR>(g: IS -> Proxy<UO, UI, DI, DO, FR>) -> (DO -> Proxy<UO, UI, NI, NO, DI>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return { f in g |>| f }
}

postfix operator |<| {}

public postfix func |<|<IS, UO, UI, DI, DO, NI, NO, FR>(f: DO -> Proxy<UO, UI, NI, NO, DI>) -> (IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return { g in g |>| f }
}

infix operator >|> {
associativity right
precedence 140
}

public func >|><IS, UO, UI, DI, DO, NO, NI, FR>(f: IS -> Proxy<UO, UI, DI, DO, FR>, g: UO -> Proxy<NO, NI, DI, DO, UI>) -> IS -> Proxy<NO, NI, DI, DO, FR> {
    return { f($0) >>| g }
}

prefix operator >|> {}

public prefix func >|><IS, UO, UI, DI, DO, NO, NI, FR>(f: IS -> Proxy<UO, UI, DI, DO, FR>) -> (UO -> Proxy<NO, NI, DI, DO, UI>) -> IS -> Proxy<NO, NI, DI, DO, FR> {
    return { g in f >|> g }
}

postfix operator >|> {}

public postfix func >|><IS, UO, UI, DI, DO, NO, NI, FR>(g: UO -> Proxy<NO, NI, DI, DO, UI>) -> (IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<NO, NI, DI, DO, FR> {
    return { f in f >|> g }
}

infix operator <<+ {
associativity left
precedence 150
}

public func <<+<UO, UI, DI, DO, NO, NI, FR>(p: Proxy<UO, UI, DI, DO, FR>, f: UO -> Proxy<NO, NI, UO, UI, FR>) -> Proxy<NO, NI, DI, DO, FR> {
    return Proxy(p.repr.pullBind { f($0).repr })
}

prefix operator <<+ {}

public prefix func <<+<UO, UI, DI, DO, NO, NI, FR>(f: UO -> Proxy<NO, NI, UO, UI, FR>) -> Proxy<UO, UI, DI, DO, FR> -> Proxy<NO, NI, DI, DO, FR> {
    return { p in p <<+ f }
}

postfix operator <<+ {}

public postfix func <<+<UO, UI, DI, DO, NO, NI, FR>(p: Proxy<UO, UI, DI, DO, FR>) -> (UO -> Proxy<NO, NI, UO, UI, FR>) -> Proxy<NO, NI, DI, DO, FR> {
    return { f in p <<+ f }
}

infix operator +>> {
associativity right
precedence 150
}

public func +>><UO, UI, DI, DO, NO, NI, FR>(f: UO -> Proxy<NO, NI, UO, UI, FR>, p: Proxy<UO, UI, DI, DO, FR>) -> Proxy<NO, NI, DI, DO, FR> {
    return p <<+ f
}

prefix operator +>> {}

public prefix func +>><UO, UI, DI, DO, NO, NI, FR>(p: Proxy<UO, UI, DI, DO, FR>) -> (UO -> Proxy<NO, NI, UO, UI, FR>) -> Proxy<NO, NI, DI, DO, FR> {
    return { f in p <<+ f }
}

postfix operator +>> {}

public postfix func +>><UO, UI, DI, DO, NO, NI, FR>(f: UO -> Proxy<NO, NI, UO, UI, FR>) -> Proxy<UO, UI, DI, DO, FR> -> Proxy<NO, NI, DI, DO, FR> {
    return { p in p <<+ f }
}

infix operator >+> {
associativity left
precedence 160
}

public func >+><IS, UO, UI, DI, DO, NO, NI, FR>(f: UO -> Proxy<NO, NI, UO, UI, FR>, g: IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<NO, NI, DI, DO, FR> {
    return g <+< f
}

prefix operator >+> {}

public prefix func >+><IS, UO, UI, DI, DO, NO, NI, FR>(g: IS -> Proxy<UO, UI, DI, DO, FR>) -> (UO -> Proxy<NO, NI, UO, UI, FR>) -> IS -> Proxy<NO, NI, DI, DO, FR> {
    return { f in g <+< f }
}

postfix operator >+> {}

public postfix func >+><IS, UO, UI, DI, DO, NO, NI, FR>(f: UO -> Proxy<NO, NI, UO, UI, FR>) -> (IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<NO, NI, DI, DO, FR> {
    return { g in g <+< f }
}

infix operator >>~ {
associativity left
precedence 160
}

public func >>~<UO, UI, DI, DO, NI, NO, FR>(p: Proxy<UO, UI, DI, DO, FR>, f: DO -> Proxy<DI, DO, NI, NO, FR>) -> Proxy<UO, UI, NI, NO, FR> {
    return Proxy(p.repr.pushBind { f($0).repr })
}

prefix operator >>~ {}

public prefix func >>~<UO, UI, DI, DO, NI, NO, FR>(f: DO -> Proxy<DI, DO, NI, NO, FR>) -> Proxy<UO, UI, DI, DO, FR> -> Proxy<UO, UI, NI, NO, FR> {
    return { p in p >>~ f }
}

postfix operator >>~ {}

public postfix func >>~<UO, UI, DI, DO, NI, NO, FR>(p: Proxy<UO, UI, DI, DO, FR>) -> (DO -> Proxy<DI, DO, NI, NO, FR>) -> Proxy<UO, UI, NI, NO, FR> {
    return { f in p >>~ f }
}

infix operator <+< {
associativity right
precedence 160
}

public func <+<<IS, UO, UI, DI, DO, NO, NI, FR>(f: IS -> Proxy<UO, UI, DI, DO, FR>, g: UO -> Proxy<NO, NI, UO, UI, FR>) -> IS -> Proxy<NO, NI, DI, DO, FR> {
    return { f($0) <<+ g }
}

prefix operator <+< {}

public prefix func <+<<IS, UO, UI, DI, DO, NO, NI, FR>(g: UO -> Proxy<NO, NI, UO, UI, FR>) -> (IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<NO, NI, DI, DO, FR> {
    return { f in f <+< g }
}

postfix operator <+< {}

public postfix func <+<<IS, UO, UI, DI, DO, NO, NI, FR>(f: IS -> Proxy<UO, UI, DI, DO, FR>) -> (UO -> Proxy<NO, NI, UO, UI, FR>) -> IS -> Proxy<NO, NI, DI, DO, FR> {
    return { g in f <+< g }
}

infix operator ~<< {
associativity right
precedence 160
}

public func ~<<<UO, UI, DI, DO, NI, NO, FR>(f: DO -> Proxy<DI, DO, NI, NO, FR>, p: Proxy<UO, UI, DI, DO, FR>) -> Proxy<UO, UI, NI, NO, FR> {
    return p >>~ f
}

prefix operator ~<< {}

public prefix func ~<<<UO, UI, DI, DO, NI, NO, FR>(p: Proxy<UO, UI, DI, DO, FR>) -> (DO -> Proxy<DI, DO, NI, NO, FR>) -> Proxy<UO, UI, NI, NO, FR> {
    return { f in p >>~ f }
}

postfix operator ~<< {}

public postfix func ~<<<UO, UI, DI, DO, NI, NO, FR>(f: DO -> Proxy<DI, DO, NI, NO, FR>) -> Proxy<UO, UI, DI, DO, FR> -> Proxy<UO, UI, NI, NO, FR> {
    return { p in p >>~ f }
}

infix operator <~< {
associativity left
precedence 170
}

public func <~<<IS, UO, UI, DI, DO, NI, NO, FR>(f: DO -> Proxy<DI, DO, NI, NO, FR>, g: IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return g >~> f
}

prefix operator <~< {}

public prefix func <~<<IS, UO, UI, DI, DO, NI, NO, FR>(f: IS -> Proxy<UO, UI, DI, DO, FR>) -> (DO -> Proxy<DI, DO, NI, NO, FR>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return { g in f >~> g }
}

postfix operator <~< {}

public postfix func <~<<IS, UO, UI, DI, DO, NI, NO, FR>(g: DO -> Proxy<DI, DO, NI, NO, FR>) -> (IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return { f in f >~> g }
}

infix operator >~> {
associativity right
precedence 170
}

public func >~><IS, UO, UI, DI, DO, NI, NO, FR>(f: IS -> Proxy<UO, UI, DI, DO, FR>, g: DO -> Proxy<DI, DO, NI, NO, FR>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return { f($0) >>~ g }
}

prefix operator >~> {}

public prefix func >~><IS, UO, UI, DI, DO, NI, NO, FR>(g: DO -> Proxy<DI, DO, NI, NO, FR>) -> (IS -> Proxy<UO, UI, DI, DO, FR>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return { f in f >~> g }
}

postfix operator >~> {}

public postfix func >~><IS, UO, UI, DI, DO, NI, NO, FR>(f: IS -> Proxy<UO, UI, DI, DO, FR>) -> (DO -> Proxy<DI, DO, NI, NO, FR>) -> IS -> Proxy<UO, UI, NI, NO, FR> {
    return { g in f >~> g }
}
