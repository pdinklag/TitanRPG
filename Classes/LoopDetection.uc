class LoopDetection extends Object
	config(TitanRPGInstance)
	PerObjectConfig;

struct DateTime
{
	var int Y, M, D, H, N, S;
};

var config DateTime LastTravel;

function bool IsInfoValid()
{
	return (LastTravel.Y >= 2000);
}

function FromCurrent(LevelInfo Level)
{
	LastTravel.Y = Level.Year;
	LastTravel.M = Level.Month;
	LastTravel.D = Level.Day;
	LastTravel.H = Level.Hour;
	LastTravel.N = Level.Minute;
	LastTravel.S = Level.Second;
}

function int ToSeconds()
{
	return
		(LastTravel.Y - 2000) * 31104000 +
		LastTravel.M * 2592000 +
		LastTravel.D * 86400 +
		LastTravel.H * 3600 +
		LastTravel.N * 60 +
		LastTravel.S;
}

function string Format()
{
	return LastTravel.Y $ "/" $ LastTravel.M $ "/" $ LastTravel.D @ LastTravel.H $ ":" $ LastTravel.N $ ":" $ LastTravel.S;
}

defaultproperties
{

}
