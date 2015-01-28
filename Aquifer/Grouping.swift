//
//  Grouping.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/18/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

import Foundation
import Swiftz

internal enum GroupedProducerRepr<V, R> {
    case End(() -> R)
    case More(() -> Proxy<X, (), (), V, GroupedProducerRepr<V, R>>)
}

public struct GroupedProducer<V, R> {
    internal let repr: () -> GroupedProducerRepr<V, R>

    internal init(_ r: @autoclosure () -> GroupedProducerRepr<V, R>) {
        repr = r
    }
}

public func delay(p: @autoclosure () -> GroupedProducer)

private func groupsBySignature<V, R>(p: Proxy<X, (), (), V, R>, equals: (V, V) -> Bool) -> GroupedProducerRepr<V, R> {
    switch next(p) {
    case let .Left(x): return GroupedProducerRepr.End { _ in x.value }
    case let .Right(k):
        let (dO, q) = k.value
        return GroupedProducerRepr.More { _ in { r in groupsBySignature(r, equals) } <^> (span(yield(dO) >>- { _ in q }) { v in equals(dO, v) }) }
    }
}

public func groupsBy<V, R>(p: Proxy<X, (), (), V, R>, equals: (V, V) -> Bool) -> GroupedProducer<V, R> {
    return GroupedProducer(groupsBySignature(p, equals))
}

public func groups<V: Equatable, R>(p: Proxy<X, (), (), V, R>) -> GroupedProducer<V, R> {
    return groupsBy(p) { v0, v1 in v0 == v1  }
}

public func chunksOf<V, R>(p: Proxy<X, (), (), V, R>, n: Int) -> GroupedProducer<V, R> {
    switch next(p) {
    }
}
