class Ability_ArtifactDenial extends RPGAbility;

function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> DamageType, vector HitLocation, bool bAlreadyPrevented) {
    local Inventory Inv;

    for(Inv = Killed.Inventory; Inv != None; Inv = Inv.Inventory) {
        if(Inv.IsA('RPGArtifact')) {
            RPGArtifact(Inv).bCanBeTossed = false;
        }
    }

    return false;
}

function ModifyPawn(Pawn Other) {
}

defaultproperties
{
	AbilityName="Artifact Denial"
	Description="When you die, you do not drop any artifacts for your enemies."
	MaxLevel=1
	bUseLevelCost=True
	LevelCost(0)=10
	Category=class'AbilityCategory_Artifacts'
}
