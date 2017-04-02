//
//  NSFileHandleExt.swift
//  Aquifer
//
//  Created by Robert Widmann on 9/20/16.
//  Copyright © 2016 TypeLift. All rights reserved.
//

#if os(Linux)
	import Glibc
#else
	import Darwin
#endif

import Foundation

private let BUFFER_SIZE : Int = 256

extension FileHandle {
	public var readLine : String {
		let fd = self.fileDescriptor
		guard fd > 0 else {
			return ""
		}

		// Allocate BUFFER_SIZE bytes to store the line
		var bufferSize = BUFFER_SIZE
		var buffer = UnsafeMutablePointer<CChar>.allocate(capacity: bufferSize + 1)
		var bytesReceived = 0
		var n = 1
		while n > 0 {
			n = read(fd, buffer.advanced(by: bytesReceived + 1), 1)
			if n < 0 {
				fatalError("Remote host closed connection")
			}

			if bytesReceived >= bufferSize {
				// Make buffer bigger
				let oldBuf = buffer
				let oldSize = bufferSize
				bufferSize += BUFFER_SIZE
				buffer = UnsafeMutablePointer<CChar>.allocate(capacity: bufferSize + 1)
				buffer.initialize(from: oldBuf, count: oldSize + 1)
				oldBuf.deallocate(capacity: oldSize + 1)
			}

			switch buffer[bytesReceived - 1] {
			case CChar("\n".utf8.first!):
				buffer[bytesReceived - 1] = CChar("\0".utf8.first!)
				let retVal = String(cString: UnsafePointer(buffer))
				buffer.deallocate(capacity: bufferSize + 1)
				return retVal
			case CChar("\r".utf8.first!):
				bytesReceived -= 1
			default:
				continue
			}
		}
		buffer[bytesReceived - 1] = CChar("\0".utf8.first!)
		let retVal = String(cString: UnsafePointer(buffer))
		buffer.deallocate(capacity: bufferSize + 1)
		return retVal
	}

	public func writeLine(_ line : String) {
		guard let data = (line + "\n").data(using: .utf8) else {
			return
		}
		self.write(data)
	}

	public var isAtEndOfFile : Bool {
		let currentOffset = self.offsetInFile
		self.seekToEndOfFile()
		let endOffset = self.offsetInFile
		self.seek(toFileOffset: currentOffset)
		return currentOffset >= endOffset
	}
}
