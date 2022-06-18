using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using static Unity.Mathematics.math;

namespace Unity.Mathematics
{
    public class DistanceFunctions : MonoBehaviour
    {
        // ****************** Distance Functions ****************** 

        // Sphere
        // s: radius
        public float sdSphere(float3 p, float s)
        {
            return length(p) - s;
        }

        // Box
        // b: size of box in x/y/z
        public float sdBox(float3 p, float3 b)
        {
            float3 d = abs(p) - b;
            return min(max(d.x, max(d.y, d.z)), 0.0f) + length(max(d, 0.0f));
        }

        // 4D HyperCube
        // b: size of box in x/y/z
        public float sdHypercube(float4 p, float4 b)
        {
            float4 d = abs(p) - b;
            return min(max(d.x, max(d.y, max(d.z, d.w))), 0.0f) + length(max(d, 0.0f));
        }

        // 4D HyperSphere
        // s: radius
        public float sdHypersphere(float4 p, float s)
        {
            return length(p) - s;
        }

        // http://eusebeia.dyndns.org/4d/duocylinder
        public float sdDuoCylinder(float4 p, float2 r1r2)
        {
            float2 d = abs(float2(length(p.xz), length(p.yw))) - r1r2;
            return min(max(d.x, d.y), 0.0f) + length(max(d, 0.0f));
        }

        public float sdCone(float4 p,float4 h)
        {
            return max(length(p.xzw) - h.x, abs(p.y) - h.y) - (h.x * p.y);
        }

        public float sd16Cell(float4 p, float s)
        {
            p = abs(p);
            return (p.x + p.y + p.z + p.w - s) * 0.57735027f;
        }

        public float sd5Cell(float4 p, float4 a)
        {
            return (max(max(max(abs(p.x + p.y + (p.w / a.w)) - p.z, abs(p.x - p.y + (p.w / a.w)) + p.z), abs(p.x - p.y - (p.w / a.w)) + p.z), abs(p.x + p.y - (p.w / a.w)) - p.z) - a.x) / sqrt(3.0f);
        }

        // plane
        public float sdPlane(float4 p, float4 s)
        {

            float plane = dot(p, normalize(float4(0, 1, 0, 0))) - (sin(p.x * s.x + p.w) + sin(p.z * s.z) + sin((p.x * 0.34f + p.z * 0.21f) * s.w)) / s.y;
            return plane;
        }

        public float Blend(float a, float b, float k)
        {
            float h = clamp(0.5f + 0.5f * (b - a) / k, 0.0f, 1.0f);
            return lerp(b, a, h) - (k * h * (1.0f - h));
        }

        public float Combine(float dstA, float dstB, Shape4D.Operation operation, float blendStrength)
        {
            float dst = dstA;

            switch (operation)
            {
                case Shape4D.Operation.Union:
                    if (dstB < dstA)
                    {
                        dst = dstB;
                    }
                    break;

                case Shape4D.Operation.Blend:
                    dst = Blend(dstA, dstB, blendStrength);
                    break;

                case Shape4D.Operation.Substract:
                    // max(a,-b)
                    if (-dstB > dst)
                    {
                        dst = -dstB;
                    }
                    break;

                case Shape4D.Operation.Intersect:
                    // max(a,b)
                    if (dstB > dst)
                    {
                        dst = dstB;
                    }
                    break;
            }

            return dst;
        }

        // returns the absolute value of a vector
        public Vector3 Abs(Vector3 vec)
        {
            return new Vector3(Mathf.Abs(vec.x), Mathf.Abs(vec.y), Mathf.Abs(vec.z));
        }

        // returns the absolute value of a vector
        public Vector4 Abs4(Vector4 vec)
        {
            return new Vector4(Mathf.Abs(vec.x), Mathf.Abs(vec.y), Mathf.Abs(vec.z), Mathf.Abs(vec.w));
        }

        // returns the absolute value of a vector
        public Vector2 Abs2(Vector2 vec)
        {
            return new Vector2(Mathf.Abs(vec.x), Mathf.Abs(vec.y));
        }

        // returns the Largest Vector3
        public Vector3 Max(Vector3 vec1, Vector3 vec2)
        {
            return new Vector3(Mathf.Max(vec1.x, vec2.x), Mathf.Max(vec1.y, vec2.y), Mathf.Max(vec1.z, vec2.z));
        }

        // returns the Smallest Vector3
        public Vector3 Min(Vector3 vec1, Vector3 vec2)
        {
            return new Vector3(Mathf.Max(vec1.x, vec2.x), Mathf.Max(vec1.y, vec2.y), Mathf.Max(vec1.z, vec2.z));
        }

        // returns the Largest Vector2
        public Vector2 Max2(Vector2 vec1, Vector2 vec2)
        {
            return new Vector2(Mathf.Max(vec1.x, vec2.x), Mathf.Max(vec1.y, vec2.y));
        }

        // returns the Smallest Vector2
        public Vector2 Min2(Vector2 vec1, Vector2 vec2)
        {
            return new Vector2(Mathf.Max(vec1.x, vec2.x), Mathf.Max(vec1.y, vec2.y));
        }

        // returns the Smallest Vector4
        public Vector4 Max4(Vector4 vec1, Vector4 vec2)
        {
            return new Vector4(Mathf.Max(vec1.x, vec2.x), Mathf.Max(vec1.y, vec2.y), Mathf.Max(vec1.z, vec2.z), Mathf.Max(vec1.w, vec2.w));
        }
    }
}

