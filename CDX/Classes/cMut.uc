class cMut extends Mutator config(CDX);

var config bool bModSpydrone, bKillCarcasses;
var config int BioRegenLimit;

function PostBeginPlay ()
{
	Level.Game.BaseMutator.AddMutator (Self);
	//Level.Game.RegisterDamageMutator (Self);
}

function ModifyPlayer(Pawn Other)
{
	local DeusExPlayer P;
	local inventory inv;
	local class<Pawn> mySkin;
	local int i;
	local AugmentationManager AM;
	
	P = DeusExPlayer(Other);

	//Disables the auto-bio regeneration up to 25% and acts more like singleplayer
	if(P != None)
		P.MaxRegenPoint = BioRegenLimit;
	
	//Deleting default inventory
	foreach AllActors(class'Inventory',inv)
	{
		if(Inv.Owner == Other)
		{
			if(Inv.IsA('Medkit'))
				Inv.Destroy();
			if(Inv.IsA('Lockpick'))
				Inv.Destroy();
			if(Inv.IsA('Multitool'))
				Inv.Destroy();
		}
	}
	
	//This begins the code to reset augmentations, to stop the requirement to disable augs server-side, it resets the augmentation system entirely on spawn, also works as an anti-cheat method
	
	//First line records the targets augmentation system, this allows support for any game mode using a custom aug system.
	AM = P.AugmentationSystem;
	Log("Player augmentation system detected as: "$AM);
	
	//If we see the aug system...
	if (P.AugmentationSystem != None)
	{
		//Shut down the augs, destroy and null the system
		P.AugmentationSystem.DeactivateAll();
		P.AugmentationSystem.ResetAugmentations();
		P.AugmentationSystem.Destroy();
		P.AugmentationSystem = None;
	}
	
	//If the previous step worked and the aug system is gone...
	if (P.AugmentationSystem == None)
	{
		//Spawns the class of the recorded aug, this is where the custom aug manager would be spawned too, then add the default augs and set as owner
		P.AugmentationSystem = Spawn(AM.class, P);
		P.AugmentationSystem.CreateAugmentations(P);
		P.AugmentationSystem.AddDefaultAugmentations();        
		P.AugmentationSystem.SetOwner(P);     
	}
	
	//Resetting skins, not needed, but fixes my OCD for while players are respawning and before class-choice
	P.Mesh = P.default.Mesh;
	P.Texture = P.default.Texture;
	P.Skin = P.default.Skin;
	
	for(i=0;i<8;i++)
		P.Multiskins[i] = P.default.Multiskins[i];
	
	
   Super.ModifyPlayer(Other);
}

function Tick(float deltatime)
{
local Spydrone SD;
local Carcass C;

	if(bKillCarcasses)
		foreach allactors (class'Carcass', c)
			if (c != None)
				c.Destroy();
	//Fun little mod to allow spydrone flying
	if(bModSpydrone)
	{
		foreach AllActors(class'SpyDrone',SD)
		{
			if(SD != None)
			{
				SD.bBlockPlayers = True;
				SD.DamageType = 'None';
				SD.Damage = 0;
				SD.MaxSpeed = 700;
				ConsoleCommand("Set Augdrone ReconstructTime 15");
			}
		}
	}
}

function Mutate (String S, PlayerPawn PP)
{	
	Super.Mutate (S, PP);
	
	if(left(S,5) ~= "test ")
	{
		
	}
	
	if(S ~= "cdx.carcass")
	{
		bKillCarcasses = !bKillCarcasses;
		BroadcastMessage("Carcass disposal: " $ bKillCarcasses);
		SaveConfig();
	}
	if(S ~= "cdx.drones")
	{
		bModSpydrone = !bModSpydrone;
		BroadcastMessage("Drone Modding: " $ bModSpydrone);
		SaveConfig();
	}
}


defaultproperties
{
}
