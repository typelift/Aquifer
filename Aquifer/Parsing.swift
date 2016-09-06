//
//  Parsing.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/27/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

// roughly `Pipes.Parse`

import Swiftz

/// Splits the `Producer` into two `Producer`s, where the outer `Producer` is the longest
/// consecutive group of elements that satisfy the given predicate.
public func span<V, R>(_ p : Producer<V, R>, _ predicate : @escaping (V) -> Bool) -> Producer<V, Producer<V, R>> {
	switch next(p) {
	case let .Left(x): return pure(pure(x))
	case let .Right((dO, q)):
		if predicate(dO) {
			return yield(dO) >>- { _ in span(p, predicate) }
		} else {
			return pure(yield(dO) >>- { _ in q })
		}
	}
}

/// Splits the `Producer` into two `Producer`s, where the outer `Producer` is the longest
/// consecutive group of elements that do not satisfy the given predicate.
public func extreme<V, R>(_ p : Producer<V, R>, _ predicate : @escaping (V) -> Bool) -> Producer<V, Producer<V, R>> {
	return span(p, (!) • predicate)
}

/// Splits a `Producer` into two `Producer`s after a fixed number of elements
public func splitAt<V, R>(_ p : Producer<V, R>, _ n : Int) -> Producer<V, Producer<V, R>> {
	if n <= 0 {
		return pure(p)
	} else {
		switch next(p) {
		case let .Left(x): return pure(pure(x))
		case let .Right((dO, q)):
			return yield(dO) >>- { _ in splitAt(q, n - 1) }
		}
	}
}

/// Splits a `Producer` into two `Producer`s after the first group of elements that are equal
/// according to the equality predicate.
public func groupBy<V, R>(_ p : Producer<V, R>, _ equals : @escaping (V, V) -> Bool) -> Producer<V, Producer<V, R>> {
	switch next(p) {
	case let .Left(x): return pure(pure(x))
	case let .Right((dO, q)):
		return span(yield(dO) >>- { _ in q }) { v in equals(dO, v) }
	}
}

/// Splits a `Producer` into two `Producer`s after the first group of elements that are equal.
public func group<V : Equatable, R>(_ p : Producer<V, R>) -> Producer<V, Producer<V, R>> {
	return groupBy(p) { v0, v1 in v0 == v1 }
}
