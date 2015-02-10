//
//  MODSSLOptions.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 24/08/2014.
//
//

#import <Foundation/Foundation.h>

@interface MODSSLOptions : NSObject

@property (nonatomic, readonly, strong) NSString *pemFileName;
@property (nonatomic, readonly, strong) NSString *pemPassword;
@property (nonatomic, readonly, strong) NSString *caFileName;
@property (nonatomic, readonly, strong) NSString *caDirectory;
@property (nonatomic, readonly, strong) NSString *crlFileName;
@property (nonatomic, readonly, assign) BOOL weakCertificate;

- (instancetype)initWithPemFileName:(NSString *)pemFileName pemPassword:(NSString *)pemPassword caFileName:(NSString *)caFileName caDirectory:(NSString *)caDirectory crlFileName:(NSString *)crlFileName weakCertificate:(BOOL)weakCertificate;

@end
