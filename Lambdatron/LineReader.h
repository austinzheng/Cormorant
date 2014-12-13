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

@interface LineReader : NSObject

- (instancetype) initWithArgv0:(const char*)argv0;
- (NSString*) gets;

@end

#endif
