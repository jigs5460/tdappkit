//
//  TDSemaphore.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 5/31/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "TDSemaphore.h"

@interface TDSemaphore ()
- (void)lock;
- (void)unlock;

- (void)decrement;
- (void)increment;

- (BOOL)available;
- (void)signal;

@property (assign) NSInteger value;
@property (retain) NSCondition *condition;
@end

@implementation TDSemaphore

- (id)initWithValue:(NSInteger)value {
    NSParameterAssert(value >= 0);
    self = [super init];
    if (self) {
        self.value = value;
        self.condition = [[[NSCondition alloc] init] autorelease];
    }
    return self;
}


- (void)dealloc {
    self.condition = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Public

- (BOOL)attempt {
    [self lock];
    
    BOOL success = [self available];
    
    if (success) {
        [self decrement];
    }
    
    [self unlock];

    return success;
}


- (void)take {
    //NSLog(@"%@ taking", [[NSThread currentThread] name]);
    
    [self lock];
    
    while (![self available]) {
        [_condition wait];
    }
    
    [self decrement];
    [self unlock];
}


- (void)put {
    //NSLog(@"%@ putting", [[NSThread currentThread] name]);

    [self lock];
    [self increment];

    if ([self available]) {
        [self signal];
    }
    
    [self unlock];
}


#pragma mark -
#pragma mark Private

- (void)lock {
    [_condition lock];
}


- (void)unlock {
    [_condition unlock];
}


- (void)decrement {
    self.value--;
}


- (void)increment {
    self.value++;
}


- (BOOL)available {
    return _value > 0;
}


- (void)wait {
    [_condition wait];
}


- (void)signal {
    [_condition signal];
}

@end
