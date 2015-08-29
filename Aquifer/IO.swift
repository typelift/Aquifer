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

/// Returns a `Pipe` that reads input from `stdin` line-by-line and terminates on end-of-input.
public func stdinLn() -> Producer<String, ()>.T {
    return fromHandle(NSFileHandle.fileHandleWithStandardInput())
}

/// Returns a `Pipe` that reads input from the given handle line-by-line and terminates on
/// end-of-input.
public func fromHandle(handle : NSFileHandle) -> Producer<String, ()>.T {
    if handle.isAtEndOfFile {
        return pure(())
    } else {
        return yield(handle.readLine()) >>- { _ in fromHandle(handle) }
    }
}

/// Returns a `Pipe` that writes output to `stdout` line-by-line and terminates on end-of-input.
public func stdoutLn() -> Consumer<String, ()>.T {
    return toHandle(NSFileHandle.fileHandleWithStandardOutput())
}

/// Returns a `Pipe` that writes output to the given handle line-by-line and terminates on
/// end-of-input.
public func toHandle(handle : NSFileHandle) -> Consumer<String, ()>.T {
    return for_(cat()) { handle.writeLine($0); return pure(()) }
}

/// Returns a `Pipe` that prints the description of input values to `stdout`.
public func describe<UI : CustomStringConvertible, FR>() -> Consumer<UI, FR>.T {
    return for_(cat()) { a in
        return Consumer.T.pure(print(a.description))
    }
}

/// Returns a `Pipe` that prints the debug description of input values to `stdout`.
public func debugDescribe<UI : CustomDebugStringConvertible, FR>() -> Consumer<UI, FR>.T {
    return for_(cat()) { a in
        return Consumer.T.pure(print(a.debugDescription))
    }
}

/// Returns a `Pipe` that prints the streamable data of input values to the given output stream.
public func writeTo<DT : Streamable, OS : OutputStreamType, FR>(inout stream: OS) -> Pipe<DT, DT, FR>.T {
    return chain { $0.writeTo(&stream) }
}
