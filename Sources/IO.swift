//
//  IO.swift
//  Aquifer
//
//  Created by Alexander Ronald Altman on 1/28/15.
//  Copyright (c) 2015 TypeLift. All rights reserved.
//

// part of `Pipes.Prelude`

import Foundation
import Swiftz
#if !XCODE_BUILD
	import Operadics
#endif

/// Returns a `Pipe` that reads input from `stdin` line-by-line and terminates on end-of-input.
public func stdinLn() -> Producer<String, ()> {
	return fromHandle(FileHandle.standardInput)
}

/// Returns a `Pipe` that reads input from the given handle line-by-line and terminates on
/// end-of-input.
public func fromHandle(_ handle : FileHandle) -> Producer<String, ()> {
	if handle.isAtEndOfFile {
		return pure(())
	} else {
		return yield(handle.readLine) >>- { _ in fromHandle(handle) }
	}
}

/// Returns a `Pipe` that writes output to `stdout` line-by-line and terminates on end-of-input.
public func stdoutLn() -> Consumer<String, ()> {
	return toHandle(FileHandle.standardOutput)
}

/// Returns a `Pipe` that writes output to the given handle line-by-line and terminates on
/// end-of-input.
public func toHandle(_ handle : FileHandle) -> Consumer<String, ()> {
	return for_(cat()) { handle.writeLine($0); return pure(()) }
}

/// Returns a `Pipe` that prints the description of input values to `stdout`.
public func describe<UI : CustomStringConvertible, FR>() -> Consumer<UI, FR> {
	return for_(cat()) { a in
		return Consumer.pure(print(a.description))
	}
}

/// Returns a `Pipe` that prints the debug description of input values to `stdout`.
public func debugDescribe<UI : CustomDebugStringConvertible, FR>() -> Consumer<UI, FR> {
	return for_(cat()) { a in
		return Consumer.pure(print(a.debugDescription))
	}
}

/// Returns a `Pipe` that prints the streamable data of input values to the given output stream.
/// public func writeTo<DT : Streamable, OS : TextOutputStream, FR>(_ stream : OS) -> Pipe<DT, DT, FR> {
/// 	return chain { s in s.write(&stream) }
/// }
