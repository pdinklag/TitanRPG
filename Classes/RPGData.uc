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

//struct for the LastSeen meta data
struct DateStruct
{
	var int D, M, Y; //day, month, year
};
var config DateStruct LS; //last time this player connected to the server
var config DateStruct DC; //date this character was created

//AI
var config string AI;
var config int AA;

defaultproperties
{
}
