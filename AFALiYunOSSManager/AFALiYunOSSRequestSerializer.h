//
// Created by 魏涛 on 14-9-7.
// Copyright (c) 2014 boxfish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFURLRequestSerialization.h>

@interface AFALiYunOSSRequestSerializer : AFHTTPRequestSerializer

@property(nonatomic, copy) NSString *region;
@property(nonatomic, copy) NSString *bucket;

@property(nonatomic, assign) BOOL useSSL;
@property(readonly, nonatomic, copy) NSURL *endpointURL;

- (void)setAccessKey:(NSString *)accessKey
           AccessSec:(NSString *)accessSec;

@end