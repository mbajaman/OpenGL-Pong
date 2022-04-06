//
//  Copyright © Borna Noureddin. All rights reserved.
//

#import "Renderer.h"
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "GLESText.h"
#include <chrono>
#include "GLESRenderer.hpp"
#include <Box2D/Box2D.h>
#include <map>

enum {
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_AMBIENT_COMPONENT,
    UNIFORM_TEXTURE,
    UNIFORM_FRAG_TEXT,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Vertex Attributes
enum {
    ATTRIB_POS,
    ATTRIB_COL,
    ATTRIB_TEXTURE_COORDINATE,
    NUM_ATTRIBUTES
};

// Used to make the VBO code more readable
#define BUFFER_OFFSET(i) ((char *)NULL + (i))


@interface Renderer () {
    GLKView *theView;
    GLESRenderer glesRenderer;
    GLuint programObject;
    std::chrono::time_point<std::chrono::steady_clock> lastTime;    // Used to calculated elapsed time

    GLuint paddle1VertexArray, paddle2VertexArray;   // Vertex arrays for Paddles
    GLuint EWallVertexArray, WWallVertexArray;       // Vertex arrays for Walls
    GLuint ballVertexArray;                          // Vertex array for Ball
    
    int numBrickVerts, numBallVerts;
    GLKMatrix4 modelViewProjectionMatrix;
    
    GLKVector4 ambientComponent;
    
    // Vertex array, buffer and vertices for GLESText
    GLuint _textVertexArray;
    GLuint _textVertexBuffers[1];
    float *vertices;
    
    GLESText *_glesText;
}

@end

@implementation Renderer

@synthesize box2d; // Allows to access box2d synthesized variables directly from Swift code

- (void)dealloc {
    // Delete GL buffers
    glDeleteBuffers(3, _textVertexBuffers);
    glDeleteVertexArrays(1, &_textVertexArray);
    glDeleteVertexArrays(1, &paddle1VertexArray);
    glDeleteVertexArrays(1, &paddle2VertexArray);
    glDeleteVertexArrays(1, &EWallVertexArray);
    glDeleteVertexArrays(1, &WWallVertexArray);
    glDeleteVertexArrays(1, &ballVertexArray);
    
    // Delete vertices buffers
    if (vertices)
        free(vertices);
    
    glDeleteProgram(programObject);
}

- (void)setup:(GLKView *)view {
    // Set up OpenGL ES
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!view.context) {
        NSLog(@"Failed to create ES context");
    }
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    theView = view;
    [EAGLContext setCurrentContext:view.context];
    
    // Load shaders
    if (![self setupShaders])
        return;

    // Set background colours and initialize timer
    glClearColor ( 0.11f, 0.11f, 0.69f, 0.0f );
    glEnable(GL_DEPTH_TEST);
    lastTime = std::chrono::steady_clock::now();

    // Initialize Box2D
    box2d = [[CBox2D alloc] init];
    
    // Initialize helper Objective-C++ class for GLES text
    _glesText = [[GLESText alloc] init];
    
}

- (bool)setupShaders {
    // Load shaders
    char *vShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"Shader.vsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.vsh"] pathExtension]] cStringUsingEncoding:1]);
    char *fShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"Shader.fsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.fsh"] pathExtension]] cStringUsingEncoding:1]);
    
    // Bind attribute locations.
    glBindAttribLocation(programObject, ATTRIB_POS, "position");
    glBindAttribLocation(programObject, ATTRIB_TEXTURE_COORDINATE, "texCoordIn");
    
    programObject = glesRenderer.LoadProgram(vShaderStr, fShaderStr);
    if (programObject == 0)
        return false;
    
    // Set up uniform variables
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(programObject, "modelViewProjectionMatrix");
    uniforms[UNIFORM_TEXTURE] = glGetUniformLocation(programObject, "texSampler");
    uniforms[UNIFORM_AMBIENT_COMPONENT] = glGetUniformLocation(programObject, "ambientComponent");
    uniforms[UNIFORM_FRAG_TEXT] = glGetUniformLocation(programObject, "fragText");
    
    // Set up lighting parameters
    ambientComponent = GLKVector4Make(0.0f, 1.0f, 1.0f, 1.0f);

    return true;
}

- (void)loadModels {
    
    // Create VAOs
    glGenVertexArrays(1, &_textVertexArray);
    glBindVertexArray(_textVertexArray);

    // Create VBOs
    glGenBuffers(NUM_ATTRIBUTES, _textVertexBuffers);   // One buffer for each attribute
    
    //[box2d HelloWorld]; // Just a simple HelloWorld test for Box2D. Can be removed.
    int numVerts = glesRenderer.GenTextCanvas(&vertices);
    
    // Set up VBOs...
    glBindBuffer(GL_ARRAY_BUFFER, _textVertexBuffers[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*5*numVerts, vertices, GL_STATIC_DRAW);

    // Position
    glEnableVertexAttribArray(ATTRIB_POS);
    glVertexAttribPointer(ATTRIB_POS, 3, GL_FLOAT, GL_FALSE, 20, BUFFER_OFFSET(0));

    // Texture coordinate
    glEnableVertexAttribArray(ATTRIB_TEXTURE_COORDINATE);
    glVertexAttribPointer(ATTRIB_TEXTURE_COORDINATE, 2, GL_FLOAT, GL_FALSE, 20, BUFFER_OFFSET(12));
    
    // Reset VAO
    glBindVertexArray(0);
    
}

- (void)update {
    // Calculate elapsed time and update Box2D
    auto currentTime = std::chrono::steady_clock::now();
    auto elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime - lastTime).count();
    lastTime = currentTime;
    [box2d Update:elapsedTime/1000.0f];

    // Get all objects from Box2D
    auto objPosList = static_cast<std::map<const char *, b2Vec2> *>([box2d GetObjectPositions]);
    b2Vec2 *theBall = (((*objPosList).find("ball") == (*objPosList).end()) ? nullptr : &(*objPosList)["ball"]);
    b2Vec2 *Paddle1 = (((*objPosList).find("paddle1") == (*objPosList).end()) ? nullptr : &(*objPosList)["paddle1"]);
    b2Vec2 *Paddle2 = (((*objPosList).find("paddle2") == (*objPosList).end()) ? nullptr : &(*objPosList)["paddle2"]);
    b2Vec2 *EWall = (((*objPosList).find("ewall") == (*objPosList).end()) ? nullptr : &(*objPosList)["ewall"]);
    b2Vec2 *WWall = (((*objPosList).find("wwall") == (*objPosList).end()) ? nullptr : &(*objPosList)["wwall"]);

    if (theBall) {
        // Set up VAO/VBO for brick
        glGenVertexArrays(1, &ballVertexArray);
        glBindVertexArray(ballVertexArray);
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        
        // VBO for vertex colours
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[3*(BALL_SPHERE_SEGS+2)];    // triangle fan, so need 3 coords for each vertex; need to close the sphere; and need the center of the sphere
        int k = 0;
        // Center of the sphere
        vertPos[k++] = theBall->x;
        vertPos[k++] = theBall->y;
        vertPos[k++] = 0;
        numBallVerts = 1;
        for (int n=0; n<=BALL_SPHERE_SEGS; n++)
        {
            float const t = 2*M_PI*(float)n/(float)BALL_SPHERE_SEGS;
            //NSLog(@"%f", sin(t));
            vertPos[k++] = theBall->x + sin(t)*3*BALL_RADIUS;
            vertPos[k++] = theBall->y + cos(t)*BALL_RADIUS;
            vertPos[k++] = 0;
            numBallVerts++;
        }
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_POS);
        glVertexAttribPointer(ATTRIB_POS, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        // VBO for vertex colours
        GLfloat vertCol[numBallVerts*3];
        for (k=0; k<numBallVerts*3; k+=3)
        {
            vertCol[k] = 0.0f;
            vertCol[k+1] = 1.0f;
            vertCol[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_COL);
        glVertexAttribPointer(ATTRIB_COL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        glBindVertexArray(0);
    }
    
    if (Paddle1) {
        // Set up VAO/VBO for brick
        glGenVertexArrays(1, &paddle1VertexArray);
        glBindVertexArray(paddle1VertexArray);
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        
        // VBO for vertex positions
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[18];    // 2 triangles x 3 vertices/triangle x 3 coords (x,y,z) per vertex
        int k = 0;
        numBrickVerts = 0;
        vertPos[k++] = Paddle1->x - BRICK_WIDTH/2;
        vertPos[k++] = Paddle1->y + BRICK_HEIGHT/2;
        vertPos[k++] = 10;  // z-value is always set to same value since 2D
        numBrickVerts++;
        vertPos[k++] = Paddle1->x + BRICK_WIDTH/2;
        vertPos[k++] = Paddle1->y + BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = Paddle1->x + BRICK_WIDTH/2;
        vertPos[k++] = Paddle1->y - BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = Paddle1->x - BRICK_WIDTH/2;
        vertPos[k++] = Paddle1->y + BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = Paddle1->x + BRICK_WIDTH/2;
        vertPos[k++] = Paddle1->y - BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = Paddle1->x - BRICK_WIDTH/2;
        vertPos[k++] = Paddle1->y - BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_POS);
        glVertexAttribPointer(ATTRIB_POS, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        // VBO for vertex colours
        GLfloat vertCol[numBrickVerts*3];
        for (k=0; k<numBrickVerts*3; k+=3)
        {
            vertCol[k] = 1.0f;
            vertCol[k+1] = 0.0f;
            vertCol[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_COL);
        glVertexAttribPointer(ATTRIB_COL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        glBindVertexArray(0);
    }
    
    if (Paddle2) {
        // Set up VAO/VBO for brick
        glGenVertexArrays(1, &paddle2VertexArray);
        glBindVertexArray(paddle2VertexArray);
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        
        // VBO for vertex positions
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[18];    // 2 triangles x 3 vertices/triangle x 3 coords (x,y,z) per vertex
        
        int k = 0;
        numBrickVerts = 0;
        vertPos[k++] = Paddle2->x - BRICK_WIDTH/2;
        vertPos[k++] = Paddle2->y + BRICK_HEIGHT/2;
        vertPos[k++] = 10;  // z-value is always set to same value since 2D
        numBrickVerts++;
        vertPos[k++] = Paddle2->x + BRICK_WIDTH/2;
        vertPos[k++] = Paddle2->y + BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = Paddle2->x + BRICK_WIDTH/2;
        vertPos[k++] = Paddle2->y - BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = Paddle2->x - BRICK_WIDTH/2;
        vertPos[k++] = Paddle2->y + BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = Paddle2->x + BRICK_WIDTH/2;
        vertPos[k++] = Paddle2->y - BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = Paddle2->x - BRICK_WIDTH/2;
        vertPos[k++] = Paddle2->y - BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_POS);
        glVertexAttribPointer(ATTRIB_POS, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        // VBO for vertex colours
        GLfloat vertCol[numBrickVerts*3];
        for (k=0; k<numBrickVerts*3; k+=3)
        {
            vertCol[k] = 1.0f;
            vertCol[k+1] = 0.0f;
            vertCol[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_COL);
        glVertexAttribPointer(ATTRIB_COL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        glBindVertexArray(0);
    }
    
    if (EWall) {
        // Set up VAO/VBO for brick
        glGenVertexArrays(1, &EWallVertexArray);
        glBindVertexArray(EWallVertexArray);
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        
        // VBO for vertex positions
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[18];    // 2 triangles x 3 vertices/triangle x 3 coords (x,y,z) per vertex
        
        int k = 0;
        numBrickVerts = 0;
        vertPos[k++] = EWall->x - EWALL_WIDTH/2;
        vertPos[k++] = EWall->y + EWALL_HEIGHT/2;
        vertPos[k++] = 10;  // z-value is always set to same value since 2D
        numBrickVerts++;
        vertPos[k++] = EWall->x + EWALL_WIDTH/2;
        vertPos[k++] = EWall->y + EWALL_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = EWall->x + EWALL_WIDTH/2;
        vertPos[k++] = EWall->y - EWALL_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = EWall->x - EWALL_WIDTH/2;
        vertPos[k++] = EWall->y + EWALL_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = EWall->x + EWALL_WIDTH/2;
        vertPos[k++] = EWall->y - EWALL_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = EWall->x - EWALL_WIDTH/2;
        vertPos[k++] = EWall->y - EWALL_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_POS);
        glVertexAttribPointer(ATTRIB_POS, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        // VBO for vertex colours
        GLfloat vertCol[numBrickVerts*3];
        for (k=0; k<numBrickVerts*3; k+=3)
        {
            vertCol[k] = 1.0f;
            vertCol[k+1] = 0.0f;
            vertCol[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_COL);
        glVertexAttribPointer(ATTRIB_COL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        glBindVertexArray(0);
    }
    
    if (WWall) {
        // Set up VAO/VBO for brick
        glGenVertexArrays(1, &WWallVertexArray);
        glBindVertexArray(WWallVertexArray);
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        
        // VBO for vertex positions
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[18];    // 2 triangles x 3 vertices/triangle x 3 coords (x,y,z) per vertex
        
        int k = 0;
        numBrickVerts = 0;
        vertPos[k++] = WWall->x - WWALL_WIDTH/2;
        vertPos[k++] = WWall->y + WWALL_HEIGHT/2;
        vertPos[k++] = 10;  // z-value is always set to same value since 2D
        numBrickVerts++;
        vertPos[k++] = WWall->x + WWALL_WIDTH/2;
        vertPos[k++] = WWall->y + WWALL_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = WWall->x + WWALL_WIDTH/2;
        vertPos[k++] = WWall->y - WWALL_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = WWall->x - WWALL_WIDTH/2;
        vertPos[k++] = WWall->y + WWALL_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = WWall->x + WWALL_WIDTH/2;
        vertPos[k++] = WWall->y - WWALL_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = WWall->x - WWALL_WIDTH/2;
        vertPos[k++] = WWall->y - WWALL_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_POS);
        glVertexAttribPointer(ATTRIB_POS, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        // VBO for vertex colours
        GLfloat vertCol[numBrickVerts*3];
        for (k=0; k<numBrickVerts*3; k+=3)
        {
            vertCol[k] = 1.0f;
            vertCol[k+1] = 0.0f;
            vertCol[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_COL);
        glVertexAttribPointer(ATTRIB_COL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        glBindVertexArray(0);
    }

    // For now assume simple ortho projection since it's only 2D
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, 800, 0, 600, -10, 100);    // note bounding box matches Box2D world
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
}

- (void)draw:(CGRect)drawRect; {
    // Set up GL for draw calls
    glViewport(0, 0, (int)theView.drawableWidth, (int)theView.drawableHeight);
    glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glUseProgram (programObject);

    // Pass along updated MVP matrix
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, modelViewProjectionMatrix.m);
    glUniform4fv(uniforms[UNIFORM_AMBIENT_COMPONENT], 1, ambientComponent.v);
    
    // Retrieve brick and ball positions from Box2D
    auto objPosList = static_cast<std::map<const char *, b2Vec2> *>([box2d GetObjectPositions]);
    b2Vec2 *theBall = (((*objPosList).find("ball") == (*objPosList).end()) ? nullptr : &(*objPosList)["ball"]);
    b2Vec2 *Paddle1 = (((*objPosList).find("paddle1") == (*objPosList).end()) ? nullptr : &(*objPosList)["paddle1"]);
    b2Vec2 *Paddle2 = (((*objPosList).find("paddle2") == (*objPosList).end()) ? nullptr : &(*objPosList)["paddle2"]);
    b2Vec2 *EWall = (((*objPosList).find("ewall") == (*objPosList).end()) ? nullptr : &(*objPosList)["ewall"]);
    b2Vec2 *WWall = (((*objPosList).find("wwall") == (*objPosList).end()) ? nullptr : &(*objPosList)["wwall"]);

    // Utilize simple frag shader that draw in white
    glUniform1i(uniforms[UNIFORM_FRAG_TEXT], 0);
    
    // Bind each vertex array and call glDrawArrays for each of the objects
    glBindVertexArray(ballVertexArray);
    if (theBall && numBallVerts > 0)
        glDrawArrays(GL_TRIANGLE_FAN, 0, numBallVerts);
    
    glBindVertexArray(paddle1VertexArray);
    if (Paddle1 && numBrickVerts > 0)
        glDrawArrays(GL_TRIANGLES, 0, numBrickVerts);
    
    glBindVertexArray(paddle2VertexArray);
    if (Paddle2 && numBrickVerts > 0)
        glDrawArrays(GL_TRIANGLES, 0, numBrickVerts);
    
    glBindVertexArray(EWallVertexArray);
    if (EWall && numBrickVerts > 0)
        glDrawArrays(GL_TRIANGLES, 0, numBrickVerts);
    
    glBindVertexArray(WWallVertexArray);
    if (WWall && numBrickVerts > 0)
        glDrawArrays(GL_TRIANGLES, 0, numBrickVerts);
    
/* ##################                     ################## */
/* ################## GLES TEXT RENDERING ################## */
/* ##################                     ################## */
    
    // Utilize ambientComponent and texture mapping in frag shader
    glUniform1i(uniforms[UNIFORM_FRAG_TEXT], 1);
    glBindVertexArray(_textVertexArray);
    
    // Use our helper class to draw text to an internal bitmap
    _glesText.posx = 0.0f;
    char *playerText = "PLAYER 1: 0 - PLAYER 2: 0";
    char Player1ScoreChar = box2d.GetPlayer1Score + '0';
    char Player2ScoreChar = box2d.GetPlayer2Score + '0';
    size_t len = strlen(playerText);
    char *Score = new char[len*2+1];
    strcpy(Score, playerText);
    Score[10] = Player1ScoreChar;
    Score[24] = Player2ScoreChar;
    
    [_glesText DrawText:(Score) fontName:@"arial"];
    
    // Now transfer the internal bitmap to a GL texture
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    unsigned char *img = [_glesText GetImage];  // get the internal bitmap
    int w = [_glesText GetWidth];
    int h = [_glesText GetHeight];
    
    // Send the values from the internal bitmap to the GL texture
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, (void *)img);
    
    // Now select that as the active texture
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texName);
    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);

    // Draw the cube (square), with the new texture mapped onto it
    glDrawArrays(GL_TRIANGLES, 0, 6);
}

@end

