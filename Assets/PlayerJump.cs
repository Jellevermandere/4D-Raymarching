using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerJump : MonoBehaviour
{
    // Start is called before the first frame update
    public float jumpForce = 20;
    public float gravity = -9.81f;
    public float gravityScale = 5;
    public float velocity = 0;
    public float dir = 0;
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        velocity += gravity * gravityScale * Time.deltaTime;
        if (velocity <= 0)
        {
            velocity = 0;
        }
        if (Input.GetKeyDown(KeyCode.Space))
        {
            velocity += (float).01;
        }
        transform.Translate(new Vector3(0, velocity, 0) * Time.deltaTime);
    }
}