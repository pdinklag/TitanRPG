class Ability_MedicAwareness extends RPGAbility;

//Client
var Interaction_MedicAwareness Interaction;
var array<Pawn> Teammates;

replication {
	reliable if(Role == ROLE_Authority)
		ClientCreateInteraction;
}

simulated function ClientCreateInteraction()
{
	local PlayerController PC;

    if(Level.NetMode != NM_DedicatedServer) {
        if(Interaction == None) {
            PC = Level.GetLocalPlayerController();
            if(PC == None) {
                return;
            }

            Interaction = Interaction_MedicAwareness(
                PC.Player.InteractionMaster.AddInteraction(
                    class'MutTitanRPG'.default.PackageName $ ".Interaction_MedicAwareness", PC.Player));

            Interaction.Ability = Self;
            
            SetTimer(1.0, true);
        }
    }
}

simulated function Timer() {
    local PlayerController PC;
    local Pawn P;
    
    if(Interaction != None) {
        Teammates.Length = 0;
        
        PC = Level.GetLocalPlayerController();
        if(PC != None && PC.Pawn != None && PC.Pawn.Health > 0) {
            foreach DynamicActors(class'Pawn', P) {
                if(P == PC.Pawn) {
                    continue;
                }
            
                if(P.PlayerReplicationInfo == None || P.PlayerReplicationInfo.Team == None) {
                    continue;
                }
            
                if(P.GetTeamNum() == 255 || P.GetTeamNum() != PC.GetTeamNum()) {
                    continue;
                }
                
                if(P.IsA('Monster') || P.IsA('Vehicle') || P.DrivenVehicle != None) {
                    continue;
                }

                Teammates[Teammates.Length] = P;
            }
        }
    }
}

function ModifyPawn(Pawn Other) {
    Super.ModifyPawn(Other);

    if(Role == ROLE_Authority && Level.Game.bTeamGame)
        ClientCreateInteraction();
}

simulated event Destroyed() {
    if(Interaction != None) {
        Interaction.Master.RemoveInteraction(Interaction);
        Interaction = None;
    }

    Super.Destroyed();
}

defaultproperties {
	AbilityName="Medic Awareness"
	Description="Informs you of your teammates' current health by displaying a team-colored health bar above their heads."
	StartingCost=20
	CostAddPerLevel=5
	MaxLevel=1
	Category=class'AbilityCategory_Medic'
}
