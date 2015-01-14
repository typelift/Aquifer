//
//  Operators.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/14/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

import Foundation
import Swiftz

public func respond<UO, UI, DI, DO, FR>(dO: DO) -> Proxy<UO, UI, DI, DO, FR> {
    return Proxy(ProxyRepr.Respond({ _ in dO }, { x in ProxyRepr.Pure { _ in x } }))
}

infix operator |>> {
associativity left
precedence 120
}

prefix operator |>> {}

postfix operator |>> {}

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
