//
// Created by 魏涛 on 14-9-7.
// Copyright (c) 2014 boxfish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperationManager.h"

@class AFALiYunOSSRequestSerializer;


@interface AFALiYunOSSManager : AFHTTPRequestOperationManager

@property(nonatomic, strong) AFALiYunOSSRequestSerializer <AFURLRequestSerialization> *requestSerializer;

- (id)initWithAccessKey:(NSString *)accessKey
              AccessSec:(NSString *)accessSec;


- (void)getBucketsWithSuccess:(void (^)(id responseObject))success
                      failure:(void (^)(NSError *error))failure;


- (void)getBucket:(NSString *)bucket
          success:(void (^)(id responseObject))success
          failure:(void (^)(NSError *error))failure;
@end

extern NSString *const AFALiYunOSSManagerErrorDomain;
