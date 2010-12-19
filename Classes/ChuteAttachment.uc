class ChuteAttachment extends InventoryAttachment;

defaultproperties
{
	DrawType=DT_StaticMesh
	StaticMesh=StaticMesh'<? echo($packageName); ?>.Chute.chutemesh'
	AttachmentBone="spine"
	DrawScale=2.000000
}
