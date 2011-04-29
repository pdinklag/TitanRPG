/*
	Optimized for effects without a duration
*/
class RPGInstantEffect extends RPGEffect abstract;

function DoEffect();

state Activated
{
	function BeginState()
	{
		Duration = 1; //don't destroy immediately, so stacking can be handled properly
		
		Super.BeginState();
		
		DoEffect();
	}
	
	function Timer()
	{
		Destroy();
	}
}

defaultproperties
{
}
