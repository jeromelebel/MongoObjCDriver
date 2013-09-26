
#line 1 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
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


#line 80 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"



#line 62 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
static const char _JSON_value_actions[] = {
	0, 1, 0, 1, 1, 1, 2, 1, 
	3, 1, 4, 1, 5, 1, 6, 1, 
	7, 1, 8, 1, 9, 1, 10
};

static const char _JSON_value_key_offsets[] = {
	0, 0, 11, 13, 14, 15, 16, 17, 
	18, 19, 20, 21, 22, 23, 24, 25, 
	26, 27, 28, 29, 30, 31, 32, 33, 
	34, 35, 36, 37, 38, 39
};

static const char _JSON_value_trans_keys[] = {
	34, 45, 77, 91, 102, 110, 116, 117, 
	123, 48, 57, 97, 105, 120, 75, 101, 
	121, 110, 75, 101, 121, 97, 108, 115, 
	101, 117, 108, 108, 114, 117, 101, 110, 
	100, 101, 102, 105, 110, 101, 100, 0
};

static const char _JSON_value_single_lengths[] = {
	0, 9, 2, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 0
};

static const char _JSON_value_range_lengths[] = {
	0, 1, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0
};

static const char _JSON_value_index_offsets[] = {
	0, 0, 11, 14, 16, 18, 20, 22, 
	24, 26, 28, 30, 32, 34, 36, 38, 
	40, 42, 44, 46, 48, 50, 52, 54, 
	56, 58, 60, 62, 64, 66
};

static const char _JSON_value_trans_targs[] = {
	29, 29, 2, 29, 11, 15, 18, 21, 
	29, 29, 0, 3, 7, 0, 4, 0, 
	5, 0, 6, 0, 29, 0, 8, 0, 
	9, 0, 10, 0, 29, 0, 12, 0, 
	13, 0, 14, 0, 29, 0, 16, 0, 
	17, 0, 29, 0, 19, 0, 20, 0, 
	29, 0, 22, 0, 23, 0, 24, 0, 
	25, 0, 26, 0, 27, 0, 28, 0, 
	29, 0, 0, 0
};

static const char _JSON_value_trans_actions[] = {
	13, 15, 0, 17, 0, 0, 0, 0, 
	19, 15, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 9, 0, 0, 0, 
	0, 0, 0, 0, 7, 0, 0, 0, 
	0, 0, 0, 0, 3, 0, 0, 0, 
	0, 0, 1, 0, 0, 0, 0, 0, 
	5, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	11, 0, 0, 0
};

static const char _JSON_value_from_state_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 21
};

static const int JSON_value_start = 1;
static const int JSON_value_first_final = 29;
static const int JSON_value_error = 0;

static const int JSON_value_en_main = 1;


#line 154 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"


- (const char *)_parseValueWithPointer:(const char *)p endPointer:(const char *)pe result:(id *)result
{
    int cs = 0;

    
#line 151 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_value_start;
	}

#line 161 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
    
#line 158 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
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
	case 10:
#line 140 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{ p--; {p++; goto _out; } }
	break;
#line 179 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
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
#line 88 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{
        *result = [NSNull null];
    }
	break;
	case 1:
#line 91 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{
        *result = [NSNumber numberWithBool:NO];
    }
	break;
	case 2:
#line 94 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{
        *result = [NSNumber numberWithBool:YES];
    }
	break;
	case 3:
#line 98 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{
        *result = [[[MODMinKey alloc] init] autorelease];
    }
	break;
	case 4:
#line 102 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{
        *result = [[[MODMaxKey alloc] init] autorelease];
    }
	break;
	case 5:
#line 106 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{
        *result = [[[MODUndefined alloc] init] autorelease];
    }
	break;
	case 6:
#line 110 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{
        const char *np = [self _parseStringWithPointer:p endPointer:pe result:result];
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
	case 7:
#line 115 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        np = [self _parseFloatWithPointer:p endPointer:pe result:result];
        if (np != NULL) {p = (( np))-1;}
        np = [self _parseIntegerWithPointer:p endPointer:pe result:result];
        if (np != NULL) {p = (( np))-1;}
        p--; {p++; goto _out; }
    }
	break;
	case 8:
#line 124 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        _currentNesting++;
        np = [self _parseArrayWithPointer:p endPointer:pe result:result];
        _currentNesting--;
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
	case 9:
#line 132 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        _currentNesting++;
        np = [self _parseObjectWithPointer:p endPointer:pe result:result];
        _currentNesting--;
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
#line 317 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
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

#line 162 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"

    if (cs >= JSON_value_first_final) {
        return p;
    } else {
        return NULL;
    }
}


#line 340 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
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


#line 178 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"


- (const char *)_parseIntegerWithPointer:(const char *)p endPointer:(const char *)pe result:(NSNumber **)result
{
    int cs = 0;

    
#line 394 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_integer_start;
	}

#line 185 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
    _memo = p;
    
#line 402 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
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
#line 175 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{ p--; {p++; goto _out; } }
	break;
#line 480 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
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

#line 187 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"

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


#line 508 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
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


#line 212 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"


- (const char *)_parseFloatWithPointer:(const char *)p endPointer:(const char *)pe result:(NSNumber **)result
{
    int cs = 0;

    
#line 574 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_float_start;
	}

#line 219 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
    _memo = p;
    
#line 582 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
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
#line 206 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{ p--; {p++; goto _out; } }
	break;
#line 660 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
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

#line 221 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"

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


#line 750 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
static const char _JSON_object_actions[] = {
	0, 1, 0, 1, 1, 1, 2
};

static const char _JSON_object_key_offsets[] = {
	0, 0, 1, 8, 14, 16, 17, 19, 
	20, 38, 45, 51, 53, 54, 56, 57, 
	59, 60, 62, 63, 65, 66, 68, 69, 
	71, 72, 74, 75
};

static const char _JSON_object_trans_keys[] = {
	123, 13, 32, 34, 47, 125, 9, 10, 
	13, 32, 47, 58, 9, 10, 42, 47, 
	42, 42, 47, 10, 13, 32, 34, 45, 
	47, 73, 91, 102, 110, 123, 9, 10, 
	48, 57, 77, 78, 116, 117, 13, 32, 
	44, 47, 125, 9, 10, 13, 32, 34, 
	47, 9, 10, 42, 47, 42, 42, 47, 
	10, 42, 47, 42, 42, 47, 10, 42, 
	47, 42, 42, 47, 10, 42, 47, 42, 
	42, 47, 10, 0
};

static const char _JSON_object_single_lengths[] = {
	0, 1, 5, 4, 2, 1, 2, 1, 
	10, 5, 4, 2, 1, 2, 1, 2, 
	1, 2, 1, 2, 1, 2, 1, 2, 
	1, 2, 1, 0
};

static const char _JSON_object_range_lengths[] = {
	0, 0, 1, 1, 0, 0, 0, 0, 
	4, 1, 1, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0
};

static const char _JSON_object_index_offsets[] = {
	0, 0, 2, 9, 15, 18, 20, 23, 
	25, 40, 47, 53, 56, 58, 61, 63, 
	66, 68, 71, 73, 76, 78, 81, 83, 
	86, 88, 91, 93
};

static const char _JSON_object_indicies[] = {
	0, 1, 0, 0, 2, 3, 4, 0, 
	1, 5, 5, 6, 7, 5, 1, 8, 
	9, 1, 10, 8, 10, 5, 8, 5, 
	9, 7, 7, 11, 11, 12, 11, 11, 
	11, 11, 11, 7, 11, 11, 11, 1, 
	13, 13, 14, 15, 4, 13, 1, 14, 
	14, 2, 16, 14, 1, 17, 18, 1, 
	19, 17, 19, 14, 17, 14, 18, 20, 
	21, 1, 22, 20, 22, 13, 20, 13, 
	21, 23, 24, 1, 25, 23, 25, 7, 
	23, 7, 24, 26, 27, 1, 28, 26, 
	28, 0, 26, 0, 27, 1, 0
};

static const char _JSON_object_trans_targs[] = {
	2, 0, 3, 23, 27, 3, 4, 8, 
	5, 7, 6, 9, 19, 9, 10, 15, 
	11, 12, 14, 13, 16, 18, 17, 20, 
	22, 21, 24, 26, 25
};

static const char _JSON_object_trans_actions[] = {
	0, 0, 3, 0, 5, 0, 0, 0, 
	0, 0, 0, 1, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0
};

static const int JSON_object_start = 1;
static const int JSON_object_first_final = 27;
static const int JSON_object_error = 0;

static const int JSON_object_en_main = 1;


#line 331 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"


- (const char *)_parseObjectWithPointer:(const char *)p endPointer:(const char *)pe result:(MODSortedMutableDictionary **)result
{
    int cs = 0;
    NSMutableString *lastName;
    
    if (_maxNesting && _currentNesting > _maxNesting) {
        [NSException raise:@"NestingError" format:@"nesting of %d is too deep", _currentNesting];
    }
    
    *result = [[MODSortedMutableDictionary alloc] init];
    
    
#line 847 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_object_start;
	}

#line 345 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
    
#line 854 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
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
#line 302 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{
        id value = nil;
        const char *np = [self _parseValueWithPointer:p endPointer:pe result:&value];
        if (np == NULL) {
            p--; {p++; goto _out; }
        } else {
            [*result setObject:value forKey:lastName];
            {p = (( np))-1;}
        }
    }
	break;
	case 1:
#line 313 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        _parsingName = YES;
        np = [self _parseStringWithPointer:p endPointer:pe result:&lastName];
        _parsingName = NO;
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
	case 2:
#line 321 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{ p--; {p++; goto _out; } }
	break;
#line 955 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
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

#line 346 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
    
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


#line 989 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
static const char _JSON_string_actions[] = {
	0, 2, 0, 1
};

static const char _JSON_string_key_offsets[] = {
	0, 0, 1, 5, 8, 14, 20, 26, 
	32
};

static const char _JSON_string_trans_keys[] = {
	34, 34, 92, 0, 31, 117, 0, 31, 
	48, 57, 65, 70, 97, 102, 48, 57, 
	65, 70, 97, 102, 48, 57, 65, 70, 
	97, 102, 48, 57, 65, 70, 97, 102, 
	0
};

static const char _JSON_string_single_lengths[] = {
	0, 1, 2, 1, 0, 0, 0, 0, 
	0
};

static const char _JSON_string_range_lengths[] = {
	0, 0, 1, 1, 3, 3, 3, 3, 
	0
};

static const char _JSON_string_index_offsets[] = {
	0, 0, 2, 6, 9, 13, 17, 21, 
	25
};

static const char _JSON_string_indicies[] = {
	0, 1, 2, 3, 1, 0, 4, 1, 
	0, 5, 5, 5, 1, 6, 6, 6, 
	1, 7, 7, 7, 1, 0, 0, 0, 
	1, 1, 0
};

static const char _JSON_string_trans_targs[] = {
	2, 0, 8, 3, 4, 5, 6, 7
};

static const char _JSON_string_trans_actions[] = {
	0, 0, 1, 0, 0, 0, 0, 0
};

static const int JSON_string_start = 1;
static const int JSON_string_first_final = 8;
static const int JSON_string_error = 0;

static const int JSON_string_en_main = 1;


#line 384 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"


- (const char *)_parseStringWithPointer:(const char *)p endPointer:(const char *)pe result:(NSMutableString **)result
{
    int cs = 0;
   
    *result = [NSMutableString string];
    
#line 1053 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_string_start;
	}

#line 392 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
    _memo = p;
    
#line 1061 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
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
	_keys = _JSON_string_trans_keys + _JSON_string_key_offsets[cs];
	_trans = _JSON_string_index_offsets[cs];

	_klen = _JSON_string_single_lengths[cs];
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

	_klen = _JSON_string_range_lengths[cs];
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
	_trans = _JSON_string_indicies[_trans];
	cs = _JSON_string_trans_targs[_trans];

	if ( _JSON_string_trans_actions[_trans] == 0 )
		goto _again;

	_acts = _JSON_string_actions + _JSON_string_trans_actions[_trans];
	_nacts = (unsigned int) *_acts++;
	while ( _nacts-- > 0 )
	{
		switch ( *_acts++ )
		{
	case 0:
#line 371 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{
       *result = jsonStringUnescape(*result, _memo + 1, p);
       if (*result == nil) {
           p--;
           {p++; goto _out; }
       } else {
           {p = (( p + 1))-1;}
       }
   }
	break;
	case 1:
#line 381 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{ p--; {p++; goto _out; } }
	break;
#line 1151 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
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

#line 394 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
   
    if (cs >= JSON_string_first_final) {
        return p + 1;
    } else {
        *result = nil;
        return NULL;
    }
}


#line 1175 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
static const char _JSON_array_actions[] = {
	0, 1, 0, 1, 1
};

static const char _JSON_array_key_offsets[] = {
	0, 0, 1, 20, 27, 45, 47, 48, 
	50, 51, 53, 54, 56, 57, 59, 60, 
	62, 63
};

static const char _JSON_array_trans_keys[] = {
	91, 13, 32, 34, 45, 47, 73, 91, 
	93, 102, 110, 123, 9, 10, 48, 57, 
	77, 78, 116, 117, 13, 32, 44, 47, 
	93, 9, 10, 13, 32, 34, 45, 47, 
	73, 91, 102, 110, 123, 9, 10, 48, 
	57, 77, 78, 116, 117, 42, 47, 42, 
	42, 47, 10, 42, 47, 42, 42, 47, 
	10, 42, 47, 42, 42, 47, 10, 0
};

static const char _JSON_array_single_lengths[] = {
	0, 1, 11, 5, 10, 2, 1, 2, 
	1, 2, 1, 2, 1, 2, 1, 2, 
	1, 0
};

static const char _JSON_array_range_lengths[] = {
	0, 0, 4, 1, 4, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0
};

static const char _JSON_array_index_offsets[] = {
	0, 0, 2, 18, 25, 40, 43, 45, 
	48, 50, 53, 55, 58, 60, 63, 65, 
	68, 70
};

static const char _JSON_array_indicies[] = {
	0, 1, 0, 0, 2, 2, 3, 2, 
	2, 4, 2, 2, 2, 0, 2, 2, 
	2, 1, 5, 5, 6, 7, 4, 5, 
	1, 6, 6, 2, 2, 8, 2, 2, 
	2, 2, 2, 6, 2, 2, 2, 1, 
	9, 10, 1, 11, 9, 11, 6, 9, 
	6, 10, 12, 13, 1, 14, 12, 14, 
	5, 12, 5, 13, 15, 16, 1, 17, 
	15, 17, 0, 15, 0, 16, 1, 0
};

static const char _JSON_array_trans_targs[] = {
	2, 0, 3, 13, 17, 3, 4, 9, 
	5, 6, 8, 7, 10, 12, 11, 14, 
	16, 15
};

static const char _JSON_array_trans_actions[] = {
	0, 0, 1, 0, 3, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0
};

static const int JSON_array_start = 1;
static const int JSON_array_first_final = 17;
static const int JSON_array_error = 0;

static const int JSON_array_en_main = 1;


#line 428 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"


- (const char *)_parseArrayWithPointer:(const char *)p endPointer:(const char *)pe result:(NSMutableArray **)result
{
    int cs = 0;
    
    if (_maxNesting && _currentNesting > _maxNesting) {
        [NSException raise:@"NestingError" format:@"nesting of %d is too deep", _currentNesting];
    }
    *result = [[[NSMutableArray alloc] init] autorelease];
    
    
#line 1259 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_array_start;
	}

#line 440 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
    
#line 1266 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
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
#line 409 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
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
#line 420 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{ p--; {p++; goto _out; } }
	break;
#line 1357 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
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

#line 441 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
    
    if(cs >= JSON_array_first_final) {
        return p + 1;
    } else {
        [NSException raise:@"ParserError"format:@"%u: unexpected token at '%s'", __LINE__, p];
        return NULL;
    }
}


#line 1381 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
static const char _JSON_actions[] = {
	0, 1, 0, 1, 1
};

static const char _JSON_key_offsets[] = {
	0, 0, 7, 9, 10, 12, 13, 15, 
	16, 18, 19
};

static const char _JSON_trans_keys[] = {
	13, 32, 47, 91, 123, 9, 10, 42, 
	47, 42, 42, 47, 10, 42, 47, 42, 
	42, 47, 10, 13, 32, 47, 9, 10, 
	0
};

static const char _JSON_single_lengths[] = {
	0, 5, 2, 1, 2, 1, 2, 1, 
	2, 1, 3
};

static const char _JSON_range_lengths[] = {
	0, 1, 0, 0, 0, 0, 0, 0, 
	0, 0, 1
};

static const char _JSON_index_offsets[] = {
	0, 0, 7, 10, 12, 15, 17, 20, 
	22, 25, 27
};

static const char _JSON_indicies[] = {
	0, 0, 2, 3, 4, 0, 1, 5, 
	6, 1, 7, 5, 7, 0, 5, 0, 
	6, 8, 9, 1, 10, 8, 10, 11, 
	8, 11, 9, 11, 11, 12, 11, 1, 
	0
};

static const char _JSON_trans_targs[] = {
	1, 0, 2, 10, 10, 3, 5, 4, 
	7, 9, 8, 10, 6
};

static const char _JSON_trans_actions[] = {
	0, 0, 0, 3, 1, 0, 0, 0, 
	0, 0, 0, 0, 0
};

static const int JSON_start = 1;
static const int JSON_first_final = 10;
static const int JSON_error = 0;

static const int JSON_en_main = 1;


#line 475 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"


- (id)parseJson:(NSString *)source withError:(NSError **)error
{
    const char *p, *pe;
    id result = nil;
    int cs = 0;
    const char *cString = [source UTF8String];
    
    
#line 1449 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
	{
	cs = JSON_start;
	}

#line 485 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
    p = cString;
    pe = p + strlen(p);
    
#line 1458 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
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
	_trans = _JSON_indicies[_trans];
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
#line 457 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        _currentNesting = 1;
        np = [self _parseObjectWithPointer:p endPointer:pe result:&result];
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
	case 1:
#line 464 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
	{
        const char *np;
        _currentNesting = 1;
        np = [self _parseArrayWithPointer:p endPointer:pe result:&result];
        if (np == NULL) { p--; {p++; goto _out; } } else {p = (( np))-1;}
    }
	break;
#line 1550 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.m"
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

#line 488 "/Users/jerome/Sources/MongoHub-Mac/Libraries/mongo-objc-driver/Sources/MODRagelJsonParser.rl"
    
    if (cs >= JSON_first_final && p == pe) {
        *error = nil;
        return result;
    } else {
        if (!_error) {
            _error = [self _errorWithMessage:[NSString stringWithFormat:@"unexpected token at '%s'", p]];
        }
        return nil;
    }
}

@end
