//character-specific settings
class RPGCharSettings extends Object
	config(TitanRPGSettings)
	PerObjectConfig;

struct ArtifactOrderConfigStruct
{
	var string ArtifactID;
	var bool bShowAlways;
};
var config array<ArtifactOrderConfigStruct> ArtifactOrderConfig;

defaultproperties
{
}
