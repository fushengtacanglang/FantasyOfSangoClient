using Assets.Scripts.Common.Constant;
using SangoCommon.DataCache.AttackCache;
using SangoCommon.DataCache.PlayerDataCache;
using SangoCommon.GameObjectCode;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

//Developer : SangonomiyaSakunovi
//Discription:

public class MainGameSystem : BaseSystem
{
    public static MainGameSystem Instance = null;

    public MainGameWindow mainGameWindow;

    public GameObject miniMapBaseLocation;
    public GameObject miniMapLocals;
    private float miniMapScaling = 10;
    private Vector3 HomePos = new Vector3(5.568432f, 0, -21.45944f);
    private Vector3 HillPos = new Vector3(88.04138f, 0, 678.8067f);

    private Vector3 miniHomePos = new Vector3(-8, 198, 0);
    private Vector3 miniHillPos = new Vector3(-115.7629f, -693.5677f, 0);

    private float xChange = 265;
    private float yChange = 930;

    [HideInInspector]
    public GameObject playerCapsule = null;
    [HideInInspector]
    public GameObject playerCube = null;

    public AvaterCode LocalAvaterCurrent { get; private set; }

    public TMP_Text hpText;
    public TMP_Text levelText;
    public Image hpFG;
    public Image elementBurstFG;

    private PlayerCache playerCache = null;

    public override void InitSystem()
    {
        base.InitSystem();
        Instance = this;
        miniMapScaling = Vector3.Distance(HomePos, HillPos) / Vector3.Distance(miniHomePos, miniHillPos);
    }

    public void EnterMainGame()
    {
        resourceService.AsyncLoadScene(SceneConstant.MainGameScene, () =>
        {
            //Load Avater
            InitiateLocalAvater();
            playerCube.GetComponent<MovePlayerCubeController>().SetAvaterNow(AvaterCode.SangonomiyaKokomi);
            playerCube.GetComponent<MovePlayerCubeController>().AvaterNow.SetActive(true);
            LocalAvaterCurrent = AvaterCode.SangonomiyaKokomi;
            CameraController.Instance.player = playerCube.transform;
            CameraController.Instance.InitCamera();
            //Load UI
            mainGameWindow.SetWindowState();
            playerCache = OnlineAccountCache.Instance.PlayerCache;
            RefreshMainGameUI(playerCache.AttributeInfoList[0].HP, playerCache.AttributeInfoList[0].HPFull,
            playerCache.AttributeInfoList[0].MP, playerCache.AttributeInfoList[0].MPFull);
            //LoadMusic
            audioService.LoadAudio(AudioConstant.NormalFightBG);
            //PlayMusic
            audioService.PlayBGAudio(AudioConstant.MainGameBG, true);
            //MiniMap
            SetMiniMapTransPosition(playerCube.transform);
            //LoadEnemy
            InitiateEnemy();
        });
    }

    public void RefreshMainGameUI(int hp, int hpFull, int mp, int mpFull)
    {
        SetText(hpText, hp + " / " + hpFull);
        hpFG.fillAmount = (float)hp / hpFull;
        elementBurstFG.fillAmount = (float)mp / hpFull;
    }

    private void InitiateLocalAvater()
    {
        playerCapsule = (GameObject)GameObject.Instantiate(Resources.Load(AvaterConstant.PlayerCapsule));
        playerCube = (GameObject)GameObject.Instantiate(Resources.Load(AvaterConstant.PlayerCube));
        GameObject tempKokomi = (GameObject)GameObject.Instantiate(Resources.Load(AvaterConstant.SangonomiyaKokomiPath));
        GameObject tempYoimiya = (GameObject)GameObject.Instantiate(Resources.Load(AvaterConstant.YoimiyaPath));
        GameObject tempAyaka = (GameObject)GameObject.Instantiate(Resources.Load(AvaterConstant.AyakaPath));
        SetChildAvater(tempKokomi, playerCube);
        SetChildAvater(tempYoimiya, playerCube);
        SetChildAvater(tempAyaka, playerCube);
        playerCube.transform.position = playerCapsule.transform.position;
        playerCube.transform.rotation = playerCapsule.transform.rotation;
    }

    private void SetChildAvater(GameObject childObject, GameObject parentObject)
    {
        childObject.transform.parent = parentObject.transform;
        childObject.transform.localPosition = new Vector3(0, 0, 0);
        childObject.transform.localRotation = Quaternion.Euler(0, 0, 0);
    }

    private void InitiateEnemy()
    {
        GameObject.Instantiate(Resources.Load(EnemyConstant.HilichulPath));
    }

    public void RefreshAvaterUI()
    {

    }

    public void SetLocalAvaterAttackResult(AttackResultCache attackResultCache)
    {
        if (attackResultCache.DamageNumber > 0)
        {
            if (LocalAvaterCurrent == AvaterCode.SangonomiyaKokomi)
            {
                playerCube.transform.Find(AvaterConstant.SangonomiyaKokomiName).GetComponent<AttackControllerSangonomiyaKokomi>().SetDamaged(attackResultCache);
            }
            else if (LocalAvaterCurrent == AvaterCode.Yoimiya)
            {
                playerCube.transform.Find(AvaterConstant.YoimiyaName).GetComponent<AttackControllerYoimiya>().SetDamaged(attackResultCache);
            }
            SangoRoot.AddMessage("你被玩家" + attackResultCache.AttackerAccount + "攻击了，受到伤害-" + attackResultCache.DamageNumber + "HP");
            AttributeInfoCache tempAttribute = attackResultCache.DamagerPlayerCache.AttributeInfoList[0];
            Instance.RefreshMainGameUI(tempAttribute.HP, tempAttribute.HPFull, tempAttribute.MP, tempAttribute.MPFull);
        }
        else    //in this kind, the avater has been cured
        {
            GameObject healerGameobject = IslandOnlineAccountSystem.Instance.GetOnlineCurrentGameobject(attackResultCache.AttackerAccount);
            AvaterCode healerAvater = IslandOnlineAccountSystem.Instance.GetOnlineCurrentAvater(attackResultCache.AttackerAccount);
            if (healerAvater == AvaterCode.SangonomiyaKokomi)
            {
                healerGameobject.GetComponent<AttackControllerSangonomiyaKokomi>().SetCureResult(playerCube.transform.position);
            }
            SangoRoot.AddMessage("你被玩家" + attackResultCache.AttackerAccount + "治疗了，治疗量为" + -attackResultCache.DamageNumber + "HP");
            AttributeInfoCache tempAttribute = attackResultCache.DamagerPlayerCache.AttributeInfoList[0];
            Instance.RefreshMainGameUI(tempAttribute.HP, tempAttribute.HPFull, tempAttribute.MP, tempAttribute.MPFull);
        }
    }

    public void SetMiniMapTransPosition(Transform playerTrans)
    {
        float moveX = (playerTrans.position.x - HomePos.x) / miniMapScaling;
        float moveY = (playerTrans.position.z - HomePos.z) / miniMapScaling;
        miniMapBaseLocation.transform.position = new Vector3(miniHomePos.x - moveX + xChange, miniHomePos.y - moveY + yChange, 0);
        Vector3 rotations = playerTrans.rotation.eulerAngles;
        miniMapLocals.transform.rotation = Quaternion.Euler(0, 0, -rotations.y);
    }
}
