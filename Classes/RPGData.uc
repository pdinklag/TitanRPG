class RPGData extends Object
	config(TitanRPGPlayerData)
	PerObjectConfig;

//Player name is the object name
var config string ID; //owner GUID ("Bot" for bots)

var config int LV; //level
var config float XP; //experience
var config int PA, XN; //points available, experience needed

var config array<string> AB; //ability aliases (mapped to class refs in RPGPlayerReplicationInfo)
var config array<int> AL; //ability levels

//AI
var config string AI;
var config int AA;

defaultproperties
{
}
