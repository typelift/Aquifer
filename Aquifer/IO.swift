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

/// Returns a pipe that reads input from `stdin` line-by-line and terminates on end-of-input.
public func stdinLn<UO, UI>() -> Proxy<UO, UI, (), String, ()> {
    return fromHandle(NSFileHandle.fileHandleWithStandardInput())
}

/// Returns a pipe that reads input from the given handle line-by-line and terminates on 
/// end-of-input.
public func fromHandle<UO, UI>(handle: NSFileHandle) -> Proxy<UO, UI, (), String, ()> {
    if handle.isAtEndOfFile {
        return pure(())
    } else {
        return yield(handle.readLine) >>- { _ in fromHandle(handle) }
    }
}

/// Returns a pipe that writes output to `stdout` line-by-line and terminates on end-of-input.
public func stdoutLn<DI, DO, FR>() -> Proxy<(), String, DI, DO, FR> {
    return toHandle(NSFileHandle.fileHandleWithStandardOutput())
}

/// Returns a pipe that writes output to the given handle line-by-line and terminates on 
/// end-of-input.
public func toHandle<DI, DO, FR>(handle: NSFileHandle) -> Proxy<(), String, DI, DO, FR> {
    return for_(cat()) { handle.writeLine($0); return pure(()) }
}

/// Returns a pipe that prints the description of input values to `stdout`.
public func describe<UI: CustomStringConvertible, DI, DO, FR>() -> Proxy<(), UI, DI, DO, FR> {
    return description() >-> stdoutLn()
}

/// Returns a pipe that prints the debug description of input values to `stdout`.
public func debugDescribe<UI: CustomDebugStringConvertible, DI, DO, FR>() -> Proxy<(), UI, DI, DO, FR> {
    return debugDescription() >-> stdoutLn()
}

/// Returns a pipe that prints the streamable data of input values to the given output stream.
public func writeTo<DT: Streamable, OS: OutputStreamType, FR>(inout stream: OS) -> Proxy<(), DT, (), DT, FR> {
    return chain { $0.writeTo(&stream) }
}
