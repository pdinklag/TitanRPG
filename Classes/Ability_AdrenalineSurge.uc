class Ability_AdrenalineSurge extends RPGAbility;

function ScoreKill(Controller Killed, class<DamageType> DamageType)
{
    local Controller C;

    C = Instigator.Controller;
    if(C != None) {
        if(Level.Game.IsA('Invasion') && Monster(Killed.Pawn) != None)
        {
            C.AwardAdrenaline(Monster(Killed.Pawn).ScoringValue * BonusPerLevel * AbilityLevel);
        }
        else
        {
            if(Killed != C && !Killed.SameTeamAs(C))
            {
                if(UnrealPlayer(C) != None && UnrealPlayer(C).MultiKillLevel > 0)
                    C.AwardAdrenaline(Deathmatch(Level.Game).ADR_MajorKill * BonusPerLevel * AbilityLevel);
                
                if(UnrealPawn(Killed.Pawn) != None && UnrealPawn(Killed.Pawn).spree > 4)
                    C.AwardAdrenaline(Deathmatch(Level.Game).ADR_MajorKill * BonusPerLevel * AbilityLevel);

                if(
                    C.PlayerReplicationInfo.Kills == 1 &&
                    TeamPlayerReplicationInfo(C.PlayerReplicationInfo) != None &&
                    TeamPlayerReplicationInfo(C.PlayerReplicationInfo).bFirstBlood
                )
                {
                    C.AwardAdrenaline(Deathmatch(Level.Game).ADR_MajorKill * BonusPerLevel * AbilityLevel);
                }
            
                if(Killed.bIsPlayer)
                    C.AwardAdrenaline(Deathmatch(Level.Game).ADR_Kill * BonusPerLevel * AbilityLevel);
            }
        }
    }
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Adrenal Surge"
	Description="For each level of this ability, you gain $1 more adrenaline from all kill related adrenaline bonuses."
	StartingCost=10
	CostAddPerLevel=0
	MaxLevel=2
	BonusPerLevel=0.500000
	Category=class'AbilityCategory_Adrenaline'
}
