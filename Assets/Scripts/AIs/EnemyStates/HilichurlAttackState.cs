using UnityEngine;

public class HilichurlAttackState : FSMState
{
    private Transform playerTrans;
    private float attackToChaseDis;

    public HilichurlAttackState(FSMSystem fSMSystem, float attackToChaseDistance) : base(fSMSystem)
    {
        stateCode = FSMStateCode.HilichurlAttack;
        attackToChaseDis = attackToChaseDistance;
        playerTrans = MainGameSystem.Instance.playerCube.transform;
    }
    public override void Act(GameObject npc)
    {
        npc.transform.LookAt(playerTrans.position);
    }

    public override void Reason(GameObject npc)
    {
        if (Vector3.Distance(playerTrans.position, npc.transform.position) > attackToChaseDis)
        {
            fSMSystem.OnFSMTransition(FSMTransitionCode.PlayerRunAway);
        }
    }
}
