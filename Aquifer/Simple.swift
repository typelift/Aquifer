//
//  Simple.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/26/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

import Foundation
import Swiftz

public func next<DO, FR>(p: Proxy<X, (), (), DO, FR>) -> Either<FR, (DO, Proxy<X, (), (), DO, FR>)> {
    switch p.repr {
    case let .Request(uO, _): return closed(uO)
    case let .Respond(dO, fDI): return .Right(Box((dO(), Proxy(fDI(())))))
    case let .Pure(x): return .Left(Box(x()))
    }
}
