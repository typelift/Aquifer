//
//  FocusedParsing.swift
//  Aquifer
//
//  Created by Robert Widmann on 8/30/16.
//  Copyright © 2016 TypeLift. All rights reserved.
//

import Focus

/// Draws one element from the underlying `Producer`, returning `.None` if the Producer is empty
public func draw<V, I>() -> IxState<Producer<V, I>, Producer<V, I>, V?> {
	return get() >>- { p in
		switch next(p) {
		case let .Left(x): return { _ in nil } <^> put(pure(x))
		case let .Right((dO, q)):
			return { _ in dO } <^> put(q)
		}
	}
}

/// Skips one element of the underlying `Producer`.  The final result of the returned pipe is `true`
/// if the operation was successful or `false` if the pipe was empty.
public func skip<V, I>() -> IxState<Producer<V, I>, Producer<V, I>, Bool> {
	return { if let _ = $0 { return true } else { return false } } <^> draw()
}

/// Draw all elements from the underlying `Producer`.
public func drawAll<V, I>() -> IxState<Producer<V, I>, Producer<V, I>, [V]> {
	return drawAllInner { v in v }
}

/// Drops all elements from the underlying `Producer`.
public func skipAll<V, I>() -> IxState<Producer<V, I>, Producer<V, I>, ()> {
	return draw() >>- { if let _ = $0 { return skipAll() } else { return pure(()) } }
}

/// Push back an element onto the underlying `Producer`.
public func unDraw<V, I>(_ x : V) -> IxState<Producer<V, I>, Producer<V, I>, ()> {
	return modify { p in yield(x) >>- { _ in p } }
}

/// Checks the first element of the pipe, but uses `unDraw` to push the element back so that it is
/// available for the next `draw` command.
public func peek<V, I>() -> IxState<Producer<V, I>, Producer<V, I>, V?> {
	return draw() >>- { k in if let v = k { return { _ in k } <^> unDraw(v) } else { return pure(k) } }
}

/// Returns whether the underlying `Producer` is empty
public func isEndOfInput<V, I>() -> IxState<Producer<V, I>, Producer<V, I>, Bool> {
	return { if let _ = $0 { return true } else { return false } } <^> peek()
}

/// Fold all input values.
public func foldAll<A, V, I, R>(stepWith step : @escaping (A, V) -> A, initializeWith initial : A, extractWith extractor : @escaping (A) -> R) -> IxState<Producer<V, I>, Producer<V, I>, R> {
	return draw() >>- {
		if let v = $0 {
			return foldAll(stepWith : step, initializeWith : step(initial, v), extractWith : extractor)
		} else {
			return pure(extractor(initial))
		}
	}
}

// this seems to required higher-kinded types to implement, even though none appear in its signature
/*public func toParser<V, I, R>(p : Proxy<(), V?, (), Never, R>) -> IxState<Producer<V, >, Producer<V, >, R> {
}*/

/// Convert a never-ending Consumer to a Parser
public func toParser<V, I>(endless p : Consumer<V, Never>) -> IxState<Producer<V, I>, Producer<V, I>, ()> {
	func undefined<T>() -> T { fatalError() }
	return IxState { q in ((), pure(runEffect(q >-> ({ _ in return undefined() } <^> p)))) }
}

// MARK: - Implementation Details Follow

private func drawAllInner<V, I>(_ diffAs : @escaping ([V]) -> [V]) -> IxState<Producer<V, I>, Producer<V, I>, [V]> {
	return draw() >>- { d in
		if let v = d {
			return drawAllInner({ xs in diffAs([v] + xs) })
		} else {
			return pure(diffAs([]))
		}
	}
}
