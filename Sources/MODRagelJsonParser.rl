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
#import "MOD_internal.h"

@interface MODRagelJsonParser ()
- (id)parseJson:(NSString *)source withError:(NSError **)error;
@end

@implementation MODRagelJsonParser (private)

+ (void)bsonFromJson:(bson *)bsonResult json:(NSString *)json error:(NSError **)error
{
    id object = [self objectsFromJson:json error:error];
    
    if (object && !*error && [object isKindOfClass:NSArray.class]) {
        object = [MODSortedMutableDictionary sortedDictionaryWithObject:object forKey:@"array"];
    }
    if (object && !*error && [object isKindOfClass:MODSortedMutableDictionary.class]) {
        [MODServer appendObject:object toBson:bsonResult];
    }
}

@end

@implementation MODRagelJsonParser

+ (id)objectsFromJson:(NSString *)source error:(NSError **)error
{
    //
    MODRagelJsonParser *parser = [[self alloc] init];
    id result;

    result = [parser parseJson:source withError:error];
    [parser release];
    return result;
}

- (NSError *)_errorWithMessage:(NSString *)message
{
    return [NSError errorWithDomain:@"error" code:0 userInfo:nil];
}

%%{
    machine JSON_common;

    cr                  = '\n';
    cr_neg              = [^\n];
    ws                  = [ \t\r\n];
    c_comment           = '/*' ( any* - (any* '*/' any* ) ) '*/';
    cpp_comment         = '//' cr_neg* cr;
    comment             = c_comment | cpp_comment;
    ignore              = ws | comment;
    name_separator      = ':';
    value_separator     = ',';
    Vnull               = 'null';
    Vfalse              = 'false';
    Vtrue               = 'true';
    VNaN                = 'NaN';
    VInfinity           = 'Infinity';
    VMinusInfinity      = '-Infinity';
    VMinKey             = 'MinKey';
    VMaxKey             = 'MaxKey';
    begin_value         = [nftM\"\-\[\{NI] | digit;
    begin_object        = '{';
    end_object          = '}';
    begin_array         = '[';
    end_array           = ']';
    begin_string        = '"';
    begin_name          = begin_string;
    begin_number        = digit | '-';
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
   action parse_nan {
       assert(NO); // not implemented
//       if (_allowNan) {
//           *result = CNaN;
//       } else {
//           [NSException raise:@"ParserError" format:@"%u: unexpected token at '%s'", __LINE__, p - 2];
//       }
   }
    action parse_infinity {
        assert(NO); // not implemented
        if (_allowNan) {
//           *result = CInfinity;
        } else {
//           [NSException raise:@"ParserError" format:"%u: unexpected token at '%s'", __LINE__, p - 8];
        }
    }

    action parse_min_key {
        *result = [[[MODMinKey alloc] init] autorelease];
    }

    action parse_max_key {
        *result = [[[MODMaxKey alloc] init] autorelease];
    }

    action parse_string {
        const char *np = [self _parseStringWithPointer:fpc endPointer:pe result:result];
        if (np == NULL) { fhold; fbreak; } else fexec np;
    }

    action parse_number {
        const char *np;
//       if(pe > fpc + 9 - json->quirks_mode && !strncmp(MinusInfinity, fpc, 9)) {
//           if (_allowNan) {
//               *result = CMinusInfinity;
//               fexec p + 10;
//               fhold; fbreak;
//           } else {
//               [NSException raise:@"ParserError" format:@"%u: unexpected token at '%s'", __LINE__, p];
//           }
//       }
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

    action exit { fhold; fbreak; }

    main := (
        Vnull @parse_null |
        Vfalse @parse_false |
        Vtrue @parse_true |
        VNaN @parse_nan |
        VInfinity @parse_infinity |
        VMinKey @parse_min_key |
        VMaxKey @parse_max_key |
        begin_number >parse_number |
        begin_string >parse_string |
        begin_array >parse_array |
        begin_object >parse_object
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

    %% write init;
    _memo = p;
    %% write exec;

    if (cs >= JSON_integer_first_final) {
        NSString *buffer;
        
        buffer = [[NSString alloc] initWithBytesNoCopy:(void *)_memo length:p - _memo encoding:NSUTF8StringEncoding freeWhenDone:NO];
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

    %% write init;
    _memo = p;
    %% write exec;

    if (cs >= JSON_float_first_final) {
        NSUInteger length = p - _memo;
        char *buffer;
        double value;
        
        buffer = malloc(length + 1);
        strncpy(buffer, _memo, length);
        sscanf(buffer, "%lf", &value);
        *result = [NSNumber numberWithDouble:value];
        free(buffer);
        return p + 1;
    } else {
        return NULL;
    }
}

static NSMutableString *jsonStringUnescape(NSMutableString *result, const char *string, const char *stringEnd)
{
    const char *p = string, *pe = string, *unescape;
    int unescape_len;
    NSString *buffer;

    while (pe < stringEnd) {
        if (*pe == '\\') {
            unescape = (char *) "?";
            unescape_len = 1;
            if (pe > p) {
                buffer = [[NSString alloc] initWithBytesNoCopy:(void *)p length:pe - p encoding:NSUTF8StringEncoding freeWhenDone:NO];
                [result appendString:buffer];
                [buffer release];
            }
            switch (*++pe) {
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
                    p = pe;
                    continue;
            }
            buffer = [[NSString alloc] initWithBytesNoCopy:(void *)unescape length:unescape_len encoding:NSUTF8StringEncoding freeWhenDone:NO];
            [result appendString:buffer];
            [buffer release];
            p = ++pe;
        } else {
            pe++;
        }
    }
    buffer = [[NSString alloc] initWithBytesNoCopy:(void *)p length:pe - p encoding:NSUTF8StringEncoding freeWhenDone:NO];
    [result appendString:buffer];
    [buffer release];
    return result;
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
        _parsingName = YES;
        np = [self _parseStringWithPointer:fpc endPointer:pe result:&lastName];
        _parsingName = NO;
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
    NSMutableString *lastName;
    
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
   machine JSON_string;
   include JSON_common;
   
   write data;
   
   action parse_string {
       *result = jsonStringUnescape(*result, _memo + 1, p);
       if (*result == nil) {
           fhold;
           fbreak;
       } else {
           fexec p + 1;
       }
   }
   
   action exit { fhold; fbreak; }
   
   main := '"' ((^([\"\\] | 0..0x1f) | '\\'[\"\\/bfnrt] | '\\u'[0-9a-fA-F]{4} | '\\'^([\"\\/bfnrtu]|0..0x1f))* %parse_string) '"' @exit;
}%%

- (const char *)_parseStringWithPointer:(const char *)p endPointer:(const char *)pe result:(NSMutableString **)result
{
    int cs = 0;
   
    *result = [NSMutableString string];
    %% write init;
    _memo = p;
    %% write exec;
   
    if (cs >= JSON_string_first_final) {
        return p + 1;
    } else {
        *result = nil;
        return NULL;
    }
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

- (id)parseJson:(NSString *)source withError:(NSError **)error
{
    const char *p, *pe;
    id result = nil;
    int cs = 0;
    const char *cString = [source UTF8String];
    
    %% write init;
    p = cString;
    pe = p + strlen(p);
    %% write exec;
    
    if (cs >= JSON_first_final && p == pe) {
        *error = nil;
        return result;
    } else {
        *error = [self _errorWithMessage:[NSString stringWithFormat:@"unexpected token at '%s'", p]];
        return nil;
    }
}

@end
