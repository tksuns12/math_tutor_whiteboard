//
//  ELViewRecord.h
//  EMPCLibEx
//
//  Created by user on 2023/01/19.
//  Copyright © 2023 neotechsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ELViewRecordDelegate <NSObject>

- (void)onStartRecord:(NSInteger)result errorCode:(NSInteger)errorCode;
- (void)onStopRecord:(NSInteger)result errorCode:(NSInteger)errorCode filePath:(nullable NSString *)filePath;

@end

@interface ELViewRecord : NSObject

+ (ELViewRecord *)getInstance;

- (void)setEventDelegate:(id)delegate;

- (BOOL)isRecording;

- (void)startRecording:(NSString *)filePath;
- (void)stopRecording;


@end

NS_ASSUME_NONNULL_END
