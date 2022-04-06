//
//  Copyright © Borna Noureddin. All rights reserved.
//

#ifndef GLESRenderer_hpp
#define GLESRenderer_hpp

#include <stdlib.h>

#include <OpenGLES/ES3/gl.h>

class GLESRenderer {
public:
    char *LoadShaderFile(const char *shaderFileName); // Load shader files into memory
    GLuint LoadShader(GLenum type, const char *shaderSrc); // Compile shaders
    GLuint LoadProgram(const char *vertShaderSrc, const char *fragShaderSrc); // Load OpenGL Program by linking compiled shaders into OpenGL
    int GenTextCanvas(GLfloat **vertices); // Generate Canvas for GLESText - the letters will be drawn on this as a texture
};

#endif /* GLESRenderer_hpp */
