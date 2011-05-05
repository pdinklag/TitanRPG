class AbilityLooter extends RPGAbility;

struct DropItemStruct
{
	var int Level;
	var class<Pickup> PickupClass;
	var int Chance;
};

var config array<DropItemStruct> DropItems;

function ScoreKill(Controller Killed, class<DamageType> DamageType)
{
	local int i, x, k, TotalChance, Amount;
	local class<Pickup> PickupClass;
	local Pickup Pickup;
	local Pawn Victim;
	
	Victim = Killed.Pawn;
	if(Victim != None)
	{
		for(i = 0; i < DropItems.Length; i++)
		{
			if(AbilityLevel < DropItems[i].Level)
				continue;
		
			TotalChance += DropItems[i].Chance;
		}
		
		Amount = 1 + Rand((AbilityLevel - 1) * BonusPerLevel);
		
		for(k = 0; k < Amount; k++)
		{
			x = Rand(TotalChance);
			for(i = 0; i < DropItems.Length; i++)
			{
				if(AbilityLevel < DropItems[i].Level)
					continue;
			
				x -= DropItems[i].Chance;
				if(x <= 0)
				{
					PickupClass = DropItems[i].PickupClass;
					break;
				}
			}
			
			//Spawn pickup
			Pickup = Spawn(PickupClass, None, '', Victim.Location);
			Pickup.InitDroppedPickupFor(Pickup.Inventory);
			Pickup.Velocity = VRand() * RandRange(10.0f, 20.0f);
			Pickup.Velocity.Z = FMin(5.0f, Abs(Pickup.Velocity.Z));
		}
	}
}

//TODO: Description?

defaultproperties
{
	AbilityName="Looter"
	Description="If you kill somebody, your victim will drop more powerful pickups each level."
	MaxLevel=3
	BonusPerLevel=1 //amount of pickups
	bUseLevelCost=true
	LevelCost(0)=15
	LevelCost(1)=15
	LevelCost(2)=10
	DropItems(0)=(Level=1,Chance=40,PickupClass=class'XPickups.MiniHealthPack')
	DropItems(1)=(Level=1,Chance=35,PickupClass=class'XPickups.AdrenalinePickup')
	DropItems(2)=(Level=2,Chance=15,PickupClass=class'XPickups.HealthPack')
	DropItems(3)=(Level=3,Chance=9,PickupClass=class'XPickups.ShieldPack')
	DropItems(4)=(Level=3,Chance=1,PickupClass=class'XPickups.UDamagePack')
	Category=class'AbilityCategory_Misc'
}
