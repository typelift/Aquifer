//
//  Basic.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/28/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

// part of `Pipes.Prelude`

import Foundation
import Swiftz

public func once<UO, UI, DI, DO, FR>(v: () -> FR) -> Proxy<UO, UI, DI, DO, FR> {
    return Proxy(ProxyRepr.Pure(v))
}

public func repeat<UO, UI, DO, FR>(v: () -> DO) -> Proxy<UO, UI, (), DO, FR> {
    return once(v) >~ cat()
}

public func replicate<UO, UI, DO>(v: () -> DO, n: Int) -> Proxy<UO, UI, (), DO, ()> {
    return once(v) >~ take(n)
}

public func take<DT>(n: Int) -> Proxy<(), DT, (), DT, ()> {
    if n <= 0 {
        return pure(())
    } else {
        return await() >>- { yield($0) >>- { _ in take(n - 1) } }
    }
}

public func takeWhile<DT>(predicate: DT -> Bool) -> Proxy<(), DT, (), DT, ()> {
    return await() >>- { v in
        if predicate(v) {
            return yield(v) >>- { _ in takeWhile(predicate) }
        } else {
            return pure(())
        }
    }
}
