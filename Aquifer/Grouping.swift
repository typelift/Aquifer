//
//  Grouping.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/18/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

import Foundation
import Swiftz

internal enum GroupedProducerSignature<V, R> {
    case End(() -> R)
    case More(() -> Proxy<X, (), (), V, GroupedProducerSignature<V, R>>)
}

public struct GroupedProducer<V, R> {
    internal let underlying: () -> GroupedProducerSignature<V, R>

    internal init(_ u: @autoclosure () -> GroupedProducerSignature<V, R>) {
        underlying = u
    }
}

private func groupsBySignature<V, R>(p: Proxy<X, (), (), V, R>, equals: (V, V) -> Bool) -> GroupedProducerSignature<V, R> {
    switch next(p) {
    case let .Left(x): return GroupedProducerSignature.End { _ in x.value }
    case let .Right(k):
        let (dO, q) = k.value
        return GroupedProducerSignature.More { _ in
            groupsBySignature(
                span(
                    yield(dO) >>- { _ in
                        q
                    }
                    ) { v in
                        equals(dO, v)
                }, equals)
        }
    }
}

public func groupsBy<V, R>(p: Proxy<X, (), (), V, R>, equals: (V, V) -> Bool) -> GroupedProducer<V, R> {
    return GroupedProducer(groupsBySignature(p, equals))
}

public func groups<V: Equatable, R>(p: Proxy<X, (), (), V, R>) -> GroupedProducer<V, R> {
    return groupsBy(p) { v0, v1 in v0 == v1  }
}
