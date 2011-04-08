/*
	Optimized for effects without a duration
*/
class RPGInstantEffect extends RPGEffect abstract;

function DoEffect();

state Activated
{
	function BeginState()
	{
		Duration = 0;
		
		Super.BeginState();
		
		DoEffect();
		Destroy();
	}
}

defaultproperties
{
}
