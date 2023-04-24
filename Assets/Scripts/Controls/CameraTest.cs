using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraTest : MonoBehaviour
{
    Camera maincamera;
    public float turnSpeed;
    void Start()
    {
        maincamera = Camera.main;
    }

    // Update is called once per frame
    void FixedUpdate()
    {
        float playerCamera = maincamera.transform.rotation.eulerAngles.y;
        transform.rotation = Quaternion.Slerp(transform.rotation,Quaternion.Euler(0,playerCamera,0), Time.deltaTime);
    }
}
