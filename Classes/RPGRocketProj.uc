/*
	This should replace all rocket projectiles as this fixes the Force client-side bug
*/
class RPGRocketProj extends RocketProj;

simulated function Timer()
{
    local vector ForceDir, CurlDir;
    local float ForceMag;
    local int i;

	//This was the problem...
	//Velocity =  Default.Speed * Normal(Dir * 0.5 * Default.Speed + Velocity);
	
	//This is the cure...
	Velocity = VSize(Velocity) * Normal(Dir * 0.5 * VSize(Velocity) + Velocity);

	// Work out force between flock to add madness
	for(i=0; i<2; i++)
	{
		if(Flock[i] == None)
			continue;

		// Attract if distance between rockets is over 2*FlockRadius, repulse if below.
		ForceDir = Flock[i].Location - Location;
		ForceMag = FlockStiffness * ( (2 * FlockRadius) - VSize(ForceDir) );
		Acceleration = Normal(ForceDir) * Min(ForceMag, FlockMaxForce);

		// Vector 'curl'
		CurlDir = Flock[i].Velocity Cross ForceDir;
		if ( bCurl == Flock[i].bCurl )
			Acceleration += Normal(CurlDir) * FlockCurlForce;
		else
			Acceleration -= Normal(CurlDir) * FlockCurlForce;
	}
}

defaultproperties {
}
