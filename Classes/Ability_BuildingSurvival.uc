class Ability_BuildingSurvival extends RPGAbility;

function ModifyRPRI() {
    Super.ModifyRPRI();
    
    RPRI.bTurretsDie = false;
    RPRI.bTotemsDie = false;
}

defaultproperties {
    AbilityName="Intelligent Architecture"
    Description="Your constructions (turrets and totems) will no longer be destroyed if you die."
    StartingCost=10
    MaxLevel=1
    Category=class'AbilityCategory_Engineer'
}
