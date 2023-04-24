using SangoCommon.DataCache.PositionCache;
using SangoCommon.ServerCode;
using SangoCommon.Tools;
using ExitGames.Client.Photon;
using System.Collections.Generic;

//Developer : SangonomiyaSakunovi
//Discription:

public class SyncPlayerTransformEvent : BaseEvent
{
    public override void InitEvent()
    {
        base.InitEvent();
    }
    public override void OnEvent(EventData eventData)
    {
        string playerTransformCacheJson = DictTools.GetStringValue(eventData.Parameters, (byte)ParameterCode.PlayerTransformCacheList);
        if (playerTransformCacheJson != null && IslandOnlineAccountSystem.Instance != null)
        {
            List<TransformCache> playerTransformCacheList = DeJsonString<List<TransformCache>>(playerTransformCacheJson);
            IslandOnlineAccountSystem.Instance.SetOnlineAvaterTransform(playerTransformCacheList);
        }
    }
}
