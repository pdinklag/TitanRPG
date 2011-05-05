class SummonBeacon extends RPGArtifactBeacon;

var class<Actor> SummonClass;

defaultproperties
{
	StaticMesh=StaticMesh'<? echo($packageName); ?>.Pokeball.PokeballStatic' //oh my
    DrawScale=0.03125
}
