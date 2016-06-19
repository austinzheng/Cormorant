//
//  main.m
//  CormorantREPLRunner
//
//  Created by Austin Zheng on 4/7/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@import CormorantREPL;

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    NSMutableArray *buffer = [@[] mutableCopy];
    for (NSInteger i=0; i<argc; i++) {
      const char *cur = argv[i];
      NSString *str = [NSString stringWithCString:cur encoding:NSUTF8StringEncoding];
      if (str) {
        [buffer addObject:str];
      }
    }

    [REPLWrapper runWithArguments:buffer];
  }
  return 0;
}
