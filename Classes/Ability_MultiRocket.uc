class Ability_MultiRocket extends RPGAbility;

replication {
    reliable if(Role == ROLE_Authority)
        ClientModifyMaxLoad;
}

function ModifyWeapon(Weapon Weapon) {
    local int i;
    local RocketMultiFire RMF;
    
    for(i = 0; i < Weapon.NUM_FIRE_MODES; i++) {
        RMF = RocketMultiFire(Weapon.GetFireMode(i));
        if(RMF != None) {
            RMF.MaxLoad = RMF.default.MaxLoad + AbilityLevel;
            RMF.MaxHoldTime = RMF.FireRate * (RMF.MaxLoad - 1) + 0.5;

            ClientModifyMaxLoad(Weapon, i, RMF.MaxLoad, RMF.MaxHoldTime);
        }
    }
}

simulated function ClientModifyMaxLoad(Weapon Weapon, int Mode, int MaxLoad, float MaxHoldTime) {
    local RocketMultiFire RMF;
    
    RMF = RocketMultiFire(Weapon.GetFireMode(Mode));
    if(RMF != None) {
        RMF.MaxLoad = MaxLoad;
        RMF.MaxHoldTime = MaxHoldTime;
    }
}

defaultproperties
{
	AbilityName="Rocket Science"
	Description="Increases the amount of rockets that your rocket launchers can load up and fire simultaneously by one per level."
	MaxLevel=5
	StartingCost=10
	Category=class'AbilityCategory_Weapons'
}
