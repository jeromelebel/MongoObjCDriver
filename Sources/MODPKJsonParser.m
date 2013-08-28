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
@property (nonatomic, retain) NSMutableDictionary *dateElement_memo;
@property (nonatomic, retain) NSMutableDictionary *symbolElement_memo;
@property (nonatomic, retain) NSMutableDictionary *dataElement_memo;
@property (nonatomic, retain) NSMutableDictionary *timestampElement_memo;
@property (nonatomic, retain) NSMutableDictionary *valueElement_memo;
@property (nonatomic, retain) NSMutableDictionary *objectIdElement_memo;
@property (nonatomic, retain) NSMutableDictionary *quotedStringToken_memo;
@property (nonatomic, retain) NSMutableDictionary *wordToken_memo;
@property (nonatomic, retain) NSMutableDictionary *numberToken_memo;
@property (nonatomic, retain) NSMutableDictionary *nullToken_memo;
@property (nonatomic, retain) NSMutableDictionary *trueToken_memo;
@property (nonatomic, retain) NSMutableDictionary *falseToken_memo;
@property (nonatomic, retain) NSMutableDictionary *undefinedToken_memo;
@property (nonatomic, retain) NSMutableDictionary *objectIdToken_memo;
@property (nonatomic, retain) NSMutableDictionary *minKeyToken_memo;
@property (nonatomic, retain) NSMutableDictionary *maxKeyToken_memo;
@property (nonatomic, retain) NSMutableDictionary *jsnewToken_memo;
@property (nonatomic, retain) NSMutableDictionary *dateToken_memo;
@property (nonatomic, retain) NSMutableDictionary *symbolToken_memo;
@property (nonatomic, retain) NSMutableDictionary *binDataToken_memo;
@property (nonatomic, retain) NSMutableDictionary *timestampToken_memo;
@property (nonatomic, retain) NSMutableDictionary *openCurlyToken_memo;
@property (nonatomic, retain) NSMutableDictionary *closeCurlyToken_memo;
@property (nonatomic, retain) NSMutableDictionary *openBracketToken_memo;
@property (nonatomic, retain) NSMutableDictionary *closeBracketToken_memo;
@property (nonatomic, retain) NSMutableDictionary *commaToken_memo;
@property (nonatomic, retain) NSMutableDictionary *colonToken_memo;
@property (nonatomic, retain) NSMutableDictionary *openParentheseToken_memo;
@property (nonatomic, retain) NSMutableDictionary *closeParenthesetoken_memo;
@end

@implementation MODPKJsonParser

- (id)init {
    self = [super init];
    if (self) {
        self.enableAutomaticErrorRecovery = YES;

        self._tokenKindTab[@","] = @(MODPKJSON_TOKEN_KIND_COMMATOKEN);
        self._tokenKindTab[@":"] = @(MODPKJSON_TOKEN_KIND_COLONTOKEN);
        self._tokenKindTab[@"ObjectId"] = @(MODPKJSON_TOKEN_KIND_OBJECTIDTOKEN);
        self._tokenKindTab[@"true"] = @(MODPKJSON_TOKEN_KIND_TRUETOKEN);
        self._tokenKindTab[@"MaxKey"] = @(MODPKJSON_TOKEN_KIND_MAXKEYTOKEN);
        self._tokenKindTab[@"null"] = @(MODPKJSON_TOKEN_KIND_NULLTOKEN);
        self._tokenKindTab[@"new"] = @(MODPKJSON_TOKEN_KIND_JSNEWTOKEN);
        self._tokenKindTab[@"Symbol"] = @(MODPKJSON_TOKEN_KIND_SYMBOLTOKEN);
        self._tokenKindTab[@"Timestamp"] = @(MODPKJSON_TOKEN_KIND_TIMESTAMPTOKEN);
        self._tokenKindTab[@"["] = @(MODPKJSON_TOKEN_KIND_OPENBRACKETTOKEN);
        self._tokenKindTab[@"Date"] = @(MODPKJSON_TOKEN_KIND_DATETOKEN);
        self._tokenKindTab[@"false"] = @(MODPKJSON_TOKEN_KIND_FALSETOKEN);
        self._tokenKindTab[@"BinData"] = @(MODPKJSON_TOKEN_KIND_BINDATATOKEN);
        self._tokenKindTab[@"]"] = @(MODPKJSON_TOKEN_KIND_CLOSEBRACKETTOKEN);
        self._tokenKindTab[@"MinKey"] = @(MODPKJSON_TOKEN_KIND_MINKEYTOKEN);
        self._tokenKindTab[@"undefined"] = @(MODPKJSON_TOKEN_KIND_UNDEFINEDTOKEN);
        self._tokenKindTab[@"("] = @(MODPKJSON_TOKEN_KIND_OPENPARENTHESETOKEN);
        self._tokenKindTab[@"{"] = @(MODPKJSON_TOKEN_KIND_OPENCURLYTOKEN);
        self._tokenKindTab[@")"] = @(MODPKJSON_TOKEN_KIND_CLOSEPARENTHESETOKEN);
        self._tokenKindTab[@"}"] = @(MODPKJSON_TOKEN_KIND_CLOSECURLYTOKEN);

        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_COMMATOKEN] = @",";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_COLONTOKEN] = @":";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_OBJECTIDTOKEN] = @"ObjectId";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_TRUETOKEN] = @"true";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_MAXKEYTOKEN] = @"MaxKey";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_NULLTOKEN] = @"null";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_JSNEWTOKEN] = @"new";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_SYMBOLTOKEN] = @"Symbol";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_TIMESTAMPTOKEN] = @"Timestamp";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_OPENBRACKETTOKEN] = @"[";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_DATETOKEN] = @"Date";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_FALSETOKEN] = @"false";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_BINDATATOKEN] = @"BinData";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_CLOSEBRACKETTOKEN] = @"]";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_MINKEYTOKEN] = @"MinKey";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_UNDEFINEDTOKEN] = @"undefined";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_OPENPARENTHESETOKEN] = @"(";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_OPENCURLYTOKEN] = @"{";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_CLOSEPARENTHESETOKEN] = @")";
        self._tokenKindNameTab[MODPKJSON_TOKEN_KIND_CLOSECURLYTOKEN] = @"}";

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
        self.dateElement_memo = [NSMutableDictionary dictionary];
        self.symbolElement_memo = [NSMutableDictionary dictionary];
        self.dataElement_memo = [NSMutableDictionary dictionary];
        self.timestampElement_memo = [NSMutableDictionary dictionary];
        self.valueElement_memo = [NSMutableDictionary dictionary];
        self.objectIdElement_memo = [NSMutableDictionary dictionary];
        self.quotedStringToken_memo = [NSMutableDictionary dictionary];
        self.wordToken_memo = [NSMutableDictionary dictionary];
        self.numberToken_memo = [NSMutableDictionary dictionary];
        self.nullToken_memo = [NSMutableDictionary dictionary];
        self.trueToken_memo = [NSMutableDictionary dictionary];
        self.falseToken_memo = [NSMutableDictionary dictionary];
        self.undefinedToken_memo = [NSMutableDictionary dictionary];
        self.objectIdToken_memo = [NSMutableDictionary dictionary];
        self.minKeyToken_memo = [NSMutableDictionary dictionary];
        self.maxKeyToken_memo = [NSMutableDictionary dictionary];
        self.jsnewToken_memo = [NSMutableDictionary dictionary];
        self.dateToken_memo = [NSMutableDictionary dictionary];
        self.symbolToken_memo = [NSMutableDictionary dictionary];
        self.binDataToken_memo = [NSMutableDictionary dictionary];
        self.timestampToken_memo = [NSMutableDictionary dictionary];
        self.openCurlyToken_memo = [NSMutableDictionary dictionary];
        self.closeCurlyToken_memo = [NSMutableDictionary dictionary];
        self.openBracketToken_memo = [NSMutableDictionary dictionary];
        self.closeBracketToken_memo = [NSMutableDictionary dictionary];
        self.commaToken_memo = [NSMutableDictionary dictionary];
        self.colonToken_memo = [NSMutableDictionary dictionary];
        self.openParentheseToken_memo = [NSMutableDictionary dictionary];
        self.closeParenthesetoken_memo = [NSMutableDictionary dictionary];
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
    self.dateElement_memo = nil;
    self.symbolElement_memo = nil;
    self.dataElement_memo = nil;
    self.timestampElement_memo = nil;
    self.valueElement_memo = nil;
    self.objectIdElement_memo = nil;
    self.quotedStringToken_memo = nil;
    self.wordToken_memo = nil;
    self.numberToken_memo = nil;
    self.nullToken_memo = nil;
    self.trueToken_memo = nil;
    self.falseToken_memo = nil;
    self.undefinedToken_memo = nil;
    self.objectIdToken_memo = nil;
    self.minKeyToken_memo = nil;
    self.maxKeyToken_memo = nil;
    self.jsnewToken_memo = nil;
    self.dateToken_memo = nil;
    self.symbolToken_memo = nil;
    self.binDataToken_memo = nil;
    self.timestampToken_memo = nil;
    self.openCurlyToken_memo = nil;
    self.closeCurlyToken_memo = nil;
    self.openBracketToken_memo = nil;
    self.closeBracketToken_memo = nil;
    self.commaToken_memo = nil;
    self.colonToken_memo = nil;
    self.openParentheseToken_memo = nil;
    self.closeParenthesetoken_memo = nil;

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
    [_dateElement_memo removeAllObjects];
    [_symbolElement_memo removeAllObjects];
    [_dataElement_memo removeAllObjects];
    [_timestampElement_memo removeAllObjects];
    [_valueElement_memo removeAllObjects];
    [_objectIdElement_memo removeAllObjects];
    [_quotedStringToken_memo removeAllObjects];
    [_wordToken_memo removeAllObjects];
    [_numberToken_memo removeAllObjects];
    [_nullToken_memo removeAllObjects];
    [_trueToken_memo removeAllObjects];
    [_falseToken_memo removeAllObjects];
    [_undefinedToken_memo removeAllObjects];
    [_objectIdToken_memo removeAllObjects];
    [_minKeyToken_memo removeAllObjects];
    [_maxKeyToken_memo removeAllObjects];
    [_jsnewToken_memo removeAllObjects];
    [_dateToken_memo removeAllObjects];
    [_symbolToken_memo removeAllObjects];
    [_binDataToken_memo removeAllObjects];
    [_timestampToken_memo removeAllObjects];
    [_openCurlyToken_memo removeAllObjects];
    [_closeCurlyToken_memo removeAllObjects];
    [_openBracketToken_memo removeAllObjects];
    [_closeBracketToken_memo removeAllObjects];
    [_commaToken_memo removeAllObjects];
    [_colonToken_memo removeAllObjects];
    [_openParentheseToken_memo removeAllObjects];
    [_closeParenthesetoken_memo removeAllObjects];
}

- (void)_start {
    
    [self execute:(id)^{
    
        self.tokenizer.numberState.allowsScientificNotation = YES;

    }];
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
    
    if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, TOKEN_KIND_BUILTIN_WORD, 0]) {
        [self actualObjectElement]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchObjectContentElement:)];
}

- (void)objectContentElement {
    [self parseRule:@selector(__objectContentElement) withMemo:_objectContentElement_memo];
}

- (void)__actualObjectElement {
    
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
    
    [self commaToken]; 
    [self propertyElement]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCommaPropertyElement:)];
}

- (void)commaPropertyElement {
    [self parseRule:@selector(__commaPropertyElement) withMemo:_commaPropertyElement_memo];
}

- (void)__propertyNameElement {
    
    if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self quotedStringToken]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
        [self wordToken]; 
    } else {
        [self raise:@"No viable alternative found in rule 'propertyNameElement'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchPropertyNameElement:)];
}

- (void)propertyNameElement {
    [self parseRule:@selector(__propertyNameElement) withMemo:_propertyNameElement_memo];
}

- (void)__arrayElement {
    
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
    
    if ([self predicts:MODPKJSON_TOKEN_KIND_BINDATATOKEN, MODPKJSON_TOKEN_KIND_FALSETOKEN, MODPKJSON_TOKEN_KIND_JSNEWTOKEN, MODPKJSON_TOKEN_KIND_MAXKEYTOKEN, MODPKJSON_TOKEN_KIND_MINKEYTOKEN, MODPKJSON_TOKEN_KIND_NULLTOKEN, MODPKJSON_TOKEN_KIND_OBJECTIDTOKEN, MODPKJSON_TOKEN_KIND_OPENBRACKETTOKEN, MODPKJSON_TOKEN_KIND_OPENCURLYTOKEN, MODPKJSON_TOKEN_KIND_SYMBOLTOKEN, MODPKJSON_TOKEN_KIND_TIMESTAMPTOKEN, MODPKJSON_TOKEN_KIND_TRUETOKEN, MODPKJSON_TOKEN_KIND_UNDEFINEDTOKEN, TOKEN_KIND_BUILTIN_NUMBER, TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self actualArrayElement]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchArrayContentElement:)];
}

- (void)arrayContentElement {
    [self parseRule:@selector(__arrayContentElement) withMemo:_arrayContentElement_memo];
}

- (void)__actualArrayElement {
    
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
    
    [self commaToken]; 
    [self valueElement]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCommaValueElement:)];
}

- (void)commaValueElement {
    [self parseRule:@selector(__commaValueElement) withMemo:_commaValueElement_memo];
}

- (void)__dateElement {
    
    [self jsnewToken]; 
    [self tryAndRecover:MODPKJSON_TOKEN_KIND_DATETOKEN block:^{ 
        [self dateToken]; 
    } completion:^{ 
        [self dateToken]; 
    }];
    [self openParentheseToken]; 
    [self tryAndRecover:MODPKJSON_TOKEN_KIND_CLOSEPARENTHESETOKEN block:^{ 
        if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
            [self quotedStringToken]; 
        }
        [self closeParenthesetoken]; 
    } completion:^{ 
        [self closeParenthesetoken]; 
    }];

    [self fireAssemblerSelector:@selector(parser:didMatchDateElement:)];
}

- (void)dateElement {
    [self parseRule:@selector(__dateElement) withMemo:_dateElement_memo];
}

- (void)__symbolElement {
    
    [self symbolToken]; 
    [self tryAndRecover:MODPKJSON_TOKEN_KIND_OPENPARENTHESETOKEN block:^{ 
        [self openParentheseToken]; 
    } completion:^{ 
        [self openParentheseToken]; 
    }];
    [self quotedStringToken]; 
    [self tryAndRecover:MODPKJSON_TOKEN_KIND_CLOSEPARENTHESETOKEN block:^{ 
        [self closeParenthesetoken]; 
    } completion:^{ 
        [self closeParenthesetoken]; 
    }];

    [self fireAssemblerSelector:@selector(parser:didMatchSymbolElement:)];
}

- (void)symbolElement {
    [self parseRule:@selector(__symbolElement) withMemo:_symbolElement_memo];
}

- (void)__dataElement {
    
    [self binDataToken]; 
    [self tryAndRecover:MODPKJSON_TOKEN_KIND_OPENPARENTHESETOKEN block:^{ 
        [self openParentheseToken]; 
    } completion:^{ 
        [self openParentheseToken]; 
    }];
    [self numberToken]; 
    [self tryAndRecover:TOKEN_KIND_BUILTIN_QUOTEDSTRING block:^{ 
        [self quotedStringToken]; 
    } completion:^{ 
        [self quotedStringToken]; 
    }];
    [self closeParenthesetoken]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDataElement:)];
}

- (void)dataElement {
    [self parseRule:@selector(__dataElement) withMemo:_dataElement_memo];
}

- (void)__timestampElement {
    
    [self timestampToken]; 
    [self tryAndRecover:MODPKJSON_TOKEN_KIND_OPENPARENTHESETOKEN block:^{ 
        [self openParentheseToken]; 
    } completion:^{ 
        [self openParentheseToken]; 
    }];
    [self numberToken]; 
    [self tryAndRecover:MODPKJSON_TOKEN_KIND_COMMATOKEN block:^{ 
        [self commaToken]; 
    } completion:^{ 
        [self commaToken]; 
    }];
    [self numberToken]; 
    [self tryAndRecover:MODPKJSON_TOKEN_KIND_CLOSEPARENTHESETOKEN block:^{ 
        [self closeParenthesetoken]; 
    } completion:^{ 
        [self closeParenthesetoken]; 
    }];

    [self fireAssemblerSelector:@selector(parser:didMatchTimestampElement:)];
}

- (void)timestampElement {
    [self parseRule:@selector(__timestampElement) withMemo:_timestampElement_memo];
}

- (void)__valueElement {
    
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
        [self quotedStringToken]; 
    } else if ([self predicts:MODPKJSON_TOKEN_KIND_UNDEFINEDTOKEN, 0]) {
        [self undefinedToken]; 
    } else if ([self predicts:MODPKJSON_TOKEN_KIND_OBJECTIDTOKEN, 0]) {
        [self objectIdElement]; 
    } else if ([self predicts:MODPKJSON_TOKEN_KIND_MINKEYTOKEN, 0]) {
        [self minKeyToken]; 
    } else if ([self predicts:MODPKJSON_TOKEN_KIND_MAXKEYTOKEN, 0]) {
        [self maxKeyToken]; 
    } else if ([self predicts:MODPKJSON_TOKEN_KIND_SYMBOLTOKEN, 0]) {
        [self symbolElement]; 
    } else if ([self predicts:MODPKJSON_TOKEN_KIND_JSNEWTOKEN, 0]) {
        [self dateElement]; 
    } else if ([self predicts:MODPKJSON_TOKEN_KIND_BINDATATOKEN, 0]) {
        [self dataElement]; 
    } else if ([self predicts:MODPKJSON_TOKEN_KIND_TIMESTAMPTOKEN, 0]) {
        [self timestampElement]; 
    } else {
        [self raise:@"No viable alternative found in rule 'valueElement'."];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchValueElement:)];
}

- (void)valueElement {
    [self parseRule:@selector(__valueElement) withMemo:_valueElement_memo];
}

- (void)__objectIdElement {
    
    [self objectIdToken]; 
    [self tryAndRecover:MODPKJSON_TOKEN_KIND_OPENPARENTHESETOKEN block:^{ 
        [self openParentheseToken]; 
    } completion:^{ 
        [self openParentheseToken]; 
    }];
    [self quotedStringToken]; 
    [self tryAndRecover:MODPKJSON_TOKEN_KIND_CLOSEPARENTHESETOKEN block:^{ 
        [self closeParenthesetoken]; 
    } completion:^{ 
        [self closeParenthesetoken]; 
    }];

    [self fireAssemblerSelector:@selector(parser:didMatchObjectIdElement:)];
}

- (void)objectIdElement {
    [self parseRule:@selector(__objectIdElement) withMemo:_objectIdElement_memo];
}

- (void)__quotedStringToken {
    
    [self matchQuotedString:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchQuotedStringToken:)];
}

- (void)quotedStringToken {
    [self parseRule:@selector(__quotedStringToken) withMemo:_quotedStringToken_memo];
}

- (void)__wordToken {
    
    [self matchWord:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchWordToken:)];
}

- (void)wordToken {
    [self parseRule:@selector(__wordToken) withMemo:_wordToken_memo];
}

- (void)__numberToken {
    
    [self matchNumber:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNumberToken:)];
}

- (void)numberToken {
    [self parseRule:@selector(__numberToken) withMemo:_numberToken_memo];
}

- (void)__nullToken {
    
    [self match:MODPKJSON_TOKEN_KIND_NULLTOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNullToken:)];
}

- (void)nullToken {
    [self parseRule:@selector(__nullToken) withMemo:_nullToken_memo];
}

- (void)__trueToken {
    
    [self match:MODPKJSON_TOKEN_KIND_TRUETOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchTrueToken:)];
}

- (void)trueToken {
    [self parseRule:@selector(__trueToken) withMemo:_trueToken_memo];
}

- (void)__falseToken {
    
    [self match:MODPKJSON_TOKEN_KIND_FALSETOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchFalseToken:)];
}

- (void)falseToken {
    [self parseRule:@selector(__falseToken) withMemo:_falseToken_memo];
}

- (void)__undefinedToken {
    
    [self match:MODPKJSON_TOKEN_KIND_UNDEFINEDTOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchUndefinedToken:)];
}

- (void)undefinedToken {
    [self parseRule:@selector(__undefinedToken) withMemo:_undefinedToken_memo];
}

- (void)__objectIdToken {
    
    [self match:MODPKJSON_TOKEN_KIND_OBJECTIDTOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchObjectIdToken:)];
}

- (void)objectIdToken {
    [self parseRule:@selector(__objectIdToken) withMemo:_objectIdToken_memo];
}

- (void)__minKeyToken {
    
    [self match:MODPKJSON_TOKEN_KIND_MINKEYTOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchMinKeyToken:)];
}

- (void)minKeyToken {
    [self parseRule:@selector(__minKeyToken) withMemo:_minKeyToken_memo];
}

- (void)__maxKeyToken {
    
    [self match:MODPKJSON_TOKEN_KIND_MAXKEYTOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchMaxKeyToken:)];
}

- (void)maxKeyToken {
    [self parseRule:@selector(__maxKeyToken) withMemo:_maxKeyToken_memo];
}

- (void)__jsnewToken {
    
    [self match:MODPKJSON_TOKEN_KIND_JSNEWTOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchJsnewToken:)];
}

- (void)jsnewToken {
    [self parseRule:@selector(__jsnewToken) withMemo:_jsnewToken_memo];
}

- (void)__dateToken {
    
    [self match:MODPKJSON_TOKEN_KIND_DATETOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchDateToken:)];
}

- (void)dateToken {
    [self parseRule:@selector(__dateToken) withMemo:_dateToken_memo];
}

- (void)__symbolToken {
    
    [self match:MODPKJSON_TOKEN_KIND_SYMBOLTOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchSymbolToken:)];
}

- (void)symbolToken {
    [self parseRule:@selector(__symbolToken) withMemo:_symbolToken_memo];
}

- (void)__binDataToken {
    
    [self match:MODPKJSON_TOKEN_KIND_BINDATATOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchBinDataToken:)];
}

- (void)binDataToken {
    [self parseRule:@selector(__binDataToken) withMemo:_binDataToken_memo];
}

- (void)__timestampToken {
    
    [self match:MODPKJSON_TOKEN_KIND_TIMESTAMPTOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchTimestampToken:)];
}

- (void)timestampToken {
    [self parseRule:@selector(__timestampToken) withMemo:_timestampToken_memo];
}

- (void)__openCurlyToken {
    
    [self match:MODPKJSON_TOKEN_KIND_OPENCURLYTOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOpenCurlyToken:)];
}

- (void)openCurlyToken {
    [self parseRule:@selector(__openCurlyToken) withMemo:_openCurlyToken_memo];
}

- (void)__closeCurlyToken {
    
    [self match:MODPKJSON_TOKEN_KIND_CLOSECURLYTOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCloseCurlyToken:)];
}

- (void)closeCurlyToken {
    [self parseRule:@selector(__closeCurlyToken) withMemo:_closeCurlyToken_memo];
}

- (void)__openBracketToken {
    
    [self match:MODPKJSON_TOKEN_KIND_OPENBRACKETTOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOpenBracketToken:)];
}

- (void)openBracketToken {
    [self parseRule:@selector(__openBracketToken) withMemo:_openBracketToken_memo];
}

- (void)__closeBracketToken {
    
    [self match:MODPKJSON_TOKEN_KIND_CLOSEBRACKETTOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCloseBracketToken:)];
}

- (void)closeBracketToken {
    [self parseRule:@selector(__closeBracketToken) withMemo:_closeBracketToken_memo];
}

- (void)__commaToken {
    
    [self match:MODPKJSON_TOKEN_KIND_COMMATOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCommaToken:)];
}

- (void)commaToken {
    [self parseRule:@selector(__commaToken) withMemo:_commaToken_memo];
}

- (void)__colonToken {
    
    [self match:MODPKJSON_TOKEN_KIND_COLONTOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchColonToken:)];
}

- (void)colonToken {
    [self parseRule:@selector(__colonToken) withMemo:_colonToken_memo];
}

- (void)__openParentheseToken {
    
    [self match:MODPKJSON_TOKEN_KIND_OPENPARENTHESETOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOpenParentheseToken:)];
}

- (void)openParentheseToken {
    [self parseRule:@selector(__openParentheseToken) withMemo:_openParentheseToken_memo];
}

- (void)__closeParenthesetoken {
    
    [self match:MODPKJSON_TOKEN_KIND_CLOSEPARENTHESETOKEN discard:NO]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCloseParenthesetoken:)];
}

- (void)closeParenthesetoken {
    [self parseRule:@selector(__closeParenthesetoken) withMemo:_closeParenthesetoken_memo];
}

@end