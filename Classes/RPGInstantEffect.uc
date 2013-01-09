/*
	Optimized for effects without a duration
*/
class RPGInstantEffect extends RPGEffect abstract;

function DoEffect();

state Activated
{
	function BeginState()
	{
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
    TimerInterval=0 //display message only one
}
