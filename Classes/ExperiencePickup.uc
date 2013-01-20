class ExperiencePickup extends TournamentPickUp placeable;

var() float ExperienceAmount;

/* DetourWeight()
value of this path to take a quick detour (usually 0, used when on route to distant objective, but want to grab inventory for example)
*/
function float DetourWeight(Pawn Other,float PathWeight)
{
	if ( (Other.Controller.Enemy != None) && (Level.TimeSeconds - Other.Controller.LastSeenTime < 1) )
		return 0;
	
	return 0.15/PathWeight;
}

event float BotDesireability(Pawn Bot)
{
	if(Bot.Controller.bHuntPlayer)
		return 0;

	return MaxDesireability;
}

auto state Pickup
{
	function Touch( actor Other )
	{
        local Pawn P;
		local RPGPlayerReplicationInfo RPRI;

		if ( ValidTouch(Other) ) 
		{
			P = Pawn(Other);
            RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(P.Controller);
			if(RPRI != None)
			{
				RPRI.AwardExperience(ExperienceAmount);
				AnnouncePickup(P);
				SetRespawn();
			}
		}
	}
}

defaultproperties
{
    ExperienceAmount=2.00
    PickupMessage="Experience "
    RespawnTime=60
    MaxDesireability=0.9
    RemoteRole=ROLE_DumbProxy
    AmbientGlow=128
    CollisionRadius=32.000000
    CollisionHeight=23.000000
    Mass=10.000000
    Physics=PHYS_Rotating
	RotationRate=(Yaw=24000)
    DrawScale=0.07
    PickupSound=sound'PickupSounds.AdrenelinPickup'
    PickupForce="AdrenelinPickup"  // jdf
    DrawType=DT_StaticMesh
    StaticMesh=StaticMesh'XPickups_rc.AdrenalinePack'
    Skins(0)=Texture'TitanRPG.PickupStatics.Experience'
    Skins(1)=Combiner'TitanRPG.Disco.Combiner3'
    Style=STY_AlphaZ
    ScaleGlow=0.6
    CullDistance=+5500.0
}
