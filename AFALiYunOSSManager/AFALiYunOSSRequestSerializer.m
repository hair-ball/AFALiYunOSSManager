//
// Created by 魏涛 on 14-9-7.
// Copyright (c) 2014 boxfish. All rights reserved.
//

#import "AFALiYunOSSRequestSerializer.h"
#import "AFALiYunOSSManager.h"
#import <CommonCrypto/CommonHMAC.h>

NSString *const AFALiYunOSSHangZhouRegion = @"oss-cn-hangzhou.aliyuncs.com";

static NSData *AFHMACSHA1EncodedDataFromStringWithKey(NSString *string, NSString *key) {
    NSData *data = [string dataUsingEncoding:NSASCIIStringEncoding];
    CCHmacContext context;
    const char *keyCString = [key cStringUsingEncoding:NSASCIIStringEncoding];

    CCHmacInit(&context, kCCHmacAlgSHA1, keyCString, strlen(keyCString));
    CCHmacUpdate(&context, [data bytes], [data length]);

    unsigned char digestRaw[CC_SHA1_DIGEST_LENGTH];
    NSUInteger digestLength = CC_SHA1_DIGEST_LENGTH;

    CCHmacFinal(&context, digestRaw);

    return [NSData dataWithBytes:digestRaw length:digestLength];
}

static NSString *AFRFC822FormatStringFromDate(NSDate *date) {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss z"];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];

    return [dateFormatter stringFromDate:date];
}

static NSString *AFBase64EncodedStringFromData(NSData *data) {
    NSUInteger length = [data length];
    NSMutableData *mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];

    uint8_t *input = (uint8_t *) [data bytes];
    uint8_t *output = (uint8_t *) [mutableData mutableBytes];

    for (NSUInteger i = 0; i < length; i += 3) {
        NSUInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }

        static uint8_t const kAFBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        NSUInteger idx = (i / 3) * 4;
        output[idx + 0] = kAFBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kAFBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kAFBase64EncodingTable[(value >> 6) & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kAFBase64EncodingTable[(value >> 0) & 0x3F] : '=';
    }

    return [[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding];
}

@interface AFALiYunOSSRequestSerializer ()

@property(readwrite, nonatomic, copy) NSString *accessKey;
@property(readwrite, nonatomic, copy) NSString *accessSec;

@end

@implementation AFALiYunOSSRequestSerializer {

}

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.region = AFALiYunOSSHangZhouRegion;
    self.useSSL = NO;

    return self;
}

- (void)setAccessKey:(NSString *)accessKey AccessSec:(NSString *)accessSec {
    NSParameterAssert(accessKey);
    NSParameterAssert(accessSec);

    self.accessKey = accessKey;
    self.accessSec = accessSec;
}

- (void)setRegion:(NSString *)region {
    NSParameterAssert(region);
    _region = region;
}

- (NSURL *)endpointURL {
    NSString *URLString = nil;
    NSString *scheme = self.useSSL ? @"https" : @"http";

    if (self.bucket) {
        URLString = [NSString stringWithFormat:@"%@://%@.%@", scheme, self.bucket, self.region];
    } else {
        URLString = [NSString stringWithFormat:@"%@://%@", scheme, self.region];
    }

    return [NSURL URLWithString:URLString];
}

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request withParameters:(id)parameters error:(NSError *__autoreleasing *)error {
    NSMutableURLRequest *mutableRequest = [request mutableCopy];

    NSLog(@"!!!");
    NSLog(@"%@,%@", self.accessKey, self.accessSec);
    NSLog(@"bucket -> %@", self.bucket);

    if (self.accessKey && self.accessSec) {
        NSMutableDictionary *mutableHeaderFields = [NSMutableDictionary dictionary];
        [[request allHTTPHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id key, id value, __unused BOOL *stop) {
            key = [key lowercaseString];
            if ([key hasPrefix:@"x-oss"]) {
                if ([mutableHeaderFields objectForKey:key]) {
                    value = [[mutableHeaderFields objectForKey:key] stringByAppendingFormat:@",%@", value];
                }
                [mutableHeaderFields setObject:value forKey:key];
            }
        }];

        NSMutableString *mutableCanonicalizedHeaderString = [NSMutableString string];
        for (NSString *key in [[mutableHeaderFields allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
            id value = [mutableHeaderFields valueForKey:key];
            [mutableCanonicalizedHeaderString appendFormat:@"%@:%@\n", key, value];
        }


        NSString *canonicalizedResource = [NSString stringWithFormat:@"%@%@", (self.bucket) ? self.bucket : @"", request.URL.path];
        NSLog(@"%@", canonicalizedResource);
        NSString *method = [request HTTPMethod];
        NSString *contentMD5 = [request valueForHTTPHeaderField:@"Content-MD5"];
        NSString *contentType = [request valueForHTTPHeaderField:@"Content-Type"];
        NSString *date = AFRFC822FormatStringFromDate([NSDate date]);

        NSMutableString *mutableString = [NSMutableString string];
        [mutableString appendFormat:@"%@\n", (method) ? method : @""];
        [mutableString appendFormat:@"%@\n", (contentMD5) ? contentMD5 : @""];
        [mutableString appendFormat:@"%@\n", (contentType) ? contentType : @""];
        [mutableString appendFormat:@"%@\n", (date) ? date : @""];
        [mutableString appendFormat:@"%@\n", mutableCanonicalizedHeaderString];
        [mutableString appendFormat:@"%@\n", canonicalizedResource];
        NSData *hmac = AFHMACSHA1EncodedDataFromStringWithKey(mutableString, self.accessSec);
        NSString *signature = AFBase64EncodedStringFromData(hmac);

        [mutableRequest setValue:[NSString stringWithFormat:@"OSS %@:%@", self.accessKey, signature] forHTTPHeaderField:@"Authorization"];
        [mutableRequest setValue:(date) ? date : @"" forHTTPHeaderField:@"Date"];

    } else {
        if (error) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"Access Key and Secret Required", @"AFALiYunOSSManager", nil)};
            *error = [[NSError alloc] initWithDomain:AFALiYunOSSManagerErrorDomain code:NSURLErrorUserAuthenticationRequired userInfo:userInfo];
        }
    }


    return mutableRequest;
}


- (NSMutableURLRequest *)requestWithMethod:(NSString *)method URLString:(NSString *)URLString parameters:(id)parameters error:(NSError *__autoreleasing *)error {
    return [super requestWithMethod:method URLString:URLString parameters:parameters error:error];
}


@end