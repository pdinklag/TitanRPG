class WeaponModifier_Penetrating extends RPGWeaponModifier;

var localized string PenetratingText;

var int Recursions;

static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
	local int x;
	
	if(!Super.AllowedFor(Weapon, Other))
		return false;

	for (x = 0; x < 2; x++) {
		if(ClassIsChildOf(Weapon.default.FireModeClass[x], class'InstantFire'))
			return true;
	}

	return false;
}

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local int i;
	local vector X, Y, Z, StartTrace;
    local WeaponFire FireMode;

	Super.AdjustTargetDamage(Damage, OriginalDamage, Injured, InstigatedBy, HitLocation, Momentum, DamageType);
	Identify();
	
	if(Recursions >= 10)
	{
		Log(Self @ "More than 10 recursions detected!");
		return;
	}

	for (i = 0; i < Weapon.NUM_FIRE_MODES; i++) {
        FireMode = Weapon.GetFireMode(i);
		if (InstantFire(FireMode) != None && InstantFire(FireMode).DamageType == DamageType) {
			//HACK - compensate for shock rifle not firing on crosshair
			if(ShockBeamFire(FireMode) != None && PlayerController(InstigatedBy.Controller) != None) {
				StartTrace = InstigatedBy.Location + InstigatedBy.EyePosition();
				Weapon.GetViewAxes(X,Y,Z);
				StartTrace = StartTrace + X * class'ShockProjFire'.Default.ProjSpawnOffset.X;
				if (!Weapon.WeaponCentered())
					StartTrace = StartTrace + Weapon.Hand * Y * class'ShockProjFire'.Default.ProjSpawnOffset.Y + Z * class'ShockProjFire'.Default.ProjSpawnOffset.Z;
				
				Recursions++;
				InstantFire(FireMode).DoTrace(
                    HitLocation + Normal(HitLocation - StartTrace) * Injured.CollisionRadius * 2,
                    rotator(HitLocation - StartTrace));
				Recursions--;
			}
			else {
				Recursions++;
				InstantFire(FireMode).DoTrace(
                    HitLocation + Normal(HitLocation - (InstigatedBy.Location + InstigatedBy.EyePosition())) * Injured.CollisionRadius * 2,
                    rotator(HitLocation - (InstigatedBy.Location + InstigatedBy.EyePosition())));
				Recursions--;
			}
			return;
		}
	}
}

simulated function BuildDescription()
{
	Super.BuildDescription();
	AddToDescription(PenetratingText);
}

defaultproperties
{
	DamageBonus=0.05
	MinModifier=-2
	MaxModifier=4
	bCanHaveZeroModifier=True
	PenetratingText="fires through enemies"
	ModifierOverlay=Shader'XGameShaders.PlayerShaders.PlayerTrans'
	PatternPos="Penetrating $W"
	//AI
	AIRatingBonus=0
}
