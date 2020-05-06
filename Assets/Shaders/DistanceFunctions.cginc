// Sphere
// s: radius
float sdSphere(float3 p, float s)
{
	return length(p) - s;
}

// Box
// b: size of box in x/y/z
float sdBox(float3 p, float3 b)
{
	float3 d = abs(p) - b;
	return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

// 4D HyperCube
float sdHypercube (float4 p, float4 b)
{
    float4 d = abs(p) - b;
	return min(max(d.x,max(d.y,max(d.z,d.w))),0.0) + length(max(d,0.0));
}

float sdHypersphere (float4 p, float s)
{
    return length(p) - s;
}

// http://eusebeia.dyndns.org/4d/duocylinder
float sdDuoCylinder( float4 p, float2 r1r2) {
  float2 d = abs(float2(length(p.xz),length(p.yw))) - r1r2;
  return min(max(d.x,d.y),0.) + length(max(d,0.));
}
float sdVerticalCapsule( float3 p, float h, float r )
{
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}
float sdCone(float4 p, float4 h)
{
    return max(length(p.xzw) - h.x, abs(p.y) - h.y) - h.x * p.y;
}
float sd16Cell(float4 p, float s)
{
    p = abs(p);
    return (p.x + p.y + p.z + p.w - s)* 0.57735027f;
}
float sd5Cell(float4 p, float4 a)
{
  return (max(max(max( abs(p.x+p.y+(p.w/a.w))-p.z,abs(p.x-p.y+(p.w/a.w))+p.z), abs(p.x - p.y - (p.w/a.w))+p.z),abs(p.x+p.y-(p.w/a.w))-p.z)-a.x)/sqrt(3.);
}

// plane
float sdPlane(float4 p, float4 s)
{

    float plane = dot(p, normalize(float4(0, 1, 0, 0))) - (sin(p.x * s.x + p.w) + sin(p.z * s.z) + sin((p.x * 0.34 + p.z * 0.21)*s.w))/s.y;
    return plane;

}




// Tetrahedron
float sdTetrahedron(float3 p, float a, float4x4 rotate45)
{
    
  //p = mul(rotate45, float4(p,1)).xyz;
  return (max( abs(p.x+p.y)-p.z,abs(p.x-p.y)+p.z)-a)/sqrt(3.);
  
    
}

// Octahedron
float sdOctahedron(float3 p, float a, float4x4 rotate45)
{
  p = mul(rotate45, float4(p,1)).xyz;
  return (abs(p.x)+abs(p.y)+abs(p.z)-a)/3;
}

// BOOLEAN OPERATORS //

float4 Blend( float a, float b, float3 colA, float3 colB, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    float blendDst = lerp( b, a, h ) - k*h*(1.0-h);
    float3 blendCol = lerp(colB,colA,h);
    return float4(blendCol, blendDst);
}

float4 Combine(float dstA, float dstB, float3 colA, float3 colB, int operation, float k) {
    float dst = dstA;
    float3 colour = colA;

    //union
    if (operation == 0) {
        float h = clamp( 0.5 + 0.5*(dstA-dstB)/k, 0.0, 1.0 );
        colour = lerp(colA, colB, h);
        dst = lerp( dstA,dstB , h ) - k*h*(1.0-h);
    } 
    // Blend
    else if (operation == 1) {
        float4 blend = Blend(dstA,dstB,colA,colB, k);
        dst = blend.w;
        colour = blend.xyz;
    }
    // substract
    else if (operation == 2) {
        // max(a,-b)
        float h = clamp( 0.5 - 0.5*(dstB+dstA)/k, 0.0, 1.0 );
        colour = lerp(colA, colB, h);
        dst = lerp( dstA,-dstB , h ) + k*h*(1.0-h);
    }
    // intersect
    else if (operation == 3) {
        // max(a,b)
        float h = clamp( 0.5 - 0.5*(dstA-dstB)/k, 0.0, 1.0 );
        colour = lerp(colA, colB, h);
        dst = lerp( dstA,dstB , h ) + k*h*(1.0-h);
    }

    return float4(colour,dst);
}


//transform object

float3 sdTransform (float3 p, float4x4 _globalTransform)
{
    return mul(_globalTransform, float4(p,1)).xyz;
}









