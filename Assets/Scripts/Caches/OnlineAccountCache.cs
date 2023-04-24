using SangoCommon.DataCache.PlayerDataCache;
using System.Collections.Generic;
using UnityEngine;

//Developer : SangonomiyaSakunovi
//Discription:

public class OnlineAccountCache : BaseCache
{
    public static OnlineAccountCache Instance = null;

    public PlayerCache PlayerCache { get; private set; }

    public override void InitCache()
    {
        base.InitCache();
        Instance = this;
    }

    public void SetPlayerCache(PlayerCache playerCache)
    {
        PlayerCache = playerCache;
    }
    
}
