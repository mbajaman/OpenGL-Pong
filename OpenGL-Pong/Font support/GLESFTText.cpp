//
//  GLESFTText.cpp
//  iostext
//
//  Copyright © Borna Noureddin. All rights reserved.
//

#include "GLESFTText.hpp"

#define WIDTH   256
#define HEIGHT  256

GLESFTText::GLESFTText()
{
    image = (unsigned char *)calloc(WIDTH*HEIGHT*4, sizeof(unsigned char));
}

GLESFTText::~GLESFTText()
{
    free(image);
    image = NULL;
}

void GLESFTText::DrawText(char *fontName, char *text, int fontPtSize, int dpi, float x, float y)
{
    FT_Library library;
    FT_Error error = FT_Init_FreeType(&library);        // initialize library
    FT_Face face;
    error = FT_New_Face(library, fontName, 0, &face);   // create face object
    error = FT_Set_Char_Size(face, fontPtSize * 64, 0, dpi, 0); // set character size
    FT_GlyphSlot slot = face->glyph;
    
    // (x,y) relative to the upper left corner
    FT_Vector pen;
    pen.x = (int)(x*256) * 64;
    pen.y = (HEIGHT - (int)(y*256)) * 64;
    
    size_t numChars = strlen(text);
    int n;
    for (n = 0; n < numChars; n++)
    {
        // set transformation
        FT_Set_Transform(face, NULL, &pen);
        
        // load glyph image into the slot (erase previous one)
        error = FT_Load_Char(face, text[n], FT_LOAD_RENDER);
        if (error)
            continue;   // ignore errors
        
        // now, draw to our target surface (convert position)
        DrawBitmap(&slot->bitmap, slot->bitmap_left, HEIGHT-slot->bitmap_top);
        
        // increment pen position
        pen.x += slot->advance.x;
        pen.y += slot->advance.y;
    }
    
    FT_Done_Face(face);
    FT_Done_FreeType(library);
}

void GLESFTText::DrawBitmap(FT_Bitmap *bitmap, FT_Int x, FT_Int y)
{
    FT_Int  i, j, p, q;
    FT_Int  x_max = x + bitmap->width;
    FT_Int  y_max = y + bitmap->rows;
    
    
    for ( i = x, p = 0; i < x_max; i++, p++ )
    {
        for ( j = y, q = 0; j < y_max; j++, q++ )
        {
            if ( i < 0      || j < 0       ||
                i >= WIDTH || j >= HEIGHT )
                continue;
            image[(HEIGHT-j+1)*WIDTH*4+i*4] = bitmap->buffer[q * bitmap->width + p];
            image[(HEIGHT-j+1)*WIDTH*4+i*4+1] = bitmap->buffer[q * bitmap->width + p];
            image[(HEIGHT-j+1)*WIDTH*4+i*4+2] = bitmap->buffer[q * bitmap->width + p];
            image[(HEIGHT-j+1)*WIDTH*4+i*4+3] = 255;
        }
    }
}

int GLESFTText::GetWidth() { return WIDTH; }

int GLESFTText::GetHeight() { return HEIGHT; }
