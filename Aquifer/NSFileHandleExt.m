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

in_addr_t getipaddr(const char *host) {
    /* let's look it up */
    struct hostent *server = gethostbyname(host);
    if (server == NULL)
        [[NSException exceptionWithName:@"Error resolving" reason:@"Error resolving the host" userInfo:nil] raise];

    return *(in_addr_t *)server->h_addr;
}

int create_socket() {
    int socketfd;
    socketfd = socket(AF_INET, SOCK_STREAM, 0);
    if (socketfd == -1)
        [[NSException exceptionWithName:@"Allocating socket failed" reason:@"Could not allocate socket" userInfo:nil] raise];

    int loop = 1;
    if (setsockopt(socketfd, SOL_SOCKET, SO_KEEPALIVE, &loop, sizeof (loop)) < 0)
        [[NSException exceptionWithName:@"Error setting options" reason:@"Could not set SO_REUSEADDR" userInfo:nil] raise];

    return socketfd;
}


@implementation NSFileHandle(NSFileHandleExt)

+(instancetype)fileHandleWithConnectionToHost:(NSString*)host toPort:(int)port {
    in_addr_t remote_h_addr;

    remote_h_addr = getipaddr([host UTF8String]);

    struct sockaddr_in remoteaddr;
    bzero((char *)&remoteaddr, sizeof(remoteaddr));
    remoteaddr.sin_family = AF_INET;
    remoteaddr.sin_addr.s_addr = remote_h_addr;
    remoteaddr.sin_port = htons(port);

    int sockfd = create_socket();

    /* Set NONBLOCK to realize a timeout */
    int oldFlags = fcntl(sockfd, F_GETFL, 0);
    if (fcntl(sockfd, F_SETFL, oldFlags | O_NONBLOCK) < 0)
        [[NSException exceptionWithName:@"Could not set O_NONBLOCK" reason:@"Could not set O_NONBLOCK for socket" userInfo:nil] raise];

    int result = connect(sockfd, (struct sockaddr *)&remoteaddr, sizeof(remoteaddr));

    if (result < 0 && errno != EINPROGRESS)
        [[NSException exceptionWithName:@"Error connecting" reason:@"Error in connect()" userInfo:nil] raise];

    if (fcntl(sockfd, F_SETFL, oldFlags) < 0)
        [[NSException exceptionWithName:@"Could not set restore old flags" reason:@"Could not restore old flags for socket" userInfo:nil] raise];

    /* Test if connected but with timeout */
    fd_set fds;
    struct timeval timeout;
    timeout.tv_usec = 0;
    timeout.tv_sec = CONN_TIMEOUT;

    FD_ZERO(&fds);
    FD_SET(sockfd, &fds);

    result = select(sockfd + 1, &fds, &fds, NULL, &timeout);
    if (result < 0)
        [[NSException exceptionWithName:@"Error selecting" reason:@"Error in select()" userInfo:nil] raise];
    else if (result == 0)
        [[NSException exceptionWithName:@"Error connecting" reason:@"Timeout while connecting" userInfo:nil] raise];

    return [[NSFileHandle alloc] initWithFileDescriptor: sockfd];
}

-(NSString*)readLine {
    int fd = [self fileDescriptor];

    // If the socket is closed, return an empty string
    if (fd <= 0)
        return @"";

    // Allocate BUFFER_SIZE bytes to store the line
    int bufferSize = BUFFER_SIZE;
    char *buffer = (char*)malloc(bufferSize + 1);
    if (buffer == NULL)
        [[NSException exceptionWithName:@"No memory left" reason:@"No more memory for allocating buffer" userInfo:nil] raise];

    int bytesReceived = 0;
    ssize_t n = 1;

    while (n > 0) {
        n = read(fd, buffer + bytesReceived++, 1);

        if (n < 0)
            [[NSException exceptionWithName:@"Socket error" reason:@"Remote host closed connection" userInfo:nil] raise];

        if (bytesReceived >= bufferSize) {
            // Make buffer bigger
            bufferSize += BUFFER_SIZE;
            buffer = (char*)realloc(buffer, bufferSize + 1);
            if (buffer == NULL)
                [[NSException exceptionWithName:@"No memory left" reason:@"No more memory for allocating buffer" userInfo:nil] raise];
        }

        switch (*(buffer + bytesReceived - 1)) {
            case '\n':
                buffer[bytesReceived-1] = '\0';
                return [@(buffer) copy];
            case '\r':
                bytesReceived--;
        }
    }       
    
    buffer[bytesReceived-1] = '\0';
    NSString *retVal = [@(buffer) copy];
    free(buffer);
    return retVal;
}

-(void)writeLine:(NSString*)line {
    [self writeData: [[NSString stringWithFormat:@"%@\r\n", line] dataUsingEncoding:NSUTF8StringEncoding]];
}
@end
