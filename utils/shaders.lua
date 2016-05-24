-- Filename      : ./win32_client/utils/shaders.lua
-- Description   :
-- Last modified : 2016-04-18 13:03

local vertex_shader_position_texture_color = [[
    attribute vec4 a_position;
    attribute vec2 a_texCoord;
    attribute vec4 a_color;
    
    #ifdef GL_ES
    varying lowp vec4 v_fragmentColor;
    varying mediump vec2 v_texCoord;
    #else
    varying vec4 v_fragmentColor;
    varying vec2 v_texCoord;
    #endif
    
    void main()
    {
        gl_Position = CC_MVPMatrix * a_position;
        v_fragmentColor = a_color;
        v_texCoord = a_texCoord;
    }
]]

-- 滤波处理函数
local dip_filter = [[
    vec4 dip_filter( mat3 _filter, sampler2D tex, vec2 xy, vec2 texSize )
    {
        mat3 _filter_x = mat3( -1.0, 0.0, 1.0,
                               -1.0, 0.0, 1.0,
                               -1.0, 0.0, 1.0 );
        mat3 _filter_y = mat3( -1.0, -1.0, -1.0,
                               0.0, 0.0, 0.0,
                               1.0, 1.0, 1.0 );

        vec4 final_color = vec4( 0.0, 0.0, 0.0, 0.0 );

        for( int i=0; i < 3; i++ )
        {
            for( int j=0; j < 3; j++ )
            {
                vec2 xy_new = vec2( xy.x + _filter_x[i][j], xy.y + _filter_y[i][j] );
                vec2 uv = vec2( xy_new.x / texSize.x, xy_new.y / texSize.y );

                vec4 temp_color = texture2D( tex, uv ) * _filter[i][j];
                final_color = final_color + temp_color;
            }
        }

        return final_color;
    }
]]

--- hsl helper
local hsl_helper = [[
            vec3 convertRGBtoHSL(vec3 rgb)
            {
                float h;
                float l;
                float s;
                float r = rgb.r;
                float g = rgb.g;
                float b = rgb.b;
                float max=max(max(r,g),b);
                float min=min(min(r,g),b);
                //----h
                if(max==min){
                    h=0.0;
                }else if(max==r&&g>=b){
                    h=60.0*(g-b)/(max-min)+0.0;
                }else if(max==r&&g<b){
                    h=60.0*(g-b)/(max-min)+360.0;
                }else if(max==g){
                    h=60.0*(b-r)/(max-min)+120.0;
                }else if(max==b){
                    h=60.0*(r-g)/(max-min)+240.0;
                }
                //----l
                l=0.5*(max+min);
                //----s
                if(l==0.0||max==min){
                    s=0.0;
                }else if(0.0<=l&&l<=0.5){
                    s=(max-min)/(2.0*l);
                }else if(l>0.5){
                    s=(max-min)/(2.0-2.0*l);
                }
                return vec3(h,s,l);
            }

            vec3 convertHSLtoRGB( vec3 hsl )
            {
                float h = hsl.x;
                float s = hsl.y;
                float l = hsl.z;
                float q;
                if(l<0.5){
                    q=l*(1.0+s);
                }else if(l>=0.5) {
                    q=l+s-l*s;
                }
                float p=2.0*l-q;
                float hk=h/360.0;
                float t[3];
                t[0]=hk+1.0/3.0;t[1]=hk;t[2]=hk-1.0/3.0;
                for(int i=0;i<3;i++){
                    if(t[i]<0.0)t[i]+=1.0;
                    if(t[i]>1.0)t[i]-=1.0;
                }//got t[i]
                float c[3];
                for(int i=0;i<3;i++){
                    if(t[i]<1.0/6.0){
                        c[i]=p+((q-p)*6.0*t[i]);
                    }else if(1.0/6.0<=t[i]&&t[i]<0.5){
                        c[i]=q;
                    }else if(0.5<=t[i]&&t[i]<2.0/3.0){
                        c[i]=p+((q-p)*6.0*(2.0/3.0-t[i]));
                    }else{
                        c[i]=p;
                    }
                }
                return vec3(c[0],c[1],c[2]);
            }

            vec3 checkHSL(vec3 hsl)
            {
                //h 0~360
                hsl.x = min(360.0, max(0.0, hsl.x));
                //s 0~1
                hsl.y = min(1.0  , max(0.0, hsl.y));
                //l 0~1
                hsl.z = min(1.0  , max(0.0, hsl.z));
                return vec3(hsl);
            }
]]

local filter_param_smooth = [[
    mat3 _filter = mat3( 1.0 / 9.0, 1.0 / 9.0, 1.0 / 9.0,
                         1.0 / 9.0, 1.0 / 9.0, 1.0 / 9.0,
                         1.0 / 9.0, 1.0 / 9.0, 1.0 / 9.0 );
]]
local filter_param_gaussian = [[
    mat3 _filter = mat3( 1.0 / 16.0, 2.0 / 16.0, 1.0 / 16.0,
                         2.0 / 16.0, 4.0 / 16.0, 2.0 / 16.0,
                         1.0 / 16.0, 2.0 / 16.0, 1.0 / 16.0 );
]]
local filter_param_laplacian = [[
    mat3 _filter = mat3( 1.0 / 16.0, 2.0 / 16.0, 1.0 / 16.0,
                         2.0 / 16.0, 4.0 / 16.0, 2.0 / 16.0,
                         1.0 / 16.0, 2.0 / 16.0, 1.0 / 16.0 );
]]
local filter_param_stroke = [[
    mat3 _filter = mat3( -0.5, -1.0, 0.0,
                         1.0, 0.0, 1.0,
                         -0.0, 1.0, 0.5 );
]]

local custom_shaders = {
    {
        shader_name = 'position_texture_color_gray',
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;

            void main()
            {
                vec4 color = v_fragmentColor * texture2D( CC_Texture0, v_texCoord );
                float f = 0.3 * color.r + 0.6 * color.g + 0.1 * color.b;
                gl_FragColor = vec4( f, f, f, color.a );
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_multi_transparent',
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {
                float alpha = 1.0;
                if ( v_texCoord.x < CC_Custom.r ) 
                    alpha *= v_texCoord.x / CC_Custom.r;
                if ( v_texCoord.x > CC_Custom.g )
                    alpha *= (1.0 - v_texCoord.x) / (1.0 - CC_Custom.g);
                if ( v_texCoord.y < CC_Custom.b ) 
                    alpha *= v_texCoord.y / CC_Custom.b;
                if ( v_texCoord.y > CC_Custom.a )
                    alpha *= (1.0 - v_texCoord.y) / (1.0 - CC_Custom.a);

                vec4 tcolor = texture2D( CC_Texture0, v_texCoord );
                gl_FragColor = vec4(tcolor * alpha);
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_change_color',
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {
                vec4 color = v_fragmentColor * texture2D( CC_Texture0, v_texCoord );
                gl_FragColor = vec4( color.r * CC_Custom.x, color.g * CC_Custom.y, color.b * CC_Custom.z, color.a );
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_change_color_ex',
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
        #ifdef GL_ES
        precision highp float;
        #endif

        varying vec4 v_fragmentColor;
        varying vec2 v_texCoord;
        uniform sampler2D CC_Texture0;
        uniform vec4 CC_Custom;

        void main()
        {
            vec4 t_color = texture2D( CC_Texture0, v_texCoord );
            if( t_color.r == 1.0 && t_color.g == 1.0 && t_color.b == 1.0 )
                t_color.rgb = CC_Custom.rgb;

            vec4 color = v_fragmentColor * t_color;
            gl_FragColor = vec4( color.r, color.g, color.b, color.a );
        }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_texture_flow',
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
        #ifdef GL_ES
        precision highp float;
        #endif

        varying vec4 v_fragmentColor;
        varying vec2 v_texCoord;
        uniform sampler2D CC_Texture0;
        uniform vec4 CC_Custom;

        void main()
        {
            vec2 uv = v_texCoord.xy + CC_Custom.xy;
            vec4 color = v_fragmentColor * texture2D( CC_Texture0, uv );
            gl_FragColor = vec4( color.r, color.g, color.b, color.a );
        }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_HDR',                 -- 伪 HDR
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;

            void main()
            {
                vec4 color = v_fragmentColor * texture2D( CC_Texture0, v_texCoord );
                float gray = 0.3 * color.r + 0.59 * color.g + 0.11 * color.b;

                float k = 2.0;
                float b = ( 4.0 * k - 1.0 );
                float a = 1.0 - b;
                float f = gray * ( a * gray + b );

                gl_FragColor = f * color;
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_relief',              -- 浮雕效果
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {
                vec2 upLeftUV = vec2( v_texCoord.x - 1.0 / CC_Custom.x, v_texCoord.y - 1.0 / CC_Custom.y );

                vec4 color = v_fragmentColor * texture2D( CC_Texture0, v_texCoord );
                vec4 upLeftColor = texture2D( CC_Texture0, upLeftUV );

                vec4 delColor = color - upLeftColor;

                float gray = 0.3 * delColor.r + 0.59 * delColor.g + 0.11 * delColor.b;
                gray += 0.5;
                gray *= color.a;

                gl_FragColor = vec4( gray, gray, gray, color.a );
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_mosaics_box',              -- 马赛克
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {
                vec2 intXY = vec2( v_texCoord.x * CC_Custom.x, v_texCoord.y * CC_Custom.y );
                vec2 mXY = vec2( intXY.x / CC_Custom.z * CC_Custom.z, intXY.y / CC_Custom.w * CC_Custom.w );
                vec2 uv = vec2( mXY.x / CC_Custom.x, mXY.y / CC_Custom.y );

                //gl_FragColor = v_fragmentColor * texture2D( CC_Texture0, uv );
                gl_FragColor = texture2D( CC_Texture0, uv );
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_mosaics_round',              -- 马赛克
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {
                vec2 intXY = vec2( v_texCoord.x * CC_Custom.x, v_texCoord.y * CC_Custom.y );
                vec2 mXY = vec2( intXY.x / CC_Custom.z * CC_Custom.z, intXY.y / CC_Custom.w * CC_Custom.w ) + 0.5 * CC_Custom.zw;

                vec2 delXY = mXY - intXY;
                float len = length( delXY );

                if( len < 0.5 * CC_Custom.z )
                {
                    vec2 uv = vec2( mXY.x / CC_Custom.x, mXY.y / CC_Custom.y );
                    gl_FragColor = texture2D( CC_Texture0, uv );
                }
                else
                {
                    gl_FragColor = texture2D( CC_Texture0, v_texCoord );
                }
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_sharpen_fuzzy_smooth',              -- 锐化模糊 平滑
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;
        ]] .. dip_filter .. [[
            void main()
            {
                vec2 intXY = vec2( v_texCoord.x * CC_Custom.x, v_texCoord.y * CC_Custom.y );

        ]] .. filter_param_smooth .. [[

                gl_FragColor = dip_filter( _filter, CC_Texture0, intXY, CC_Custom.xy );
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_sharpen_fuzzy_gaussian',              -- 锐化模糊 高斯
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;
        ]] .. dip_filter .. [[
            void main()
            {
                vec2 intXY = vec2( v_texCoord.x * CC_Custom.x, v_texCoord.y * CC_Custom.y );

        ]] .. filter_param_gaussian .. [[

                gl_FragColor = dip_filter( _filter, CC_Texture0, intXY, CC_Custom.xy );
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_sharpen_fuzzy_laplacian',              -- 锐化模糊 拉普拉斯
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;
        ]] .. dip_filter .. [[
            void main()
            {
                vec2 intXY = vec2( v_texCoord.x * CC_Custom.x, v_texCoord.y * CC_Custom.y );

        ]] .. filter_param_laplacian .. [[

                gl_FragColor = dip_filter( _filter, CC_Texture0, intXY, CC_Custom.xy );
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_stroke',              -- 描边
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;
        ]] .. dip_filter .. [[
            void main()
            {
                vec4 color = v_fragmentColor * texture2D( CC_Texture0, v_texCoord );
                vec2 intXY = vec2( v_texCoord.x * CC_Custom.x, v_texCoord.y * CC_Custom.y );

        ]] .. filter_param_stroke .. [[

                vec4 delColor = dip_filter( _filter, CC_Texture0, intXY, CC_Custom.xy );
                float delGray = 0.3 * delColor.r + 0.59 * delColor.g + 0.11 * delColor.b;

                if( delGray < 0.0 )
                    delGray = -1.0 * delGray;

                delGray = ( 1.0 - delGray ) * color.a;

                gl_FragColor = vec4( delGray, delGray, delGray, color.a );
                //gl_FragColor = vec4( 1.0, 0.0, 0.0, 0.5 );
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_wave',              -- 水波
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;

            void main()
            {
                vec4 color = v_fragmentColor * texture2D( CC_Texture0, v_texCoord );
                float f = 0.3 * color.r + 0.6 * color.g + 0.1 * color.b;
                gl_FragColor = vec4( f, f, f, color.a );
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_zoomblur',              -- 径向模糊
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;

            void main()
            {				      
				// 设置模糊度
				float BlurAmount = 0.09;
   
				vec4 c = vec4(0,0,0,0);
				for (int i = -7; i < 8; i++)
				{
					vec2 uv = vec2(v_texCoord.x + BlurAmount * (float(i) / 14.0), v_texCoord.y);
					c += v_fragmentColor * texture2D(CC_Texture0, uv);
				}
				c /= 15.0;
            
				gl_FragColor = c;
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_zoomblur_scale_white',              -- 径向泛白
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {
				vec2 Center = vec2(CC_Custom.x, CC_Custom.y);

				float time = CC_Custom.z;
				float scaletime = (1.0-time);
				if(scaletime < 0.1) scaletime = 0.1;
      
				// 设置模糊度
				float BlurAmount = 0.2 * time / 0.3; // 0 ~0.2
				if(BlurAmount > 0.2) BlurAmount = 0.2;
   
				vec4 c = vec4(0,0,0,0);
				vec2 uv = v_texCoord - Center;
				for (int i = 0; i < 15; i++)
				{
					float scale = 1.0 + BlurAmount * (float(i) / 14.0);
					c += v_fragmentColor * texture2D(CC_Texture0, uv * scale * scaletime + Center);
				}
				c /= 15.0;
				c += time;
            
				gl_FragColor = c;
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_zoomblur',              -- 径向模糊
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {
				vec2 Center = vec2(CC_Custom.x, CC_Custom.y);
				float BlurAmount = CC_Custom.z; // 模糊度 0 ~0.2
				if(BlurAmount > 0.2) BlurAmount = 0.2;
   
				vec4 c = vec4(0,0,0,0);
				vec2 uv = v_texCoord - Center;
				for (int i = 0; i < 15; i++)
				{
					float scale = 1.0 + BlurAmount * (float(i) / 14.0);
					c += v_fragmentColor * texture2D(CC_Texture0, uv * scale + Center);
				}
				c /= 15.0;
            
				gl_FragColor = c;
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_alpha_glow',              -- 半透明处泛光
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {				   
				vec4 c = texture2D(CC_Texture0, v_texCoord);
				if(c.a > 0.0 && c.a < 1.0)	
				{
					c.r = CC_Custom.x * c.a;
					c.g = CC_Custom.y * c.a;
					c.b = CC_Custom.z * c.a;					
				}
            
				gl_FragColor = v_fragmentColor * c;
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_brightness',              -- 亮度
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {			
				float B = CC_Custom.x; // 亮度
				float C = CC_Custom.y; // 对比度
				float k = tan( (45.0 + 44.0 * C) / 180.0 * 3.1415926 );
		   
				vec4 c = texture2D(CC_Texture0, v_texCoord);
				c.r = (c.r - 0.5 * (1.0 - B)) * k + 0.5 * (1.0 + B);
				c.g = (c.g - 0.5 * (1.0 - B)) * k + 0.5 * (1.0 + B);
				c.b = (c.b - 0.5 * (1.0 - B)) * k + 0.5 * (1.0 + B);
            
				gl_FragColor = v_fragmentColor * c;
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_mask_layer',              -- 遮罩
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;
            uniform vec4 CC_Custom_Ex;

            void main()
            {
                if( ( v_texCoord.x > CC_Custom.x && v_texCoord.x < CC_Custom.x + CC_Custom.z && v_texCoord.y > CC_Custom.y && v_texCoord.y < CC_Custom.y + CC_Custom.w ) ||
                    ( v_texCoord.x > CC_Custom_Ex.x && v_texCoord.x < CC_Custom_Ex.x + CC_Custom_Ex.z && v_texCoord.y > CC_Custom_Ex.y && v_texCoord.y < CC_Custom_Ex.y + CC_Custom_Ex.w ) )
                {
					gl_FragColor = vec4( 0.0, 0.0, 0.0, 0.0 );
                }
				else
				{
					gl_FragColor = v_fragmentColor;
				}
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_replacement',              -- 颜色替换，我是使用在美术数字变色上
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;

            void main()
            {
                vec4 color = texture2D( CC_Texture0, v_texCoord );

                vec4 temp_color = color;
                if( color.r < 10.0 / 255.0 )
                {
                    temp_color = vec4( 0.0, 0.0, 0.0, 1.0 );
                }

                if( color.r > 45.0 / 255.0 && color.r < 55.0 / 255.0 )
                {
                    temp_color = vec4( 0.0, 0.0, 0.0, 0.0 );
                }

                if( color.r > 80.0 / 255.0 && color.r < 250.0 / 255.0 )
                {
                    temp_color.rgb = v_fragmentColor.rgb;
                    temp_color.a = 1.0;
                    //temp_color = vec4( 0.0, 1.0, 0.0, 1.0 );
                }

                gl_FragColor = temp_color;
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        -- 战斗中使用，批量渲染，包括攻击箭头，血条，队长头标，特性等等
        shader_name = 'position_texture_color_fight_hp',
        vertex_shader = [[
            attribute vec4 a_position;
            attribute vec2 a_texCoord;
            attribute vec4 a_color;

            #ifdef GL_ES
            varying lowp vec4 v_fragmentColor;
            varying mediump vec2 v_texCoord;
            varying lowp vec4 v_fragmentPos;
            #else
            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            varying vec4 v_fragmentPos;
            #endif

            void main()
            {
                gl_Position = CC_MVPMatrix * a_position;
                v_fragmentColor = a_color;
                v_texCoord = a_texCoord;
                v_fragmentPos = a_position;
            }
        ]],
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            varying vec4 v_fragmentPos;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {
                if( v_texCoord.y == 0.0 )
                {
                    if( v_texCoord.x >= v_fragmentPos.z )
                    {
                        gl_FragColor.rgb = v_fragmentColor.rgb;
                        gl_FragColor.a = 1.0;
                    }
                    else
                    {
                        if( v_texCoord.x >= v_fragmentColor.a )
                        {
                            gl_FragColor = vec4( 0.8, 0.8, 0.8, 1.0 );
                        }
                        else
                        {
                            gl_FragColor = vec4( 0.0, 0.0, 0.0, 1.0 );
                        }
                    }
                }
                else
                {
                    gl_FragColor = v_fragmentColor * texture2D( CC_Texture0, v_texCoord );
                }
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_fight_head',              -- 战斗中的头像
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;

            void main()
            {
                float len = length( vec2( v_texCoord.x - 0.5, v_texCoord.y - 0.5 ) );
                if( len <= 0.5 )
                {
                    gl_FragColor = texture2D( CC_Texture0, v_texCoord );

                    vec4 cover_color = vec4( 0.0, 0.0, 0.0, 0.0 );
                    if( v_fragmentColor.a < 0.5 )
                    {
                        gl_FragColor.r = gl_FragColor.r + v_fragmentColor.a;
                        gl_FragColor.g = gl_FragColor.g + v_fragmentColor.a;
                        gl_FragColor.b = gl_FragColor.b + v_fragmentColor.a;
                    }
                    else
                    {
                        gl_FragColor = gl_FragColor * v_fragmentColor;
                    }
                }
                else
                {
                    gl_FragColor = vec4( 0.0, 0.0, 0.0, 0.0 );
                }
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_fight_head_enemy',              -- 战斗中的头像
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {
                if( v_texCoord.x > CC_Custom.x && v_texCoord.x < CC_Custom.y && v_texCoord.y > CC_Custom.z && v_texCoord.y < CC_Custom.w )
                {
                    gl_FragColor = texture2D( CC_Texture0, v_texCoord );

                    vec4 cover_color = vec4( 0.0, 0.0, 0.0, 0.0 );
                    if( v_fragmentColor.a < 0.5 )
                    {
                        gl_FragColor.r = gl_FragColor.r + v_fragmentColor.a;
                        gl_FragColor.g = gl_FragColor.g + v_fragmentColor.a;
                        gl_FragColor.b = gl_FragColor.b + v_fragmentColor.a;
                    }
                    else
                    {
                        gl_FragColor = gl_FragColor * v_fragmentColor;
                    }
                }
                else
                {
                    gl_FragColor = vec4( 0.0, 0.0, 0.0, 0.0 );
                }
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_fight_boss_sketch',              -- 战斗 BOSS 剪影
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;

            void main()
            {
                gl_FragColor = texture2D( CC_Texture0, v_texCoord );
                gl_FragColor.r = 0.0;
                gl_FragColor.g = 0.0;
                gl_FragColor.b = 0.0;
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_rich_string_color',              -- 颜色富文本
        vertex_shader = [[
            attribute vec4 a_position;
            attribute vec2 a_texCoord;
            attribute vec4 a_color;
            attribute vec4 a_color2;

            #ifdef GL_ES
            varying lowp vec4 v_fragmentColor;
            varying mediump vec2 v_texCoord;
            varying mediump vec4 v_fragmentColor2;
            #else
            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            varying vec4 v_fragmentColor2;
            #endif

            void main()
            {
                gl_Position = CC_MVPMatrix * a_position;
                v_fragmentColor = a_color;
                v_texCoord = a_texCoord;
                v_fragmentColor2 = a_color2;
            }
        ]],
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            varying vec4 v_fragmentColor2;
            uniform sampler2D CC_Texture0;
            uniform sampler2D CC_Texture1;

            void main()
            {
                vec4 color_0 = texture2D( CC_Texture0, v_texCoord );
                vec4 color_1 = texture2D( CC_Texture1, v_fragmentColor2.xy );
                if( v_fragmentColor2.z < 0.5 && color_0.a > 0.0 && color_0.a < 1.0 )
                {
                    //color_0.rgb = v_fragmentColor.rgb;
                    color_0.r = 1.0;
                    color_0.g = 1.0;
                    color_0.b = 1.0;
                }
                gl_FragColor = v_fragmentColor * color_0 * vec4( color_1.r, color_1.g, color_1.b, 1.0 );
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
            { name = 'a_color2', index = kCCVertexAttrib_Color_2, },
        },
    },
    {
        shader_name = 'position_texture_color_model',
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;

            void main()
            {
                vec4 color = texture2D( CC_Texture0, v_texCoord );

                float r = color.r * ( 1.0 - v_fragmentColor.a ) + v_fragmentColor.r * v_fragmentColor.a;
                float g = color.g * ( 1.0 - v_fragmentColor.a ) + v_fragmentColor.g * v_fragmentColor.a;
                float b = color.b * ( 1.0 - v_fragmentColor.a ) + v_fragmentColor.b * v_fragmentColor.a;

                gl_FragColor.r = r * color.a;
                gl_FragColor.g = g * color.a;
                gl_FragColor.b = b * color.a;
                gl_FragColor.a = color.a;
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_outer_glow',              -- 外发光
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {
                vec4 color = v_fragmentColor * texture2D( CC_Texture0, v_texCoord );

                float param = CC_Custom.a;
                float r = ( ( CC_Custom.r * param ) * ( 1.0 - color.a ) + color.r ) * color.a;
                float g = ( ( CC_Custom.g * param ) * ( 1.0 - color.a ) + color.g ) * color.a;
                float b = ( ( CC_Custom.b * param ) * ( 1.0 - color.a ) + color.b ) * color.a;

                gl_FragColor = vec4( r, g, b, color.a );
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_radar5dim',              -- 5维度雷达图 
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;
            uniform vec4 CC_Custom_Ex;

            // Determine whether point P in triangle ABC
            bool PointinTriangle(vec2 A, vec2 B, vec2 C, vec2 P)
            {
                vec3 cb = vec3(B.x - C.x, B.y - C.y, 0.0);
                vec3 ca = vec3(A.x - C.x, A.y - C.y, 0.0);
                vec3 pa = vec3(A.x - P.x, A.y - P.y, 0.0);
                vec3 pb = vec3(B.x - P.x, B.y - P.y, 0.0);
                vec3 pc = vec3(C.x - P.x, C.y - P.y, 0.0);

                bool inside = false;
                if ((length(cb) > 0.0) && (length(ca) > 0.0))
                    {
                        float crosab_ac = length(cross(cb, ca)) / 2.0;
                        float crospa_pb = length(cross(pa, pb)) / 2.0;
                        float crospb_pc = length(cross(pb, pc)) / 2.0;
                        float crospc_pa = length(cross(pc, pa)) / 2.0;

                        //return (crosab_ac >= (crospa_pb + crospb_pc + crospc_pa - 0.000001)) && (crosab_ac <= (crospa_pb + crospb_pc + crospc_pa + 0.000001));
                        inside = (crosab_ac >= (crospa_pb + crospb_pc + crospc_pa - 0.000001)) && (crosab_ac <= (crospa_pb + crospb_pc + crospc_pa + 0.000001));
                    }
                return inside;
            }

            void main()
            {
                //x，y交换转换成迪卡尔坐标


                float ratios[5]; 
                ratios[0] = CC_Custom.x;
                ratios[1] = CC_Custom.y;
                ratios[2] = CC_Custom.z;
                ratios[3] = CC_Custom.w;
                ratios[4] = CC_Custom_Ex.x;
                
                float const_radarR = 0.5;             //雷达半径
                vec2 const_origin = vec2(0.0, 0.0);  //
                int dim = 5;                          //维度

                //axis_x = (0.5, 0.0);

                float offset_degrees[5];
                offset_degrees[0] = radians(180.0);
                offset_degrees[1] = radians(-108.0);
                offset_degrees[2] = radians(-36.0);
                offset_degrees[3] = radians(36.0);
                offset_degrees[4] = radians(108.0);


                vec2 const_dimAxis[5];
                const_dimAxis[0] = vec2(0.5 * cos(radians(180.0)), -0.5 * sin(radians(180.0)));
                const_dimAxis[1] = vec2(0.5 * cos(radians(108.0)), -0.5 * sin(radians(108.0)));
                const_dimAxis[2] = vec2(0.5 * cos(radians(36.0)), -0.5 * sin(radians(36.0)));
                const_dimAxis[3] = vec2(0.5 * cos(radians(-36.0)), -0.5 * sin(radians(-36.0)));
                const_dimAxis[4] = vec2(0.5 * cos(radians(-108.0)), -0.5 * sin(radians(-108.0)));

                vec2 real_values[5];
                real_values[0] = vec2(const_dimAxis[0].x * ratios[0], const_dimAxis[0].y * ratios[0]);
                real_values[1] = vec2(const_dimAxis[1].x * ratios[1], const_dimAxis[1].y * ratios[1]);
                real_values[2] = vec2(const_dimAxis[2].x * ratios[2], const_dimAxis[2].y * ratios[2]);
                real_values[3] = vec2(const_dimAxis[3].x * ratios[3], const_dimAxis[3].y * ratios[3]);
                real_values[4] = vec2(const_dimAxis[4].x * ratios[4], const_dimAxis[4].y * ratios[4]);

                vec2 this_p = vec2(v_texCoord.y - 0.5, v_texCoord.x - 0.5);
                float angel = 0.0;

                if ((this_p.x != 0.0) && (this_p.y != 0.0))
                    angel = atan(this_p.y, this_p.x);
                else
                    angel = 0.0;

                bool isInside = false;

                if ((angel >= radians(-180.0)) && (angel < offset_degrees[1]))
                    isInside = PointinTriangle(real_values[0], real_values[1], const_origin, this_p);
                else if((angel >= offset_degrees[1]) && (angel < offset_degrees[2]))
                    isInside = PointinTriangle(real_values[1], real_values[2], const_origin, this_p);
                else if((angel >= offset_degrees[2]) && (angel < offset_degrees[3]))
                    isInside = PointinTriangle(real_values[2], real_values[3], const_origin, this_p);
                else if((angel >= offset_degrees[3]) && (angel < offset_degrees[4]))
                    isInside = PointinTriangle(real_values[3], real_values[4], const_origin, this_p);
                else if((angel >= offset_degrees[4]) && (angel < offset_degrees[0]))
                    isInside = PointinTriangle(real_values[4], real_values[0], const_origin, this_p);
                    
                // 返回颜色值
                if( !isInside )
                {
                    //vec4 color = texture2D( CC_Texture0, v_texCoord );
                    //color.w = 0.0;
                    gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
                }
                else
                {
                    vec4 color = v_fragmentColor;  // * texture2D( CC_Texture0, v_texCoord ); 
                    gl_FragColor = color * (1.0 + length(this_p) / const_radarR);
                }
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_whitening',
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;

            void main()
            {
                vec4 color = v_fragmentColor * texture2D( CC_Texture0, v_texCoord );
                gl_FragColor.rgba = vec4( color.a, color.a, color.a, color.a );
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_scanner_light',              -- 扫光
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[

            varying vec2 v_texCoord;
            varying vec4 v_fragmentColor;
            varying vec4 v_fragmentColor2;
            uniform sampler2D CC_Texture0;
            uniform sampler2D CC_Texture1;

            uniform vec4 CC_Custom;
            uniform vec4 CC_Custom_Ex;

            void main()
            {
                vec2 this_p = v_texCoord;
                //vec4 color = texture2D( CC_Texture1, v_fragmentColor2.xy);
                gl_FragColor = texture2D( CC_Texture0, v_texCoord );

                float x1 = CC_Custom.x;
                float y1 = CC_Custom.y;
                float k1 = CC_Custom.z;
                float b1 = CC_Custom.w;

                float x2 = CC_Custom_Ex.x;
                float y2 = CC_Custom_Ex.y;
                float k2 = CC_Custom_Ex.z;
                float b2 = CC_Custom_Ex.w;

                float limit1 = k1 * (this_p.x - x1) + b1 + y1;
                float limit2 = k2 * (this_p.x - x2) + b2 + y2;

                if ((min(limit1, limit2) < this_p.y) && (this_p.y < max(limit1, limit2)) && (gl_FragColor.r + gl_FragColor.g + gl_FragColor.b > 0.3))
                    {
                        //gl_FragColor = v_fragmentColor * texture2D(CC_Texture0, v_texCoord) * vec4(color.r, color.g, color.b, 1.0);
                        //gl_FragColor = v_fragmentColor * texture2D(CC_Texture0, v_texCoord) * vec4(255.0, 255.0, 255.0, 1.0);
                        float r = 255.0 * gl_FragColor.a;
                        float g = 255.0 * gl_FragColor.a;
                        float b = 255.0 * gl_FragColor.a;
                        gl_FragColor = vec4(r, g, b, 1.0);
                        //gl_FragColor = vec4(color.r, color.g, color.b, 1.0);
                        //gl_FragColor = color;
                    }
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_avatar_sketch',              -- 彩色剪影 用于进化动画
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {
                gl_FragColor = texture2D( CC_Texture0, v_texCoord );
                gl_FragColor.a = gl_FragColor.a * v_fragmentColor.a;
                gl_FragColor.r = v_fragmentColor.r * gl_FragColor.a;
                gl_FragColor.g = v_fragmentColor.g * gl_FragColor.a;
                gl_FragColor.b = v_fragmentColor.b * gl_FragColor.a;

            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_equip_quality',              -- 装备品质背景
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {
                float dis = distance( vec2( 0.5, 1.4 ), v_texCoord );
                //float temp = dis / 0.5;
                float temp = 1.4 / dis;
                if( temp > 2.0 )
                    temp = 2.0;
                vec4 temp_color = v_fragmentColor * temp;

                gl_FragColor = temp_color * texture2D( CC_Texture0, v_texCoord );
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_lineup_quality',              -- 编队里面的品质背景
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {
                gl_FragColor = v_fragmentColor * texture2D( CC_Texture0, v_texCoord ) * 2.0;
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_lineup_portrait_quality',              -- 编队肖像详情背景里面的品质背景
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {
                float min = 0.8;
                float max = 0.9;
                float temp = v_texCoord.y * ( max - min ) + min;
                //temp = ( temp - min ) / ( max - min ) + min;

                vec4 color = v_fragmentColor * temp;

                gl_FragColor = color * texture2D( CC_Texture0, v_texCoord ) * 3.3;
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_mall_good_count_down',            --商店的倒计时
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[

            varying vec2 v_texCoord;
            varying vec4 v_fragmentColor;
            varying vec4 v_fragmentColor2;
            uniform sampler2D CC_Texture0;

            uniform vec4 CC_Custom;

            void main()
            {
                vec2 this_p = v_texCoord;
                gl_FragColor = texture2D( CC_Texture0, v_texCoord );

                float pi = radians(180.0);
                float p  = CC_Custom.x * pi * 2.0;
                float offset = 0.5;

                float x_trans = this_p.x - 0.5;
                float y_trans = 0.5 - this_p.y;

                float angle;

                if ( ( y_trans > 0.0 ) && ( x_trans > 0.0 ) ) 
                {
                    angle = atan( y_trans / x_trans );
                }
                if ( ( y_trans > 0.0 ) && ( x_trans < 0.0 ) ) 
                {
                    angle = atan( -x_trans / y_trans ) + 0.5 * pi;
                }
                if ( ( y_trans < 0.0 ) && ( x_trans < 0.0 ) ) 
                {
                    angle = atan( y_trans / x_trans ) + 1.0 * pi;
                }
                if ( ( y_trans < 0.0 ) && ( x_trans > 0.0 ) ) 
                {
                    angle = atan( -x_trans / y_trans ) + 1.5 * pi;
                }

                angle = angle - offset * pi;
                if ( angle < 0.0 )
                    angle = 2.0 * pi + angle;

                if ( angle < p )
                {
                    gl_FragColor = v_fragmentColor * texture2D( CC_Texture0, v_texCoord );
                }
                else
                {
                    gl_FragColor = vec4( 0.0, 0.0, 0.0, 0.0 );
                }

                //if ( ( angle < p ) && ( gl_FragColor.r + gl_FragColor.g + gl_FragColor.b > 0.3 ) )
                //{
                //    vec4 color = v_fragmentColor * texture2D( CC_Texture0, v_texCoord );
                //    float f = 0.3 * color.r + 0.6 * color.g + 0.1 * color.b;
                //    gl_FragColor = vec4( f, f, f, color.a );
                //}
                //else
                //{
                //    gl_FragColor = vec4( 0.0, 0.0, 0.0, 0.0 );
                //}
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_overlay',                     -- PS 中的叠加模式 : B <= 0.5: C=2*A*B; B > 0.5: C=1-2*(1-A)*(1-B)
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {
                vec4 tex_color = texture2D( CC_Texture0, v_texCoord );
                float a = tex_color.a * v_fragmentColor.a;
                float f = 0.3 * tex_color.r + 0.6 * tex_color.g + 0.1 * tex_color.b;

                if( f <= 0.5 )
                {
                    gl_FragColor.rgb = 2.0 * f * v_fragmentColor.rgb;
                }
                else
                {
                    gl_FragColor.rgb = 1.0 - 2.0 * ( 1.0 - f ) * ( 1.0 - v_fragmentColor.rgb );
                }

                gl_FragColor.rgb = gl_FragColor.rgb * a;
                gl_FragColor.a = a;

                //vec4 tex_color = texture2D( CC_Texture0, v_texCoord ) * v_fragmentColor;
                //float f = 0.3 * tex_color.r + 0.6 * tex_color.g + 0.1 * tex_color.b;

                //if( f <= 0.5 )
                //{
                //    gl_FragColor.rgb = 2.0 * f * CC_Custom.rgb;
                //}
                //else
                //{
                //    gl_FragColor.rgb = 1.0 - 2.0 * ( 1.0 - f ) * ( 1.0 - CC_Custom.rgb );
                //}

                //gl_FragColor.a = tex_color.a;
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_overlay_ex',                     -- PS 中的叠加模式 : B <= 0.5: C=2*A*B; B > 0.5: C=1-2*(1-A)*(1-B)
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;
            uniform vec4 CC_Custom_Ex;

            void main()
            {
                vec4 tex_color = texture2D( CC_Texture0, v_texCoord ) * v_fragmentColor;
                float f = 0.3 * tex_color.r + 0.6 * tex_color.g + 0.1 * tex_color.b;

                // 根据美术的需求，这个叠加的颜色，可能有个线性渐变的过程，从上而下的渐变
                // 其中 CC_Custom.a 是顶部的纹理坐标 v，CC_Custom_Ex.a 是底部的纹理坐标 v 
                // CC_Custom.rgb 就是顶部渐变颜色，CC_Custom_Ex.rgb 就是底部渐变颜色
                float temp = ( v_texCoord.y - CC_Custom.a ) / ( CC_Custom_Ex.a - CC_Custom.a );
                vec4 temp_color = vec4( CC_Custom.rgb * temp + CC_Custom_Ex.rgb * ( 1.0 - temp ), 1.0 );

                if( f <= 0.5 )
                {
                    gl_FragColor.rgb = 2.0 * f * temp_color.rgb;
                }
                else
                {
                    gl_FragColor.rgb = 1.0 - 2.0 * ( 1.0 - f ) * ( 1.0 - temp_color.rgb );
                }

                gl_FragColor.a = tex_color.a;
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_overlay_icon_batch',                    -- PS 中的叠加模式 : B <= 0.5: C=2*A*B; B > 0.5: C=1-2*(1-A)*(1-B)
        vertex_shader = [[
            attribute vec4 a_position;
            attribute vec2 a_texCoord;
            attribute vec4 a_color;
            attribute vec4 a_color2;

            #ifdef GL_ES
            varying lowp vec4 v_fragmentColor;
            varying mediump vec2 v_texCoord;
            varying mediump vec4 v_fragmentColor2;
            #else
            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            varying vec4 v_fragmentColor2;
            #endif

            void main()
            {
                gl_Position = CC_MVPMatrix * a_position;
                v_fragmentColor = a_color;
                v_texCoord = a_texCoord;
                v_fragmentColor2 = a_color2;
            }
        ]],
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            varying vec4 v_fragmentColor2;
            uniform sampler2D CC_Texture0;

            void main()
            {
                vec4 tex_color = texture2D( CC_Texture0, v_texCoord );
                if( v_fragmentColor2.r > 0.0 )
                {
                    float a = tex_color.a * v_fragmentColor.a;
                    float f = 0.3 * tex_color.r + 0.6 * tex_color.g + 0.1 * tex_color.b;

                    if( f <= 0.5 )
                    {
                        gl_FragColor.rgb = 2.0 * f * v_fragmentColor.rgb;
                    }
                    else
                    {
                        gl_FragColor.rgb = 1.0 - 2.0 * ( 1.0 - f ) * ( 1.0 - v_fragmentColor.rgb );
                    }

                    gl_FragColor.rgb = gl_FragColor.rgb * a;
                    gl_FragColor.a = a;
                }
                else
                {
                    gl_FragColor = tex_color * v_fragmentColor;
                }

                if( v_fragmentColor2.g > 0.0 )
                {
                    float f = 0.3 * gl_FragColor.r + 0.6 * gl_FragColor.g + 0.1 * gl_FragColor.b;
                    gl_FragColor.rgb = vec3( f, f, f );
                }
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_glare',                     -- PS 中的强光模式 : A <= 0.5 : C = 2 * A * B;  A > 0.5: C = 1 - 2 * ( 1 - A ) * ( 1 - B )
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {
                vec4 tex_color = texture2D( CC_Texture0, v_texCoord ) * v_fragmentColor;
                float f = 0.3 * tex_color.r + 0.6 * tex_color.g + 0.1 * tex_color.b;
                float f_a = 0.3 * CC_Custom.r + 0.6 * CC_Custom.g + 0.1 * CC_Custom.b;

                if( f_a <= 0.5 )
                {
                    gl_FragColor.rgb = 2.0 * f * CC_Custom.rgb;
                }
                else
                {
                    gl_FragColor.rgb = 1.0 - 2.0 * ( 1.0 - f ) * ( 1.0 - CC_Custom.rgb );
                }

                gl_FragColor.a = tex_color.a;
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_layout_lineup',                     -- 在战前布阵界面使用的，左边和右边的背景格子，使用不一样的颜色
        vertex_shader = [[
            attribute vec4 a_position;
            attribute vec2 a_texCoord;
            attribute vec4 a_color;
            attribute vec4 a_color2;

            #ifdef GL_ES
            varying lowp vec4 v_fragmentColor;
            varying mediump vec2 v_texCoord;
            varying lowp vec4 v_fragmentPos;
            varying mediump vec4 v_fragmentColor2;
            #else
            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            varying vec4 v_fragmentPos;
            varying vec4 v_fragmentColor2;
            #endif

            void main()
            {
                gl_Position = CC_MVPMatrix * a_position;
                v_fragmentColor = a_color;
                v_texCoord = a_texCoord;
                v_fragmentPos = a_position;
                v_fragmentColor2 = a_color2;
            }
        ]],
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            varying vec4 v_fragmentPos;
            varying vec4 v_fragmentColor2;
            uniform sampler2D CC_Texture0;

            void main()
            {
                vec4 tex_color = texture2D( CC_Texture0, v_texCoord );

                float render_z = fract( v_fragmentPos.z );
                if( render_z < 0.1 )
                {
                    gl_FragColor = tex_color * v_fragmentColor;
                }
                else
                {
                    vec4 depth_red = vec4( 47.0 / 255.0, 2.0 / 255.0, 24.0 / 255.0, 204.0 / 255.0 );
                    vec4 light_red = vec4( 111.0 / 255.0, 5.0 / 255.0, 55.0 / 255.0, 178.0 / 255.0 );
                    vec4 depth_blue = vec4( 11.0 / 255.0, 11.0 / 255.0, 37.0 / 255.0, 204.0 / 255.0 );
                    vec4 light_blue = vec4( 25.0 / 255.0, 26.0 / 255.0, 87.0 / 255.0, 178.0 / 255.0 );

                    float alpha = 1.0;
                    if( render_z < 0.2 )
                    {
                        gl_FragColor.rgb = depth_red.rgb;
                        alpha = 0.8;
                    }
                    else
                    {
                        if( render_z < 0.3 )
                        {
                            gl_FragColor.rgb = light_red.rgb;
                            alpha = 0.7;
                        }
                        else
                        {
                            if( render_z < 0.8 )
                            {
                                gl_FragColor.rgb = depth_blue.rgb;
                                alpha = 0.8;
                            }
                            else
                            {
                                if( render_z < 0.9 )
                                {
                                    gl_FragColor.rgb = light_blue.rgb;
                                    alpha = 0.7;
                                }
                                else
                                {
                                    alpha = 0.7;
                                    float u = v_fragmentColor2.x;
                                    float v = v_fragmentColor2.y;
                                    if( u + v < 1.0 )
                                    {
                                        gl_FragColor.rgb = light_red.rgb;
                                    }
                                    else
                                    {
                                        gl_FragColor.rgb = light_blue.rgb;
                                    }
                                }
                            }
                        }
                    }

                    if( tex_color.a > 0.5 )
                    {
                        gl_FragColor.a = tex_color.a * alpha;
                    }
                    else
                    {
                        gl_FragColor.a = 0.0;
                        gl_FragColor.r = 0.0;
                        gl_FragColor.g = 0.0;
                        gl_FragColor.b = 0.0;
                    }
                }
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
            { name = 'a_color2', index = kCCVertexAttrib_Color_2, },
        },
    },
    {
        shader_name = 'position_texture_color_local_hight_light',                -- 全局蒙黑局部高光
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec2 v_texCoord;
            varying vec4 v_fragmentColor;
            varying vec4 v_fragmentColor2;
            uniform sampler2D CC_Texture0;

            uniform vec4 CC_Custom;
            uniform vec4 CC_Custom_Ex;

            void main()
            {
                float _r = 0.0;
                float _g = 0.0;
                float _b = 0.0;
                float _a = 220.0 / 255.0;

                vec2 this_p = v_texCoord;

                float x_position  = CC_Custom.x;
                float y_position  = CC_Custom.y;
                float width       = CC_Custom.z;
                float height      = CC_Custom.w;

                float gap         = CC_Custom_Ex.x;

                //float x_gap = ;
                //float y_gap = ;

                float _d = pow(gap, 2.0);
                float _t = pow(abs(x_position - this_p.x * width ), 2.0) + pow(abs(y_position - this_p.y * height), 2.0);

                if (_t < _d) {
                    float a = _a * pow(pow(_t / _d, 0.5), 0.5);
                    gl_FragColor = vec4( _r, _g, _b, a );
                }
                else {
                    gl_FragColor = vec4( _r, _g, _b, _a );
                }
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_welcome',                     -- 首页的批量渲染使用的 shader
        vertex_shader = [[
            attribute vec4 a_position;
            attribute vec2 a_texCoord;
            attribute vec4 a_color;

            #ifdef GL_ES
            varying lowp vec4 v_fragmentColor;
            varying mediump vec2 v_texCoord;
            varying lowp vec4 v_fragmentPos;
            #else
            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            varying vec4 v_fragmentPos;
            #endif

            void main()
            {
                gl_Position = CC_MVPMatrix * a_position;
                v_fragmentColor = a_color;
                v_texCoord = a_texCoord;
                v_fragmentPos = a_position;
            }
        ]],
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            varying vec4 v_fragmentPos;
            uniform sampler2D CC_Texture0;

            void main()
            {
                if( v_fragmentPos.z > 0.0 )
                {
                    vec4 color = v_fragmentColor * texture2D( CC_Texture0, v_texCoord );
                    float f = 0.3 * color.r + 0.6 * color.g + 0.1 * color.b;
                    gl_FragColor = vec4( f, f, f, color.a );
                }
                else
                {
                    gl_FragColor = v_fragmentColor * texture2D( CC_Texture0, v_texCoord );
                }
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_ring_exp',                -- 圆环经验条
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {
                float dis = distance( v_texCoord, vec2( 0.5, 0.5 ) );
                if( dis >= CC_Custom.r && dis <= CC_Custom.g )
                {
                    float angle = degrees( atan( ( v_texCoord.y - 0.5 ) / ( v_texCoord.x - 0.5 ) ) );
                    if( v_texCoord.x > 0.5 && v_texCoord.y > 0.5 )      //
                    {
                        angle = angle;
                    }
                    else
                    {
                        if( v_texCoord.x < 0.5 && v_texCoord.y > 0.5 )      //
                        {
                            angle = angle + 180.0;
                        }
                        else
                        {
                            if( v_texCoord.x < 0.5 && v_texCoord.y < 0.5 )      //
                            {
                                angle = angle + 180.0;
                            }
                            else
                            {
                                if( v_texCoord.x > 0.5 && v_texCoord.y < 0.5 )      //
                                {
                                    angle = angle + 360.0;
                                }
                                else
                                {
                                    angle = angle;
                                }
                            }
                        }
                    }
                    angle = 360.0 - angle;
                    float fTempAngle = ( 1.0 - CC_Custom.b ) * 270.0;
                    if( angle > 60.0 && angle < ( 330.0 - fTempAngle ) )
                    {
                        gl_FragColor = v_fragmentColor * texture2D( CC_Texture0, v_texCoord );
                    }
                    else
                    {
                        gl_FragColor = vec4( 0.0, 0.0, 0.0, 0.0 );
                    }
                }
                else
                {
                    gl_FragColor = vec4( 0.0, 0.0, 0.0, 0.0 );
                }
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_head_icon',                -- 左上角圆形头像
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {
                float dis = distance( v_texCoord, vec2( 0.5, 0.5 ) );
                if( dis <= CC_Custom.r )
                {
                    gl_FragColor = texture2D( CC_Texture0, v_texCoord );
                }
                else
                {
                    gl_FragColor = vec4( 0.0, 0.0, 0.0, 0.0 );
                }
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_x_mask_layer',              -- 遮罩
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;
            uniform vec4 CC_Custom_Ex;

            void main()
            {
                vec4 color = v_fragmentColor * texture2D( CC_Texture0, v_texCoord );

                float gap   = CC_Custom.w;
                float width = CC_Custom.z;

                float l = CC_Custom.x;
                float r = CC_Custom.y;

                float p = v_texCoord.x * width;
                float offset = 1.0;

                if ( p < l ) {
                    if ( l - p > gap )
                        offset = 0.0;
                    else
                        offset = (gap - l + p) / gap;
                }

                if ( (width - p) < r ) {
                    if ( r - (width - p) > gap )
                        offset = 0.0;
                    else
                        offset = (gap - r + (width - p)) / gap;
                }

                if ( offset > 1.0 )
                    offset = 1.0;

                if ( offset < 0.0 )
                    offset = 0.0;

                gl_FragColor = vec4( color.r * offset, color.g * offset, color.b * offset, color.a * offset );
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_ellipse_mask_layer',              -- 遮罩
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;
            uniform vec4 CC_Custom_Ex;

            void main()
            {
                float x = v_texCoord.x;         // 点的坐标
                float y = v_texCoord.y;

                float x1 = CC_Custom.x;         // 椭圆原点坐标
                float y1 = CC_Custom.y;
                float a = CC_Custom.z;          // 椭圆长短半径
                float b = CC_Custom.w;

                float temp_1 = 0.5;

                float dis = ( ( x - x1 ) * ( x - x1 ) ) / ( a * a ) + ( ( y - y1 ) * ( y - y1 ) ) / ( b * b );
                if( dis < 1.0 )
                {
                    if( dis > temp_1 )
                    {
                        gl_FragColor = v_fragmentColor * ( ( dis - temp_1 ) / ( 1.0 - temp_1 ) );
                    }
                    else
                    {
                        gl_FragColor = vec4( 0.0, 0.0, 0.0, 0.0 );
                    }
                }
                else
                {
                    float x2 = CC_Custom_Ex.x;         // 椭圆原点坐标
                    float y2 = CC_Custom_Ex.y;
                    float a2 = CC_Custom_Ex.z;          // 椭圆长短半径
                    float b2 = CC_Custom_Ex.w;

                    float dis2 = ( ( x - x2 ) * ( x - x2 ) ) / ( a2 * a2 ) + ( ( y - y2 ) * ( y - y2 ) ) / ( b2 * b2 );
                    if( dis2 < 1.0 )
                    {
                        if( dis2 > temp_1 )
                        {
                            gl_FragColor = v_fragmentColor * ( ( dis2 - temp_1 ) / ( 1.0 - temp_1 ) );
                        }
                        else
                        {
                            gl_FragColor = vec4( 0.0, 0.0, 0.0, 0.0 );
                        }
                    }
                    else
                    {
                        gl_FragColor = v_fragmentColor;
                    }
                }
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_overlay_2',                     -- 灰阶图渲染，洗练
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {
                vec4 tex_color = texture2D( CC_Texture0, v_texCoord ) * v_fragmentColor;
                float f = 0.3 * tex_color.r + 0.6 * tex_color.g + 0.1 * tex_color.b;

                if( f <= 0.5 )
                {
                    gl_FragColor.rgb = 2.0 * f * CC_Custom.rgb;
                }
                else
                {
                    gl_FragColor.rgb = 1.0 - 2.0 * ( 1.0 - f ) * ( 1.0 - CC_Custom.rgb );
                }

                gl_FragColor.a = tex_color.a;
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_circle',              -- 圆形遮罩
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;

            void main()
            {
                float dis = distance( v_texCoord, vec2( 0.5, 0.5 ) );
                if( dis < 0.5 )
                {
                    gl_FragColor = v_fragmentColor;
                }
                else
                {
                    gl_FragColor = vec4(0.0,0.0,0.0,0.0);
                }
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_HSL',              -- HSV(HSB)模型
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

    ]] .. hsl_helper .. [[

            void main()
            {

                float flag = CC_Custom.w;
                vec4 texColor = texture2D(CC_Texture0, v_texCoord);

                //convert rgb to hsl
                vec3 hslA = convertRGBtoHSL(texColor.rgb);

                vec3 finalHSL = hslA;
                if(flag == 0.0) // Saturation: HcScYc =HASBYA
                {
                    vec3 hslB = convertRGBtoHSL(vec3(0.0,0.0,0.0));
                    hslB      += CC_Custom.xyz;
                    hslB       = checkHSL(hslB);
                    finalHSL.x = hslA.x;
                    finalHSL.y = hslB.y;
                    finalHSL.z = hslA.z;
                    //finalHSL  += CC_Custom.xyz;
                    //finalHSL   = checkHSL(finalHSL);
                }

                gl_FragColor.rgb = convertHSLtoRGB(finalHSL);
                gl_FragColor.a   = texColor.a;
            } 
         ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_avatar_sketch2',              -- 剪影 + 彩色描边 + 透明消失
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;    // x:width, y:height, z:分割线, w:剪影透明度
            uniform vec4 CC_Custom_Ex; // 描边rgb
        ]] .. dip_filter .. [[
            void main()
            {
                vec2 intXY = vec2( v_texCoord.x * CC_Custom.x, v_texCoord.y * CC_Custom.y );

        ]] .. filter_param_smooth .. [[

                vec4 xColor  = dip_filter( _filter, CC_Texture0, intXY, CC_Custom.xy );

                vec4 color = CC_Custom_Ex;

                if ( v_texCoord.y > CC_Custom.z )
                    {
                        gl_FragColor = texture2D( CC_Texture0, v_texCoord );
                    }
                else
                    {
                        if ( xColor.a < 1.0 )
                            {
                                gl_FragColor.a = xColor.a;
                                gl_FragColor.r = (1.0 - xColor.a) * xColor.a;
                                gl_FragColor.g = (1.0 - xColor.a) * xColor.a;
                                gl_FragColor.b = (1.0 - xColor.a) * xColor.a;
                                gl_FragColor   = gl_FragColor * color;
                            }
                        else
                            {
                                gl_FragColor.a = xColor.a;
                                gl_FragColor.r = 0.0 * xColor.a;
                                gl_FragColor.g = 0.0 * xColor.a;
                                gl_FragColor.b = 0.0 * xColor.a;
                            }

                        gl_FragColor.a = CC_Custom.w * gl_FragColor.a;
                        gl_FragColor.r = CC_Custom.w * gl_FragColor.r;
                        gl_FragColor.g = CC_Custom.w * gl_FragColor.g;
                        gl_FragColor.b = CC_Custom.w * gl_FragColor.b;
                    }

            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_progress',              -- 进度变色
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[

            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;    // 进度条rgba
            uniform vec4 CC_Custom_Ex; // x: 进度
            void main()
            {
                float limit_value = 200.0;
                vec4 color_gray = vec4( 206.0/255.0, 198.0/255.0, 211.0/255.0, 255.0/255.0 );

                vec4 color = v_fragmentColor * texture2D( CC_Texture0, v_texCoord );
                gl_FragColor = color * color_gray;

                if ( color.a > 0.001 ) {
                    if ( v_texCoord.x <= CC_Custom_Ex.x ) {
                        gl_FragColor = color * CC_Custom;
                    }
                }
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_test',
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;
            uniform vec4 CC_Custom_Ex;

            void main()
            {
                if( distance( v_texCoord, vec2( 0.5, 0.5 ) ) <= 0.5 ) {
                    gl_FragColor = vec4( 0.0, 0.3, 0.3, 1.0 );
                } else {
                    gl_FragColor = vec4( 0.0, 0.0, 0.0, 0.0 );
                }
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_cut_out_for_spirit',              -- 精灵2精灵图标的叠加裁剪
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[

            varying vec2 v_texCoord;
            varying vec4 v_fragmentColor;
            varying vec4 v_fragmentColor2;
            uniform sampler2D CC_Texture0; // 背景
            uniform sampler2D CC_Texture1; // 图标

            uniform vec4 CC_Custom;
            uniform vec4 CC_Custom_Ex;

            void main()
            {
                float texture_1_w = CC_Custom_Ex.x;
                float texture_1_h = CC_Custom_Ex.y;
                float texture_2_w = CC_Custom_Ex.z;
                float texture_2_h = CC_Custom_Ex.w;

                float bg_r = CC_Custom.x;
                float bg_g = CC_Custom.y;
                float bg_b = CC_Custom.z;
                float cut_out_flag = CC_Custom.w; // 小于1就不裁剪, 只叠加

                vec4 color_0 = texture2D( CC_Texture0, v_texCoord ) * vec4( bg_r, bg_g, bg_b, 1.0 ); // 背景color
                vec4 color_1;                                        // 图标color

                // 以右下角为对齐角，切割左上
                float v_x = 1.0 - ( 1.0 - v_texCoord.x ) * texture_1_w / texture_2_w;
                float v_y = 1.0 - ( 1.0 - v_texCoord.y ) * texture_1_h / texture_2_h;

                if ( v_x < 0.0 || v_x > 1.0 || v_y < 0.0 || v_y > 1.0 )
                    // 超边使用vec4( 0.0, 0.0, 0.0, 0.0 )
                    color_1 = vec4( 0.0, 0.0, 0.0, 0.0 );
                else
                    // 取到背景的color
                    color_1 = texture2D( CC_Texture1, vec2( v_x, v_y) );

                if ( color_0.a > 0.0 || cut_out_flag < 1.0 ) {
                    // 背景可见，图标可见
                    if ( color_1.a < 1.0 ) {
                        gl_FragColor = v_fragmentColor * ( color_1 * color_1.a + color_0 * ( 1.0 - color_1.a ) );
                    } else {
                        gl_FragColor = v_fragmentColor * color_1;
                    }
                } else {
                    // 否则不显示
                    gl_FragColor = v_fragmentColor * vec4( 0.0, 0.0, 0.0, 0.0 );
                }
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_cut_out_for_equ',              -- 精灵2装备图标的叠加裁剪
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[

            varying vec2 v_texCoord;
            varying vec4 v_fragmentColor;
            varying vec4 v_fragmentColor2;
            uniform sampler2D CC_Texture0; // 背景
            uniform sampler2D CC_Texture1; // 图标

            uniform vec4 CC_Custom;
            uniform vec4 CC_Custom_Ex;

            void main()
            {
                float texture_1_w = CC_Custom_Ex.x;
                float texture_1_h = CC_Custom_Ex.y;
                float texture_2_w = CC_Custom_Ex.z;
                float texture_2_h = CC_Custom_Ex.w;

                float bg_r = CC_Custom.x;
                float bg_g = CC_Custom.y;
                float bg_b = CC_Custom.z;
                float cut_out_flag = CC_Custom.w; // 小于1就不裁剪, 只叠加

                vec4 color_0 = texture2D( CC_Texture0, v_texCoord ) * vec4( bg_r, bg_g, bg_b, 1.0 ); // 背景color
                vec4 color_1;                                        // 图标color

                // 转换中心点
                float v_x = ( v_texCoord.x * texture_1_w - texture_1_w / 2.0 ) / texture_2_w + 0.5 ;
                float v_y = ( v_texCoord.y * texture_1_h - texture_1_h / 2.0 ) / texture_2_h + 0.5 ;

                if ( v_x < 0.0 || v_x > 1.0 || v_y < 0.0 || v_y > 1.0 )
                    // 超边使用vec4( 0.0, 0.0, 0.0, 0.0 )
                    color_1 = vec4( 0.0, 0.0, 0.0, 0.0 );
                else
                    // 取到背景的color
                    color_1 = texture2D( CC_Texture1, vec2( v_x, v_y) );

                if ( color_0.a > 0.0 || cut_out_flag < 1.0 ) {
                    // 背景可见，图标可见
                    if ( color_1.a < 1.0 ) {
                        gl_FragColor = v_fragmentColor * ( color_1 * color_1.a + color_0 * ( 1.0 - color_1.a ) );
                    } else {
                        gl_FragColor = v_fragmentColor * color_1;
                    }
                } else {
                    // 否则不显示
                    gl_FragColor = v_fragmentColor * vec4( 0.0, 0.0, 0.0, 0.0 );
                }
            }
        ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_HBSBYA',              -- color(颜色模式)
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;
        ]] .. hsl_helper .. [[

            void main()
            {
                vec4 texColor = texture2D(CC_Texture0, v_texCoord);

                //convert rgb to hsl
                vec3 hslA = convertRGBtoHSL(texColor.rgb);

                vec3 finalHSL = hslA;
                // Saturation: HcScYc =HBSBYA
                {
                    vec3 hslB  = convertRGBtoHSL(v_fragmentColor.xyz);
                    hslB       = checkHSL(hslB);
                    finalHSL.x = hslB.x;
                    finalHSL.y = hslB.y;
                    finalHSL.z = hslA.z;
                    finalHSL   = checkHSL(finalHSL);
                }

                gl_FragColor.rgb = convertHSLtoRGB(finalHSL);
                gl_FragColor.a   = texColor.a;
            }
         ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_cover',              -- 正常模式颜色遮罩
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;

            void main()
            {
                vec4 texColor = texture2D(CC_Texture0, v_texCoord);

                gl_FragColor.rgb = texColor.rgb;
                if( texColor.a > 0.0 )
                {
                    gl_FragColor.rgb = texColor.rgb * (1.0 - CC_Custom.a);
                    gl_FragColor.rgb+= CC_Custom.rgb * CC_Custom.a;
                }
                gl_FragColor.a   = texColor.a;
            }
         ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_fight_cd',              -- 战斗按钮点击CD
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform vec4 CC_Custom;
            uniform vec4 CC_Custom_Ex;

            void main()
            {
                vec4 texColor = texture2D(CC_Texture0, v_texCoord);

                bool inCdArea = false;
                float dis = distance( vec2( 0.5, 0.5 ), v_texCoord );
                vec2  dCoord = v_texCoord - vec2( 0.5, 0.5 );

                if( dis > 0.0 )
                {
                    float dx = dis * sin(radians(CC_Custom_Ex.x));
                    float dy = dis * cos(radians(CC_Custom_Ex.x));
                    if( dx > 0.0 && dCoord.x > 0.0)
                    {
                        inCdArea = dCoord.y > dy;
                    }

                    if( dx < 0.0 && dCoord.x < 0.0)
                    {
                        inCdArea = dCoord.y < dy;
                    }

                    if( dx < 0.0 && dCoord.x > 0.0)
                    {
                        inCdArea = true;
                    }
                }


                gl_FragColor.rgb = texColor.rgb;
                if( texColor.a > 0.0 && !inCdArea )
                {
                    gl_FragColor.rgb = texColor.rgb * (1.0 - CC_Custom.a);
                    gl_FragColor.rgb+= CC_Custom.rgb * CC_Custom.a;
                }
                gl_FragColor.a   = texColor.a;
            }
         ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
    {
        shader_name = 'position_texture_color_fight_mp_highlight',              -- 魔水高亮
        vertex_shader = vertex_shader_position_texture_color,
        fragment_shader = [[
            #ifdef GL_ES
            precision highp float;
            #endif

            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            uniform sampler2D CC_Texture0;
            uniform sampler2D CC_Texture1;

            void main()
            {
                vec4 texColor  = texture2D(CC_Texture0, v_texCoord);

                gl_FragColor.r = texColor.r + texColor.r * v_fragmentColor.r / (1.0 - v_fragmentColor.r);
                gl_FragColor.g = texColor.g + texColor.g * v_fragmentColor.g / (1.0 - v_fragmentColor.g);
                gl_FragColor.b = texColor.b + texColor.b * v_fragmentColor.b / (1.0 - v_fragmentColor.b);
                gl_FragColor.a = texColor.a * v_fragmentColor.a;
            }
         ]],
        attributes = {
            { name = 'a_position', index = kCCVertexAttrib_Position, },
            { name = 'a_color', index = kCCVertexAttrib_Color, },
            { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
        },
    },
}

local gaussian_blur_shader_mod = {
    shader_name = 'position_texture_color_sharpen_gaussian',              -- 锐化模糊 高斯
    vertex_shader = vertex_shader_position_texture_color,
    fragment_shader = [[
#ifdef GL_ES
precision highp float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;
uniform sampler2D CC_Texture0;
uniform vec4 CC_Custom;

void main()
{
    vec2  intXY   = vec2( v_texCoord.x * CC_Custom.x, v_texCoord.y * CC_Custom.y );
    int   radius  = int(CC_Custom.z) * 2 + 1;
    %s;

    vec4 final_color = vec4(0.0,0.0,0.0,0.0);

    for( int i=0; i < radius; i++ )
    {
        for( int j=0; j < radius; j++ )
        {
            vec2 xy_new = vec2( intXY.x + float(i) - float(radius) - 1.0, intXY.y + float(j) - float(radius) - 1.0);
            vec2 uv = vec2( xy_new.x / CC_Custom.x, xy_new.y / CC_Custom.y );

            float odds = _filter[i * radius + j];
            vec4 temp_color = texture2D( CC_Texture0, uv ) * odds;
            final_color = final_color + temp_color;
        }
    }

    gl_FragColor = final_color;
} ]],
    attributes = {
        { name = 'a_position', index = kCCVertexAttrib_Position, },
        { name = 'a_color', index = kCCVertexAttrib_Color, },
        { name = 'a_texCoord', index = kCCVertexAttrib_TexCoords, },
    },
}

local function createShader(shader_info)
    local p = CCGLProgram:create()
    p:initWithVertexShaderByteArray( shader_info.vertex_shader, shader_info.fragment_shader )

    for _,attrib in ipairs( shader_info.attributes ) do
        p:addAttribute( attrib.name, attrib.index )
    end

    p:link()
    p:updateUniforms()

    CCShaderCache:sharedShaderCache():addProgram( p, shader_info.shader_name )
    return p
end

local function updateShader(shader_info)
    local p = CCShaderCache:sharedShaderCache():programForKey( shader_info.shader_name )
    if p ~= nil then
        p:reset()
        p:initWithVertexShaderByteArray( shader_info.vertex_shader, shader_info.fragment_shader )

        for _,attrib in ipairs( shader_info.attributes ) do
            p:addAttribute( attrib.name, attrib.index )
        end

        p:link()
        p:updateUniforms()
    end
    return p
end

local function getGaussionFilterList(radius)
    local sigma = 10
    local list = {}
    local total = 0
    for i = - radius, radius do
        for j = - radius, radius do
            local val = math.exp(-(i*i+j*j)/(2*sigma*sigma)) / (2*math.pi*sigma*sigma)
            total = total + val
            table.insert(list, val)
        end
    end
    CCLuaLog('>>>>>>>>>>>>>>>>>>>>>>>>>>>>.' .. tostring(total))
    local slist = {}
    for _, val in ipairs(list) do
        table.insert(slist, string.format("%f", val / total))
    end
    return string.format('float _filter[%d] = {%s}', #slist, table.concat(slist, ','))
end

local gaussian_blur_shaders = {}
function getGaussionBlurShader(blur_radius)
    blur_radius = math.floor(blur_radius)
    if blur_radius <= 0 then return nil end

    local shaderName = string.format('gaussian_blur_shader_radius_%d', blur_radius)
    if gaussian_blur_shaders[shaderName] then return shaderName end

    local info = table.copy(gaussian_blur_shader_mod)
    info.shader_name = shaderName
    info.fragment_shader = string.format(info.fragment_shader, getGaussionFilterList(blur_radius))
    CCLuaLog(info.fragment_shader)
    gaussian_blur_shaders[shaderName] = info
    createShader(info)
    return shaderName
end

function initCustomShaders()
    for _,shader_info in pairs( custom_shaders ) do
        createShader(shader_info)
    end
end

function reloadOpenGL()
    for _,shader_info in pairs( custom_shaders ) do
        updateShader(p)
    end

    for _,shader_info in pairs( gaussian_blur_shaders ) do
        updateShader(p)
    end

    TLFontTex:sharedTLFontTex():initFontTexture( GameSettings.color_tex_file, GameSettings.color_tex_row, GameSettings.color_tex_col, GameSettings.color_shader )
end

CCNotificationCenter:sharedNotificationCenter():registerScriptObserver(CCDirector:sharedDirector():getRunningScene(), reloadOpenGL, "event_come_to_foreground")

function updateReloadShaders()
    for _,shader_info in pairs( custom_shaders ) do
        local p = CCShaderCache:sharedShaderCache():programForKey( shader_info.shader_name )
        if p == nil then
            createShader(shader_info)
        end
    end

    for _,shader_info in pairs( gaussian_blur_shaders ) do
        local p = CCShaderCache:sharedShaderCache():programForKey( shader_info.shader_name )
        if p == nil then
            createShader(shader_info)
        end
    end
end
