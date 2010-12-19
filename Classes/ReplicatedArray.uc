<?
	$types = array("Object", "int", "float", "string");
?>

//u can't touch this ~pd
class ReplicatedArray extends ReplicationInfo;

const CHUNK_SIZE_MAX = 16;

<?
	foreach($types as $type)
	{
		?>
		
		var array<<? echo($type); ?>> <? echo($type); ?>Array;
		struct <? echo($type); ?>Chunk
		{
			var int Size;
			var <? echo($type); ?> Data[CHUNK_SIZE_MAX];
		};
		
		<?
	}
?>

//Replication
replication
{
	reliable if(Role < ROLE_Authority)
		ServerDestroy;

	reliable if(Role == ROLE_Authority)
		<?
			$first = true;
			foreach($types as $type)
			{
				if(!$first)
					echo(", ");
				
				$first = false;
			
				?>
					ClientReceive<? echo($type); ?>Chunk
				<?
			}
		?>
		;
}

//Call this once the arrays were intialized
function Replicate()
{
	<?
		foreach($types as $type)
		{
			?>
			
			local <? echo($type); ?>Chunk <? echo($type); ?>Chunk;
				
			<?
		}
	?>
	local int i, k;

	<?
		foreach($types as $type)
		{
			?>
			
			i = 0;
			while(i < <? echo($type); ?>Array.Length)
			{
				<? echo($type); ?>Chunk.Size = 0;
				for(k = 0; k < CHUNK_SIZE_MAX && (i + k) < <? echo($type); ?>Array.Length; k++)
				{
					//Log("Writing to chunk (" $ i $ "," @ k $ "):" @ <? echo($type); ?>Array[i + k]);
					<? echo($type); ?>Chunk.Data[k] = <? echo($type); ?>Array[i + k];
					<? echo($type); ?>Chunk.Size++;
				}
				
				if(<? echo($type); ?>Chunk.Size > 0)
				{
					i += <? echo($type); ?>Chunk.Size;
					ClientReceive<? echo($type); ?>Chunk(<? echo($type); ?>Chunk);
				}
				else
				{
					break;
				}
			}
			
			<?
		}
	?>
}

//Client reception
<?
	foreach($types as $type)
	{
		?>
	
		simulated function ClientReceive<? echo($type); ?>Chunk(<? echo($type); ?>Chunk Chunk)
		{
			local int i;
			
			//Log("Received <? echo($type); ?> chunk containing" @ Chunk.Size @ "items");
			for(i = 0; i < Chunk.Size; i++)
			{
				<? echo($type); ?>Array[<? echo($type); ?>Array.Length] = Chunk.Data[i];
				//Log("Received item" @ Chunk.Data[i]);
			}
		}
		
		<?
	}
?>

function ServerDestroy()
{
	Destroy();
}

simulated event Destroyed()
{
	//Log(Self @ "Destroyed");
	Super.Destroyed();
}

defaultproperties
{
	bOnlyRelevantToOwner=True
}
