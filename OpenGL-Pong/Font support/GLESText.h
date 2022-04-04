//
//  GLESText.h
//  iostext
//
//  Copyright © Borna Noureddin. All rights reserved.
//

#ifndef GLESText_h
#define GLESText_h

#import <Foundation/Foundation.h>

struct CPPClass;

@interface GLESText : NSObject
{
    @private
    struct CPPClass *theObj;
}
@property int fontPtSize;
@property int dpi;
@property float posx;
@property float posy;

-(void)DrawText:(char *)theText fontName:(NSString *)fontName;
-(unsigned char *)GetImage;
-(int)GetWidth;
-(int)GetHeight;

@end

#endif /* GLESText_h */
