//
//  TDCoprocess.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 10/15/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "TDCoprocess.h"

static void sig_pipe(int signo) {
    NSLog(@"SIGPIPE Caught!");
    exit(1);
}

@interface TDCoprocess ()
@property (nonatomic, copy) NSString *commandString;
@property (nonatomic, retain) NSPipe *childStdinPipe;
@property (nonatomic, retain) NSPipe *childStdoutPipe;

@property (nonatomic, assign) BOOL hasRun;
@end

@implementation TDCoprocess

+ (instancetype)coprocessWithCommandString:(NSString *)cmdString {
    return [[[TDCoprocess alloc] initWithCommandString:cmdString] autorelease];
}


- (instancetype)initWithCommandString:(NSString *)cmdString {
    self = [super init];
    if (self) {
        self.commandString = cmdString;
    }
    return self;
}


- (void)dealloc {
    printf("in coprocess child dealloc\n"); fflush(stdout);

    self.commandString = nil;
    self.childStdinPipe = nil;
    self.childStdoutPipe = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Public

- (NSFileHandle *)fileHandleForWriting {
    NSAssert(_childStdinPipe, @"");
    return [_childStdinPipe fileHandleForReading];
}


- (NSFileHandle *)fileHandleForReading {
    NSAssert(_childStdoutPipe, @"");
    return [_childStdoutPipe fileHandleForReading];
}


#pragma mark -
#pragma mark Private

- (NSError *)errorWithFormat:(NSString *)fmt, ... {
    NSAssert([fmt length], @"");
    
    va_list vargs;
    va_start(vargs, fmt);
    NSString *msg = [[[NSString alloc] initWithFormat:fmt arguments:vargs] autorelease];
    va_end(vargs);
    
    NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey: msg};
    return [NSError errorWithDomain:NSStringFromClass([self class]) code:-1 userInfo:userInfo];
}


- (BOOL)forkAndExecWithError:(NSError **)outErr {
    NSAssert(!_hasRun, @"");
    
    // programmer error.
    if (_hasRun) {
        [NSException raise:@"NSException" format:@"each %@ object is one-shot. this one has already run. you should create a new one for running instead of reusing this one.", NSStringFromClass([self class])];
        return NO;
    }
    
    self.hasRun = YES;
    
    NSLog(@"%@", _commandString);
    
    NSAssert([_commandString length], @"");
    NSAssert(!_childStdinPipe, @"");
    NSAssert(!_childStdoutPipe, @"");
    
    if (signal(SIGPIPE, sig_pipe) < 0) {
        if (outErr) *outErr = [self errorWithFormat:@"could not set SIGPIE handler"];
        return NO;
    }
    
    self.childStdinPipe = [NSPipe pipe];
    self.childStdoutPipe = [NSPipe pipe];
    
    pid_t pid;
    
    if ((pid = fork()) < 0) {
        if (outErr) *outErr = [self errorWithFormat:@"could not fork coprocess"];
        return NO;
    }
    
    // parent
    else if (pid > 0) {
        // close unused file descs
        [[_childStdinPipe fileHandleForReading] closeFile];
        [[_childStdoutPipe fileHandleForWriting] closeFile];
    }
    
    // child
    else {
        @autoreleasepool {
            NSAssert(0 == pid, @"");
            
            printf("in coprocess child 1:\n"); //fflush(stdout);
            
            //sleep(13);

            // close unused file descs
            [[_childStdinPipe fileHandleForWriting] closeFile];
            [[_childStdoutPipe fileHandleForReading] closeFile];
            
            printf("in coprocess child 2\n");// fflush(stdout);
            // attach pipe to stdin
            NSFileHandle *childStdinHandle = [_childStdinPipe fileHandleForReading];
            if ([childStdinHandle fileDescriptor] != STDIN_FILENO) {
                if (dup2([childStdinHandle fileDescriptor], STDIN_FILENO) != STDIN_FILENO) {
                    printf("error while attching pipe to child stdin\n");
                }
                [childStdinHandle closeFile];
            }
            
            printf("in coprocess child 3\n");// fflush(stdout);
            // attach pipe to stdout
            NSFileHandle *childStdoutHandle = [_childStdoutPipe fileHandleForWriting];
            if ([childStdoutHandle fileDescriptor] != STDOUT_FILENO) {
                if (dup2([childStdoutHandle fileDescriptor], STDOUT_FILENO) != STDOUT_FILENO) {
                    printf("error while attching pipe to child stdout\n");
                }
                [childStdoutHandle closeFile];
            }
            
            // set stdout to line buffer instead of fully buffered
            //            if (setvbuf(stdin, NULL, _IOLBF, 0) != 0) {
            //                printf("setvbug error\n");
            //            }
            if (setvbuf(stdout, NULL, _IOLBF, 0) != 0) {
                printf("setvbug error\n");
            }
            
            printf("in coprocess child 4\n"); //fflush(stdout);
            printf("in coprocess child 5, _commandString: %s\n", [_commandString UTF8String]); //fflush(stdout);
            // exec
            NSArray *args = [_commandString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSUInteger len = [args count];
            NSAssert(len > 1, @"");
            printf("in coprocess 6: len: %lu\n", len); //fflush(stdout);
            
            NSString *exePath = args[0];
            NSString *exeName = [exePath lastPathComponent];
            printf("in coprocess: %s %s\n", [exePath UTF8String], [exeName UTF8String]); //fflush(stdout);
            
            const char *argv[len+1];
            argv[0] = [exeName UTF8String];
            
            NSUInteger i = 1;
            for (NSString *arg in [args subarrayWithRange:NSMakeRange(1, len-1)]) {
                NSAssert([arg isKindOfClass:[NSString class]], @"");
                printf("arg %lu: %s\n", i, [arg UTF8String]); //fflush(stdout);
                argv[i++] = [arg UTF8String];
            }
            argv[i] = NULL;
            
            for (NSUInteger i =0 ; i < len+1; ++i) {
                const char *argc = argv[i];
                printf("arg %lu: %s\n", i, argc); //fflush(stdout);
            }
            
            if (execv([exePath UTF8String], (char * const *)argv)) {
                printf("error while attching exec'ing command string: `%s`\n", [_commandString UTF8String]);
            }
            printf("did exec string: `%s`\n", [_commandString UTF8String]);
        }
    }

    return YES;
}

@end
