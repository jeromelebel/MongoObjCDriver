#import "MODPKJsonParser.h"
#import <ParseKit/ParseKit.h>

#define LT(i) [self LT:(i)]
#define LA(i) [self LA:(i)]
#define LS(i) [self LS:(i)]
#define LF(i) [self LF:(i)]

#define POP()       [self.assembly pop]
#define POP_STR()   [self _popString]
#define POP_TOK()   [self _popToken]
#define POP_BOOL()  [self _popBool]
#define POP_INT()   [self _popInteger]
#define POP_FLOAT() [self _popDouble]

#define PUSH(obj)     [self.assembly push:(id)(obj)]
#define PUSH_BOOL(yn) [self _pushBool:(BOOL)(yn)]
#define PUSH_INT(i)   [self _pushInteger:(NSInteger)(i)]
#define PUSH_FLOAT(f) [self _pushDouble:(double)(f)]

#define EQ(a, b) [(a) isEqual:(b)]
#define NE(a, b) (![(a) isEqual:(b)])
#define EQ_IGNORE_CASE(a, b) (NSOrderedSame == [(a) compare:(b)])

#define ABOVE(fence) [self.assembly objectsAbove:(fence)]

#define LOG(obj) do { NSLog(@"%@", (obj)); } while (0);
#define PRINT(str) do { printf("%s\n", (str)); } while (0);

@interface PKSParser ()
@property (nonatomic, retain) NSMutableDictionary *_tokenKindTab;
@property (nonatomic, retain) NSMutableArray *_tokenKindNameTab;

- (BOOL)_popBool;
- (NSInteger)_popInteger;
- (double)_popDouble;
- (PKToken *)_popToken;
- (NSString *)_popString;

- (void)_pushBool:(BOOL)yn;
- (void)_pushInteger:(NSInteger)i;
- (void)_pushDouble:(double)d;
@end

@interface MODPKJsonParser ()
@property (nonatomic, retain) NSMutableDictionary *objectElement_memo;
@property (nonatomic, retain) NSMutableDictionary *objectContentElement_memo;
@property (nonatomic, retain) NSMutableDictionary *actualObjectElement_memo;
@property (nonatomic, retain) NSMutableDictionary *propertyElement_memo;
@property (nonatomic, retain) NSMutableDictionary *commaPropertyElement_memo;
@property (nonatomic, retain) NSMutableDictionary *propertyNameElement_memo;
@property (nonatomic, retain) NSMutableDictionary *arrayElement_memo;
@property (nonatomic, retain) NSMutableDictionary *arrayContentElement_memo;
@property (nonatomic, retain) NSMutableDictionary *actualArrayElement_memo;
@property (nonatomic, retain) NSMutableDictionary *commaValueElement_memo;
@property (nonatomic, retain) NSMutableDictionary *valueElement_memo;
@property (nonatomic, retain) NSMutableDictionary *stringToken_memo;
@property (nonatomic, retain) NSMutableDictionary *numberToken_memo;
@property (nonatomic, retain) NSMutableDictionary *nullToken_memo;
@property (nonatomic, retain) NSMutableDictionary *trueToken_memo;
@property (nonatomic, retain) NSMutableDictionary *falseToken_memo;
@property (nonatomic, retain) NSMutableDictionary *openCurlyToken_memo;
@property (nonatomic, retain) NSMutableDictionary *closeCurlyToken_memo;
@property (nonatomic, retain) NSMutableDictionary *openBracketToken_memo;
@property (nonatomic, retain) NSMutableDictionary *closeBracketToken_memo;
@property (nonatomic, retain) NSMutableDictionary *commaToken_memo;
@property (nonatomic, retain) NSMutableDictionary *colonToken_memo;
@end

@implementation MODPKJsonParser

- (id)init {
    self = [super init];
    if (self) {
        self.enableAutomaticErrorRecovery = YES;

        self._tokenKindTab[@"false"] = @(MODPKJSON_TOKEN_KIND_FALSETOKEN);
        self._tokenKindTab[@"}"] = @(MODPKJSON_TOKEN_KIND_CLOSECURLYTOKEN);
        self._tokenKindTab[@"["] = @(MODPKJSON_TOKEN_KIND_OPENBRACKETTOKEN);
        self._tokenKindTab[@"null"] = @(MODPKJSON_TOKEN_KIND_NULLTOKEN);
        self._tokenKindTab[@","] = @(MODPKJSON_TOKEN_KIND_COMMATOKEN);
        self._tokenKindTab[@"true"] = @(MODPKJSON_TOKEN_KIND_TRUETOKEN);
        self._tokenKindTab[@"]"] = @(MODPKJSON_TOKEN_KIND_CLOSEBRACKETTOKEN);
        self._tokenKindTab[@"{"] = @(MODPKJSON_TOKEN_KIND_OPENCURLYTOKEN);
        self._tokenKindTab[@":"] = @(MODPKJSON_TOKEN_KIND_COLONTOKEN);

        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_FALSETOKEN] = @"false";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_CLOSECURLYTOKEN] = @"}";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_OPENBRACKETTOKEN] = @"[";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_NULLTOKEN] = @"null";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_COMMATOKEN] = @",";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_TRUETOKEN] = @"true";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_CLOSEBRACKETTOKEN] = @"]";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_OPENCURLYTOKEN] = @"{";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_COLONTOKEN] = @":";

        self.objectElement_memo = [NSMutableDictionary dictionary];
        self.objectContentElement_memo = [NSMutableDictionary dictionary];
        self.actualObjectElement_memo = [NSMutableDictionary dictionary];
        self.propertyElement_memo = [NSMutableDictionary dictionary];
        self.commaPropertyElement_memo = [NSMutableDictionary dictionary];
        self.propertyNameElement_memo = [NSMutableDictionary dictionary];
        self.arrayElement_memo = [NSMutableDictionary dictionary];
        self.arrayContentElement_memo = [NSMutableDictionary dictionary];
        self.actualArrayElement_memo = [NSMutableDictionary dictionary];
        self.commaValueElement_memo = [NSMutableDictionary dictionary];
        self.valueElement_memo = [NSMutableDictionary dictionary];
        self.stringToken_memo = [NSMutableDictionary dictionary];
        self.numberToken_memo = [NSMutableDictionary dictionary];
        self.nullToken_memo = [NSMutableDictionary dictionary];
        self.trueToken_memo = [NSMutableDictionary dictionary];
        self.falseToken_memo = [NSMutableDictionary dictionary];
        self.openCurlyToken_memo = [NSMutableDictionary dictionary];
        self.closeCurlyToken_memo = [NSMutableDictionary dictionary];
        self.openBracketToken_memo = [NSMutableDictionary dictionary];
        self.closeBracketToken_memo = [NSMutableDictionary dictionary];
        self.commaToken_memo = [NSMutableDictionary dictionary];
        self.colonToken_memo = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc {
    self.objectElement_memo = nil;
    self.objectContentElement_memo = nil;
    self.actualObjectElement_memo = nil;
    self.propertyElement_memo = nil;
    self.commaPropertyElement_memo = nil;
    self.propertyNameElement_memo = nil;
    self.arrayElement_memo = nil;
    self.arrayContentElement_memo = nil;
    self.actualArrayElement_memo = nil;
    self.commaValueElement_memo = nil;
    self.valueElement_memo = nil;
    self.stringToken_memo = nil;
    self.numberToken_memo = nil;
    self.nullToken_memo = nil;
    self.trueToken_memo = nil;
    self.falseToken_memo = nil;
    self.openCurlyToken_memo = nil;
    self.closeCurlyToken_memo = nil;
    self.openBracketToken_memo = nil;
    self.closeBracketToken_memo = nil;
    self.commaToken_memo = nil;
    self.colonToken_memo = nil;

    [super dealloc];
}

- (void)_clearMemo {
    [_objectElement_memo removeAllObjects];
    [_objectContentElement_memo removeAllObjects];
    [_actualObjectElement_memo removeAllObjects];
    [_propertyElement_memo removeAllObjects];
    [_commaPropertyElement_memo removeAllObjects];
    [_propertyNameElement_memo removeAllObjects];
    [_arrayElement_memo removeAllObjects];
    [_arrayContentElement_memo removeAllObjects];
    [_actualArrayElement_memo removeAllObjects];
    [_commaValueElement_memo removeAllObjects];
    [_valueElement_memo removeAllObjects];
    [_stringToken_memo removeAllObjects];
    [_numberToken_memo removeAllObjects];
    [_nullToken_memo removeAllObjects];
    [_trueToken_memo removeAllObjects];
    [_falseToken_memo removeAllObjects];
    [_openCurlyToken_memo removeAllObjects];
    [_closeCurlyToken_memo removeAllObjects];
    [_openBracketToken_memo removeAllObjects];
    [_closeBracketToken_memo removeAllObjects];
    [_commaToken_memo removeAllObjects];
    [_colonToken_memo removeAllObjects];
}

- (void)_start {
    
    [self tryAndRecover:TOKEN_KIND_BUILTIN_EOF block:^{
        if ([self predicts:MODPKJSON_TOKEN_KIND_OPENBRACKETTOKEN, 0]) {
            [self arrayElement]; 
        } else if ([self predicts:MODPKJSON_TOKEN_KIND_OPENCURLYTOKEN, 0]) {
            [self objectElement]; 
        }
        [self matchEOF:YES]; 
    } completion:^{
        [self matchEOF:YES];
    }];

}

- (void)__objectElement {
    
    [self fireAssemblerSelector:@selector(parser:willMatchObjectElement:)];
        [self openCurlyToken]; 
    [self tryAndRecover:MODPKJSON_TOKEN_KIND_CLOSECURLYTOKEN block:^{ 
        [self objectContentElement]; 
        [self closeCurlyToken]; 
    } completion:^{ 
        [self closeCurlyToken]; 
    }];

    [self fireAssemblerSelector:@selector(parser:didMatchObjectElement:)];
}

- (void)objectElement {
    [self parseRule:@selector(__objectElement) withMemo:_objectElement_memo];
}

- (void)__objectContentElement {
    
    [self fireAssemblerSelector:@selector(parser:willMatchObjectContentElement:)];
        if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self actualObjectElement]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchObjectContentElement:)];
}

- (void)objectContentElement {
    [self parseRule:@selector(__objectContentElement) withMemo:_objectContentElement_memo];
}

- (void)__actualObjectElement {
    
    [self fireAssemblerSelector:@selector(parser:willMatchActualObjectElement:)];
        [self propertyElement]; 
    while ([self predicts:MODPKJSON_TOKEN_KIND_COMMATOKEN, 0]) {
        if ([self speculate:^{ [self commaPropertyElement]; }]) {
            [self commaPropertyElement]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchActualObjectElement:)];
}

- (void)actualObjectElement {
    [self parseRule:@selector(__actualObjectElement) withMemo:_actualObjectElement_memo];
}

- (void)__propertyElement {
    
    [self fireAssemblerSelector:@selector(parser:willMatchPropertyElement:)];
        [self propertyNameElement]; 
    [self tryAndRecover:MODPKJSON_TOKEN_KIND_COLONTOKEN block:^{ 
        [self colonToken]; 
    } completion:^{ 
        [self colonToken]; 
    }];
    [self valueElement]; 

    [self fireAssemblerSelector:@selector(parser:didMatchPropertyElement:)];
}

- (void)propertyElement {
    [self parseRule:@selector(__propertyElement) withMemo:_propertyElement_memo];
}

- (void)__commaPropertyElement {
    
    [self fireAssemblerSelector:@selector(parser:willMatchCommaPropertyElement:)];
        [self commaToken]; 
    [self propertyElement]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCommaPropertyElement:)];
}

- (void)commaPropertyElement {
    [self parseRule:@selector(__commaPropertyElement) withMemo:_commaPropertyElement_memo];
}

- (void)__propertyNameElement {
    
    [self fireAssemblerSelector:@selector(parser:willMatchPropertyNameElement:)];
        [self stringToken]; 

    [self fireAssemblerSelector:@selector(parser:didMatchPropertyNameElement:)];
}

- (void)propertyNameElement {
    [self parseRule:@selector(__propertyNameElement) withMemo:_propertyNameElement_memo];
}

- (void)__arrayElement {
    
    [self fireAssemblerSelector:@selector(parser:willMatchArrayElement:)];
        [self openBracketToken]; 
    [self tryAndRecover:MODPKJSON_TOKEN_KIND_CLOSEBRACKETTOKEN block:^{ 
        [self arrayContentElement]; 
        [self closeBracketToken]; 
    } completion:^{ 
        [self closeBracketToken]; 
    }];

    [self fireAssemblerSelector:@selector(parser:didMatchArrayElement:)];
}

- (void)arrayElement {
    [self parseRule:@selector(__arrayElement) withMemo:_arrayElement_memo];
}

- (void)__arrayContentElement {
    
    [self fireAssemblerSelector:@selector(parser:willMatchArrayContentElement:)];
        if ([self predicts:MODPKJSON_TOKEN_KIND_FALSETOKEN, MODPKJSON_TOKEN_KIND_NULLTOKEN, MODPKJSON_TOKEN_KIND_OPENBRACKETTOKEN, MODPKJSON_TOKEN_KIND_OPENCURLYTOKEN, MODPKJSON_TOKEN_KIND_TRUETOKEN, TOKEN_KIND_BUILTIN_NUMBER, TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self actualArrayElement]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchArrayContentElement:)];
}

- (void)arrayContentElement {
    [self parseRule:@selector(__arrayContentElement) withMemo:_arrayContentElement_memo];
}

- (void)__actualArrayElement {
    
    [self fireAssemblerSelector:@selector(parser:willMatchActualArrayElement:)];
        [self valueElement]; 
    while ([self predicts:MODPKJSON_TOKEN_KIND_COMMATOKEN, 0]) {
        if ([self speculate:^{ [self commaValueElement]; }]) {
            [self commaValueElement]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchActualArrayElement:)];
}

- (void)actualArrayElement {
    [self parseRule:@selector(__actualArrayElement) withMemo:_actualArrayElement_memo];
}

- (void)__commaValueElement {
    
    [self fireAssemblerSelector:@selector(parser:willMatchCommaValueElement:)];
        [self commaToken]; 
    [self valueElement]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCommaValueElement:)];
}

- (void)commaValueElement {
    [self parseRule:@selector(__commaValueElement) withMemo:_commaValueElement_memo];
}

- (void)__valueElement {
    
    [self fireAssemblerSelector:@selector(parser:willMatchValueElement:)];
        if ([self predicts:MODPKJSON_TOKEN_KIND_NULLTOKEN, 0]) {
        [self nullToken]; 
    } else if ([self predicts:MODPKJSON_TOKEN_KIND_TRUETOKEN, 0]) {
        [self trueToken]; 
    } else if ([self predicts:MODPKJSON_TOKEN_KIND_FALSETOKEN, 0]) {
        [self falseToken]; 
    } else if ([self predicts:MODPKJSON_TOKEN_KIND_OPENBRACKETTOKEN, 0]) {
        [self arrayElement]; 
    } else if ([self predicts:MODPKJSON_TOKEN_KIND_OPENCURLYTOKEN, 0]) {
        [self objectElement]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_NUMBER, 0]) {
        [self numberToken]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self stringToken]; 
    } else {
        [self raise:@"No viable alternative found in rule 'valueElement'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchValueElement:)];
}

- (void)valueElement {
    [self parseRule:@selector(__valueElement) withMemo:_valueElement_memo];
}

- (void)__stringToken {
    
    [self fireAssemblerSelector:@selector(parser:willMatchStringToken:)];
        [self matchQuotedString:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchStringToken:)];
}

- (void)stringToken {
    [self parseRule:@selector(__stringToken) withMemo:_stringToken_memo];
}

- (void)__numberToken {
    
    [self fireAssemblerSelector:@selector(parser:willMatchNumberToken:)];
        [self matchNumber:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNumberToken:)];
}

- (void)numberToken {
    [self parseRule:@selector(__numberToken) withMemo:_numberToken_memo];
}

- (void)__nullToken {
    
    [self fireAssemblerSelector:@selector(parser:willMatchNullToken:)];
        [self match:MODPKJSON_TOKEN_KIND_NULLTOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNullToken:)];
}

- (void)nullToken {
    [self parseRule:@selector(__nullToken) withMemo:_nullToken_memo];
}

- (void)__trueToken {
    
    [self fireAssemblerSelector:@selector(parser:willMatchTrueToken:)];
        [self match:MODPKJSON_TOKEN_KIND_TRUETOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchTrueToken:)];
}

- (void)trueToken {
    [self parseRule:@selector(__trueToken) withMemo:_trueToken_memo];
}

- (void)__falseToken {
    
    [self fireAssemblerSelector:@selector(parser:willMatchFalseToken:)];
        [self match:MODPKJSON_TOKEN_KIND_FALSETOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchFalseToken:)];
}

- (void)falseToken {
    [self parseRule:@selector(__falseToken) withMemo:_falseToken_memo];
}

- (void)__openCurlyToken {
    
    [self fireAssemblerSelector:@selector(parser:willMatchOpenCurlyToken:)];
        [self match:MODPKJSON_TOKEN_KIND_OPENCURLYTOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOpenCurlyToken:)];
}

- (void)openCurlyToken {
    [self parseRule:@selector(__openCurlyToken) withMemo:_openCurlyToken_memo];
}

- (void)__closeCurlyToken {
    
    [self fireAssemblerSelector:@selector(parser:willMatchCloseCurlyToken:)];
        [self match:MODPKJSON_TOKEN_KIND_CLOSECURLYTOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCloseCurlyToken:)];
}

- (void)closeCurlyToken {
    [self parseRule:@selector(__closeCurlyToken) withMemo:_closeCurlyToken_memo];
}

- (void)__openBracketToken {
    
    [self fireAssemblerSelector:@selector(parser:willMatchOpenBracketToken:)];
        [self match:MODPKJSON_TOKEN_KIND_OPENBRACKETTOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOpenBracketToken:)];
}

- (void)openBracketToken {
    [self parseRule:@selector(__openBracketToken) withMemo:_openBracketToken_memo];
}

- (void)__closeBracketToken {
    
    [self fireAssemblerSelector:@selector(parser:willMatchCloseBracketToken:)];
        [self match:MODPKJSON_TOKEN_KIND_CLOSEBRACKETTOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCloseBracketToken:)];
}

- (void)closeBracketToken {
    [self parseRule:@selector(__closeBracketToken) withMemo:_closeBracketToken_memo];
}

- (void)__commaToken {
    
    [self fireAssemblerSelector:@selector(parser:willMatchCommaToken:)];
        [self match:MODPKJSON_TOKEN_KIND_COMMATOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCommaToken:)];
}

- (void)commaToken {
    [self parseRule:@selector(__commaToken) withMemo:_commaToken_memo];
}

- (void)__colonToken {
    
    [self fireAssemblerSelector:@selector(parser:willMatchColonToken:)];
        [self match:MODPKJSON_TOKEN_KIND_COLONTOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchColonToken:)];
}

- (void)colonToken {
    [self parseRule:@selector(__colonToken) withMemo:_colonToken_memo];
}

@end