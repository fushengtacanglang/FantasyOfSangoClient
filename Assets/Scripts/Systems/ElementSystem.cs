using SangoCommon.ComBatCode;
using SangoCommon.Constant;
using SangoCommon.DataCache.ElementCache;
using SangoCommon.ElementCode;
using System;
using System.Collections.Generic;
using UnityEngine;

//Developer : SangonomiyaSakunovi
//Discription:

public class ElementSystem : MonoBehaviour
{
    private float unitModifier;
    private float frozenRate;

    private float frozenOriginalRate;
    private string DamagerAccount;

    public Dictionary<ElementTypeCode, ElementApplicationCache> elementApplicationDict = new Dictionary<ElementTypeCode, ElementApplicationCache>();

    private void Start()
    {
        unitModifier = ElementConstant.ElementReactionUnitModifier;
        frozenOriginalRate = ElementConstant.FrozenOriginalRate;
    }

    public void ElementReaction(FightTypeCode fightType, SkillCode skill, ElementApplicationCache elementApplicationCache, Vector3 attakerPos, string damagerAccount)
    {
        DamagerAccount = damagerAccount;
        switch (elementApplicationCache.Type)
        {
            case ElementTypeCode.Hydro:
                {
                    TrigerHydro(fightType, elementApplicationCache, skill, attakerPos, damagerAccount);
                    break;
                }
            case ElementTypeCode.Pyro:
                {
                    TrigerPyro(fightType, elementApplicationCache, skill, attakerPos, damagerAccount);
                    break;
                }
            case ElementTypeCode.Cryo:
                {
                    TrigerCryo(fightType, elementApplicationCache, skill, attakerPos, damagerAccount);
                    break;
                }
        }
    }

    private void Update()
    {
        ElementDecay();
    }

    private void ElementDecay()
    {
        if (elementApplicationDict.Count == 0)
        {
            return;
        }
        if (elementApplicationDict.ContainsKey(ElementTypeCode.Cryoing))
        {
            frozenRate += 0.1f * Time.deltaTime;
        }
        else
        {
            frozenRate -= 0.2f * Time.deltaTime;
            frozenRate = Math.Max(0, frozenRate);
        }

        foreach (var value in elementApplicationDict.Values)
        {
            if (value != null)
            {
                if (value.Type == ElementTypeCode.Cryoing)
                {
                    value.Gauge -= frozenRate * Time.deltaTime;
                }
                else
                {
                    value.Gauge -= value.DecayRate * Time.deltaTime;
                }
            }
        }
        List<ElementTypeCode> elementTypeList = new List<ElementTypeCode>();
        foreach (var value in elementApplicationDict.Values)
        {
            if (value.Gauge <= 0f)
            {
                SangoRoot.Instance.dynamicWindow.RemoveEnemyElementImg(DamagerAccount, value.Type);
                elementTypeList.Add(value.Type);
            }
        }
        for (int i = 0; i < elementTypeList.Count; i++)
        {
            elementApplicationDict.Remove(elementTypeList[i]);
        }
    }

    private void TrigerHydro(FightTypeCode fightType, ElementApplicationCache hydroApplicationCache, SkillCode skill, Vector3 attakerPos, string damagerAccount)
    {       
        if (elementApplicationDict.ContainsKey(ElementTypeCode.Hydro))
        {
            elementApplicationDict[ElementTypeCode.Hydro].Gauge = hydroApplicationCache.Gauge;
        }
        else if (elementApplicationDict.ContainsKey(ElementTypeCode.Pyro))
        {
            ReactionVaporize(fightType, hydroApplicationCache, elementApplicationDict[ElementTypeCode.Pyro], skill, attakerPos, damagerAccount);
        }
        else if (elementApplicationDict.ContainsKey(ElementTypeCode.Cryo))
        {
            ReactionFrozen(fightType, hydroApplicationCache, elementApplicationDict[ElementTypeCode.Cryo], skill, attakerPos, damagerAccount);
        }
        else
        {
            elementApplicationDict.Add(ElementTypeCode.Hydro, hydroApplicationCache);
            CacheSystem.Instance.attackDamageRequest.SetAttackDamage(fightType, damagerAccount, skill, ElementReactionCode.AddHydro, attakerPos, transform.position);
            SangoRoot.Instance.dynamicWindow.AddEnemyElementImg(DamagerAccount, ElementTypeCode.Hydro);
        }
    }

    private void TrigerPyro(FightTypeCode fightType, ElementApplicationCache pyroApplicationCache, SkillCode skill, Vector3 attakerPos, string damagerAccount)
    {
        if (elementApplicationDict.ContainsKey(ElementTypeCode.Pyro))
        {
            elementApplicationDict[ElementTypeCode.Pyro].Gauge = pyroApplicationCache.Gauge;
        }
        else if (elementApplicationDict.ContainsKey(ElementTypeCode.Cryoing))
        {
            ReactionMelt(fightType, pyroApplicationCache, elementApplicationDict[ElementTypeCode.Cryoing], skill, attakerPos, damagerAccount);
        }
        else if (elementApplicationDict.ContainsKey(ElementTypeCode.Cryo))
        {
            ReactionMelt(fightType, pyroApplicationCache, elementApplicationDict[ElementTypeCode.Cryo], skill, attakerPos, damagerAccount);
        }
        else if (elementApplicationDict.ContainsKey(ElementTypeCode.Hydro))
        {
            ReactionVaporize(fightType, elementApplicationDict[ElementTypeCode.Hydro], pyroApplicationCache, skill, attakerPos, damagerAccount);
        }
        else
        {
            elementApplicationDict.Add(ElementTypeCode.Pyro, pyroApplicationCache);
            CacheSystem.Instance.attackDamageRequest.SetAttackDamage(fightType, damagerAccount, skill, ElementReactionCode.AddPyro, attakerPos, transform.position);
            SangoRoot.Instance.dynamicWindow.AddEnemyElementImg(DamagerAccount, ElementTypeCode.Pyro);
        }
    }

    private void TrigerCryo(FightTypeCode fightType, ElementApplicationCache cryoApplicationCache, SkillCode skill, Vector3 attakerPos, string damagerAccount)
    {
        if (elementApplicationDict.ContainsKey(ElementTypeCode.Cryo))
        {
            elementApplicationDict[ElementTypeCode.Cryo].Gauge = cryoApplicationCache.Gauge;
        }
        else if (elementApplicationDict.ContainsKey(ElementTypeCode.Hydro))
        {
            ReactionFrozen(fightType, elementApplicationDict[ElementTypeCode.Hydro], cryoApplicationCache, skill, attakerPos, damagerAccount);
        }
        else if (elementApplicationDict.ContainsKey(ElementTypeCode.Pyro))
        {
            ReactionMelt(fightType, elementApplicationDict[ElementTypeCode.Pyro], cryoApplicationCache, skill, attakerPos, damagerAccount);
        }
        else
        {
            elementApplicationDict.Add(ElementTypeCode.Cryo, cryoApplicationCache);
            CacheSystem.Instance.attackDamageRequest.SetAttackDamage(fightType, damagerAccount, skill, ElementReactionCode.AddCryo, attakerPos, transform.position);
            SangoRoot.Instance.dynamicWindow.AddEnemyElementImg(DamagerAccount, ElementTypeCode.Cryo);
        }
    }

    private void ReactionVaporize(FightTypeCode fightType, ElementApplicationCache elementHydro, ElementApplicationCache elementPyro, SkillCode skill, Vector3 attakerPos, string damagerAccount)
    {
        if (elementHydro.Gauge < 0 || elementPyro.Gauge < 0)
        {
            return;
        }
        if (elementHydro.Gauge * unitModifier > elementPyro.Gauge)    //Hydro left
        {
            elementHydro.Gauge -= elementPyro.Gauge / unitModifier;
            elementPyro.Gauge = 0;
        }
        else    //Pyro left
        {
            elementPyro.Gauge -= elementHydro.Gauge * unitModifier;
            elementHydro.Gauge = 0;
        }
        CacheSystem.Instance.attackDamageRequest.SetAttackDamage(fightType, damagerAccount, skill, ElementReactionCode.Vaporize, attakerPos, transform.position);
        SangoRoot.Instance.dynamicWindow.PlayElementReactionName(ElementReactionCode.Vaporize, transform.position);
    }

    private void ReactionMelt(FightTypeCode fightType, ElementApplicationCache elementPyro, ElementApplicationCache elementCryo, SkillCode skill, Vector3 attakerPos, string damagerAccount)
    {
        if (elementPyro.Gauge < 0 || elementCryo.Gauge < 0)
        {
            return;
        }
        if (elementPyro.Gauge * unitModifier > elementCryo.Gauge)    //Pyro left
        {
            elementPyro.Gauge -= elementCryo.Gauge / unitModifier;
            elementCryo.Gauge = 0;
        }
        else    //Cryo left
        {
            elementCryo.Gauge -= elementPyro.Gauge * unitModifier;
            elementPyro.Gauge = 0;
        }
        CacheSystem.Instance.attackDamageRequest.SetAttackDamage(fightType, damagerAccount, skill, ElementReactionCode.Melt, attakerPos, transform.position);
        SangoRoot.Instance.dynamicWindow.PlayElementReactionName(ElementReactionCode.Melt, transform.position);
    }

    private void ReactionFrozen(FightTypeCode fightType, ElementApplicationCache elementHydro, ElementApplicationCache elementCryo, SkillCode skill, Vector3 attakerPos, string damagerAccount)
    {
        if (elementHydro.Gauge < 0 || elementCryo.Gauge < 0)
        {
            return;
        }
        float reactionFrozenGauge;
        if (elementHydro.Gauge > elementCryo.Gauge)    //Hydro left
        {
            elementHydro.Gauge -= elementCryo.Gauge;
            elementCryo.Gauge = 0;
            reactionFrozenGauge = unitModifier * elementCryo.Gauge;
        }
        else    //Cryo left
        {
            elementCryo.Gauge -= elementHydro.Gauge;
            elementHydro.Gauge = 0;
            reactionFrozenGauge = unitModifier * elementHydro.Gauge;
        }
        if (elementApplicationDict.ContainsKey(ElementTypeCode.Cryoing))
        {
            elementApplicationDict[ElementTypeCode.Cryoing].Gauge = reactionFrozenGauge;
        }
        else
        {
            elementApplicationDict.Add(ElementTypeCode.Cryoing, new ElementApplicationCache(ElementTypeCode.Cryoing, reactionFrozenGauge));
            frozenRate = frozenOriginalRate;
        }
        CacheSystem.Instance.attackDamageRequest.SetAttackDamage(fightType, damagerAccount, skill, ElementReactionCode.Frozen, attakerPos, transform.position);
        SangoRoot.Instance.dynamicWindow.PlayElementReactionName(ElementReactionCode.Frozen, transform.position);
    }
}
