//
//  GLESFTText.hpp
//  iostext
//
//  Copyright © Borna Noureddin. All rights reserved.
//

#ifndef GLESFTText_hpp
#define GLESFTText_hpp

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <ft2build.h>
#include "freetype/freetype.h"

class GLESFTText
{
public:
    GLESFTText();
    ~GLESFTText();
    void DrawText(char *fontName, char *text, int fontPtSize=24, int dpi=100, float x=0.2f, float y=0.2f);
    unsigned char *GetImage() { return image; };
    int GetWidth();
    int GetHeight();
    
private:
    unsigned char *image;
    void DrawBitmap(FT_Bitmap *bitmap, FT_Int x, FT_Int y);
};

#endif /* GLESFTText_hpp */
