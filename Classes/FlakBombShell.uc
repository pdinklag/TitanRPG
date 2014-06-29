class FlakBombShell extends FlakShell;

simulated function Explode(vector HitLocation, vector HitNormal)
{
	local vector start;
    local rotator rot;
    local int i;
    local FlakChunk NewChunk;

	start = Location + 10 * HitNormal;
	if ( Role == ROLE_Authority )
	{
		HurtRadius(damage, 220, MyDamageType, MomentumTransfer, HitLocation);	
		for (i=0; i<6; i++)
		{
			rot = Rotation;
			rot.yaw += FRand()*32000-16000;
			rot.pitch += FRand()*32000-16000;
			rot.roll += FRand()*32000-16000;
			NewChunk = Spawn( class 'FlakBombChunk',, '', Start, rot); //thanks epic, needed to copy this whole function thanks to your hardcoding bulls#$%
		}
	}
    Destroy();
}

defaultproperties {
    MyDamageType=class'DamTypeFlakBomb'
}
