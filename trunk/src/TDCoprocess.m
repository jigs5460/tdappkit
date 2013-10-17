//
//  TDCoprocess.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 10/15/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "TDCoprocess.h"
#import <util.h>

static void sig_pipe(int signo) {
    NSLog(@"SIGPIPE Caught!");
    exit(1);
}

@interface TDCoprocess ()
@property (nonatomic, copy) NSString *commandString;
@property (nonatomic, retain) NSFileHandle *tty;

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

    self.tty = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Public



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


- (NSFileHandle *)fileHandleForWriting {
    return _tty;
}


- (NSFileHandle *)fileHandleForReading {
    return _tty;
}


- (void)spawnWithCompletion:(void (^)(int status, NSError *err))completion {
    
}


- (int)spawnWithError:(NSError **)outErr {
    NSAssert(!_hasRun, @"");
    
    // programmer error.
    if (_hasRun) {
        [NSException raise:@"NSException" format:@"each %@ object is one-shot. this one has already run. you should create a new one for running instead of reusing this one.", NSStringFromClass([self class])];
        return -1;
    }
    
    self.hasRun = YES;
    
    NSLog(@"%@", _commandString);
    
    NSAssert([_commandString length], @"");
    NSAssert(!_tty, @"");
    
    if (signal(SIGPIPE, sig_pipe) < 0) {
        if (outErr) *outErr = [self errorWithFormat:@"could not set SIGPIE handler: %s", strerror(errno)];
        return -1;
    }

    pid_t pid;
//    pid = fork();
    
    int master[2];
    struct winsize win = {
        .ws_col = 80, .ws_row = 24,
        .ws_xpixel = 480, .ws_ypixel = 192,
    };
    pid = forkpty(master, NULL, NULL, &win);
    
    if (pid < 0) {
        if (outErr) *outErr = [self errorWithFormat:@"could not fork coprocess"];
        return -1;
    }
    
    // parent
    else if (pid > 0) {
        // close unused file descs

        self.tty = [[[NSFileHandle alloc] initWithFileDescriptor:master[0] closeOnDealloc:NO] autorelease];
        
        return 0;
        
//        int status;
//        if (waitpid(pid, &status, 0) != pid) {
//            if (outErr) *outErr = [self errorWithFormat:@"waitpid error"];
//            return -1;
//        } else {
//            if (status != 0) {
//                char *errstr = strerror(errno);
//                if (outErr) *outErr = [self errorWithFormat:@"child process exit status: %d: %s", status, errstr];
//            }
//            return status;
//        }
    }
    
    // child
    else {
        @autoreleasepool {
            NSAssert(0 == pid, @"");
            
            // exec
            NSArray *args = [_commandString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSUInteger argc = [args count];
            NSAssert(argc > 1, @"");
            
            NSString *exePath = args[0];
            NSString *exeName = [exePath lastPathComponent];
            
            const char *argv[argc+1];
            argv[0] = [exeName UTF8String];
            
            NSUInteger i = 1;
            for (NSString *arg in [args subarrayWithRange:NSMakeRange(1, argc-1)]) {
                NSAssert([arg isKindOfClass:[NSString class]], @"");
                arg = [arg stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"'\""]];
                argv[i++] = [arg UTF8String];
            }
            argv[i] = NULL;
            
            if (execv([exePath UTF8String], (char * const *)argv)) {
                printf("error while execing command string: `%s`\n%s\n", [_commandString UTF8String], strerror(errno));
            }
            
            NSAssert1(0, @"failed to exec string: `%@`", _commandString);
        }
    }

    return 0;
}

@end
