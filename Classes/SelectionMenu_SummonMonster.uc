class SelectionMenu_SummonMonster extends RPGSelectionMenu;

static function name GetMonsterIdleAnim(class<Monster> MonsterClass, Actor RefActor)
{
	if(RefActor.HasAnim(MonsterClass.default.IdleRestAnim))
		return MonsterClass.default.IdleRestAnim;
	else if(RefActor.HasAnim(MonsterClass.default.AirStillAnim))
		return MonsterClass.default.AirStillAnim;
	else if(ClassIsChildOf(MonsterClass, class'RazorFly')) //well done, Epic
		return 'Fly';
	else
		return 'Idle_Rest';
}

function int GetNumItems()
{
	return Artifact_MonsterSummon(Artifact).MonsterTypes.Length;
}

function string GetItem(int i)
{
	return
		Artifact_MonsterSummon(Artifact).MonsterTypes[i].DisplayName @
		"(" $ Artifact_MonsterSummon(Artifact).MonsterTypes[i].Cost $ ")";
}

function int GetDefaultItemIndex()
{
	return Artifact.MenuPickBest();
}

function SelectItem()
{
	local int i;
	local int Cost;
	local class<Monster> SelectedMonster;

	if(SpinnyItem != None)
	{
		if(lstItems.List.Index >= 0)
		{
			SelectedMonster = Artifact_MonsterSummon(Artifact).MonsterTypes[lstItems.List.Index].MonsterClass;
			SpinnyItem.LinkMesh(SelectedMonster.default.Mesh);
			
			SpinnyItem.Skins.Length = SelectedMonster.default.Skins.Length;
			for(i = 0; i < SelectedMonster.default.Skins.Length; i++)
				SpinnyItem.Skins[i] = SelectedMonster.default.Skins[i];
			
			SpinnyItem.LoopAnim(
				GetMonsterIdleAnim(SelectedMonster, SpinnyItem), 1.0 / SpinnyItem.Level.TimeDilation);
		}
		else
		{
			SpinnyItem.LinkMesh(None);
		}
	}
	
	if(Artifact_MonsterSummon(Artifact).bUseCostAsCooldown)
	{
		btOK.MenuState = MSAT_Blurry;
	}
	else
	{
		Cost = Artifact_MonsterSummon(Artifact).MonsterTypes[lstItems.List.Index].Cost;
		if(Cost > PlayerOwner().Adrenaline)
			btOK.MenuState = MSAT_Disabled;
		else
			btOK.MenuState = MSAT_Blurry;
	}
}

defaultproperties
{
	OKText="Summon"

	WindowTitle="Pick Monster to summon"
	
	ListTitle="Monsters"
	ListHint="Select a monster to summon"

	SpinnyItemOffset=(X=80,Y=0,Z=0)
	SpinnyItemRotation=(Pitch=-2048,Yaw=36864,Roll=0)
}
