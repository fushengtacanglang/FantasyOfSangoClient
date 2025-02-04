using SangoCommon.ComBatCode;
using SangoCommon.DataCache.AttackCache;
using SangoCommon.DataCache.PositionCache;
using SangoCommon.ServerCode;
using ExitGames.Client.Photon;
using System;
using System.Collections.Generic;
using UnityEngine;
using static SangoCommon.Struct.CommonStruct;

//Developer : SangonomiyaSakunovi
//Discription:

public class AttackCommandRequest : BaseRequest
{
    public string Account { get; private set; }
    private AttackCommandCache attackCommandCache;
    public override void InitRequset()
    {
        base.InitRequset();
    }

    public void SetAttackCommand(SkillCode skillCode, Vector3 position, Quaternion rotation)
    {
        attackCommandCache = new AttackCommandCache
        {
            Account = this.Account,
            SkillCode = skillCode,
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
    }

    public override void DefaultRequest()
    {
        string attackCommandJson = SetJsonString(attackCommandCache);
        Dictionary<byte, object> dict = new Dictionary<byte, object>();
        dict.Add((byte)ParameterCode.AttackCommand, attackCommandJson);
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
