//
//  MODSortedDictionary.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 05/12/2014.
//
//

#import "MongoObjCDriver-private.h"

@implementation MODSortedDictionary

@synthesize content = _content;
@synthesize sortedKeys = _sortedKeys;

+ (Class)contentDictionaryClass
{
    return NSDictionary.class;
}

+ (Class)keyArrayClass
{
    return NSArray.class;
}

+ (id)sortedDictionary
{
    return [[[self alloc] init] autorelease];
}

+ (id)sortedDictionaryWithObject:(id)object forKey:(id)key
{
    return [[[self alloc] initWithObjects:&object forKeys:&key count:1] autorelease];
}

+ (id)sortedDictionaryWithObjects:(const id [])objects forKeys:(const id [])keys count:(NSUInteger)cnt
{
    return [[[self alloc] initWithObjects:objects forKeys:keys count:cnt] autorelease];
}

static void getValuesAndKeys(id firstObject, va_list ap, NSMutableDictionary *values, NSMutableArray *keys)
{
    id object = firstObject;
    
    while (object) {
        id key;
        
        key = va_arg(ap, id);
        if (!values[key]) {
            [keys addObject:key];
        }
        [values setValue:object forKey:key];
        object = va_arg(ap, id);
    }
}

+ (id)sortedDictionaryWithObjectsAndKeys:(id)firstObject, ...
{
    va_list(ap);
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    NSMutableArray *keys = [NSMutableArray array];
    MODSortedDictionary *result;
    
    va_start(ap, firstObject);
    getValuesAndKeys(firstObject, ap, values, keys);
    result = [[[self alloc] initWithDictionary:values sortedKeys:keys] autorelease];
    va_end(ap);
    return result;
}

+ (id)sortedDictionaryWithDictionary:(NSDictionary *)dict
{
    return [[[self alloc] initWithDictionary:dict] autorelease];
}

+ (id)sortedDictionaryWithDictionary:(NSDictionary *)dict sortedKeys:(NSArray *)sortedKeys
{
    return [[[self alloc] initWithDictionary:dict sortedKeys:sortedKeys] autorelease];
}

+ (id)sortedDictionaryWithObjects:(NSArray *)objects forKeys:(NSArray *)keys
{
    return [[[self alloc] initWithObjects:objects forKeys:keys] autorelease];
}

- (instancetype)initWithObjects:(const id [])objects forKeys:(const id [])keys count:(NSUInteger)cnt
{
    if (self = [self init]) {
        self.content = [[self.class contentDictionaryClass] dictionaryWithObjects:objects forKeys:keys count:cnt];
        self.sortedKeys = [[self.class keyArrayClass] arrayWithObjects:keys count:cnt];
    }
    return self;
}

- (instancetype)initWithObjectsAndKeys:(id)firstObject, ...
{
    va_list(ap);
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    NSMutableArray *keys = [NSMutableArray array];
    
    va_start(ap, firstObject);
    self = [self initWithDictionary:values sortedKeys:keys];
    va_end(ap);
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)otherDictionary
{
    self = [self initWithDictionary:otherDictionary sortedKeys:otherDictionary.allKeys];
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)otherDictionary sortedKeys:(NSArray *)sortedKeys
{
    if (self = [self init]) {
        self.content = [[self.class contentDictionaryClass] dictionaryWithDictionary:otherDictionary];
        self.sortedKeys = [[self.class keyArrayClass] arrayWithArray:sortedKeys];
    }
    return self;
}

- (instancetype)initWithObjects:(NSArray *)objects forKeys:(NSArray *)keys
{
    if (self = [self init]) {
        self.content = [[self.class contentDictionaryClass] dictionaryWithObjects:objects forKeys:keys];
        self.sortedKeys = [[self.class keyArrayClass] arrayWithArray:self.content.allKeys];
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
    }
    return self;
}

- (void)dealloc
{
    self.content = nil;
    self.sortedKeys = nil;
    [super dealloc];
}

- (id)objectForKey:(id)aKey
{
    return [_content objectForKey:aKey];
}

- (NSArray *)allKeys
{
    return _sortedKeys;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[MODSortedDictionary class]]) {
        // the content and sortedKeys of MODSortedDictionary (non-mutable one) with no data are set to nil
        if (self.count == 0 && [object count] == 0) {
            return YES;
        } else if (self.count != [object count]) {
            return NO;
        } else {
            return [self.content isEqual:[object content]] && [self.sortedKeys isEqual:[object sortedKeys]];
        }
    }
    return NO;
}

- (NSEnumerator *)keyEnumerator
{
    return [_sortedKeys objectEnumerator];
}

- (NSUInteger)count
{
    return [_content count];
}

- (NSString *)description
{
    NSMutableDictionary *hack;
    NSString *result;
    
    hack = [[NSMutableDictionary alloc] init];
    if (self.content) {
        [hack addEntriesFromDictionary:self.content];
        [hack setObject:self.sortedKeys forKey:@"__sorted_keys__"];
    } else {
        [hack setObject:@[] forKey:@"__sorted_keys__"];
    }
    result = [[hack description] retain];
    [hack release];
    return [result autorelease];
}

- (id)tengenJsonEncodedObject
{
    id result = nil;
    
    if (self.count == 1 && [[self objectForKey:@"$date"] isKindOfClass:NSNumber.class]) {
        result = [[NSDate alloc] initWithTimeIntervalSince1970:[[self objectForKey:@"$date"] doubleValue] / 1000.0];
    } else if (self.count == 1 && [[self objectForKey:@"$oid"] isKindOfClass:NSString.class] && [[self objectForKey:@"$oid"] length] == 24) {
        result = [[MODObjectId alloc] initWithCString:[[self objectForKey:@"$oid"] cStringUsingEncoding:NSUTF8StringEncoding]];
    } else if (self.count == 1 && [[self objectForKey:@"$timestamp"] isKindOfClass:NSArray.class] && [[self objectForKey:@"$timestamp"] count] == 2) {
        result = [[MODTimestamp alloc] initWithTValue:[[[self objectForKey:@"$timestamp"] objectAtIndex:0] intValue] iValue:[[[self objectForKey:@"$timestamp"] objectAtIndex:1] intValue]];
    } else if (self.count == 2 && [[self objectForKey:@"$binary"] isKindOfClass:NSString.class] && [[self objectForKey:@"$type"] isKindOfClass:NSString.class]) {
        result = [[MODBinary alloc] initWithData:[[self objectForKey:@"$binary"] mod_dataFromBase64] binaryType:[[self objectForKey:@"$type"] intValue]];
    } else if (self.count == 2 && [[self objectForKey:@"$regex"] isKindOfClass:NSString.class] && [[self objectForKey:@"$options"] isKindOfClass:NSString.class]) {
        result = [[MODRegex alloc] initWithPattern:[self objectForKey:@"$regex"] options:[self objectForKey:@"$options"]];
    } else if (self.count == 1 && [[self objectForKey:@"$regex"] isKindOfClass:NSString.class]) {
        result = [[MODRegex alloc] initWithPattern:[self objectForKey:@"$regex"] options:nil];
    } else if (self.count == 1 && [[self objectForKey:@"$symbol"] isKindOfClass:NSString.class]) {
        result = [[MODSymbol alloc] initWithValue:[self objectForKey:@"$symbol"]];
    } else if (self.count == 1 && [[self objectForKey:@"$undefined"] isKindOfClass:NSNumber.class] && [[self objectForKey:@"$undefined"] boolValue]) {
        result = [[MODUndefined alloc] init];
    } else if (self.count == 1 && [[self objectForKey:@"$minKey"] isKindOfClass:NSNumber.class] && [[self objectForKey:@"$minKey"] intValue] == 1) {
        result = [[MODMinKey alloc] init];
    } else if (self.count == 1 && [[self objectForKey:@"$maxKey"] isKindOfClass:NSNumber.class] && [[self objectForKey:@"$maxKey"] intValue] == 1) {
        result = [[MODMaxKey alloc] init];
    } else if (self.count == 1 && [[self objectForKey:@"$function"] isKindOfClass:NSString.class]) {
        result = [[MODFunction alloc] initWithFunction:[self objectForKey:@"$function"]];
    } else if (self.count == 2 && [[self objectForKey:@"$function"] isKindOfClass:NSString.class] && [[self objectForKey:@"$scope"] isKindOfClass:MODSortedDictionary.class]) {
        if ([[self objectForKey:@"$scope"] count] == 0) {
            result = [[MODFunction alloc] initWithFunction:[self objectForKey:@"$function"]];
        } else {
            result = [[MODScopeFunction alloc] initWithFunction:[self objectForKey:@"$function"] scope:[self objectForKey:@"$scope"]];
        }
    }
    return [result autorelease];
}

@end
