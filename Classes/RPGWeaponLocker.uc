class RPGWeaponLocker extends WeaponLocker
	notplaceable;

var WeaponLocker ReplacedLocker; //this is the locker we replaced

function Inventory SpawnCopy( pawn Other )
{
	local inventory Copy;
	local RPGPlayerReplicationInfo RPRI;
	local RPGWeapon OldWeapon;
	local class<RPGWeapon> NewWeaponClass;
	local int x;
	local bool bRemoveReference;

	if ( Inventory != None )
		Inventory.Destroy();

	//if player previously had a weapon of class InventoryType, force modifier to be the same
	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Other.Controller);
	if (RPRI != None)
	{
		for (x = 0; x < RPRI.OldRPGWeapons.length; x++)
		{
			if (RPRI.OldRPGWeapons[x].ModifiedClass == InventoryType)
			{
				OldWeapon = RPRI.OldRPGWeapons[x].Weapon;
				if (OldWeapon == None)
				{
					RPRI.OldRPGWeapons.Remove(x, 1);
					x--;
				}
				else
				{
					NewWeaponClass = class'RPGWeapon'; //no magic at all once dropped
					break;
				}
			}
		}
	}
	else
	{
		Log("RPRI not found for " $ Other.GetHumanReadableName(), 'TitanRPG');
	}

	if (NewWeaponClass == None)
		NewWeaponClass = class'MutTitanRPG'.static.Instance(Level).GetRandomWeaponModifier(class<Weapon>(InventoryType), Other);

	if(NewWeaponClass != None)
	{
		Copy = spawn(NewWeaponClass,Other,,,rot(0,0,0));
		if(Copy != None)
		{
			if(NewWeaponClass != class'RPGWeapon')
				RPGWeapon(Copy).Generate(OldWeapon);
			else
				RPGWeapon(Copy).Generate(None);
			
			RPGWeapon(Copy).SetModifiedWeapon(
				Weapon(spawn(InventoryType,Other,,,rot(0,0,0))),
				((bDropped && OldWeapon != None && OldWeapon.bIdentified) || class'MutTitanRPG'.static.Instance(Level).GameSettings.bNoUnidentified));

			Copy.GiveTo(Other, self);
		}
	}
	else
	{
		Log("RPGWeaponLocker.SpawnCopy - NewWeaponClass is None! OldWeapon = " $ OldWeapon, 'TitanRPG');
	}

	if (bRemoveReference)
		OldWeapon.RemoveReference();

	return Copy;
}

function Tick(float deltaTime)
{
	local int i;

	//steal attributes from WeaponLocker we replaced
	Weapons = ReplacedLocker.Weapons;
	bSentinelProtected = ReplacedLocker.bSentinelProtected;

	MaxDesireability = 0;

	if (bHidden)
		return;
	for (i = 0; i < Weapons.Length; i++)
		MaxDesireability += Weapons[i].WeaponClass.Default.AIRating;
	SpawnLockerWeapon();

	disable('Tick');
	bStasis = true;
}

auto state LockerPickup
{
	simulated function Touch( actor Other )
	{
		local Weapon Copy;
		local int i;
		local Inventory Inv;
		local Pawn P;

		// If touched by a player pawn, let him pick this up.
		if( ValidTouch(Other) )
		{
			P = Pawn(Other);
			if ( (PlayerController(P.Controller) != None) && (Viewport(PlayerController(P.Controller).Player) != None) )
			{
				if ( (Effect != None) && !Effect.bHidden )
					Effect.TurnOff(30);
			}
			
			if ( Role < ROLE_Authority )
				return;
				
			if ( !AddCustomer(P) )
				return;
				
			TriggerEvent(Event, self, P);
			for ( i=0; i < Weapons.Length; i++ )
			{
				InventoryType = Weapons[i].WeaponClass;
				Copy = None;
				
				for (Inv = P.Inventory; Inv != None; Inv = Inv.Inventory)
				{
					if ( Inv.Class == Weapons[i].WeaponClass
					     || (RPGWeapon(Inv) != None && RPGWeapon(Inv).ModifiedWeapon.Class == Weapons[i].WeaponClass) )
					{
						Copy = Weapon(Inv);
						break;
					}
				}
					
				if ( Copy != None )
				{
					Copy.FillToInitialAmmo();
				}
				else if ( Level.Game.PickupQuery(P, self) )
				{
					Copy = Weapon(SpawnCopy(P));
					if ( Copy != None )
					{
						Copy.PickupFunction(P);
						if ( Weapons[i].ExtraAmmo > 0 )
							Copy.AddAmmo(Weapons[i].ExtraAmmo, 0);
					}
				}

				//ChaosUT stuff removed
			}

			AnnouncePickup(P);
		}
	}
}

defaultproperties
{
     bStatic=False
     bGameRelevant=True
     bCollideWorld=False
}
