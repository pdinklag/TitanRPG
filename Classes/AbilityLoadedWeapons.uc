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
	}
}

simulated event PostNetReceive()
{
	local GrantWeaponStruct W;
	local int i;
	
	Super.PostNetReceive();

	if(Role < ROLE_Authority && WeaponsRepl != None)
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
	}
}

function ModifyPawn(Pawn Other)
{
	local string WeaponClassName;
	local int x;
	
	Super.ModifyPawn(Other);

	for(x = 0; x < Weapons.length; x++)
	{
		if(AbilityLevel >= Weapons[x].Level)
		{
			if(Weapons[x].WeaponClass != None)
			{
				WeaponClassName = string(Weapons[x].WeaponClass);
				WeaponClassName = Level.Game.BaseMutator.GetInventoryClassOverride(WeaponClassName);
			
				GiveWeapon(Other, class<Weapon>(DynamicLoadObject(WeaponClassName, class'Class')), AbilityLevel);
			}
		}
	}
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

static function GiveWeapon(Pawn Other, class<Weapon> WeaponClass, int AbilityLevel)
{
	local RPGPlayerReplicationInfo RPRI;
	local class<RPGWeapon> RPGWeaponClass;
	local Weapon NewWeapon;
	local RPGWeapon RPGWeapon;
	local int x;
	local MutTitanRPG RPGMut;

	if(Other.IsA('Monster'))
		return;
	
	RPGMut = class'MutTitanRPG'.default.Instance;
	
	newWeapon = Other.spawn(WeaponClass, Other,,, rot(0,0,0));
	
	if(RPGWeapon(newWeapon) != None)
		newWeapon = RPGWeapon(newWeapon).ModifiedWeapon;
	
	if(newWeapon != None)
	{
		RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Other.Controller);
		if(RPRI != None && RPRI.SuicidePenalty > 0)
		{
			RPGWeaponClass = class'RPGWeapon';
		}
		else
		{
			if(AbilityLevel >= 3) //definitively a magic wepon
				RPGWeaponClass = GetRandomWeaponModifier(WeaponClass, Other, RPGMut);
			else
				RPGWeaponClass = RPGMut.GetRandomWeaponModifier(WeaponClass, Other);
		}

		RPGWeapon = Other.spawn(RPGWeaponClass, Other,,, rot(0,0,0));
		
		if(RPGWeapon != None)
		{
			RPGWeapon.Generate(None);
			
			//Log("LW Line 159: RPGWeapon =" @ RPGWeapon);

			if(AbilityLevel >= 6 || (default.bTC0X && AbilityLevel >= 5))
			{
				RPGWeapon.Modifier = RPGWeapon.MaxModifier;
			}
			else if(!default.bTC0X && AbilityLevel >= 5)
			{
				for(x = 0; x < 50; x++)
				{
					if(RPGWeapon.Modifier >= 4)
						break;
						
					RPGWeapon.Generate(None);
				}
			}
			else if(AbilityLevel >= 4)
			{
				for(x = 0; x < 50; x++)
				{
					if(RPGWeapon.Modifier >= 0)
						break;

					RPGWeapon.Generate(None);
				}
			}
			
			//Log("LW Line 186: RPGWeapon =" @ RPGWeapon);
			
			RPGWeapon.SetModifiedWeapon(newWeapon, true);
			
			//Log("LW Line 190: RPGWeapon =" @ RPGWeapon);
			
			RPGWeapon.GiveTo(Other);

			if(AbilityLevel == 1)
				RPGWeapon.FillToInitialAmmo();
			else if(AbilityLevel > 1)
				RPGWeapon.MaxOutAmmo();
		}
	}
}

static function class<RPGWeapon> GetRandomWeaponModifier(class<Weapon> WeaponType, Pawn Other, MutTitanRPG RPGMut)
{
	local int x, Chance;

	Chance = Rand(RPGMut.TotalModifierChance);
	for(x = 0; x < RPGMut.WeaponModifiers.Length; x++)
	{
		Chance -= RPGMut.WeaponModifiers[x].Chance;
		if(Chance < 0 && RPGMut.WeaponModifiers[x].WeaponClass.static.AllowedFor(WeaponType, Other))
			return RPGMut.WeaponModifiers[x].WeaponClass;
	}

	return class'RPGWeapon';
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
