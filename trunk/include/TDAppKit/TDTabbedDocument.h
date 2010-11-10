//
//  TDTabbedDocument.h
//  TDAppKit
//
//  Created by Todd Ditchendorf on 11/10/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TDTabModel;
@class TDTabController;

@interface TDTabbedDocument : NSDocument {
    NSMutableArray *tabModels;
    NSMutableArray *tabControllers;
    NSUInteger selectedTabIndex;
}

@property (nonatomic, retain) NSMutableArray *tabModels;
@property (nonatomic, retain) NSMutableArray *tabControllers;
@property (nonatomic, assign) NSUInteger selectedTabIndex;
@property (nonatomic, retain, readonly) TDTabModel *selectedTabModel;
@property (nonatomic, retain, readonly) TDTabController *selectedTabController;
@end
