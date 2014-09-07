//
// Created by 魏涛 on 14-9-7.
// Copyright (c) 2014 boxfish. All rights reserved.
//

#import "AFALiYunOSSManager.h"
#import "AFALiYunOSSRequestSerializer.h"

NSString *const AFALiYunOSSManagerErrorDomain = @"cn.boxfish.networking.oss.error";

@interface AFALiYunOSSManager ()
@property(readwrite, nonatomic, strong) NSURL *baseURL;
@end

@implementation AFALiYunOSSManager {
}
@synthesize baseURL = _baseURL;

- (instancetype)initWithBaseURL:(NSURL *)url {
    NSLog(@"initWithBaseURL");

    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }

    self.requestSerializer = [AFALiYunOSSRequestSerializer serializer];
    self.responseSerializer = [AFXMLParserResponseSerializer serializer];

    return self;
}

- (id)initWithAccessKey:(NSString *)accessKey AccessSec:(NSString *)accessSec {
    self = [self init];
    if (!self) {
        return nil;
    }

    [self.requestSerializer setAccessKey:accessKey AccessSec:accessSec];

    return self;
}

- (NSURL *)baseURL {
    if (!_baseURL) {
        return self.requestSerializer.endpointURL;
    }
    return _baseURL;
}

- (void)getBucketsWithSuccess:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure {
    [self enqueueOSSRequestOperationWithMethod:@"GET" path:@"/" parameters:nil success:success failure:failure];
}

- (void)getBucket:(NSString *)bucket success:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure {
    [self enqueueOSSRequestOperationWithMethod:@"GET" path:bucket parameters:nil success:success failure:failure];
}

- (void)enqueueOSSRequestOperationWithMethod:(NSString *)method
                                        path:(NSString *)path
                                  parameters:(NSDictionary *)parameters
                                     success:(void (^)(id responseObject))success
                                     failure:(void (^)(NSError *error))failure {

    NSMutableURLRequest *request =
            [self.requestSerializer requestWithMethod:method
                                            URLString:[[self.baseURL URLByAppendingPathComponent:path] absoluteString]
                                           parameters:parameters
                                                error:nil
            ];

    AFHTTPRequestOperation *requestOperation =
            [self HTTPRequestOperationWithRequest:request
                                          success:^(AFHTTPRequestOperation *operation, __unused id responseObject) {
                                              if (success) {
                                                  success(operation.responseObject);
                                              }
                                          }
                                          failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
                                              if (failure) {
                                                  failure(error);
                                              }
                                          }
            ];

    [self.operationQueue addOperation:requestOperation];
}

@end