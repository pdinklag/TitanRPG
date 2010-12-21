class MagicWeaponMenu extends RPGSelectionMenu;

var class<Weapon> WeaponType;
var array<class<RPGWeapon> > Available;

function Timer()
{
	SpinnyItemRotation.Yaw += 2048;

	Super.Timer();
}

function InitFor(RPGArtifact A)
{
	local class<Pickup> PickupClass;

	if(A.Instigator.Weapon.IsA('RPGWeapon'))
		WeaponType = RPGWeapon(A.Instigator.Weapon).ModifiedWeapon.class;
	else
		WeaponType = A.Instigator.Weapon.class;

	Available[0] = class'WeaponDamage';
	Available[1] = class'WeaponFreeze';

	Super.InitFor(A);
	
	if(SpinnyItem != None)
	{
		PickupClass = WeaponType.default.PickupClass;
	
		SpinnyItem.SetDrawType(DT_StaticMesh);
		SpinnyItem.SetStaticMesh(PickupClass.default.StaticMesh);
		SpinnyItem.SetDrawScale(PickupClass.default.DrawScale);
	}
}

function int GetNumItems()
{
	return Available.Length;
}

function string GetItem(int i)
{
	return Repl(Available[i].default.PatternPos, "$W", WeaponType.default.ItemName);
}

function int GetDefaultItemIndex()
{
	return 0;
}

function SelectItem()
{
	if(SpinnyItem != None)
		SpinnyItem.SetOverlayMaterial(Available[lstItems.List.Index].default.OverlayMaterial, 100000, true);
}

function bool OKClicked(GUIComponent Sender)
{
	ArtifactMakeSelectedMagicWeapon(Artifact).ServerPickWeapon(Available[lstItems.List.Index]);
	return Super.OKClicked(Sender);
}

defaultproperties
{
	OKText="Enchant"

	WindowTitle="Pick Weapon Modifier"
	
	ListTitle="Weapon Modifiers"
	ListHint="Select a Weapon Modifier"

	SpinnyItemOffset=(X=80,Y=0,Z=0)
	SpinnyItemRotation=(Pitch=0,Yaw=0,Roll=0)
}
