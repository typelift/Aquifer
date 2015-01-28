/*
 *  Extension for NSFileHandle to make it capable of easy network programming
 *
 *  Version 1.0, get the newest from http://michael.stapelberg.de/NSFileHandleExt.php [EDIT:  now defunct]
 *
 *  Copyright 2007 Michael Stapelberg, modified 2015 by Alexander Altman
 *
 *  Distributed under BSD-License, see http://michael.stapelberg.de/BSD.php
 *
 */

@import Foundation;
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <fcntl.h>

@interface NSFileHandle(NSFileHandleExt)
+(instancetype)fileHandleWithConnectionToHost:(NSString*)host toPort:(int)port;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *readLine;
-(void)writeLine:(NSString*)line;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL isAtEndOfFile;
@end
