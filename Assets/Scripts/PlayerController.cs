using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;

// ****************** Player 3D Movement ****************** 

public class PlayerController : MonoBehaviour
{
    public float playerSpeed;
    public float DeathDistance;

    private Vector3 StartPos;
    private bool endGame = false;

    private void Start()
    {
        StartPos = transform.position;
    }

    // Update is called once per frame
    void Update()
    {
        if(transform.position.y < DeathDistance)
        {
            transform.position = StartPos;
        }
        if (!endGame)
        {
            MovePlayer();
        }

    }

    void MovePlayer()
    {

        if (Input.GetAxis("Horizontal") != 0 || Input.GetAxis("Vertical") != 0)
        {
            Vector3 direction = new Vector3(Input.GetAxis("Horizontal"), 0, Input.GetAxis("Vertical")).normalized;
            transform.Translate(direction * Time.deltaTime * playerSpeed, Space.World);
            transform.LookAt(direction + transform.position);
        }
        
    }

    public void EndGame()
    {
        endGame = true;
    }

}
