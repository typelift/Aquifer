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

#import "NSFileHandleExt.h"

#define CONN_TIMEOUT 5
#define BUFFER_SIZE 256

static in_addr_t getipaddr(const char *host) {
	/* let's look it up */
	struct hostent *server = gethostbyname(host);
	if (server == NULL) {
		NSCAssert(false, @"Error resolving the host");
	}

	return *(in_addr_t *)server->h_addr;
}

static int create_socket() {
	int socketfd;
	socketfd = socket(AF_INET, SOCK_STREAM, 0);
	if (socketfd == -1) {
		NSCAssert(false, @"Could not allocate socket");
	}

	int loop = 1;
	if (setsockopt(socketfd, SOL_SOCKET, SO_KEEPALIVE, &loop, sizeof (loop)) < 0) {
		NSCAssert(false, @"Could not set SO_REUSEADDR");
	}

	return socketfd;
}


@implementation NSFileHandle (AQUFileHandleExt)

+ (instancetype)fileHandleWithConnectionToHost:(NSString *)host toPort:(int)port {
	in_addr_t remote_h_addr;
	int result;

	remote_h_addr = getipaddr([host UTF8String]);

	struct sockaddr_in remoteaddr;
	bzero((char *)&remoteaddr, sizeof(remoteaddr));
	remoteaddr.sin_family = AF_INET;
	remoteaddr.sin_addr.s_addr = remote_h_addr;
	remoteaddr.sin_port = htons(port);

	int sockfd = create_socket();

	/* Set NONBLOCK to realize a timeout */
	int oldFlags = fcntl(sockfd, F_GETFL, 0);
	if (fcntl(sockfd, F_SETFL, oldFlags | O_NONBLOCK) < 0) {
		NSCAssert(false, @"Could not set O_NONBLOCK for socket");
	}

	result = connect(sockfd, (struct sockaddr *)&remoteaddr, sizeof(remoteaddr));
	if (result < 0 && errno != EINPROGRESS) {
		NSCAssert(false, @"Error in connect()");
	}

	if (fcntl(sockfd, F_SETFL, oldFlags) < 0) {
		NSCAssert(false, @"Could not restore old flags for socket");
	}

	/* Test if connected but with timeout */
	fd_set fds;
	struct timeval timeout;
	timeout.tv_usec = 0;
	timeout.tv_sec = CONN_TIMEOUT;

	FD_ZERO(&fds);
	FD_SET(sockfd, &fds);

	result = select(sockfd + 1, &fds, &fds, NULL, &timeout);
	if (result < 0) {
		NSCAssert(false, @"Error in select()");
	} else if (result == 0) {
		NSCAssert(false, @"Timeout while connecting");
	}

	return [[NSFileHandle alloc] initWithFileDescriptor: sockfd closeOnDealloc: YES];
}

- (NSString *)readLine {
	int fd = [self fileDescriptor];

	// If the socket is closed, return an empty string
	if (fd <= 0) {
		return @"";
	}

	// Allocate BUFFER_SIZE bytes to store the line
	int bufferSize = BUFFER_SIZE;
	char *buffer = (char *)malloc(bufferSize + 1);
	if (buffer == NULL) {
		NSCAssert(false, @"No more memory for allocating buffer");
	}

	int bytesReceived = 0;
	ssize_t n = 1;

	while (n > 0) {
		n = read(fd, buffer + bytesReceived++, 1);

		if (n < 0) {
			NSCAssert(false, @"Remote host closed connection");
		}

		if (bytesReceived >= bufferSize) {
			// Make buffer bigger
			bufferSize += BUFFER_SIZE;
			buffer = (char *)realloc(buffer, bufferSize + 1);
			if (buffer == NULL) {
				NSCAssert(false, @"No more memory for allocating buffer");
			}
		}

		switch (*(buffer + bytesReceived - 1)) {
			case '\n':
				buffer[bytesReceived - 1] = '\0';
				return [@(buffer) copy];
			case '\r':
				bytesReceived--;
		}
	}       
	
	buffer[bytesReceived - 1] = '\0';
	NSString *retVal = [@(buffer) copy];
	free(buffer);
	return retVal;
}

- (void)writeLine:(NSString *)line {
	[self writeData:[[NSString stringWithFormat:@"%@\n", line] dataUsingEncoding:NSUTF8StringEncoding]];
}

- (BOOL)isAtEndOfFile {
	UInt64 currentOffset = self.offsetInFile;
	[self seekToEndOfFile];
	UInt64 endOffset = self.offsetInFile;
	[self seekToFileOffset:currentOffset];
	return currentOffset >= endOffset;
}

@end
