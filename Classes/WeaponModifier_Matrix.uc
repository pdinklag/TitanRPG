class WeaponModifier_Matrix extends RPGWeaponModifier;

var config float MatrixRadius;
var config array<name> Ignore;

var localized string MatrixText;

const SLOWDOWN_CAP = 0.1;

var RPGMatrixField Field;

function StartEffect() {
    Field = Spawn(class'RPGMatrixField', Instigator.Controller,, Instigator.Location, Instigator.Rotation);
    Field.SetBase(Instigator);
    Field.Radius = MatrixRadius;
    Field.Multiplier = FMax(SLOWDOWN_CAP, 1.0f - BonusPerLevel * float(Modifier));
    Field.OnMatrix = OnMatrix;
    Field.Ignore = Ignore;
}

function StopEffect() {
    Field.Destroy();
}

function OnMatrix(RPGMatrixField Field, Projectile Proj, float Multiplier) {
    Identify();
}

simulated function BuildDescription()
{
    local float Multiplier;

	Super.BuildDescription();
    
    Multiplier = FMin(1 - SLOWDOWN_CAP, BonusPerLevel * float(Modifier));
	AddToDescription(Repl(MatrixText, "$1", class'Util'.static.FormatPercent(Multiplier)));
}

defaultproperties
{
	MatrixText="$1 enemy projectile slowdown"
	DamageBonus=0.03
	
	MatrixRadius=768
	BonusPerLevel=0.20

	MinModifier=1
	MaxModifier=4
	ModifierOverlay=ColorModifier'TitanRPG.Matrix.MatrixColorModifier'
	PatternPos="Matrix $W"
	//AI
	AIRatingBonus=0.025000
	CountersDamage(0)=class'DamTypeFlakChunk'
	CountersDamage(1)=class'DamTypeFlakShell'
	CountersDamage(2)=class'DamTypeRocket'
	CountersDamage(3)=class'DamTypeRocketHoming'
}
