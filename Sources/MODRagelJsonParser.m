
#line 1 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
//
//  MODRagelJsonParser.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 01/09/2013.
//
//

#import "MODRagelJsonParser.h"
#import "MODSortedDictionary.h"
#import "MODMaxKey.h"
#import "MODMinKey.h"
#import "MODUndefined.h"
#import "MODObjectId.h"
#import "MODRegex.h"
#import "MongoObjCDriver-private.h"
#import "MODBinary.h"
#import "MODTimestamp.h"
#import "MODSymbol.h"

#pragma clang diagnostic ignored "-Wunused-variable"

@interface MODRagelJsonParser ()
@property (nonatomic, strong, readwrite) NSError *error;

@end

@implementation MODRagelJsonParser (private)

+ (BOOL)bsonFromJson:(bson_t *)bsonResult json:(NSString *)json error:(NSError **)outputError
{
    NSError *error = nil;
    id object = [self objectsFromJson:json withError:&error];
    
    if (object && !error && [object isKindOfClass:NSArray.class]) {
        object = [MODSortedDictionary sortedDictionaryWithObject:object forKey:@"array"];
    }
    if (object && !error && [object isKindOfClass:MODSortedDictionary.class]) {
        [MODClient appendObject:object toBson:bsonResult];
    }
    if (outputError) {
        *outputError = error;
    }
    return !error;
}

@end

@implementation MODRagelJsonParser

@synthesize error = _error;

+ (id)objectsFromJson:(NSString *)source withError:(NSError **)error
{
    MODRagelJsonParser *parser = [[self alloc] init];
    id result;
    
    result = [parser parseJson:source withError:error];
    MOD_RELEASE(parser);
    return result;
}

- (void)_makeErrorWithMessage:(NSString *)message atPosition:(const char *)position
{
    if (!self.error) {
        NSUInteger length;
        
        length = strlen(position);
        if (length > 10) {
            length = 10;
        }
        self.error = [NSError errorWithDomain:@"error" code:0 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@: \"%@\"", message, MOD_AUTORELEASE([[NSString alloc] initWithBytes:position length:length encoding:NSUTF8StringEncoding])] }];
    }
}


#line 115 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"



#line 84 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
static const char _JSON_value_actions[] = {
	0, 1, 0, 1, 1, 1, 2, 1, 
	3, 1, 4, 1, 5, 1, 6, 1, 
	7, 1, 8, 1, 9, 1, 10, 1, 
	11, 1, 12, 1, 13, 1, 14, 1, 
	15, 1, 16, 1, 17, 1, 18, 1, 
	19, 1, 20, 1, 21, 1, 22, 1, 
	23
};

static const char _JSON_value_key_offsets[] = {
	0, 0, 20, 22, 23, 24, 25, 26, 
	27, 28, 29, 30, 31, 32, 33, 34, 
	35, 37, 39, 41, 42, 43, 44, 45, 
	46, 47, 48, 49, 50, 51, 52, 53, 
	54, 55, 56, 57, 58, 59, 60, 61, 
	62, 63, 64, 65, 66, 67, 68, 69, 
	70, 71, 72, 73, 74, 75, 76, 78, 
	79, 80, 81, 82, 83, 84, 85, 86, 
	87, 88, 89, 90, 91, 92, 93, 94, 
	95, 96, 97, 99, 100, 101, 102, 103, 
	104, 105, 106, 107, 108, 109, 110, 111, 
	112, 113
};

static const char _JSON_value_trans_keys[] = {
	34, 39, 45, 47, 66, 68, 70, 77, 
	78, 79, 83, 84, 91, 102, 110, 116, 
	117, 123, 48, 57, 97, 105, 120, 75, 
	101, 121, 110, 75, 101, 121, 117, 109, 
	98, 101, 114, 46, 76, 78, 80, 69, 
	97, 71, 65, 84, 73, 86, 69, 95, 
	73, 78, 70, 73, 78, 73, 84, 89, 
	78, 79, 83, 73, 84, 73, 86, 69, 
	95, 73, 78, 70, 73, 78, 73, 84, 
	89, 111, 110, 103, 99, 121, 111, 112, 
	101, 70, 117, 110, 99, 116, 105, 111, 
	110, 109, 98, 111, 108, 97, 108, 115, 
	101, 101, 117, 119, 108, 108, 114, 117, 
	101, 110, 100, 101, 102, 105, 110, 101, 
	100, 0
};

static const char _JSON_value_single_lengths[] = {
	0, 18, 2, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	2, 2, 2, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 2, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 2, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 0
};

static const char _JSON_value_range_lengths[] = {
	0, 1, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0
};

static const short _JSON_value_index_offsets[] = {
	0, 0, 20, 23, 25, 27, 29, 31, 
	33, 35, 37, 39, 41, 43, 45, 47, 
	49, 52, 55, 58, 60, 62, 64, 66, 
	68, 70, 72, 74, 76, 78, 80, 82, 
	84, 86, 88, 90, 92, 94, 96, 98, 
	100, 102, 104, 106, 108, 110, 112, 114, 
	116, 118, 120, 122, 124, 126, 128, 131, 
	133, 135, 137, 139, 141, 143, 145, 147, 
	149, 151, 153, 155, 157, 159, 161, 163, 
	165, 167, 169, 172, 174, 176, 178, 180, 
	182, 184, 186, 188, 190, 192, 194, 196, 
	198, 200
};

static const char _JSON_value_trans_targs[] = {
	89, 89, 89, 89, 89, 89, 89, 2, 
	11, 89, 54, 89, 89, 70, 74, 78, 
	81, 89, 89, 0, 3, 7, 0, 4, 
	0, 5, 0, 6, 0, 89, 0, 8, 
	0, 9, 0, 10, 0, 89, 0, 12, 
	0, 13, 0, 14, 0, 15, 0, 16, 
	0, 17, 51, 0, 18, 35, 0, 19, 
	34, 0, 20, 0, 21, 0, 22, 0, 
	23, 0, 24, 0, 25, 0, 26, 0, 
	27, 0, 28, 0, 29, 0, 30, 0, 
	31, 0, 32, 0, 33, 0, 89, 0, 
	89, 0, 36, 0, 37, 0, 38, 0, 
	39, 0, 40, 0, 41, 0, 42, 0, 
	43, 0, 44, 0, 45, 0, 46, 0, 
	47, 0, 48, 0, 49, 0, 50, 0, 
	89, 0, 52, 0, 53, 0, 89, 0, 
	55, 66, 0, 56, 0, 57, 0, 58, 
	0, 59, 0, 60, 0, 61, 0, 62, 
	0, 63, 0, 64, 0, 65, 0, 89, 
	0, 67, 0, 68, 0, 69, 0, 89, 
	0, 71, 0, 72, 0, 73, 0, 89, 
	0, 75, 76, 0, 89, 0, 77, 0, 
	89, 0, 79, 0, 80, 0, 89, 0, 
	82, 0, 83, 0, 84, 0, 85, 0, 
	86, 0, 87, 0, 88, 0, 89, 0, 
	0, 0
};

static const char _JSON_value_trans_actions[] = {
	21, 21, 23, 29, 35, 41, 39, 0, 
	0, 19, 0, 33, 25, 0, 0, 0, 
	0, 27, 23, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 9, 0, 0, 
	0, 0, 0, 0, 0, 7, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 15, 0, 
	17, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	13, 0, 0, 0, 0, 0, 31, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 43, 
	0, 0, 0, 0, 0, 0, 0, 37, 
	0, 0, 0, 0, 0, 0, 0, 3, 
	0, 0, 0, 0, 45, 0, 0, 0, 
	1, 0, 0, 0, 0, 0, 5, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 11, 0, 
	0, 0
};

static const char _JSON_value_from_state_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 47
};

static const int JSON_value_start = 1;
static const int JSON_value_first_final = 89;
static const int JSON_value_error = 0;

static const int JSON_value_en_main = 1;


#line 288 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"


- (const char *)_parseValueWithPointer:(const char *)p endPointer:(const char *)pe result:(id *)result
{
    int cs = 0;

    
#line 261 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_value_start;
	}

#line 295 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    
#line 268 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == pe )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_acts = _JSON_value_actions + _JSON_value_from_state_actions[cs];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 ) {
		switch ( *_acts++ ) {
	case 23:
#line 261 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{ p--; {p++; goto _out; } }
	break;
#line 289 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
		}
	}

	_keys = _JSON_value_trans_keys + _JSON_value_key_offsets[cs];
	_trans = _JSON_value_index_offsets[cs];

	_klen = _JSON_value_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*p) < *_mid )
				_upper = _mid - 1;
			else if ( (*p) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _JSON_value_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*p) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*p) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	cs = _JSON_value_trans_targs[_trans];

	if ( _JSON_value_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _JSON_value_actions + _JSON_value_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 123 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        *result = [NSNull null];
    }
	break;
	case 1:
#line 126 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        *result = [NSNumber numberWithBool:NO];
    }
	break;
	case 2:
#line 129 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        *result = [NSNumber numberWithBool:YES];
    }
	break;
	case 3:
#line 133 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        *result = MOD_AUTORELEASE([[MODMinKey alloc] init]);
    }
	break;
	case 4:
#line 137 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        *result = MOD_AUTORELEASE([[MODMaxKey alloc] init]);
    }
	break;
	case 5:
#line 141 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        *result = MOD_AUTORELEASE([[MODUndefined alloc] init]);
    }
	break;
	case 6:
#line 145 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        *result = [NSNumber numberWithDouble:INFINITY];
    }
	break;
	case 7:
#line 149 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        *result = [NSNumber numberWithDouble:-INFINITY];
    }
	break;
	case 8:
#line 153 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        *result = [NSNumber numberWithDouble:NAN];
    }
	break;
	case 9:
#line 157 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np = [self _parseObjectIdWithPointer:p endPointer:pe result:result];
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
	case 10:
#line 162 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np = [self _parseStringWithPointer:p endPointer:pe result:result];
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
	case 11:
#line 167 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        np = [self _parseFloatWithPointer:p endPointer:pe result:result];
        if (np != NULL) {p = (( np))-1;}
        np = [self _parseIntegerWithPointer:p endPointer:pe result:result];
        if (np != NULL) {p = (( np))-1;}
        p--; {p++; goto _out; }
    }
	break;
	case 12:
#line 176 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        _currentNesting++;
        np = [self _parseArrayWithPointer:p endPointer:pe result:result];
        _currentNesting--;
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
	case 13:
#line 184 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        _currentNesting++;
        np = [self _parseObjectWithPointer:p endPointer:pe result:result];
        _currentNesting--;
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
	case 14:
#line 192 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np = [self _parseRegexpWithPointer:p endPointer:pe result:result];
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
	case 15:
#line 197 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np = [self _parseNumberLongWithPointer:p - strlen("NumberLong") + 1 endPointer:pe result:result];
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
	case 16:
#line 202 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np = [self _parseTimestampWithPointer:p endPointer:pe result:result];
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
	case 17:
#line 207 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np = [self _parseBinDataWithPointer:p endPointer:pe result:result];
        if (np == NULL) {
            p--; {p++; goto _out; }
        } else {
            {p = (( np))-1;}
        }
    }
	break;
	case 18:
#line 216 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np = [self _parseSymbolWithPointer:p - strlen("Symbol") + 1 endPointer:pe result:result];
        if (np == NULL) {
            p--; {p++; goto _out; }
        } else {
            {p = (( np))-1;}
        }
    }
	break;
	case 19:
#line 225 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np = [self _parseFunctionWithPointer:p endPointer:pe result:result];
        if (np == NULL) {
            p--; {p++; goto _out; }
        } else {
            {p = (( np))-1;}
        }
    }
	break;
	case 20:
#line 234 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np = [self _parseDBPointerWithPointer:p endPointer:pe result:result];
        if (np == NULL) {
            p--; {p++; goto _out; }
        } else {
            {p = (( np))-1;}
        }
    }
	break;
	case 21:
#line 243 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np = [self _parseScopeFunctionWithPointer:p - strlen("ScopeFunction") + 1 endPointer:pe result:result];
        if (np == NULL) {
            p--; {p++; goto _out; }
        } else {
            {p = (( np))-1;}
        }
    }
	break;
	case 22:
#line 252 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np = [self _parseJavascriptObjectWithPointer:p - 2 endPointer:pe result:result];
        if (np == NULL) {
            p--; {p++; goto _out; }
        } else {
            {p = (( np))-1;}
        }
    }
	break;
#line 539 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

#line 296 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"

    if (*result == nil || cs < JSON_value_first_final) {
        [self _makeErrorWithMessage:@"cannot parse value" atPosition:p];
        return NULL;
    } else {
        return p;
    }
}


#line 563 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
static const char _JSON_integer_actions[] = {
	0, 1, 0
};

static const char _JSON_integer_key_offsets[] = {
	0, 0, 4, 7, 9, 9
};

static const char _JSON_integer_trans_keys[] = {
	45, 48, 49, 57, 48, 49, 57, 48, 
	57, 48, 57, 0
};

static const char _JSON_integer_single_lengths[] = {
	0, 2, 1, 0, 0, 0
};

static const char _JSON_integer_range_lengths[] = {
	0, 1, 1, 1, 0, 1
};

static const char _JSON_integer_index_offsets[] = {
	0, 0, 4, 7, 9, 10
};

static const char _JSON_integer_indicies[] = {
	0, 2, 3, 1, 2, 3, 1, 1, 
	4, 1, 3, 4, 0
};

static const char _JSON_integer_trans_targs[] = {
	2, 0, 3, 5, 4
};

static const char _JSON_integer_trans_actions[] = {
	0, 0, 0, 0, 1
};

static const int JSON_integer_start = 1;
static const int JSON_integer_first_final = 3;
static const int JSON_integer_error = 0;

static const int JSON_integer_en_main = 1;


#line 313 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"


- (const char *)_parseIntegerWithPointer:(const char *)p endPointer:(const char *)pe result:(NSNumber **)result
{
    int cs = 0;
    const char *memo;

    
#line 618 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_integer_start;
	}

#line 321 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    memo = p;
    
#line 626 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == pe )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _JSON_integer_trans_keys + _JSON_integer_key_offsets[cs];
	_trans = _JSON_integer_index_offsets[cs];

	_klen = _JSON_integer_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*p) < *_mid )
				_upper = _mid - 1;
			else if ( (*p) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _JSON_integer_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*p) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*p) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _JSON_integer_indicies[_trans];
	cs = _JSON_integer_trans_targs[_trans];

	if ( _JSON_integer_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _JSON_integer_actions + _JSON_integer_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 310 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{ p--; {p++; goto _out; } }
	break;
#line 704 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

#line 323 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"

    if (cs >= JSON_integer_first_final) {
        NSString *buffer;
        
        buffer = [[NSString alloc] initWithBytes:(void *)memo length:p - memo encoding:NSUTF8StringEncoding];
        if (buffer.longLongValue > INT_MAX || buffer.longLongValue < INT_MIN) {
            *result = [NSNumber numberWithLongLong:buffer.longLongValue];
        } else {
            *result = [NSNumber numberWithInt:buffer.intValue];
        }
        MOD_RELEASE(buffer);
        return p + 1;
    } else {
        return NULL;
    }
}


#line 736 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
static const char _JSON_float_actions[] = {
	0, 1, 0
};

static const char _JSON_float_key_offsets[] = {
	0, 0, 4, 7, 10, 12, 16, 18, 
	23, 29, 29
};

static const char _JSON_float_trans_keys[] = {
	45, 48, 49, 57, 48, 49, 57, 46, 
	69, 101, 48, 57, 43, 45, 48, 57, 
	48, 57, 46, 69, 101, 48, 57, 69, 
	101, 45, 46, 48, 57, 69, 101, 45, 
	46, 48, 57, 0
};

static const char _JSON_float_single_lengths[] = {
	0, 2, 1, 3, 0, 2, 0, 3, 
	2, 0, 2
};

static const char _JSON_float_range_lengths[] = {
	0, 1, 1, 0, 1, 1, 1, 1, 
	2, 0, 2
};

static const char _JSON_float_index_offsets[] = {
	0, 0, 4, 7, 11, 13, 17, 19, 
	24, 29, 30
};

static const char _JSON_float_indicies[] = {
	0, 2, 3, 1, 2, 3, 1, 4, 
	5, 5, 1, 6, 1, 7, 7, 8, 
	1, 8, 1, 4, 5, 5, 3, 1, 
	5, 5, 1, 6, 9, 1, 1, 1, 
	1, 8, 9, 0
};

static const char _JSON_float_trans_targs[] = {
	2, 0, 3, 7, 4, 5, 8, 6, 
	10, 9
};

static const char _JSON_float_trans_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 1
};

static const int JSON_float_start = 1;
static const int JSON_float_first_final = 8;
static const int JSON_float_error = 0;

static const int JSON_float_en_main = 1;


#line 352 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"


- (const char *)_parseFloatWithPointer:(const char *)p endPointer:(const char *)pe result:(NSNumber **)result
{
    int cs = 0;
    const char *memo;
    
    
#line 803 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_float_start;
	}

#line 360 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    memo = p;
    
#line 811 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == pe )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _JSON_float_trans_keys + _JSON_float_key_offsets[cs];
	_trans = _JSON_float_index_offsets[cs];

	_klen = _JSON_float_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*p) < *_mid )
				_upper = _mid - 1;
			else if ( (*p) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _JSON_float_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*p) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*p) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _JSON_float_indicies[_trans];
	cs = _JSON_float_trans_targs[_trans];

	if ( _JSON_float_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _JSON_float_actions + _JSON_float_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 346 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{ p--; {p++; goto _out; } }
	break;
#line 889 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

#line 362 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"

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


#line 921 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
static const char _JSON_object_actions[] = {
	0, 1, 0, 1, 1, 1, 2
};

static const char _JSON_object_key_offsets[] = {
	0, 0, 1, 16, 21, 43, 49, 63
};

static const char _JSON_object_trans_keys[] = {
	123, 13, 32, 39, 95, 125, 9, 10, 
	34, 36, 48, 57, 65, 90, 97, 122, 
	13, 32, 58, 9, 10, 13, 32, 34, 
	39, 45, 66, 68, 70, 91, 102, 110, 
	123, 9, 10, 47, 57, 77, 79, 83, 
	84, 116, 117, 13, 32, 44, 125, 9, 
	10, 13, 32, 39, 95, 9, 10, 34, 
	36, 48, 57, 65, 90, 97, 122, 0
};

static const char _JSON_object_single_lengths[] = {
	0, 1, 5, 3, 12, 4, 4, 0
};

static const char _JSON_object_range_lengths[] = {
	0, 0, 5, 1, 5, 1, 5, 0
};

static const char _JSON_object_index_offsets[] = {
	0, 0, 2, 13, 18, 36, 42, 52
};

static const char _JSON_object_indicies[] = {
	0, 1, 0, 0, 2, 2, 3, 0, 
	2, 2, 2, 2, 1, 4, 4, 5, 
	4, 1, 5, 5, 6, 6, 6, 6, 
	6, 6, 6, 6, 6, 6, 5, 6, 
	6, 6, 6, 1, 7, 7, 8, 3, 
	7, 1, 8, 8, 2, 2, 8, 2, 
	2, 2, 2, 1, 1, 0
};

static const char _JSON_object_trans_targs[] = {
	2, 0, 3, 7, 3, 4, 5, 5, 
	6
};

static const char _JSON_object_trans_actions[] = {
	0, 0, 3, 5, 0, 0, 1, 0, 
	0
};

static const int JSON_object_start = 1;
static const int JSON_object_first_final = 7;
static const int JSON_object_error = 0;

static const int JSON_object_en_main = 1;


#line 416 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"


- (const char *)_parseObjectWithPointer:(const char *)p endPointer:(const char *)pe result:(MODSortedDictionary **)result
{
    int cs = 0;
    NSString *lastName = nil;
    MODSortedMutableDictionary *dictionary;

    if (_maxNesting && _currentNesting > _maxNesting) {
        [self _makeErrorWithMessage:[NSString stringWithFormat:@"nesting of %d is too deep", _currentNesting] atPosition:p];
    }
    
    dictionary = [MODSortedMutableDictionary sortedDictionary];
    
    
#line 996 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_object_start;
	}

#line 431 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    
#line 1003 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == pe )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _JSON_object_trans_keys + _JSON_object_key_offsets[cs];
	_trans = _JSON_object_index_offsets[cs];

	_klen = _JSON_object_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*p) < *_mid )
				_upper = _mid - 1;
			else if ( (*p) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _JSON_object_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*p) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*p) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _JSON_object_indicies[_trans];
	cs = _JSON_object_trans_targs[_trans];

	if ( _JSON_object_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _JSON_object_actions + _JSON_object_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 385 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        id value = nil;
        const char *np = [self _parseValueWithPointer:p endPointer:pe result:&value];
        if (np == NULL) {
            p--; {p++; goto _out; }
        } else {
            [dictionary setObject:value forKey:lastName];
            {p = (( np))-1;}
        }
    }
	break;
	case 1:
#line 396 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        
        np = [self _parseWordWithPointer:p endPointer:pe result:&lastName];
        if (np == NULL) {
            np = [self _parseStringWithPointer:p endPointer:pe result:&lastName];
        }
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
	case 2:
#line 406 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{ p--; {p++; goto _out; } }
	break;
#line 1106 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

#line 432 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    
    if (cs >= JSON_object_first_final) {
        MODSortedDictionary *tengen;
        
        tengen = [dictionary tengenJsonEncodedObject];
        if (tengen) {
            *result = tengen;
        } else {
            *result = dictionary;
        }
        return p + 1;
    } else {
        *result = nil;
        return NULL;
    }
}


#line 1138 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
static const char _JSON_javascript_object_actions[] = {
	0, 1, 0, 1, 1, 1, 2
};

static const char _JSON_javascript_object_key_offsets[] = {
	0, 0, 2, 3, 4, 5, 6, 7, 
	8, 13, 19, 24, 25, 26, 31, 32, 
	33, 34, 39, 49, 50, 56, 63
};

static const char _JSON_javascript_object_trans_keys[] = {
	73, 110, 83, 79, 68, 97, 116, 101, 
	13, 32, 40, 9, 10, 13, 32, 34, 
	39, 9, 10, 13, 32, 41, 9, 10, 
	101, 119, 13, 32, 68, 9, 10, 97, 
	116, 101, 13, 32, 40, 9, 10, 13, 
	32, 34, 39, 41, 45, 9, 10, 48, 
	57, 41, 13, 32, 41, 44, 9, 10, 
	13, 32, 45, 9, 10, 48, 57, 0
};

static const char _JSON_javascript_object_single_lengths[] = {
	0, 2, 1, 1, 1, 1, 1, 1, 
	3, 4, 3, 1, 1, 3, 1, 1, 
	1, 3, 6, 1, 4, 3, 0
};

static const char _JSON_javascript_object_range_lengths[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	1, 1, 1, 0, 0, 1, 0, 0, 
	0, 1, 2, 0, 1, 2, 0
};

static const char _JSON_javascript_object_index_offsets[] = {
	0, 0, 3, 5, 7, 9, 11, 13, 
	15, 20, 26, 31, 33, 35, 40, 42, 
	44, 46, 51, 60, 62, 68, 74
};

static const char _JSON_javascript_object_indicies[] = {
	0, 2, 1, 3, 1, 4, 1, 5, 
	1, 6, 1, 7, 1, 8, 1, 8, 
	8, 9, 8, 1, 9, 9, 10, 10, 
	9, 1, 11, 11, 12, 11, 1, 13, 
	1, 14, 1, 14, 14, 15, 14, 1, 
	16, 1, 17, 1, 18, 1, 18, 18, 
	19, 18, 1, 19, 19, 20, 20, 12, 
	21, 19, 21, 1, 12, 1, 22, 22, 
	12, 23, 22, 1, 23, 23, 21, 23, 
	21, 1, 1, 0
};

static const char _JSON_javascript_object_trans_targs[] = {
	2, 0, 11, 3, 4, 5, 6, 7, 
	8, 9, 10, 10, 22, 12, 13, 14, 
	15, 16, 17, 18, 19, 20, 20, 21
};

static const char _JSON_javascript_object_trans_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 3, 0, 5, 0, 0, 0, 
	0, 0, 0, 0, 3, 1, 0, 0
};

static const int JSON_javascript_object_start = 1;
static const int JSON_javascript_object_first_final = 22;
static const int JSON_javascript_object_error = 0;

static const int JSON_javascript_object_en_main = 1;


#line 490 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"


- (const char *)_parseJavascriptObjectWithPointer:(const char *)p endPointer:(const char *)pe result:(id *)result
{
    int cs = 0;
    NSMutableArray *parameters = [[NSMutableArray alloc] init];

    
#line 1219 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_javascript_object_start;
	}

#line 498 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    
#line 1226 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == pe )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _JSON_javascript_object_trans_keys + _JSON_javascript_object_key_offsets[cs];
	_trans = _JSON_javascript_object_index_offsets[cs];

	_klen = _JSON_javascript_object_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*p) < *_mid )
				_upper = _mid - 1;
			else if ( (*p) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _JSON_javascript_object_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*p) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*p) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _JSON_javascript_object_indicies[_trans];
	cs = _JSON_javascript_object_trans_targs[_trans];

	if ( _JSON_javascript_object_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _JSON_javascript_object_actions + _JSON_javascript_object_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 455 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        NSNumber *number;
        
        np = [self _parseIntegerWithPointer:p endPointer:pe result:&number];
        if (np != NULL && number) {
            [parameters addObject:number];
            np--; {p = (( np))-1;}
        } else {
            p--; {p++; goto _out; }
        }
    }
	break;
	case 1:
#line 468 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        NSString *string = nil;
        
        np = [self _parseStringWithPointer:p endPointer:pe result:&string];
        if (np != NULL && string) {
            [parameters addObject:string];
            {p = (( np))-1;}
        } else {
            p--; {p++; goto _out; }
        }
    }
	break;
	case 2:
#line 481 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{ p--; {p++; goto _out; } }
	break;
#line 1334 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

#line 499 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"

    if (cs >= JSON_javascript_object_first_final) {
        if (parameters.count == 1 && [[parameters objectAtIndex:0] isKindOfClass:NSString.class]) {
            NSDateFormatter *formater;
            
            formater = [[NSDateFormatter alloc] init];
            [formater setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
            *result = MOD_AUTORELEASE(MOD_RETAIN([formater dateFromString:[parameters objectAtIndex:0]]));
            MOD_RELEASE(formater);
        } else if (parameters.count == 1 && [[parameters objectAtIndex:0] isKindOfClass:NSNumber.class]) {
            *result = [NSDate dateWithTimeIntervalSince1970:[[parameters objectAtIndex:0] doubleValue] / 1000.0];
        }
    } else {
        *result = nil;
    }
    MOD_RELEASE(parameters);
    if (*result) {
        return p + 1;
    } else {
        [self _makeErrorWithMessage:@"cannot parse javascript object" atPosition:p];
        return NULL;
    }
}


#line 1373 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
static const char _JSON_bin_data_actions[] = {
	0, 1, 0, 1, 1, 1, 2
};

static const char _JSON_bin_data_key_offsets[] = {
	0, 0, 1, 2, 3, 4, 5, 6, 
	7, 12, 19, 24, 30, 35
};

static const char _JSON_bin_data_trans_keys[] = {
	66, 105, 110, 68, 97, 116, 97, 13, 
	32, 40, 9, 10, 13, 32, 45, 9, 
	10, 48, 57, 13, 32, 44, 9, 10, 
	13, 32, 34, 39, 9, 10, 13, 32, 
	41, 9, 10, 0
};

static const char _JSON_bin_data_single_lengths[] = {
	0, 1, 1, 1, 1, 1, 1, 1, 
	3, 3, 3, 4, 3, 0
};

static const char _JSON_bin_data_range_lengths[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	1, 2, 1, 1, 1, 0
};

static const char _JSON_bin_data_index_offsets[] = {
	0, 0, 2, 4, 6, 8, 10, 12, 
	14, 19, 25, 30, 36, 41
};

static const char _JSON_bin_data_indicies[] = {
	0, 1, 2, 1, 3, 1, 4, 1, 
	5, 1, 6, 1, 7, 1, 7, 7, 
	8, 7, 1, 8, 8, 9, 8, 9, 
	1, 10, 10, 11, 10, 1, 11, 11, 
	12, 12, 11, 1, 13, 13, 14, 13, 
	1, 1, 0
};

static const char _JSON_bin_data_trans_targs[] = {
	2, 0, 3, 4, 5, 6, 7, 8, 
	9, 10, 10, 11, 12, 12, 13
};

static const char _JSON_bin_data_trans_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 3, 0, 0, 1, 0, 5
};

static const int JSON_bin_data_start = 1;
static const int JSON_bin_data_first_final = 13;
static const int JSON_bin_data_error = 0;

static const int JSON_bin_data_en_main = 1;


#line 544 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"


- (const char *)_parseBinDataWithPointer:(const char *)p endPointer:(const char *)pe result:(MODBinary **)result
{
    NSString *dataStringValue = nil;
    NSNumber *typeValue = nil;
    NSData *dataValue = nil;
    int cs = 0;

    
#line 1443 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_bin_data_start;
	}

#line 554 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    
#line 1450 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == pe )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _JSON_bin_data_trans_keys + _JSON_bin_data_key_offsets[cs];
	_trans = _JSON_bin_data_index_offsets[cs];

	_klen = _JSON_bin_data_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*p) < *_mid )
				_upper = _mid - 1;
			else if ( (*p) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _JSON_bin_data_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*p) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*p) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _JSON_bin_data_indicies[_trans];
	cs = _JSON_bin_data_trans_targs[_trans];

	if ( _JSON_bin_data_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _JSON_bin_data_actions + _JSON_bin_data_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 529 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        np = [self _parseStringWithPointer:p endPointer:pe result:&dataStringValue];
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
	case 1:
#line 535 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        np = [self _parseIntegerWithPointer:p endPointer:pe result:&typeValue];
        if (np == NULL) { p--; {p++; goto _out; } } else { np--; {p = (( np))-1;} }
    }
	break;
	case 2:
#line 541 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{ p--; {p++; goto _out; } }
	break;
#line 1544 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

#line 555 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"

    dataValue = dataStringValue.mod_dataFromBase64;
    if (cs >= JSON_bin_data_first_final && dataValue && [MODBinary isValidDataType:typeValue.unsignedCharValue] ) {
        *result = MOD_AUTORELEASE([[MODBinary alloc] initWithData:dataValue binaryType:typeValue.unsignedCharValue]);
        return p + 1;
    } else {
        *result = nil;
        return NULL;
    }
}


#line 1570 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
static const char _JSON_function_actions[] = {
	0, 1, 0, 1, 1
};

static const char _JSON_function_key_offsets[] = {
	0, 0, 1, 2, 3, 4, 5, 6, 
	7, 8, 13, 19, 24
};

static const char _JSON_function_trans_keys[] = {
	70, 117, 110, 99, 116, 105, 111, 110, 
	13, 32, 40, 9, 10, 13, 32, 34, 
	39, 9, 10, 13, 32, 41, 9, 10, 
	0
};

static const char _JSON_function_single_lengths[] = {
	0, 1, 1, 1, 1, 1, 1, 1, 
	1, 3, 4, 3, 0
};

static const char _JSON_function_range_lengths[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 1, 1, 1, 0
};

static const char _JSON_function_index_offsets[] = {
	0, 0, 2, 4, 6, 8, 10, 12, 
	14, 16, 21, 27, 32
};

static const char _JSON_function_indicies[] = {
	0, 1, 2, 1, 3, 1, 4, 1, 
	5, 1, 6, 1, 7, 1, 8, 1, 
	8, 8, 9, 8, 1, 9, 9, 10, 
	10, 9, 1, 11, 11, 12, 11, 1, 
	1, 0
};

static const char _JSON_function_trans_targs[] = {
	2, 0, 3, 4, 5, 6, 7, 8, 
	9, 10, 11, 11, 12
};

static const char _JSON_function_trans_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 1, 0, 3
};

static const int JSON_function_start = 1;
static const int JSON_function_first_final = 12;
static const int JSON_function_error = 0;

static const int JSON_function_en_main = 1;


#line 581 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"


- (const char *)_parseFunctionWithPointer:(const char *)p endPointer:(const char *)pe result:(MODFunction **)result
{
    NSString *codeStringValue = nil;
    int cs = 0;

    
#line 1636 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_function_start;
	}

#line 589 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    
#line 1643 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == pe )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _JSON_function_trans_keys + _JSON_function_key_offsets[cs];
	_trans = _JSON_function_index_offsets[cs];

	_klen = _JSON_function_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*p) < *_mid )
				_upper = _mid - 1;
			else if ( (*p) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _JSON_function_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*p) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*p) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _JSON_function_indicies[_trans];
	cs = _JSON_function_trans_targs[_trans];

	if ( _JSON_function_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _JSON_function_actions + _JSON_function_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 572 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        np = [self _parseStringWithPointer:p endPointer:pe result:&codeStringValue];
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
	case 1:
#line 578 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{ p--; {p++; goto _out; } }
	break;
#line 1729 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

#line 590 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"

    if (cs >= JSON_function_first_final && codeStringValue) {
        *result = MOD_AUTORELEASE([[MODFunction alloc] initWithFunction:codeStringValue]);
        return p + 1;
    } else {
        *result = nil;
        return NULL;
    }
}


#line 1754 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
static const char _JSON_dbref_actions[] = {
	0, 1, 0, 1, 1, 1, 2
};

static const char _JSON_dbref_key_offsets[] = {
	0, 0, 1, 2, 3, 4, 5, 6, 
	7, 8, 9, 14, 20, 25, 31, 36
};

static const char _JSON_dbref_trans_keys[] = {
	68, 66, 80, 111, 105, 110, 116, 101, 
	114, 13, 32, 40, 9, 10, 13, 32, 
	34, 39, 9, 10, 13, 32, 44, 9, 
	10, 13, 32, 34, 39, 9, 10, 13, 
	32, 41, 9, 10, 0
};

static const char _JSON_dbref_single_lengths[] = {
	0, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 3, 4, 3, 4, 3, 0
};

static const char _JSON_dbref_range_lengths[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 1, 1, 1, 1, 1, 0
};

static const char _JSON_dbref_index_offsets[] = {
	0, 0, 2, 4, 6, 8, 10, 12, 
	14, 16, 18, 23, 29, 34, 40, 45
};

static const char _JSON_dbref_indicies[] = {
	0, 1, 2, 1, 3, 1, 4, 1, 
	5, 1, 6, 1, 7, 1, 8, 1, 
	9, 1, 9, 9, 10, 9, 1, 10, 
	10, 11, 11, 10, 1, 12, 12, 13, 
	12, 1, 13, 13, 14, 14, 13, 1, 
	15, 15, 16, 15, 1, 1, 0
};

static const char _JSON_dbref_trans_targs[] = {
	2, 0, 3, 4, 5, 6, 7, 8, 
	9, 10, 11, 12, 12, 13, 14, 14, 
	15
};

static const char _JSON_dbref_trans_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 1, 0, 0, 3, 0, 
	5
};

static const int JSON_dbref_start = 1;
static const int JSON_dbref_first_final = 15;
static const int JSON_dbref_error = 0;

static const int JSON_dbref_en_main = 1;


#line 631 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"


- (const char *)_parseDBPointerWithPointer:(const char *)p endPointer:(const char *)pe result:(MODDBPointer **)result
{
    NSString *collectionName = nil;
    MODObjectId *documentId = nil;
    int cs = 0;

    
#line 1825 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_dbref_start;
	}

#line 640 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    
#line 1832 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == pe )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _JSON_dbref_trans_keys + _JSON_dbref_key_offsets[cs];
	_trans = _JSON_dbref_index_offsets[cs];

	_klen = _JSON_dbref_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*p) < *_mid )
				_upper = _mid - 1;
			else if ( (*p) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _JSON_dbref_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*p) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*p) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _JSON_dbref_indicies[_trans];
	cs = _JSON_dbref_trans_targs[_trans];

	if ( _JSON_dbref_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _JSON_dbref_actions + _JSON_dbref_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 606 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        np = [self _parseStringWithPointer:p endPointer:pe result:&collectionName];
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
	case 1:
#line 612 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        NSString *string = nil;
        
        np = [self _parseStringWithPointer:p endPointer:pe result:&string];
        if (np == NULL) {
            p--;
            {p++; goto _out; }
        } else {
            if ([MODObjectId isStringValid:string]) {
                documentId = MOD_AUTORELEASE([[MODObjectId alloc] initWithString:string]);
            }
            {p = (( np))-1;}
        }
    }
	break;
	case 2:
#line 628 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{ p--; {p++; goto _out; } }
	break;
#line 1936 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

#line 641 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"

    if (cs >= JSON_dbref_first_final && collectionName && documentId) {
        *result = MOD_AUTORELEASE([[MODDBPointer alloc] initWithCollectionName:collectionName objectId:documentId]);
        return p + 1;
    } else {
        *result = nil;
        return NULL;
    }
}


#line 1961 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
static const char _JSON_scopefunction_actions[] = {
	0, 1, 0, 1, 1, 1, 2
};

static const char _JSON_scopefunction_key_offsets[] = {
	0, 0, 1, 2, 3, 4, 5, 6, 
	7, 8, 9, 10, 11, 12, 13, 18, 
	24, 29, 34, 39
};

static const char _JSON_scopefunction_trans_keys[] = {
	83, 99, 111, 112, 101, 70, 117, 110, 
	99, 116, 105, 111, 110, 13, 32, 40, 
	9, 10, 13, 32, 34, 39, 9, 10, 
	13, 32, 44, 9, 10, 13, 32, 123, 
	9, 10, 13, 32, 41, 9, 10, 0
};

static const char _JSON_scopefunction_single_lengths[] = {
	0, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 3, 4, 
	3, 3, 3, 0
};

static const char _JSON_scopefunction_range_lengths[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 1, 1, 
	1, 1, 1, 0
};

static const char _JSON_scopefunction_index_offsets[] = {
	0, 0, 2, 4, 6, 8, 10, 12, 
	14, 16, 18, 20, 22, 24, 26, 31, 
	37, 42, 47, 52
};

static const char _JSON_scopefunction_indicies[] = {
	0, 1, 2, 1, 3, 1, 4, 1, 
	5, 1, 6, 1, 7, 1, 8, 1, 
	9, 1, 10, 1, 11, 1, 12, 1, 
	13, 1, 13, 13, 14, 13, 1, 14, 
	14, 15, 15, 14, 1, 16, 16, 17, 
	16, 1, 17, 17, 18, 17, 1, 19, 
	19, 20, 19, 1, 1, 0
};

static const char _JSON_scopefunction_trans_targs[] = {
	2, 0, 3, 4, 5, 6, 7, 8, 
	9, 10, 11, 12, 13, 14, 15, 16, 
	16, 17, 18, 18, 19
};

static const char _JSON_scopefunction_trans_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 1, 
	0, 0, 3, 0, 5
};

static const int JSON_scopefunction_start = 1;
static const int JSON_scopefunction_first_final = 19;
static const int JSON_scopefunction_error = 0;

static const int JSON_scopefunction_en_main = 1;


#line 677 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"


- (const char *)_parseScopeFunctionWithPointer:(const char *)p endPointer:(const char *)pe result:(MODScopeFunction **)result
{
    NSString *codeStringValue = nil;
    MODSortedDictionary *scopeValue = nil;
    int cs = 0;

    
#line 2037 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_scopefunction_start;
	}

#line 686 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    
#line 2044 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == pe )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _JSON_scopefunction_trans_keys + _JSON_scopefunction_key_offsets[cs];
	_trans = _JSON_scopefunction_index_offsets[cs];

	_klen = _JSON_scopefunction_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*p) < *_mid )
				_upper = _mid - 1;
			else if ( (*p) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _JSON_scopefunction_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*p) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*p) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _JSON_scopefunction_indicies[_trans];
	cs = _JSON_scopefunction_trans_targs[_trans];

	if ( _JSON_scopefunction_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _JSON_scopefunction_actions + _JSON_scopefunction_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 657 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        np = [self _parseStringWithPointer:p endPointer:pe result:&codeStringValue];
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
	case 1:
#line 663 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        
        np = [self _parseObjectWithPointer:p endPointer:pe result:&scopeValue];
        if (np == NULL) {
            p--; {p++; goto _out; }
        } else {
            {p = (( np))-1;}
        }
    }
	break;
	case 2:
#line 674 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{ p--; {p++; goto _out; } }
	break;
#line 2143 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

#line 687 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"

    if (cs >= JSON_scopefunction_first_final && codeStringValue) {
        *result = MOD_AUTORELEASE([[MODScopeFunction alloc] initWithFunction:codeStringValue scope:scopeValue]);
        return p + 1;
    } else {
        *result = nil;
        return NULL;
    }
}


#line 2168 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
static const char _JSON_object_id_actions[] = {
	0, 1, 0, 1, 1
};

static const char _JSON_object_id_key_offsets[] = {
	0, 0, 1, 2, 3, 4, 5, 6, 
	7, 8, 13, 19, 24
};

static const char _JSON_object_id_trans_keys[] = {
	79, 98, 106, 101, 99, 116, 73, 100, 
	13, 32, 40, 9, 10, 13, 32, 34, 
	39, 9, 10, 13, 32, 41, 9, 10, 
	0
};

static const char _JSON_object_id_single_lengths[] = {
	0, 1, 1, 1, 1, 1, 1, 1, 
	1, 3, 4, 3, 0
};

static const char _JSON_object_id_range_lengths[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 1, 1, 1, 0
};

static const char _JSON_object_id_index_offsets[] = {
	0, 0, 2, 4, 6, 8, 10, 12, 
	14, 16, 21, 27, 32
};

static const char _JSON_object_id_indicies[] = {
	0, 1, 2, 1, 3, 1, 4, 1, 
	5, 1, 6, 1, 7, 1, 8, 1, 
	8, 8, 9, 8, 1, 9, 9, 10, 
	10, 9, 1, 11, 11, 12, 11, 1, 
	1, 0
};

static const char _JSON_object_id_trans_targs[] = {
	2, 0, 3, 4, 5, 6, 7, 8, 
	9, 10, 11, 11, 12
};

static const char _JSON_object_id_trans_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 1, 0, 3
};

static const int JSON_object_id_start = 1;
static const int JSON_object_id_first_final = 12;
static const int JSON_object_id_error = 0;

static const int JSON_object_id_en_main = 1;


#line 712 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"


- (const char *)_parseObjectIdWithPointer:(const char *)p endPointer:(const char *)pe result:(MODObjectId **)result
{
    NSString *idStringValue = nil;
    int cs = 0;

    
#line 2234 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_object_id_start;
	}

#line 720 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    
#line 2241 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == pe )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _JSON_object_id_trans_keys + _JSON_object_id_key_offsets[cs];
	_trans = _JSON_object_id_index_offsets[cs];

	_klen = _JSON_object_id_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*p) < *_mid )
				_upper = _mid - 1;
			else if ( (*p) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _JSON_object_id_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*p) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*p) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _JSON_object_id_indicies[_trans];
	cs = _JSON_object_id_trans_targs[_trans];

	if ( _JSON_object_id_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _JSON_object_id_actions + _JSON_object_id_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 703 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        np = [self _parseStringWithPointer:p endPointer:pe result:&idStringValue];
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
	case 1:
#line 709 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{ p--; {p++; goto _out; } }
	break;
#line 2327 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

#line 721 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"

    if (cs >= JSON_object_id_first_final && [MODObjectId isStringValid:idStringValue]) {
        *result = MOD_AUTORELEASE([[MODObjectId alloc] initWithString:idStringValue]);
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
        
        buffer = [[NSString alloc] initWithBytes:(void *)bookmark length:cursor - bookmark encoding:NSUTF8StringEncoding];
        cursor++;
        
        bookmark = cursor;
        while (cursor < stringEnd && strchr("imsx", *cursor) != NULL) {
            cursor++;
        }
        options = [[NSString alloc] initWithBytes:(void *)bookmark length:cursor - bookmark encoding:NSUTF8StringEncoding];
        
        *result = MOD_AUTORELEASE([[MODRegex alloc] initWithPattern:buffer options:options]);
        MOD_RELEASE(buffer);
        MOD_RELEASE(options);
    } else {
        [self _makeErrorWithMessage:@"cannot find end of regex" atPosition:cursor];
        cursor = NULL;
    }
    return cursor;
}


#line 2390 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
static const char _JSON_numberlong_actions[] = {
	0, 1, 0, 1, 1
};

static const char _JSON_numberlong_key_offsets[] = {
	0, 0, 1, 2, 3, 4, 5, 6, 
	7, 8, 9, 10, 15, 22, 27
};

static const char _JSON_numberlong_trans_keys[] = {
	78, 117, 109, 98, 101, 114, 76, 111, 
	110, 103, 13, 32, 40, 9, 10, 13, 
	32, 45, 9, 10, 48, 57, 13, 32, 
	41, 9, 10, 0
};

static const char _JSON_numberlong_single_lengths[] = {
	0, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 3, 3, 3, 0
};

static const char _JSON_numberlong_range_lengths[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 1, 2, 1, 0
};

static const char _JSON_numberlong_index_offsets[] = {
	0, 0, 2, 4, 6, 8, 10, 12, 
	14, 16, 18, 20, 25, 31, 36
};

static const char _JSON_numberlong_indicies[] = {
	0, 1, 2, 1, 3, 1, 4, 1, 
	5, 1, 6, 1, 7, 1, 8, 1, 
	9, 1, 10, 1, 10, 10, 11, 10, 
	1, 11, 11, 12, 11, 12, 1, 13, 
	13, 14, 13, 1, 1, 0
};

static const char _JSON_numberlong_trans_targs[] = {
	2, 0, 3, 4, 5, 6, 7, 8, 
	9, 10, 11, 12, 13, 13, 14
};

static const char _JSON_numberlong_trans_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 1, 0, 3
};

static const int JSON_numberlong_start = 1;
static const int JSON_numberlong_first_final = 14;
static const int JSON_numberlong_error = 0;

static const int JSON_numberlong_en_main = 1;


#line 789 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"


- (const char *)_parseNumberLongWithPointer:(const char *)p endPointer:(const char *)pe result:(NSNumber **)result
{
    NSNumber *numberValue = nil;
    int cs = 0;
    
    
#line 2456 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_numberlong_start;
	}

#line 797 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    
#line 2463 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == pe )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _JSON_numberlong_trans_keys + _JSON_numberlong_key_offsets[cs];
	_trans = _JSON_numberlong_index_offsets[cs];

	_klen = _JSON_numberlong_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*p) < *_mid )
				_upper = _mid - 1;
			else if ( (*p) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _JSON_numberlong_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*p) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*p) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _JSON_numberlong_indicies[_trans];
	cs = _JSON_numberlong_trans_targs[_trans];

	if ( _JSON_numberlong_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _JSON_numberlong_actions + _JSON_numberlong_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 775 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        np = [self _parseIntegerWithPointer:p endPointer:pe result:&numberValue];
        if (strcmp(numberValue.objCType, @encode(long long)) != 0) {
            numberValue = [NSNumber numberWithLongLong:numberValue.longLongValue];
        }
        np--; // WHY???
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
	case 1:
#line 785 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{ p--; {p++; goto _out; } }
	break;
#line 2553 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

#line 798 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    
    if (cs >= JSON_numberlong_first_final && numberValue) {
        *result = numberValue;
        return p + 1; // why + 1 ???
    } else {
        *result = nil;
        return NULL;
    }
}


#line 2578 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
static const char _JSON_timestamp_actions[] = {
	0, 1, 0, 1, 1, 1, 2
};

static const char _JSON_timestamp_key_offsets[] = {
	0, 0, 1, 2, 3, 4, 5, 6, 
	7, 8, 9, 14, 21, 26, 33, 38
};

static const char _JSON_timestamp_trans_keys[] = {
	84, 105, 109, 101, 115, 116, 97, 109, 
	112, 13, 32, 40, 9, 10, 13, 32, 
	45, 9, 10, 48, 57, 13, 32, 44, 
	9, 10, 13, 32, 45, 9, 10, 48, 
	57, 13, 32, 41, 9, 10, 0
};

static const char _JSON_timestamp_single_lengths[] = {
	0, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 3, 3, 3, 3, 3, 0
};

static const char _JSON_timestamp_range_lengths[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 1, 2, 1, 2, 1, 0
};

static const char _JSON_timestamp_index_offsets[] = {
	0, 0, 2, 4, 6, 8, 10, 12, 
	14, 16, 18, 23, 29, 34, 40, 45
};

static const char _JSON_timestamp_indicies[] = {
	0, 1, 2, 1, 3, 1, 4, 1, 
	5, 1, 6, 1, 7, 1, 8, 1, 
	9, 1, 9, 9, 10, 9, 1, 10, 
	10, 11, 10, 11, 1, 12, 12, 13, 
	12, 1, 13, 13, 14, 13, 14, 1, 
	15, 15, 16, 15, 1, 1, 0
};

static const char _JSON_timestamp_trans_targs[] = {
	2, 0, 3, 4, 5, 6, 7, 8, 
	9, 10, 11, 12, 12, 13, 14, 14, 
	15
};

static const char _JSON_timestamp_trans_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 1, 0, 0, 3, 0, 
	5
};

static const int JSON_timestamp_start = 1;
static const int JSON_timestamp_first_final = 15;
static const int JSON_timestamp_error = 0;

static const int JSON_timestamp_en_main = 1;


#line 830 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"


- (const char *)_parseTimestampWithPointer:(const char *)p endPointer:(const char *)pe result:(MODTimestamp **)result
{
    NSNumber *timeNumber = nil;
    NSNumber *incrementNumber = nil;
    int cs = 0;
    
    
#line 2649 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_timestamp_start;
	}

#line 839 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    
#line 2656 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == pe )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _JSON_timestamp_trans_keys + _JSON_timestamp_key_offsets[cs];
	_trans = _JSON_timestamp_index_offsets[cs];

	_klen = _JSON_timestamp_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*p) < *_mid )
				_upper = _mid - 1;
			else if ( (*p) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _JSON_timestamp_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*p) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*p) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _JSON_timestamp_indicies[_trans];
	cs = _JSON_timestamp_trans_targs[_trans];

	if ( _JSON_timestamp_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _JSON_timestamp_actions + _JSON_timestamp_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 814 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        np = [self _parseIntegerWithPointer:p endPointer:pe result:&timeNumber];
        np--; // WHY???
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
	case 1:
#line 821 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        np = [self _parseIntegerWithPointer:p endPointer:pe result:&incrementNumber];
        if (np == NULL) { p--; {p++; goto _out; } } else { np--; {p = (( np))-1;} }
    }
	break;
	case 2:
#line 827 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{ p--; {p++; goto _out; } }
	break;
#line 2751 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

#line 840 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    
    if (cs >= JSON_timestamp_first_final && timeNumber && incrementNumber) {
        *result = MOD_AUTORELEASE([[MODTimestamp alloc] initWithTValue:timeNumber.intValue iValue:incrementNumber.intValue]);
        return p + 1; // why + 1 ???
    } else {
        *result = nil;
        return NULL;
    }
}


#line 2776 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
static const char _JSON_symbol_actions[] = {
	0, 1, 0, 1, 1
};

static const char _JSON_symbol_key_offsets[] = {
	0, 0, 1, 2, 3, 4, 5, 6, 
	11, 17, 22
};

static const char _JSON_symbol_trans_keys[] = {
	83, 121, 109, 98, 111, 108, 13, 32, 
	40, 9, 10, 13, 32, 34, 39, 9, 
	10, 13, 32, 41, 9, 10, 0
};

static const char _JSON_symbol_single_lengths[] = {
	0, 1, 1, 1, 1, 1, 1, 3, 
	4, 3, 0
};

static const char _JSON_symbol_range_lengths[] = {
	0, 0, 0, 0, 0, 0, 0, 1, 
	1, 1, 0
};

static const char _JSON_symbol_index_offsets[] = {
	0, 0, 2, 4, 6, 8, 10, 12, 
	17, 23, 28
};

static const char _JSON_symbol_indicies[] = {
	0, 1, 2, 1, 3, 1, 4, 1, 
	5, 1, 6, 1, 6, 6, 7, 6, 
	1, 7, 7, 8, 8, 7, 1, 9, 
	9, 10, 9, 1, 1, 0
};

static const char _JSON_symbol_trans_targs[] = {
	2, 0, 3, 4, 5, 6, 7, 8, 
	9, 9, 10
};

static const char _JSON_symbol_trans_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	1, 0, 3
};

static const int JSON_symbol_start = 1;
static const int JSON_symbol_first_final = 10;
static const int JSON_symbol_error = 0;

static const int JSON_symbol_en_main = 1;


#line 865 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"


- (const char *)_parseSymbolWithPointer:(const char *)p endPointer:(const char *)pe result:(MODSymbol **)result
{
    NSString *symbol = nil;
    int cs = 0;
    
    
#line 2840 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_symbol_start;
	}

#line 873 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    
#line 2847 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == pe )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _JSON_symbol_trans_keys + _JSON_symbol_key_offsets[cs];
	_trans = _JSON_symbol_index_offsets[cs];

	_klen = _JSON_symbol_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*p) < *_mid )
				_upper = _mid - 1;
			else if ( (*p) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _JSON_symbol_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*p) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*p) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _JSON_symbol_indicies[_trans];
	cs = _JSON_symbol_trans_targs[_trans];

	if ( _JSON_symbol_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _JSON_symbol_actions + _JSON_symbol_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 856 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        np = [self _parseStringWithPointer:p endPointer:pe result:&symbol];
        if (np == NULL) { p--; {p++; goto _out; } } else { {p = (( np))-1;} }
    }
	break;
	case 1:
#line 862 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{ p--; {p++; goto _out; } }
	break;
#line 2933 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

#line 874 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    
    if (cs >= JSON_symbol_first_final && symbol) {
        *result = MOD_AUTORELEASE([[MODSymbol alloc] initWithValue:symbol]);
        return p + 1; // why + 1 ???
    } else {
        *result = nil;
        return NULL;
    }
}

- (const char *)_parseWordWithPointer:(const char *)string endPointer:(const char *)stringEnd result:(NSString **)result
{
    NSString *buffer;
    const char *cursor;
    NSCharacterSet *wordCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890_$#"];
    NSCharacterSet *numberCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"1234567890"];
    BOOL digitOnly = [numberCharacterSet characterIsMember:string[0]];
    
    cursor = string;
    while (cursor < stringEnd && ((digitOnly && [numberCharacterSet characterIsMember:cursor[0]]) || (!digitOnly && [wordCharacterSet characterIsMember:cursor[0]]))) {
        cursor++;
    }
    if (cursor == string) {
        cursor = NULL;
        *result = NULL;
    } else {
        buffer = [[NSString alloc] initWithBytes:(void *)string length:cursor - string encoding:NSUTF8StringEncoding];
        *result = buffer;
        MOD_AUTORELEASE2(buffer);
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
                buffer = [[NSString alloc] initWithBytes:(void *)bookmark length:cursor - bookmark encoding:NSUTF8StringEncoding];
                [mutableResult appendString:buffer];
                MOD_RELEASE(buffer);
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
            buffer = [[NSString alloc] initWithBytes:(void *)unescape length:unescapeLength encoding:NSUTF8StringEncoding];
            [mutableResult appendString:buffer];
            MOD_RELEASE(buffer);
            bookmark = ++cursor;
        } else {
            cursor++;
        }
    }
    if (*cursor == quoteString) {
        buffer = [[NSString alloc] initWithBytes:(void *)bookmark length:cursor - bookmark encoding:NSUTF8StringEncoding];
        [mutableResult appendString:buffer];
        MOD_RELEASE(buffer);
        *result = MOD_AUTORELEASE(mutableResult);
        cursor++;
    } else {
        cursor = NULL;
        [self _makeErrorWithMessage:@"cannot find end of string" atPosition:cursor];
    }
    return cursor;
}


#line 3054 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
static const char _JSON_array_actions[] = {
	0, 1, 0, 1, 1
};

static const char _JSON_array_key_offsets[] = {
	0, 0, 1, 24, 30, 52
};

static const char _JSON_array_trans_keys[] = {
	91, 13, 32, 34, 39, 45, 66, 68, 
	70, 91, 93, 102, 110, 123, 9, 10, 
	47, 57, 77, 79, 83, 84, 116, 117, 
	13, 32, 44, 93, 9, 10, 13, 32, 
	34, 39, 45, 66, 68, 70, 91, 102, 
	110, 123, 9, 10, 47, 57, 77, 79, 
	83, 84, 116, 117, 0
};

static const char _JSON_array_single_lengths[] = {
	0, 1, 13, 4, 12, 0
};

static const char _JSON_array_range_lengths[] = {
	0, 0, 5, 1, 5, 0
};

static const char _JSON_array_index_offsets[] = {
	0, 0, 2, 21, 27, 45
};

static const char _JSON_array_indicies[] = {
	0, 1, 0, 0, 2, 2, 2, 2, 
	2, 2, 2, 3, 2, 2, 2, 0, 
	2, 2, 2, 2, 1, 4, 4, 5, 
	3, 4, 1, 5, 5, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 5, 
	2, 2, 2, 2, 1, 1, 0
};

static const char _JSON_array_trans_targs[] = {
	2, 0, 3, 5, 3, 4
};

static const char _JSON_array_trans_actions[] = {
	0, 0, 1, 3, 0, 0
};

static const int JSON_array_start = 1;
static const int JSON_array_first_final = 5;
static const int JSON_array_error = 0;

static const int JSON_array_en_main = 1;


#line 1005 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"


- (const char *)_parseArrayWithPointer:(const char *)p endPointer:(const char *)pe result:(NSMutableArray **)result
{
    int cs = 0;
    
    if (_maxNesting && _currentNesting > _maxNesting) {
        [self _makeErrorWithMessage:[NSString stringWithFormat:@"nesting of %d is too deep", _currentNesting] atPosition:p];
    }
    *result = MOD_AUTORELEASE([[NSMutableArray alloc] init]);
    
    
#line 3122 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_array_start;
	}

#line 1017 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    
#line 3129 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == pe )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _JSON_array_trans_keys + _JSON_array_key_offsets[cs];
	_trans = _JSON_array_index_offsets[cs];

	_klen = _JSON_array_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*p) < *_mid )
				_upper = _mid - 1;
			else if ( (*p) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _JSON_array_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*p) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*p) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	_trans = _JSON_array_indicies[_trans];
	cs = _JSON_array_trans_targs[_trans];

	if ( _JSON_array_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _JSON_array_actions + _JSON_array_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 986 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        id value;
        const char *np = [self _parseValueWithPointer:p endPointer:pe result:&value];
        if (np == NULL) {
            p--; {p++; goto _out; }
        } else {
            [*result addObject:value];
            {p = (( np))-1;}
        }
    }
	break;
	case 1:
#line 997 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{ p--; {p++; goto _out; } }
	break;
#line 3220 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

#line 1018 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    
    if(cs >= JSON_array_first_final) {
        return p + 1;
    } else {
        [self _makeErrorWithMessage:@"Unexpected character" atPosition:p];
        return NULL;
    }
}


#line 3244 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
static const char _JSON_actions[] = {
	0, 1, 0, 1, 1
};

static const char _JSON_key_offsets[] = {
	0, 0, 6
};

static const char _JSON_trans_keys[] = {
	13, 32, 91, 123, 9, 10, 13, 32, 
	9, 10, 0
};

static const char _JSON_single_lengths[] = {
	0, 4, 2
};

static const char _JSON_range_lengths[] = {
	0, 1, 1
};

static const char _JSON_index_offsets[] = {
	0, 0, 6
};

static const char _JSON_trans_targs[] = {
	1, 1, 2, 2, 1, 0, 2, 2, 
	2, 0, 0
};

static const char _JSON_trans_actions[] = {
	0, 0, 3, 1, 0, 0, 0, 0, 
	0, 0, 0
};

static const int JSON_start = 1;
static const int JSON_first_final = 2;
static const int JSON_error = 0;

static const int JSON_en_main = 1;


#line 1052 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"


- (id)parseJson:(NSString *)source withError:(NSError **)error
{
    const char *p, *pe;
    id result = nil;
    int cs = 0;
    
    self.error = nil;
    _cStringBuffer = [source UTF8String];
    
#line 3299 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_start;
	}

#line 1063 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    p = _cStringBuffer;
    pe = p + strlen(p);
    
#line 3308 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
	{
	int _klen;
	unsigned int _trans;
	const char *_acts;
	unsigned int _nacts;
	const char *_keys;

	if ( p == pe )
		goto _test_eof;
	if ( cs == 0 )
		goto _out;
_resume:
	_keys = _JSON_trans_keys + _JSON_key_offsets[cs];
	_trans = _JSON_index_offsets[cs];

	_klen = _JSON_single_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + _klen - 1;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + ((_upper-_lower) >> 1);
			if ( (*p) < *_mid )
				_upper = _mid - 1;
			else if ( (*p) > *_mid )
				_lower = _mid + 1;
			else {
				_trans += (unsigned int)(_mid - _keys);
				goto _match;
			}
		}
		_keys += _klen;
		_trans += _klen;
	}

	_klen = _JSON_range_lengths[cs];
	if ( _klen > 0 ) {
		const char *_lower = _keys;
		const char *_mid;
		const char *_upper = _keys + (_klen<<1) - 2;
		while (1) {
			if ( _upper < _lower )
				break;

			_mid = _lower + (((_upper-_lower) >> 1) & ~1);
			if ( (*p) < _mid[0] )
				_upper = _mid - 2;
			else if ( (*p) > _mid[1] )
				_lower = _mid + 2;
			else {
				_trans += (unsigned int)((_mid - _keys)>>1);
				goto _match;
			}
		}
		_trans += _klen;
	}

_match:
	cs = _JSON_trans_targs[_trans];

	if ( _JSON_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _JSON_actions + _JSON_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 1034 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        _currentNesting = 1;
        np = [self _parseObjectWithPointer:p endPointer:pe result:&result];
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
	case 1:
#line 1041 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        _currentNesting = 1;
        np = [self _parseArrayWithPointer:p endPointer:pe result:&result];
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
#line 3399 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.m"
		}
	}

_again:
	if ( cs == 0 )
		goto _out;
	if ( ++p != pe )
		goto _resume;
	_test_eof: {}
	_out: {}
	}

#line 1066 "/Users/jerome/Sources/MongoHub-Mac/Libraries/MongoObjCDriver/Sources/MODRagelJsonParser.rl"
    
    if (cs < JSON_first_final || p != pe) {
        result = nil;
        if (!self.error) {
            [self _makeErrorWithMessage:@"unexpected token" atPosition:p];
        }
    }
    if (error) {
        *error = self.error;
    }
    return result;
}

@end
