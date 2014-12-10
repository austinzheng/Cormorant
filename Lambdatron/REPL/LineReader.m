//
//  LineReader.m
//  Lambdatron
//  Use EditLine lib to construct a prompt for the REPL
//
//  Created by Sven Pedersen on 12/9/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <histedit.h>
#import "LineReader.h"

char* lineReader(EditLine *e) {
    return "> ";
}

@implementation LineReader

EditLine* _el;
History* _hist;
HistEvent _ev;

- (instancetype) initWithArgv0:(const char*)argv0 {
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

- (void) dealloc {
    if (_hist != NULL) {
        history_end(_hist);
        _hist = NULL;
    }
    
    if (_el != NULL) {
        el_end(_el);
        _el = NULL;
    }
}

- (NSString*) gets {
    
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
