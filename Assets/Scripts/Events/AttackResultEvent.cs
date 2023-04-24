using SangoCommon.DataCache.AttackCache;
using SangoCommon.DataCache.PlayerDataCache;
using SangoCommon.ServerCode;
using SangoCommon.Tools;
using ExitGames.Client.Photon;

//Developer : SangonomiyaSakunovi
//Discription:

public class AttackResultEvent : BaseEvent
{
    public override void InitEvent()
    {
        base.InitEvent();
    }
    public override void OnEvent(EventData eventData)
    {
        string attackResultJson = DictTools.GetStringValue(eventData.Parameters, (byte)ParameterCode.AttackResult);
        {
            if (attackResultJson != null && IslandOnlineAccountSystem.Instance != null)
            {
                AttackResultCache attackResultCache = DeJsonString<AttackResultCache>(attackResultJson);
                if (attackResultCache.DamagerAccount == NetService.Instance.Account)
                { 
                    MainGameSystem.Instance.SetLocalAvaterAttackResult(attackResultCache);                   
                }
                else
                {
                    IslandOnlineAccountSystem.Instance.SetOnlineAvaterAttackResult(attackResultCache);
                }
            }
        }
    }
}
