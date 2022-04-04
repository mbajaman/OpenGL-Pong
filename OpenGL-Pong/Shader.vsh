//
//  Copyright © Borna Noureddin. All rights reserved.
//

#version 300 es

layout(location = 0) in vec4 position;
layout(location = 1) in vec4 color;
layout(location = 2) in vec2 texCoordIn;

out vec4 v_color;
out vec2 texCoordOut;

uniform mat4 modelViewProjectionMatrix;

void main()
{
    // Simple passthrough shader
    v_color = color;
    
    // Pass through texture coordinate
    texCoordOut = texCoordIn;
    
    gl_Position = modelViewProjectionMatrix * position;
}
