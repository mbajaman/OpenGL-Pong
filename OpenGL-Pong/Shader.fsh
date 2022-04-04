//
//  Copyright © Borna Noureddin. All rights reserved.
//

#version 300 es

precision highp float;
in vec4 v_color;
in vec2 texCoordOut;

out vec4 o_fragColor;

uniform sampler2D texSampler;
uniform vec4 ambientComponent;

void main()
{
    vec4 ambient = ambientComponent;
    
    o_fragColor = ambient * texture(texSampler, texCoordOut);
    o_fragColor.a = 1.0;
    o_fragColor = vec4(1,1,1,1);
}

