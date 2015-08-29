//
//  LineReader.h
//  Lambdatron
//
//  Created by Sven Pedersen on 12/9/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

#ifndef Lambdatron_LineReader_h
#define Lambdatron_LineReader_h

#import <Foundation/Foundation.h>

/**
 LineReader singleton, for use with REPL application
 */
@interface LineReader : NSObject

- (_Nonnull instancetype)initWithArgv0:(const char *_Nonnull)argv0;
- (NSString * _Nullable )gets;
- (void)setPrompt:(NSString * _Nonnull)string;

@end

#endif
