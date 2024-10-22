using SangoCommon.DataCache.PositionCache;
using SangoCommon.ServerCode;
using ExitGames.Client.Photon;
using System;
using System.Collections.Generic;
using UnityEngine;
using static SangoCommon.Struct.CommonStruct;

//Developer : SangonomiyaSakunovi
//Discription:

public class SyncPlayerTransformRequest : BaseRequest
{
    public string Account { get; private set; }
    private TransformCache playerTransformCache;

    public override void InitRequset()
    {
        base.InitRequset();
    }

    public void SetPlayerTransform(Vector3 position, Quaternion rotation)
    {
        playerTransformCache = new TransformCache
        {
            Account = this.Account,
            Vector3Position = new Vector3Position
            {
                X = (float)Math.Round(position.x, 2),
                Y = (float)Math.Round(position.y, 2),
                Z = (float)Math.Round(position.z, 2)
            },
            QuaternionRotation = new QuaternionRotation
            {
                X = (float)Math.Round(rotation.x, 2),
                Y = (float)Math.Round(rotation.y, 2),
                Z = (float)Math.Round(rotation.z, 2),
                W = (float)Math.Round(rotation.w, 2)
            }
        };
        DefaultRequest();
    }

    public override void DefaultRequest()
    {
        string playerTransformJson = SetJsonString(playerTransformCache);
        Dictionary<byte, object> dict = new Dictionary<byte, object>();
        dict.Add((byte)ParameterCode.PlayerTransformCache, playerTransformJson);
        NetService.Peer.OpCustom((byte)OpCode, dict, true);
    }

    public override void OnOperationResponse(OperationResponse operationResponse)
    {
        throw new System.NotImplementedException();
    }

    public void SetAccount(string account)
    {
        Account = account;
    }
}
