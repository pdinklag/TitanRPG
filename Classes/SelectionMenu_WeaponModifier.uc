class SelectionMenu_WeaponModifier extends RPGSelectionMenu;

var class<Weapon> WeaponType;
var array<class<RPGWeapon> > Available;

//TODO: adapt

/*
	Overlay materials don't work with this thing, so I'm creating a second spinny item that is
	slightly larger than the original, to emulate the effect if a magic's ModifierOverlay is not a FinalBlend.
*/

/*
var SpinnyWeap SpinnyOverlay; // MUST be set to null when you leave the window
var FinalBlend OverlayFB;
var bool bRenderOverlay;

const NUM_SKINS = 4;

function Timer()
{
	SpinnyItemRotation.Yaw += 1024;
}

function InitFor(RPGArtifact A)
{
	local int i;
	local class<RPGWeapon> RW;
	local class<Pickup> PickupClass;

	if(A.Instigator.Weapon.IsA('RPGWeapon'))
		WeaponType = RPGWeapon(A.Instigator.Weapon).ModifiedWeapon.class;
	else
		WeaponType = A.Instigator.Weapon.class;

	for(i = 0; i < ArtifactMakeSelectedMagicWeapon(A).Available.Length; i++)
	{
		RW = class<RPGWeapon>(ArtifactMakeSelectedMagicWeapon(A).Available.ObjectArray[i]);
		if(RW != None && RW.static.AllowedFor(WeaponType, A.Instigator))
			Available[Available.Length] = RW;
	}
	
	PickupClass = WeaponType.default.PickupClass;

	if(SpinnyOverlay == None)
	{
		SpinnyOverlay = PlayerOwner().Spawn(class'XInterface.SpinnyWeap');
		SpinnyOverlay.SetDrawType(DT_StaticMesh);
		SpinnyOverlay.SetStaticMesh(PickupClass.default.StaticMesh);
		SpinnyOverlay.SetDrawScale(PickupClass.default.DrawScale * 1.01); //slightly larger
		SpinnyOverlay.bHidden = true;
		
		OverlayFB = new(None) class'FinalBlend';
		OverlayFB.FrameBufferBlending = FB_Translucent;

		for(i = 0; i < NUM_SKINS; i++)
			SpinnyOverlay.Skins[i] = OverlayFB;
	}

	Super.InitFor(A);
	
	if(SpinnyItem != None)
	{
		SpinnyItem.SetDrawType(DT_StaticMesh);
		SpinnyItem.SetStaticMesh(PickupClass.default.StaticMesh);
		SpinnyItem.SetDrawScale(PickupClass.default.DrawScale);
	}
	
	SetTimer(0.05f, true);
}

function InternalDraw(Canvas Canvas)
{
	local SpinnyWeap OriginalSpinny;

	Super.InternalDraw(Canvas);
	
	if(bRenderOverlay)
	{
		OriginalSpinny = SpinnyItem;
		SpinnyItem = SpinnyOverlay;
		
		Super.InternalDraw(Canvas);
		
		SpinnyItem = OriginalSpinny;
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
	local int i;
	local Material Mat;

	if(SpinnyItem != None)
	{
		Mat = Available[lstItems.List.Index].default.ModifierOverlay;
		
		if(Mat.IsA('Shader') && Shader(Mat).Specular != None)
		{
			for(i = 0; i < NUM_SKINS; i++)
				SpinnyItem.Skins[i] = None;

			OverlayFB.Material = Shader(Mat).Specular;
			bRenderOverlay = true;
		}
		else if(SpinnyOverlay != None)
		{
			for(i = 0; i < NUM_SKINS; i++)
				SpinnyItem.Skins[i] = Mat;
			
			bRenderOverlay = false;
		}
	}
}

function bool OKClicked(GUIComponent Sender)
{
	ArtifactMakeSelectedMagicWeapon(Artifact).ServerPickWeapon(Available[lstItems.List.Index]);
	return Super.OKClicked(Sender);
}

event Closed(GUIComponent Sender, bool bCancelled)
{
	KillTimer();
	Super.Closed(Sender, bCancelled);
}

event Free()
{
	Available.Length = 0;

	if(SpinnyOverlay != None)
	{
		SpinnyOverlay.Destroy();
		SpinnyOverlay = None;
	}
	
	OverlayFB = None;
	
	Super.Free();
}

defaultproperties
{
	OKText="Enchant"

	WindowTitle="Pick Weapon Modifier"
	
	ListTitle="Weapon Modifiers"
	ListHint="Select a Weapon Modifier"

	SpinnyItemOffset=(X=80,Y=0,Z=0)
	SpinnyItemRotation=(Pitch=0,Yaw=0,Roll=0)
	
	OnRendered=InternalDraw
}
*/
