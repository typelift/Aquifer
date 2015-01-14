//
//  Proxy.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/13/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

import Foundation
import Swiftz

public struct Proxy<UO, UI, DI, DO, FR> {
    private let repr: ProxyRepr<UO, UI, DI, DO, FR>

    internal init(_ repr: ProxyRepr<UO, UI, DI, DO, FR>) {
        self.repr = repr
    }
}

internal enum ProxyRepr<UO, UI, DI, DO, FR> {
    case Request(() -> UO, UI -> ProxyRepr<UO, UI, DI, DO, FR>)
    case Respond(() -> DO, DI -> ProxyRepr<UO, UI, DI, DO, FR>)
    case Pure(FR)
}
