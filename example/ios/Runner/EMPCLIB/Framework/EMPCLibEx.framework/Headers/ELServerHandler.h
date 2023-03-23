//
//  ELServerHandler.h
//  EMPCLibEx
//
//  Created by user on 2023/01/18.
//  Copyright © 2023 neotechsoft. All rights reserved.
//

static NSInteger const EL_RESULT_OK = 0;
static NSInteger const EL_RESULT_FAIL = 1;

static NSInteger const EL_MSG_REGISTRATION = 100;
static NSInteger const EL_MSG_LOGIN = 101;
static NSInteger const EL_MSG_ENTER_ROOM = 102;
static NSInteger const EL_MSG_REMOTE_ENTER_ROOM = 103;
static NSInteger const EL_MSG_REMOTE_EXIT_ROOM = 104;
static NSInteger const EL_MSG_OVERLAPPED_USER_ID = 105;
static NSInteger const EL_MSG_PERMISSION_CHANGE = 106;
static NSInteger const EL_MSG_DISCONNECTED_SERVER = 107;

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ELServerHandlerDelegate<NSObject>
@optional

- (void)onServerEvent:(NSInteger)what arg1:(NSInteger)arg1 arg2:(NSString*)arg2;
- (void)receivedPacket:(int)type buffer:(const char *)buffer length:(int)length;

- (void)uploadComplited:(NSString *)filePath;
- (void)uploadFailed:(NSString *)filePath;

- (void)downloadComplited:(NSString *)filePath;
- (void)downloadFailed:(NSString *)filePath;


@end


@interface ELServerHandler : NSObject

+ (ELServerHandler *)getInstance;

- (void)initial;
- (void)setEventDelegate:(id)delegate;

- (void)setServerInfo:(NSString *)serverIp serverPort:(int)serverPort;

- (void)login:(NSString *)userid alias:(NSString *)alias ownerID:(NSString *)ownerid company:(nullable NSString *)company;
- (void)logout;

- (long)sendPacket:(int)type buffer:(const char *)buffer length:(int)length;

//파일 전송
- (void)setDpwnloadDir:(NSString *)fileDir;
- (BOOL)uploadFile:(NSString *)filePath;

//사용자 리스트
- (NSArray *)getUserList;

//사용자 권한 설정
- (void)changePermissionAudio:(NSString *)userId;
- (BOOL)getPermissionAudio:(NSString *)userId;

- (void)changePermissionDoc:(NSString *)userId;
- (BOOL)getPermissionDoc:(NSString *)userId;


//스피커 설정
- (BOOL)getSpeakerphoneOn;
- (void)setSpeakerphoneOn:(BOOL)on;

@end

NS_ASSUME_NONNULL_END
