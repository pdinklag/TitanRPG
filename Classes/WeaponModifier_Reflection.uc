class WeaponModifier_Reflection extends RPGWeaponModifier;

struct ReflectMapStruct
{
	var class<DamageType> DamageType;
	var class<WeaponFire> WeaponFire;
};
var config array<ReflectMapStruct> ReflectMap;
var config float BaseChance;

var config array<class<RPGEffect> > ReflectEffects;

var bool bLock;

var localized string ReflectionText;

replication {
    reliable if(Role == ROLE_Authority)
		ClientReceiveReflectionConfig;
}

function SendConfig() {
    Super.SendConfig();
    ClientReceiveReflectionConfig(BaseChance);
}

simulated function ClientReceiveReflectionConfig(float a) {
    if(Role < ROLE_Authority) {
        BaseChance = a;
    }
}

function bool AllowEffect(class<RPGEffect> EffectClass, Controller Causer, float Duration, float Modifier)
{
	local RPGEffect Reflected;
    
    if(class'Util'.static.InArray(EffectClass, ReflectEffects) >= 0) {
		if(Causer.Pawn != None && WeaponModifier_Reflection(class'RPGWeaponModifier'.static.GetFor(Causer.Pawn.Weapon)) == None) {
			Reflected = EffectClass.static.Create(Causer.Pawn, Instigator.Controller, Duration, Modifier);
			if(Reflected != None)
				Reflected.Start();
		}
		return false;
    }

	return true;
}

function class<WeaponFire> MapDamageType(class<DamageType> DamageType)
{
	local int i;
	
	for(i = 0; i < ReflectMap.Length; i++)
	{
		if(ReflectMap[i].DamageType == DamageType)
			return ReflectMap[i].WeaponFire;
	}
	return None;
}

function WeaponFire FindWeaponFire(Pawn Other, class<WeaponFire> WFClass)
{
	local Inventory Inv;
	local Weapon W;
	local int i;
	
	for(Inv = Other.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		W = Weapon(Inv);
		if(W != None)
		{
			for(i = 0; i < W.NUM_FIRE_MODES; i++)
			{
				if(ClassIsChildOf(W.FireModeClass[i], WFClass))
					return W.GetFireMode(i);
			}
		}
	}
	
	return None;
}

function AdjustPlayerDamage(out int Damage, int OriginalDamage, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local WeaponFire WF;
	local class<WeaponFire> WFClass;
	local rotator ReflectDir;

	if(Damage > 0 && Instigator != InstigatedBy && !Instigator.Controller.SameTeamAs(InstigatedBy.Controller))
	{
		WFClass = MapDamageType(DamageType);
		if(WFClass != None && FRand() < (BaseChance + float(Modifier) * BonusPerLevel))
		{
            if(bLock) {
                Warn("Reflection: Recursion!!");
            } else {
                bLock = true;
            
                Identify();
                ReflectDir = rotator(HitLocation - Weapon.Location);
                
                WF = FindWeaponFire(InstigatedBy, WFClass);
                if(WF != None)
                {
                    if(WF.IsA('ProjectileFire')) {
                        Log("Reflection: SpawnProjectile" @ WF);
                        ProjectileFire(WF).SpawnProjectile(Instigator.Location + Instigator.CollisionHeight * vector(ReflectDir), ReflectDir);
                    } else if(WF.IsA('InstantFire')) {
                        Log("Reflection: DoTrace using " @ WF);
                        InstantFire(WF).SpawnBeamEffect(Instigator.Location + Instigator.CollisionHeight * vector(ReflectDir), ReflectDir, HitLocation, vector(ReflectDir), 0);
                    }
                }
                else
                {
                    Log("Couldn't find" @ WFClass @ "for" @ InstigatedBy, 'DEBUG');
                }
                
                bLock = false;
            }
			
			Damage = 0;
			Momentum = vect(0, 0, 0);
		}
	}
}

simulated function BuildDescription()
{
	Super.BuildDescription();
	AddToDescription(Repl(ReflectionText, "$1", class'Util'.static.FormatPercent(BaseChance + float(Modifier) * BonusPerLevel)));
}

defaultproperties
{
	ReflectionText="$1 reflection chance"
	DamageBonus=0.05
	BaseChance=0.25
	BonusPerLevel=0.10
	MinModifier=1
	MaxModifier=7
	//ModifierOverlay=Shader'AWGlobal.Shaders.WetBlood01aw'
	ModifierOverlay=TexEnvMap'VMVehicles-TX.Environments.ReflectionEnv'
	PatternPos="Reflecting $W"
	bCanHaveZeroModifier=True
	//Reflect
	ReflectMap(0)=(DamageType=class'DamTypeLinkPlasma',WeaponFire=class'LinkAltFire')
	ReflectMap(1)=(DamageType=class'DamTypeShockBeam',WeaponFire=class'ShockBeamFire')
	ReflectMap(2)=(DamageType=class'DamTypeShockBall',WeaponFire=class'ShockProjFire')
    ReflectEffects(0)=class'Effect_NullEntropy'
    ReflectEffects(1)=class'Effect_Disco'
	//AI
	AIRatingBonus=0.025
	CountersModifier(0)=class'WeaponModifier_NullEntropy'
	CountersModifier(1)=class'WeaponModifier_Party'
	CountersDamage(0)=class'DamTypeShockBeam'
	CountersDamage(1)=class'DamTypeShockBall'
	CountersDamage(2)=class'DamTypeLinkPlasma'
}
