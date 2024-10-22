using SangoCommon.ServerCode;
using SangoCommon.Tools;
using ExitGames.Client.Photon;
using System.Collections.Generic;

//Developer : SangonomiyaSakunovi
//Discription:

public class NewAccountJoinEvent : BaseEvent
{
    public string Account { get; private set; }

    Stack<string> newAccountJoinEventStack = new Stack<string>();

    public override void InitEvent()
    {
        base.InitEvent();
        newAccountJoinEventStack.Push("-1");
    }
    public override void OnEvent(EventData eventData)
    {
        string tempAccount = DictTools.GetStringValue(eventData.Parameters, (byte)ParameterCode.Account);
        if (tempAccount != null)
        {
            if (newAccountJoinEventStack.Peek() != tempAccount)
            {
                newAccountJoinEventStack.Push(tempAccount);
                IslandOnlineAccountSystem.Instance.InstantiatePlayerCube(tempAccount);
            }
        }        
    }
}
