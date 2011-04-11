class AbilityLoadedWeapons extends RPGAbility;

struct GrantWeaponStruct
{
	var int Level;
	var class<Weapon> WeaponClass;
};
var config array<GrantWeaponStruct> Weapons;

var ReplicatedArray WeaponsRepl;

var bool bTC0X; //for BattleMode's ONSRPG compatibility

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		WeaponsRepl;
}

simulated event PreBeginPlay()
{
	local int i;
	
	Super.PreBeginPlay();

	if(ShouldReplicateInfo())
	{
		WeaponsRepl = Spawn(class'ReplicatedArray', Owner);
		WeaponsRepl.Length = Weapons.Length;
		for(i = 0; i < Weapons.Length; i++)
		{
			WeaponsRepl.ObjectArray[i] = Weapons[i].WeaponClass;
			WeaponsRepl.IntArray[i] = Weapons[i].Level;
		}
		WeaponsRepl.Replicate();
		FinalSyncState++;
	}
}

simulated event PostNetReceive()
{
	local GrantWeaponStruct W;
	local int i;

	if(ShouldReceive() && WeaponsRepl != None)
	{
		Weapons.Length = WeaponsRepl.Length;
		for(i = 0; i < Weapons.Length; i++)
		{
			W.WeaponClass = class<Weapon>(WeaponsRepl.ObjectArray[i]);
			W.Level = WeaponsRepl.IntArray[i];
			Weapons[i] = W;
		}
		
		WeaponsRepl.SetOwner(Owner);
		WeaponsRepl.ServerDestroy();
		ClientSyncState++;
	}
	
	Super.PostNetReceive();
}

function ModifyPawn(Pawn Other)
{
	local int x;
	
	Super.ModifyPawn(Other);

	for(x = 0; x < Weapons.length; x++)
	{
		if(AbilityLevel >= Weapons[x].Level)
		{
			if(Weapons[x].WeaponClass != None)
				GrantWeapon(Weapons[x].WeaponClass, Other);
		}
	}
}

function GrantWeapon(class<Weapon> WeaponClass, Pawn Other)
{
	local int x;
	local class<RPGWeapon> ModifierClass;
	local int ModifierLevel;
	
	ModifierClass = RPRI.RPGMut.GetRandomWeaponModifier(WeaponClass, Other, (AbilityLevel >= 3));
	
	if(AbilityLevel >= MaxLevel)
	{
		//max modifier
		ModifierLevel = ModifierClass.default.MaxModifier;
	}
	else if(!bTC0X && AbilityLevel >= 5)
	{
		//+4 or higher
		ModifierLevel = ModifierClass.static.GetRandomModifierLevel();
		for(x = 0; x < 50; x++)
		{
			if(ModifierLevel >= 4)
				break;
				
			ModifierLevel = ModifierClass.static.GetRandomModifierLevel();
		}
	}
	else if(AbilityLevel >= 4)
	{
		//positive
		ModifierLevel = ModifierClass.static.GetRandomModifierLevel();
		for(x = 0; x < 50; x++)
		{
			if(ModifierLevel >= 0)
				break;
				
			ModifierLevel = ModifierClass.static.GetRandomModifierLevel();
		}
	}
	else
	{
		//any
		ModifierLevel = ModifierClass.static.GetRandomModifierLevel();
	}
	
	if(AbilityLevel >= 2)
		x = -1;
	else
		x = 0;
	
	RPRI.QueueWeapon(WeaponClass, ModifierClass, ModifierLevel, x, x);
}

simulated function string DescriptionText()
{
	local int x, lv;
	local array<string> list;
	local string text;
	
	for(lv = 1; lv <= MaxLevel; lv++)
	{
		list.Length = 0;
	
		for(x = 0; x < Weapons.Length; x++)
		{
			if(Weapons[x].WeaponClass != None && Weapons[x].Level == lv)
				list[list.Length] = Weapons[x].WeaponClass.default.ItemName;
		}
		
		if(list.Length > 0)
		{
			text = AtLevelText @ string(lv) $ GrantPreText;
			for(x = 0; x < list.Length; x++)
			{
				text @= list[x];
				
				if(x + 2 < list.Length)
					text $= ",";
				else if(x + 1 < list.Length)
					text @= AndText;
			}
			text @= GrantPostText;
			
			LevelDescription[lv - 1] = text;
		}
	}
	return Super.DescriptionText();
}

defaultproperties
{
	bTC0X=False //true for AbilityLoadedWeapons_TC0X

	AbilityName="Loaded Weapons"
	Description="You are granted weapons when you spawn:"
	//LevelDescription(0)="Level 1: You are granted all regular weapons with the default percentage chance for magic weapons."
	//LevelDescription(1)="Level 2: You are granted onslaught weapons and all weapons with max ammo."
	LevelDescription(0)=""
	LevelDescription(1)=""
	LevelDescription(2)="At level 3, all your weapons will be enchanted."
	LevelDescription(3)="At level 4, all of your weapons will be of positive magic."
	LevelDescription(4)="At level 5, All of your weapons will be of +4 magic or higher."
	LevelDescription(5)="At level 6, All of your weapons will be of MAX magic."
	StartingCost=15
	CostAddPerLevel=5
	MaxLevel=6
	ForbiddenAbilities(0)=(AbilityClass=class'AbilityAdrenalineSurge',Level=1)
	RequiredAbilities(0)=(AbilityClass=class'AbilityRegen',Level=1)
	RequiredAbilities(1)=(AbilityClass=class'AbilityVampire',Level=1)
	RequiredAbilities(2)=(AbilityClass=class'AbilityAmmoRegen',Level=1)
}
