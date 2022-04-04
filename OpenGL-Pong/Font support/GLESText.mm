//
//  GLESText.m
//  iostext
//
//  Copyright © Borna Noureddin. All rights reserved.
//

#import "GLESText.h"
#include "GLESFTText.hpp"

struct CPPClass
{
    GLESFTText textObj;
};

@implementation GLESText

-(id) init
{
    self = [super init];
    if (self) {
        theObj = new CPPClass;
    }
    _fontPtSize = 24;
    _dpi = 100;
    _posx = 0.2f;
    _posy = 0.2f;

    return self;
}

-(void)DrawText:(char *)theText fontName:(NSString *)fontName
{
    NSString *fontPath = [[NSBundle mainBundle] pathForResource:fontName ofType:@"ttf"];
    theObj->textObj.DrawText((char *)[fontPath cStringUsingEncoding:NSUTF8StringEncoding], theText, _fontPtSize, _dpi, _posx, _posy);
}

-(unsigned char *)GetImage { return theObj->textObj.GetImage(); }

-(int)GetWidth { return theObj->textObj.GetWidth(); }
-(int)GetHeight { return theObj->textObj.GetHeight(); }


@end
