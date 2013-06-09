//
//  MODJsonToObjectAssembler.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 09/06/13.
//
//

#import "MODJsonToObjectAssembler.h"
#import "MODPKJsonParser.h"
#import "MODSortedMutableDictionary.h"
#import <ParseKit/ParseKit.h>

@interface MODJsonToObjectAssembler()
@property (nonatomic, retain, readwrite) id mainObject;
@end

@implementation MODJsonToObjectAssembler

+ (id)objectsFromJson:(NSString *)json error:(NSError **)error
{
    id object = nil;
    MODPKJsonParser *parser;
    MODJsonToObjectAssembler *assembler;
    
    parser = [[MODPKJsonParser alloc] init];
    assembler = [[MODJsonToObjectAssembler alloc] init];
    
    object = [[[parser parseString:json assembler:assembler error:error] stack] retain];
    if ([object count] > 1) {
        NSLog(@"%@", object);
        NSLog(@"%@", json);
        NSLog(@"");
    } else {
        object = [object objectAtIndex:0];
    }
    [parser release];
    [assembler release];
    return [object autorelease];
}

- (void)parser:(MODPKJsonParser *)parser didMatchObjectElement:(PKAssembly *)assembly
{
    NSArray *stack;
    MODSortedMutableDictionary *dictionary;
    NSEnumerator *stackEnumerator;
    NSString *key;
    id tengenJsonEncodedObject;
    
    [assembly pop]; // }
    stack = [assembly objectsAbove:[PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"{" floatValue:0]];
    [assembly pop]; // {
    dictionary = MODSortedMutableDictionary.sortedDictionary;
    stackEnumerator = [stack reverseObjectEnumerator];
    while ((key = stackEnumerator.nextObject) != nil) {
        id value;
        
        [stackEnumerator nextObject]; // :
        value = stackEnumerator.nextObject;
        [dictionary setObject:value forKey:key];
        [stackEnumerator nextObject]; // ,
    }
    tengenJsonEncodedObject = [dictionary tengenJsonEncodedObject];
    NSLog(@"%@", [dictionary sortedKeys]);
    if (tengenJsonEncodedObject) {
        [assembly push:tengenJsonEncodedObject];
    } else {
        [assembly push:dictionary];
    }
}

- (void)parser:(MODPKJsonParser *)parser didMatchArrayElement:(PKAssembly *)assembly
{
    NSArray *stack;
    NSMutableArray *result = NSMutableArray.array;
    NSEnumerator *stackEnumerator;
    id element;
    
    [assembly pop]; // ]
    stack = [assembly objectsAbove:[PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"[" floatValue:0]];
    [assembly pop]; // [
    stackEnumerator = stack.reverseObjectEnumerator;
    while ((element = stackEnumerator.nextObject) != nil) {
        [result addObject:element];
        [stackEnumerator nextObject];
    }
    [assembly push:result];
}

- (void)parser:(MODPKJsonParser *)parser didMatchStringToken:(PKAssembly *)assembly
{
    PKToken *token = [assembly pop];
    [assembly push:token.quotedStringValue];
}

- (void)parser:(MODPKJsonParser *)parser didMatchNumberToken:(PKAssembly *)assembly
{
    PKToken *token = [assembly pop];
    [assembly push:[NSNumber numberWithDouble:token.floatValue]];
}

@end
