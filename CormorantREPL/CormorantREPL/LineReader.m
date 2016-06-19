//
//  LineReader.m
//  Cormorant
//  Use EditLine lib to construct a prompt for the REPL
//
//  Created by Sven Pedersen on 12/9/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <histedit.h>
#import "LineReader.h"

static NSString* _customPrompt = nil;

/**
 Return the C string that the LineReader shold use as the REPL prompt.
 */
const char* lineReader(EditLine *e) {
  if (_customPrompt != nil) {
    const char* cstr = [_customPrompt cStringUsingEncoding:NSUTF8StringEncoding];
    return cstr;
  }
  else {
    return "> ";
  }
}

@implementation LineReader

EditLine* _el;
History* _hist;
HistEvent _ev;

- (void)setPrompt:(NSString *)string {
  _customPrompt = string;
}

- (instancetype)initWithArgv0:(const char*)argv0 {
  if (self = [super init]) {
    // Setup the editor
    _el = el_init(argv0, stdin, stdout, stderr);
    el_set(_el, EL_PROMPT, &lineReader);
    el_set(_el, EL_EDITOR, "emacs");

    // enable support for history
    _hist = history_init();
    history(_hist, &_ev, H_SETSIZE, 800);
    el_set(_el, EL_HIST, history, _hist);
  }

  return self;
}

- (void)dealloc {
  if (_hist != NULL) {
    history_end(_hist);
    _hist = NULL;
  }

  if (_el != NULL) {
    el_end(_el);
    _el = NULL;
  }
}

- (NSString *)gets {

  // line includes the trailing newline
  int count;
  const char* line = el_gets(_el, &count);

  if (count > 0) {
    history(_hist, &_ev, H_ENTER, line);

    return [NSString stringWithUTF8String:line];
  }

  return nil;
}

@end
