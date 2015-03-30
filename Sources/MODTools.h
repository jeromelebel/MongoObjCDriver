//
//  MODTools.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 14/01/2015.
//
//

#if  __has_feature(objc_arc)
#define MOD_RETAIN(x)               x
#define MOD_AUTORELEASE(x)          x
#define MOD_AUTORELEASE2(x)
#define MOD_RELEASE(x)
#define MOD_SUPER_DEALLOC()
#else
#define MOD_RETAIN(x)               [x retain]
#define MOD_AUTORELEASE(x)          [x autorelease]
#define MOD_AUTORELEASE2(x)         [x autorelease]
#define MOD_RELEASE(x)              [x release]
#define MOD_SUPER_DEALLOC()         [super dealloc]
#endif


#define DEBUG_LOG(s...)                NSLog(@"%s[%@ %@] %@, %s:%d", (self == [self class])?"+":"-", [self class], NSStringFromSelector(_cmd), [NSString stringWithFormat:s], __FILE__, __LINE__)