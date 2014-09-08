//
// Created by 魏涛 on 14-9-8.
// Copyright (c) 2014 boxfish. All rights reserved.
//

#import "NSXMLParser+Dic.h"

int d;
NSString *element;
NSMutableString *xmlString;

@interface NSXMLParser () <NSXMLParserDelegate> {
}
@end

@implementation NSXMLParser (Dic)

- (NSString *)text {
    d = 0;
    xmlString = [NSMutableString string];
    [self setDelegate:self];
    [self parse];
    return xmlString;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    NSLog(@"解析开始");
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    NSLog(@"解析结束");
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    d++;
    element = elementName;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    d--;
    element = nil;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (element && string) {
        NSMutableString *mutableString = [NSMutableString string];
        for (int index = 1; index < d; index++) {
            [mutableString appendString:@"\t"];
        }
        [mutableString appendFormat:@"%@:%@", element, string];
        [xmlString appendFormat:@"%@\n", mutableString];
    }
}
@end