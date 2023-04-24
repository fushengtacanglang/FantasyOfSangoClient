using SangoCommon.DataCache.AttackCache;
using SangoCommon.ServerCode;
using SangoCommon.Tools;
using ExitGames.Client.Photon;

//Developer : SangonomiyaSakunovi
//Discription:

public class AttackCommandEvent : BaseEvent
{
    public override void InitEvent()
    {
        base.InitEvent();
    }
    public override void OnEvent(EventData eventData)
    {
        string attackCommandJson = DictTools.GetStringValue(eventData.Parameters, (byte)ParameterCode.AttackCommand);
        if (attackCommandJson != null && IslandOnlineAccountSystem.Instance != null)
        {
            AttackCommandCache attackCommandCache = DeJsonString<AttackCommandCache>(attackCommandJson);
            IslandOnlineAccountSystem.Instance.SetOnlineAvaterAttack(attackCommandCache);
        }
    }
}
