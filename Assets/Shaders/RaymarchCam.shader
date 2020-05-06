//

Shader "Raymarch/RaymarchCam"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            // the distancefuctions are located on another script

            #include "DistanceFunctions.cginc"

            // All the variables feeded through the camera

            sampler2D _MainTex;
            uniform sampler2D _CameraDepthTexture;
            uniform float4x4 _CamFrustrum, _CamToWorld;
            uniform float3 _wRotation;
            uniform float w;
            uniform float _maxDistance;
            uniform float _precision;
            uniform float _max_iteration;
            uniform float _maxShadowDistance;
            uniform float _lightIntensity;
            uniform int _nrOfCascades;
            uniform float _shadowIntensity;
            uniform float _shadowSoftness;
            uniform float _aoIntensity;

            uniform float3 _lightDir;
            uniform float3 _player;
            uniform fixed4 _skyColor;

            uniform int _useNormal;
            uniform int _useShadow;

            static const float PI = 3.14159265f;

            struct Shape {

                float4 position;
                float4 scale;
                float3 rotation;
                float3 rotationW;
                float3 colour;
                int shapeType;
                int operation;
                float blendStrength;
                int numChildren;
            };

            StructuredBuffer<Shape> shapes;
            int numShapes;


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ray : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                half index = v.vertex.z;
                v.vertex.z = 0;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv.xy;

                o.ray = _CamFrustrum[(int)index].xyz;

                o.ray /= abs(o.ray.z);

                o.ray = mul(_CamToWorld, o.ray);

                return o;
            }

            // the distancefunction for the fractals
            float GetShapeDistance(Shape shape, float4 p4D) {

                p4D -= shape.position;
                
                p4D.xz = mul(p4D.xz, float2x2(cos(shape.rotation.y), sin(shape.rotation.y), -sin(shape.rotation.y), cos(shape.rotation.y)));
                p4D.yz = mul(p4D.yz, float2x2(cos(shape.rotation.x), -sin(shape.rotation.x), sin(shape.rotation.x), cos(shape.rotation.x)));
                p4D.xy = mul(p4D.xy, float2x2(cos(shape.rotation.z), -sin(shape.rotation.z), sin(shape.rotation.z), cos(shape.rotation.z)));

                p4D.xw = mul(p4D.xw, float2x2(cos(shape.rotationW.x), sin(shape.rotationW.x), -sin(shape.rotationW.x), cos(shape.rotationW.x)));
                p4D.zw = mul(p4D.zw, float2x2(cos(shape.rotationW.z), -sin(shape.rotationW.z), sin(shape.rotationW.z), cos(shape.rotationW.z)));
                p4D.yw = mul(p4D.yw, float2x2(cos(shape.rotationW.y), -sin(shape.rotationW.y), sin(shape.rotationW.y), cos(shape.rotationW.y)));
                
                
                if (shape.shapeType == 0) {
                    return sdHypersphere(p4D , shape.scale.x);
                }
                else if (shape.shapeType == 1) {
                    return sdHypercube(p4D, shape.scale);
                }
                else if (shape.shapeType == 2) {
                    return sdDuoCylinder(p4D, shape.scale.xy);
                }
                else if (shape.shapeType == 3) {
                    return sdPlane(p4D, shape.scale);
                }
                else if (shape.shapeType == 4) {
                    return sdCone(p4D, shape.scale);
                }
                else if (shape.shapeType == 5) {
                    return sd5Cell(p4D, shape.scale);
                }
                else if (shape.shapeType == 6) {
                    return sd16Cell(p4D, shape.scale);
                }

                return _maxDistance;
            }
            

            float4 distanceField(float3 p)
            {
                float4 p4D = float4 (p,w);
                if(length(_wRotation) != 0){
                    p4D.xw = mul(p4D.xw, float2x2(cos(_wRotation.x), -sin(_wRotation.x), sin(_wRotation.x), cos(_wRotation.x)));
                    p4D.yw = mul(p4D.yw, float2x2(cos(_wRotation.y), -sin(_wRotation.y), sin(_wRotation.y), cos(_wRotation.y)));
                    p4D.zw = mul(p4D.zw, float2x2(cos(_wRotation.z), -sin(_wRotation.z), sin(_wRotation.z), cos(_wRotation.z)));
                }


                float globalDst = _maxDistance;
                float3 globalColour = 1;

                for (int i = 0; i < numShapes; i ++) {
                    Shape shape = shapes[i];
                    int numChildren = shape.numChildren;

                    float localDst = GetShapeDistance(shape,p4D);
                    float3 localColour = shape.colour;


                    for (int j = 0; j < numChildren; j ++) {
                        Shape childShape = shapes[i+j+1];
                        float childDst = GetShapeDistance(childShape,p4D);

                        float4 combined = Combine(localDst, childDst, localColour, childShape.colour, childShape.operation, childShape.blendStrength);
                        localColour = combined.xyz;
                        localDst = combined.w;
                    }
                    i+=numChildren; // skip over children in outer loop

                    float4 globalCombined = Combine(globalDst, localDst, globalColour, localColour, shape.operation, shape.blendStrength);
                    globalColour = globalCombined.xyz;
                    globalDst = globalCombined.w;
                }

                return float4(globalDst,globalColour);

            }


            // returns the normal in a single point of the fractal

            float3 getNormal(float3 p)
            {

              float d = distanceField(p).x;
                const float2 e = float2(.01, 0);
              float3 n = d - float3(distanceField(p - e.xyy).x,distanceField(p - e.yxy).x,distanceField(p - e.yyx).x);
              return normalize(n);

            }

            // calcutates hard shadows in a point

            float hardShadowCalc( in float3 ro, in float3 rd, float mint, float maxt)
            {
                float res = 1.0;
                for( float t=mint; t<maxt; )
                {
                    float h = min(distanceField(ro + rd*t).x, sdVerticalCapsule(ro + rd*t - _player, 1, 0.5));
                    if( h<0.001 )
                        return 0.0;
                    t += h;
                }
                return res;
            }

            // calcutates soft shadows in a point

            float softShadowCalc( in float3 ro, in float3 rd, float mint, float maxt, float k )
            {
                float res = 1.0;
                float ph = 1e20;
                for( float t=mint; t<maxt; )
                {
                    float h = distanceField(ro + rd*t).x;
                    if( h<0.001 )
                        return 0.0;
                    float y = h*h/(2.0*ph);
                    float d = sqrt(h*h-y*y);
                    res = min( res, k*d/max(0.0,t-y) );
                    ph = h;
                    t += h;
                }
                return res;
            }

            // the actual raymarcher
            fixed4 raymarching(float3 ro, float3 rd, float depth)
            {

                fixed4 result = fixed4(0,0,0,0.5); // default

                float t = 0; //distance traveled


                for (int i = 0; i < _max_iteration; i++)
                {
                    //sends out ray from the camera
                    float3 p = ro + rd * t;



                    // check if to far
                    if(t > _maxDistance || t >= depth)
                    {

                        //environment
                        result = fixed4(rd,0);
                        break;

                    }

                    //return distance to fractal
                    float4 d = (distanceField(p));


                    if ((d.x) < _precision) //hit
                    {
                        float3 colorDepth;
                        float light;
                        float shadow;
                        //shading

                        float3 color = d.yzw;

                        if(_useNormal == 1){
                            float3 n = getNormal(p);
                            light = dot(-_lightDir, n); //lambertian shading
                            if(_nrOfCascades > 0){
                                light = floor(light * _nrOfCascades + 1)/(float)(_nrOfCascades);
                            }
                           
                            light = light * (1 - _lightIntensity) + _lightIntensity;
                        }
                        else  light = 1;

                        if(_useShadow == 1){
                             shadow = (hardShadowCalc(p, -_lightDir, 0.1, _maxShadowDistance) * (1 - _shadowIntensity) + _shadowIntensity); // soft shadows

                        }
                        else if(_useShadow == 2){
                            shadow = (softShadowCalc(p, -_lightDir, 0.1, _maxShadowDistance, _shadowSoftness) * (1 - _shadowIntensity) + _shadowIntensity); // soft shadows
                        }
                        else  shadow = 1;

                        float ao = (1 - 2 * i/float(_max_iteration)) * (1 - _aoIntensity) + _aoIntensity; // ambient occlusion

                        float3 colorLight = float3 (color * light * shadow * ao); // multiplying all values between 0 and 1 to return final color

                        colorDepth = float3 (colorLight*(_maxDistance-t)/(_maxDistance) + _skyColor.rgb*(t)/(_maxDistance)); // multiplying with distance

                        //colorDepth = pow( colorDepth, (1.0/2.2) );
                        result = fixed4(colorDepth ,1);
                        break;

                    }

                    t += d.x;


                }

                return result;
            }
            // the fragment shader
            fixed4 frag (v2f i) : SV_Target
            {
               float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
               depth *= length(i.ray);
               fixed3 col = tex2D(_MainTex, i.uv);

               float3 rayDirection = normalize(i.ray.xyz);
               float3 rayOrigin = _WorldSpaceCameraPos;
               fixed4 result = raymarching(rayOrigin, rayDirection, depth);
               return fixed4(col * (1.0 - result.w) + result.xyz * result.w ,1.0);

            }
            ENDCG
        }
    }
}
