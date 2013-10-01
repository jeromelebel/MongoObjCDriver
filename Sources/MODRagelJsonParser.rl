//
//  MODRagelJsonParser.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 01/09/13.
//
//

#import "MODRagelJsonParser.h"
#import "MODSortedMutableDictionary.h"
#import "MODMaxKey.h"
#import "MODMinKey.h"
#import "MODUndefined.h"
#import "MODObjectId.h"
#import "MODRegex.h"
#import "MOD_internal.h"

@interface MODRagelJsonParser ()
- (id)parseJson:(NSString *)source;
- (NSError *)error;
@end

@implementation MODRagelJsonParser (private)

+ (void)bsonFromJson:(bson *)bsonResult json:(NSString *)json error:(NSError **)error
{
    id object = [self objectsFromJson:json withError:error];
    
    if (object && !*error && [object isKindOfClass:NSArray.class]) {
        object = [MODSortedMutableDictionary sortedDictionaryWithObject:object forKey:@"array"];
    }
    if (object && !*error && [object isKindOfClass:MODSortedMutableDictionary.class]) {
        [MODServer appendObject:object toBson:bsonResult];
    }
}

@end

@implementation MODRagelJsonParser

+ (id)objectsFromJson:(NSString *)source withError:(NSError **)error
{
    MODRagelJsonParser *parser = [[self alloc] init];
    id result;
    
    result = [parser parseJson:source];
    *error = [parser error];
    [parser release];
    return result;
}

- (NSError *)_errorWithMessage:(NSString *)message atPosition:(const char *)position
{
    NSUInteger length;
    
    length = strlen(position);
    if (length > 10) {
        length = 10;
    }
    return [NSError errorWithDomain:@"error" code:0 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@ %@", message, [[[NSString alloc] initWithBytes:position length:length encoding:NSUTF8StringEncoding] autorelease]] }];
}

%%{
    machine JSON_common;

    ws                  = [ \t\r\n];
    ignore              = ws;
    name_separator      = ':';
    value_separator     = ',';
    Vundefined          = 'undefined';
    Vnull               = 'null';
    Vfalse              = 'false';
    Vtrue               = 'true';
    VMinKey             = 'MinKey';
    VMaxKey             = 'MaxKey';
    begin_value         = [/unftMO'\"\-\[\{NI] | digit;
    begin_object        = '{';
    end_object          = '}';
    begin_array         = '[';
    end_array           = ']';
    begin_string        = '"' | '\'';
    begin_name          = begin_string;
    begin_number        = digit | '-';
    begin_object_id     = 'O';
    begin_regexp        = '/';
    object_id_keyword   = 'ObjectId';
}%%

%%{
    machine JSON_value;
    include JSON_common;

    write data;

    action parse_null {
        *result = [NSNull null];
    }
    action parse_false {
        *result = [NSNumber numberWithBool:NO];
    }
    action parse_true {
        *result = [NSNumber numberWithBool:YES];
    }

    action parse_min_key {
        *result = [[[MODMinKey alloc] init] autorelease];
    }

    action parse_max_key {
        *result = [[[MODMaxKey alloc] init] autorelease];
    }
    
    action parse_undefined {
        *result = [[[MODUndefined alloc] init] autorelease];
    }
    
    action parse_object_id {
        const char *np = [self _parseObjectIdWithPointer:fpc endPointer:pe result:result];
        if (np == NULL) { fhold; fbreak; } else fexec np;
    }

    action parse_string {
        const char *np = [self _parseStringWithPointer:fpc endPointer:pe result:result];
        if (np == NULL) { fhold; fbreak; } else fexec np;
    }

    action parse_number {
        const char *np;
        np = [self _parseFloatWithPointer:fpc endPointer:pe result:result];
        if (np != NULL) fexec np;
        np = [self _parseIntegerWithPointer:fpc endPointer:pe result:result];
        if (np != NULL) fexec np;
        fhold; fbreak;
    }

    action parse_array {
        const char *np;
        _currentNesting++;
        np = [self _parseArrayWithPointer:fpc endPointer:pe result:result];
        _currentNesting--;
        if (np == NULL) { fhold; fbreak; } else fexec np;
    }

    action parse_object {
        const char *np;
        _currentNesting++;
        np = [self _parseObjectWithPointer:fpc endPointer:pe result:result];
        _currentNesting--;
        if (np == NULL) { fhold; fbreak; } else fexec np;
    }
    
    action parse_regexp {
        const char *np = [self _parseRegexpWithPointer:fpc endPointer:pe result:result];
        if (np == NULL) { fhold; fbreak; } else fexec np;
    }

    action exit { fhold; fbreak; }

    main := (
        Vnull @parse_null |
        Vfalse @parse_false |
        Vtrue @parse_true |
        VMinKey @parse_min_key |
        VMaxKey @parse_max_key |
        Vundefined @parse_undefined |
        begin_object_id >parse_object_id |
        begin_number >parse_number |
        begin_string >parse_string |
        begin_array >parse_array |
        begin_object >parse_object |
        begin_regexp >parse_regexp
    ) %*exit;
}%%

- (const char *)_parseValueWithPointer:(const char *)p endPointer:(const char *)pe result:(id *)result
{
    int cs = 0;

    %% write init;
    %% write exec;

    if (cs >= JSON_value_first_final) {
        return p;
    } else {
        return NULL;
    }
}

%%{
   machine JSON_integer;

   write data;

   action exit { fhold; fbreak; }

   main := '-'? ('0' | [1-9][0-9]*) (^[0-9]? @exit);
}%%

- (const char *)_parseIntegerWithPointer:(const char *)p endPointer:(const char *)pe result:(NSNumber **)result
{
    int cs = 0;
    const char *memo;

    %% write init;
    memo = p;
    %% write exec;

    if (cs >= JSON_integer_first_final) {
        NSString *buffer;
        
        buffer = [[NSString alloc] initWithBytesNoCopy:(void *)memo length:p - memo encoding:NSUTF8StringEncoding freeWhenDone:NO];
        *result = [NSNumber numberWithLongLong:[buffer longLongValue]];
        [buffer release];
        return p + 1;
    } else {
        return NULL;
    }
}

%%{
   machine JSON_float;
   include JSON_common;

   write data;

   action exit { fhold; fbreak; }

   main := '-'? (
                 (('0' | [1-9][0-9]*) '.' [0-9]+ ([Ee] [+\-]?[0-9]+)?)
                 | (('0' | [1-9][0-9]*) ([Ee] [+\-]?[0-9]+))
                 )  (^[0-9Ee.\-]? @exit );
}%%

- (const char *)_parseFloatWithPointer:(const char *)p endPointer:(const char *)pe result:(NSNumber **)result
{
    int cs = 0;
    const char *memo;

    %% write init;
    memo = p;
    %% write exec;

    if (cs >= JSON_float_first_final) {
        NSUInteger length = p - memo;
        char *buffer;
        double value;
        
        buffer = malloc(length + 1);
        strncpy(buffer, memo, length);
        sscanf(buffer, "%lf", &value);
        *result = [NSNumber numberWithDouble:value];
        free(buffer);
        return p + 1;
    } else {
        return NULL;
    }
}

%%{
    machine JSON_object;
    include JSON_common;

    write data;

    action parse_value {
        id value = nil;
        const char *np = [self _parseValueWithPointer:fpc endPointer:pe result:&value];
        if (np == NULL) {
            fhold; fbreak;
        } else {
            [*result setObject:value forKey:lastName];
            fexec np;
        }
    }

    action parse_name {
        const char *np;
        np = [self _parseStringWithPointer:fpc endPointer:pe result:&lastName];
        if (np == NULL) { fhold; fbreak; } else fexec np;
    }

    action exit { fhold; fbreak; }

    pair  = ignore* begin_name >parse_name ignore* name_separator ignore* begin_value >parse_value;
    next_pair   = ignore* value_separator pair;
     
    main := (
        begin_object
        (pair (next_pair)*)? ignore*
        end_object
    ) @exit;
}%%

- (const char *)_parseObjectWithPointer:(const char *)p endPointer:(const char *)pe result:(MODSortedMutableDictionary **)result
{
    int cs = 0;
    NSString *lastName;
    
    if (_maxNesting && _currentNesting > _maxNesting) {
        [NSException raise:@"NestingError" format:@"nesting of %d is too deep", _currentNesting];
    }
    
    *result = [[MODSortedMutableDictionary alloc] init];
    
    %% write init;
    %% write exec;
    
    if (cs >= JSON_object_first_final) {
        MODSortedMutableDictionary *tengen;
        
        tengen = [*result tengenJsonEncodedObject];
        if (tengen) {
            [*result release];
            *result = tengen;
        } else {
            [*result autorelease];
        }
        return p + 1;
    } else {
        [*result release];
        *result = nil;
        return NULL;
    }
}

%%{
    machine JSON_object_id;
    include JSON_common;

    write data;
    
    action parse_id_value {
        const char *np;
        np = [self _parseStringWithPointer:fpc endPointer:pe result:&idStringValue];
        if (np == NULL) { fhold; fbreak; } else fexec np;
    }

    action exit { fhold; fbreak; }

    main := (object_id_keyword ignore* '(' ignore* begin_string >parse_id_value ignore* ')') @exit;
}%%

- (const char *)_parseObjectIdWithPointer:(const char *)p endPointer:(const char *)pe result:(MODObjectId **)result
{
    NSString *idStringValue;
    int cs = 0;

    %% write init;
    %% write exec;

    if (cs >= JSON_object_id_first_final && [MODObjectId isStringValid:idStringValue]) {
        *result = [[[MODObjectId alloc] initWithString:idStringValue] autorelease];
        return p + 1;
    } else {
        *result = nil;
        return NULL;
    }
}

- (const char *)_parseRegexpWithPointer:(const char *)string endPointer:(const char *)stringEnd result:(MODRegex **)result
{
    const char *bookmark, *cursor;
    BOOL backslashJustBefore = NO;
    
    cursor = string + 1;
    bookmark = cursor;
    while (cursor < stringEnd && *cursor != '/' && !backslashJustBefore) {
        if (*cursor == '\\') {
            backslashJustBefore = YES;
        } else {
            backslashJustBefore = NO;
        }
        cursor++;
    }
    if (*cursor == '/') {
        NSString *buffer;
        NSString *options;
        
        buffer = [[NSString alloc] initWithBytesNoCopy:(void *)bookmark length:cursor - bookmark encoding:NSUTF8StringEncoding freeWhenDone:NO];
        cursor++;
        
        bookmark = cursor;
        while (cursor < stringEnd && (*cursor == 'i' || *cursor == 'm' || *cursor == 's' || *cursor == 'x')) {
            cursor++;
        }
        options = [[NSString alloc] initWithBytesNoCopy:(void *)bookmark length:cursor - bookmark encoding:NSUTF8StringEncoding freeWhenDone:NO];
        
        *result = [[[MODRegex alloc] initWithPattern:buffer options:options] autorelease];
        [buffer release];
        [options release];
    } else {
        cursor = NULL;
        _error = [self _errorWithMessage:@"cannot find end of regex" atPosition:cursor];
    }
    return cursor;
}

- (const char *)_parseStringWithPointer:(const char *)string endPointer:(const char *)stringEnd result:(NSString **)result
{
    NSMutableString *mutableResult;
    const char *unescape, *bookmark, *cursor;
    int unescapeLength;
    char quoteString;
    NSString *buffer;
    
    mutableResult = [[NSMutableString alloc] init];
    quoteString = string[0];
    cursor = string + 1;
    bookmark = cursor;
    while (cursor < stringEnd && *cursor != quoteString) {
        if (*cursor == '\\') {
            unescape = (char *) "?";
            unescapeLength = 1;
            if (cursor > bookmark) {
                // if the string starts with a \, there is no need to add anything
                buffer = [[NSString alloc] initWithBytesNoCopy:(void *)bookmark length:cursor - bookmark encoding:NSUTF8StringEncoding freeWhenDone:NO];
                [mutableResult appendString:buffer];
                [buffer release];
            }
            switch (*++cursor) {
                case 'n':
                    unescape = (char *) "\n";
                    break;
                case 'r':
                    unescape = (char *) "\r";
                    break;
                case 't':
                    unescape = (char *) "\t";
                    break;
                case '"':
                    unescape = (char *) "\"";
                    break;
                case '\'':
                    unescape = (char *) "'";
                    break;
                case '\\':
                    unescape = (char *) "\\";
                    break;
                case 'b':
                    unescape = (char *) "\b";
                    break;
                case 'f':
                    unescape = (char *) "\f";
                    break;
                default:
                    // take it as a regular character
                    bookmark = cursor;
                    continue;
            }
            buffer = [[NSString alloc] initWithBytesNoCopy:(void *)unescape length:unescapeLength encoding:NSUTF8StringEncoding freeWhenDone:NO];
            [mutableResult appendString:buffer];
            [buffer release];
            bookmark = ++cursor;
        } else {
            cursor++;
        }
    }
    if (*cursor == quoteString) {
        buffer = [[NSString alloc] initWithBytesNoCopy:(void *)bookmark length:cursor - bookmark encoding:NSUTF8StringEncoding freeWhenDone:NO];
        [mutableResult appendString:buffer];
        [buffer release];
        *result = [mutableResult autorelease];
        cursor++;
    } else {
        cursor = NULL;
        _error = [self _errorWithMessage:@"cannot find end of string" atPosition:cursor];
    }
    return cursor;
}

%%{
    machine JSON_array;
    include JSON_common;
    
    write data;
    
    action parse_value {
        id value;
        const char *np = [self _parseValueWithPointer:fpc endPointer:pe result:&value];
        if (np == NULL) {
            fhold; fbreak;
        } else {
            [*result addObject:value];
            fexec np;
        }
    }
    
    action exit { fhold; fbreak; }
    
    next_element  = value_separator ignore* begin_value >parse_value;
    
    main := begin_array ignore*
    ((begin_value >parse_value ignore*)
     (ignore* next_element ignore*)*)?
    end_array @exit;
}%%

- (const char *)_parseArrayWithPointer:(const char *)p endPointer:(const char *)pe result:(NSMutableArray **)result
{
    int cs = 0;
    
    if (_maxNesting && _currentNesting > _maxNesting) {
        [NSException raise:@"NestingError" format:@"nesting of %d is too deep", _currentNesting];
    }
    *result = [[[NSMutableArray alloc] init] autorelease];
    
    %% write init;
    %% write exec;
    
    if(cs >= JSON_array_first_final) {
        return p + 1;
    } else {
        [NSException raise:@"ParserError"format:@"%u: unexpected token at '%s'", __LINE__, p];
        return NULL;
    }
}

%%{
    machine JSON;

    write data;

    include JSON_common;

    action parse_object {
        const char *np;
        _currentNesting = 1;
        np = [self _parseObjectWithPointer:fpc endPointer:pe result:&result];
        if (np == NULL) { fhold; fbreak; } else fexec np;
    }

    action parse_array {
        const char *np;
        _currentNesting = 1;
        np = [self _parseArrayWithPointer:fpc endPointer:pe result:&result];
        if (np == NULL) { fhold; fbreak; } else fexec np;
    }
    
    main := ignore* (
        begin_object >parse_object |
        begin_array >parse_array
    ) ignore*;
}%%

- (id)parseJson:(NSString *)source
{
    const char *p, *pe;
    id result = nil;
    int cs = 0;
    
    cStringBuffer = [source UTF8String];
    %% write init;
    p = cStringBuffer;
    pe = p + strlen(p);
    %% write exec;
    
    if (cs >= JSON_first_final && p == pe) {
        return result;
    } else {
        if (!_error) {
            _error = [self _errorWithMessage:@"unexpected token" atPosition:p];
        }
        return nil;
    }
}
                    
- (NSError *)error
{
    return _error;
}

@end
