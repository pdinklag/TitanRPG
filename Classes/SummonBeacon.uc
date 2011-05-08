class SummonBeacon extends RPGArtifactBeacon;

var class<Actor> SummonClass;

var rotator RotAdd;

var Material TeamSkin[4];

var int Team;

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		Team;
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	if(Controller(Owner) != None)
		Team = Controller(Owner).GetTeamNum();
	else
		Team = 255;
	
	SetSkin();
	DesiredRotation = Rotation + RotAdd;
}

simulated function SetSkin()
{
	if(Team >= 0 && Team <= 3)
		Skins[2] = TeamSkin[Team];
}

simulated event PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	SetSkin();
}

simulated event Tick(float dt)
{
	Super.Tick(dt);
	DesiredRotation = Rotation + RotAdd; //keep rotating
}

simulated event HitWall( vector HitNormal, actor Wall )
{
	Super.HitWall(HitNormal, Wall);
	
	if(!bPendingDelete)
	{
		RotAdd = rotator(-vector(RotAdd));
		DesiredRotation = Rotation + RotAdd;
		RotationRate = rotator(-0.7 * vector(RotationRate));
	}
}

defaultproperties
{
	StaticMesh=StaticMesh'<? echo($packageName); ?>.Pokeball.PokeballStatic' //oh my
    DrawScale=0.03125
	
	RotationRate=(Pitch=-49152,Yaw=0,Roll=0)
	
	RotAdd=(Pitch=-16384,Yaw=0,Roll=0);
	
	bRotateToDesired=true
	
	TeamSkin(0)=Combiner'<? echo($packageName); ?>.Pokeball.RedCombiner'
	TeamSkin(1)=Combiner'<? echo($packageName); ?>.Pokeball.BlueCombiner'
	TeamSkin(2)=Combiner'<? echo($packageName); ?>.Pokeball.GreenCombiner'
	TeamSkin(3)=Combiner'<? echo($packageName); ?>.Pokeball.GoldCombiner'
}
