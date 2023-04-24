using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameManager : BaseManager
{
    public static GameManager Instance;

    public enum GameModeCode
    {
        GamePlayMode,
        DialogueMode,
    }

    public GameModeCode GameMode;

    public override void InitManager()
    {
        base.InitManager();
        Instance = this;
    }

}
