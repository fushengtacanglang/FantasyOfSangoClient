using System.Collections;
using System.Collections.Generic;
using System.ComponentModel.Design;
using UnityEngine;

public class BaseManager : MonoBehaviour
{
    protected NetService netService;
    protected ResourceService resourceService;
    protected AudioService audioService;

    public virtual void InitManager()
    {
        netService = NetService.Instance;
        resourceService = ResourceService.Instance;
        audioService = AudioService.Instance;
    }
}
