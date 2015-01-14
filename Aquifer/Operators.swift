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

infix operator |>> {
associativity left
precedence 120
}

internal func respondBind<UO, UI, DI, DO, NI, NO, FR>(p: ProxyRepr<UO, UI, DI, DO, FR>, f: DI -> ProxyRepr<UO, UI, NI, NO, DO>) -> ProxyRepr<UO, UI, NI, NO, FR> {
    switch 
}

public func |>><UO, UI, DI, DO, NI, NO, FR>(p: Proxy<UO, UI, DI, DO, FR>, f: DI -> Proxy<UO, UI, NI, NO, DO>) -> Proxy<UO, UI, NI,NO, FR> {
    return Proxy(respondBind(p.repr) { f($0).repr })
}

prefix operator |>> {}

public prefix func |>><UO, UI, DI, DO, NI, NO, FR>(f: DI -> Proxy<UO, UI, NI, NO, DO>) -> Proxy<UO, UI, DI, DO, FR> -> Proxy<UO, UI, NI, NO, FR> {
    return { p in p |>> f }
}

postfix operator |>> {}

public postfix func |>><UO, UI, DI, DO, NI, NO, FR>(p: Proxy<UO, UI, DI, DO, FR>) -> (DI -> Proxy<UO, UI, NI, NO, DO>) -> Proxy<UO, UI, NI,NO, FR> {
    return { f in p |>> f }
}

infix operator <<| {
associativity right
precedence 120
}

prefix operator <<| {}

postfix operator <<| {}

infix operator |>| {
associativity right
precedence 130
}

prefix operator |>| {}

postfix operator |>| {}

infix operator >>| {
associativity right
precedence 130
}

prefix operator >>| {}

postfix operator >>| {}

infix operator <|< {
associativity left
precedence 130
}

prefix operator <|< {}

postfix operator <|< {}

infix operator |<< {
associativity left
precedence 130
}

prefix operator |<< {}

postfix operator |<< {}

infix operator |<| {
associativity left
precedence 140
}

prefix operator |<| {}

postfix operator |<| {}

infix operator >|> {
associativity right
precedence 140
}

prefix operator >|> {}

postfix operator >|> {}

infix operator <<+ {
associativity left
precedence 150
}

prefix operator <<+ {}

postfix operator <<+ {}

infix operator +>> {
associativity right
precedence 150
}

prefix operator +>> {}

postfix operator +>> {}

infix operator >+> {
associativity left
precedence 160
}

prefix operator >+> {}

postfix operator >+> {}

infix operator >>~ {
associativity left
precedence 160
}

prefix operator >>~ {}

postfix operator >>~ {}

infix operator <+< {
associativity right
precedence 160
}

prefix operator <+< {}

postfix operator <+< {}

infix operator ~<< {
associativity right
precedence 160
}

prefix operator ~<< {}

postfix operator ~<< {}

infix operator <~< {
associativity left
precedence 170
}

prefix operator <~< {}

postfix operator <~< {}

infix operator >~> {
associativity right
precedence 170
}

prefix operator >~> {}

postfix operator >~> {}
