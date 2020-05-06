using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using static Unity.Mathematics.math;

// ****************** Player Collision Detection through Raymarching ****************** 

namespace Unity.Mathematics
{
    public class PlayerRayMarchCollider : MonoBehaviour
    {

        public float colliderOffset = 1.2f;
        public float maxDownMovement = 1f;
        [Tooltip ("The transforms from which the raymarcher will test the distances and apply the collision")]
        public Transform[] rayMarchTransforms;

        private DistanceFunctions Df;
        private RaymarchCam camScript;


        // Start is called before the first frame update
        void Start()
        {
            camScript = Camera.main.GetComponent<RaymarchCam>();
            Df = GetComponent<DistanceFunctions>();
        }
        
        // Update is called once per frame
        void Update()
        {
            MoveToGround();
            RayMarch(rayMarchTransforms);
            
        }
        // the distancefunction for the shapes
        public float GetShapeDistance(Shape4D shape, float4 p4D)
        {
            p4D -= (float4) shape.Position();
           
            p4D.xz = mul(p4D.xz, float2x2(cos(shape.Rotation().y), sin(shape.Rotation().y), -sin(shape.Rotation().y), cos(shape.Rotation().y)));
            p4D.yz = mul(p4D.yz, float2x2(cos(shape.Rotation().x), -sin(shape.Rotation().x), sin(shape.Rotation().x), cos(shape.Rotation().x)));
            p4D.xy = mul(p4D.xy, float2x2(cos(shape.Rotation().z), -sin(shape.Rotation().z), sin(shape.Rotation().z), cos(shape.Rotation().z)));

            p4D.xw = mul(p4D.xw, float2x2(cos(shape.RotationW().x), sin(shape.RotationW().x), -sin(shape.RotationW().x), cos(shape.RotationW().x)));
            p4D.zw = mul(p4D.zw, float2x2(cos(shape.RotationW().z), -sin(shape.RotationW().z), sin(shape.RotationW().z), cos(shape.RotationW().z)));
            p4D.yw = mul(p4D.yw, float2x2(cos(shape.RotationW().y), -sin(shape.RotationW().y), sin(shape.RotationW().y), cos(shape.RotationW().y)));



            switch (shape.shapeType)
            {
                case Shape4D.ShapeType.HyperCube:
                    return Df.sdHypercube(p4D, shape.Scale());

                case Shape4D.ShapeType.HyperSphere:
                    return Df.sdHypersphere(p4D, shape.Scale().x);

                case Shape4D.ShapeType.DuoCylinder:
                    return Df.sdDuoCylinder(p4D, ((float4) shape.Scale()).xy);
                case Shape4D.ShapeType.plane:
                    return Df.sdPlane(p4D, shape.Scale());
                case Shape4D.ShapeType.Cone:
                    return Df.sdCone(p4D, shape.Scale());
                case Shape4D.ShapeType.FiveCell:
                    return Df.sd5Cell(p4D, shape.Scale());
                case Shape4D.ShapeType.SixteenCell:
                    return Df.sd16Cell(p4D, shape.Scale().x);

            }

            return Camera.main.farClipPlane;
        }

        public float DistanceField(float3 p)
        {
            float4 p4D = float4(p, camScript._wPosition);
            Vector3 wRot = camScript._wRotation * Mathf.Deg2Rad;

            if ((wRot).magnitude != 0)
            {
                p4D.xw = mul(p4D.xw, float2x2(cos(wRot.x), -sin(wRot.x), sin(wRot.x), cos(wRot.x)));
                p4D.yw = mul(p4D.yw, float2x2(cos(wRot.y), -sin(wRot.y), sin(wRot.y), cos(wRot.y)));
                p4D.zw = mul(p4D.zw, float2x2(cos(wRot.z), -sin(wRot.z), sin(wRot.z), cos(wRot.z)));

            }


            float globalDst = Camera.main.farClipPlane;


            for (int i = 0; i < camScript.orderedShapes.Count; i++)
            {
                Shape4D shape = camScript.orderedShapes[i];
                int numChildren = shape.numChildren;

                float localDst = GetShapeDistance(shape, p4D);


                for (int j = 0; j < numChildren; j++)
                {
                    Shape4D childShape = camScript.orderedShapes[i + j + 1];
                    float childDst = GetShapeDistance(childShape, p4D);

                    localDst = Df.Combine(localDst, childDst, childShape.operation, childShape.smoothRadius);

                }
                i += numChildren; // skip over children in outer loop

                globalDst = Df.Combine(globalDst, localDst, shape.operation, shape.smoothRadius);
            }

            return globalDst;

        }

        // the raymarcher checks the distance to all the given transforms, if one is less than zero, the player is moved in the opposite direction
        void RayMarch(Transform[] ro)
        {

            int nrHits = 0;

            for (int i = 0; i < ro.Length; i++)
            {
                Vector3 p = ro[i].position;
                //check hit
                float d = DistanceField(p);


                if (d < 0) //hit
                {
                    Debug.Log("hit" + i);
                    nrHits++;
                    //collision
                    transform.Translate(ro[i].forward * d * 1.5f, Space.World);

                }


            }
        }

        //moves the player to the ground
        void MoveToGround()
        {
            Vector3 p = transform.position;
           //check hit

            float d = DistanceField(p);
            d = Mathf.Min(d, maxDownMovement);
            //Debug.Log(d);
            transform.Translate(Vector3.down * d, Space.World);
        }

    }
}

