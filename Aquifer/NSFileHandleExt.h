//  Extension for NSFileHandle to make it capable of easy network programming
//
//  Version 1.0, get the newest from
//  http://michael.stapelberg.de/NSFileHandleExt.php [EDIT:  now defunct]
//
//  Copyright 2007 Michael Stapelberg, modified 2015 by Alexander Altman
//
//  Distributed under BSD-License, see http://michael.stapelberg.de/BSD.php

#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <fcntl.h>

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NSFileHandle (AQUFileHandleExt)

/// Creates and returns a file handle connected to the host address on the given
/// port.
+ (instancetype)aqu_fileHandleWithConnectionToHost:(NSString *)host
											toPort:(int)port;

/// Appends a newline to the given string and prints it to the receiver's
/// underlying file handle.
- (void)aqu_writeLine:(NSString *)line;

/// Reads a line from the receiver's underlying file handle.
- (NSString *)aqu_readLine;

/// Returns whether the receiver's underlying file descriptor no longer has any
/// data to read.  Such as when the end of a file is reached at a read, or the
/// EOF character is encountered in the stream.
@property(nonatomic, readonly) BOOL aqu_isAtEndOfFile;

@end

NS_ASSUME_NONNULL_END
