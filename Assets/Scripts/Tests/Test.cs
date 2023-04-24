using System.Collections.Generic;
using UnityEngine;

//Developer : SangonomiyaSakunovi
//Discription: A test cs

public class Test : MonoBehaviour
{
    void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            SendRequest();
        }
        if (Input.GetMouseButtonDown(1))
        {
            SendRequestTest();
        }
    }

    private void SendRequest()
    {
        Dictionary<byte, object> dataClientRequest = new Dictionary<byte, object>();
        dataClientRequest.Add(1, 100);
        dataClientRequest.Add(2, "That`s the Request by Client");
        NetService.Peer.OpCustom(1, dataClientRequest, true);
    }
    private void SendRequestTest()
    {
        Dictionary<byte, object> dataClientRequest = new Dictionary<byte, object>();
        dataClientRequest.Add(1, 100);
        dataClientRequest.Add(2, "That`s the TestRequest by Client");
        NetService.Peer.OpCustom(00000000, dataClientRequest, true);
    }
}
