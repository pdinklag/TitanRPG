//Abstract base class for auto-generated abilities
class RPGGeneratedAbility extends RPGAbility abstract;

var RPGConfigAbility Module;

replication {
	reliable if(Role == ROLE_Authority)
		ClientReceiveAbilityInfo, ClientReceiveLevelDescription;
}

function ServerRequestConfig() {
    local int i;

    Super.ServerRequestConfig();
    
    ClientReceiveAbilityInfo(AbilityName, Description, Category, LevelDescription.Length);
    
    for(i = 0; i < LevelDescription.Length; i++) {
        ClientReceiveLevelDescription(i, LevelDescription[i]);
    }
}

simulated function ClientReceiveAbilityInfo(string AName, string ADescription, class<RPGAbilityCategory> ACategory, int NumLevelDescriptions) {
    AbilityName = AName;
    Description = ADescription;
    Category = ACategory;
    LevelDescription.Length = NumLevelDescriptions;
}

simulated function ClientReceiveLevelDescription(int i, string Desc) {
    LevelDescription[i] = Desc;
}

defaultproperties {
}
