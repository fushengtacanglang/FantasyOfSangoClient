using SangoCommon.DataCache.PlayerDataCache;
using SangoCommon.ServerCode;
using SangoCommon.Tools;
using ExitGames.Client.Photon;

//Developer : SangonomiyaSakunovi
//Discription:

public class SyncPlayerDataRequest : BaseRequest
{
    public string Account { get; private set; }
    public PlayerCache PlayerCache { get; private set; }
    public bool IsGetResponse { get; private set; }

    public override void InitRequset()
    {
        base.InitRequset();
        IsGetResponse = false;
    }

    public override void DefaultRequest()
    {
        NetService.Peer.OpCustom((byte)OpCode, null, true);
    }

    public override void OnOperationResponse(OperationResponse operationResponse)
    {
        string playerCacheJson = DictTools.GetStringValue(operationResponse.Parameters, (byte)ParameterCode.PlayerCache);
        PlayerCache = DeJsonString<PlayerCache>(playerCacheJson);
        IsGetResponse = true;
    }

    public void SetAccoount(string account)
    {
        Account = account;
    }

    public void SetIsGetResponse(bool isGetResponse = false)
    {
        IsGetResponse = isGetResponse;
    }

    public void SetPlayerCache(PlayerCache playerCache)
    {
        PlayerCache = playerCache;
    }
}
