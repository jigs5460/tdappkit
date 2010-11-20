//  Copyright 2009 Todd Ditchendorf
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import <Cocoa/Cocoa.h>

@interface NSEvent (TDAdditions)
- (BOOL)isMouseDown;
- (BOOL)isMouseMoved;
- (BOOL)isMouseUp;
- (BOOL)isMouseDragged;
- (BOOL)isKeyUp;
- (BOOL)isKeyDown;
- (BOOL)isKeyUpOrDown;
- (BOOL)is3rdButtonClick;
- (BOOL)isScrollWheel;
- (BOOL)isDoubleClick;
- (BOOL)isCommandKeyPressed;
- (BOOL)isControlKeyPressed;
- (BOOL)isShiftKeyPressed;
- (BOOL)isOptionKeyPressed;
- (BOOL)isEscKeyPressed;
- (BOOL)isReturnKeyPressed;
- (BOOL)isEnterKeyPressed;
- (BOOL)isTabKeyDown;
- (BOOL)isDeleteKeyDown;
- (BOOL)isUpArrowKeyDown;
- (BOOL)isDownArrowKeyDown;
- (BOOL)isSpaceKeyDown;
- (BOOL)isCommandPeriodKeyDown;
@end
