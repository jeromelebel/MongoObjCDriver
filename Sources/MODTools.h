//
//  MODTools.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 14/01/2015.
//
//

#if  __has_feature(objc_arc)
#define RELEASE(x)
#else
#define RELEASE(x) [x release]
#endif
