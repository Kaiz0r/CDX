class cTeleporter extends Trigger;

//Enumeration of the class choices, if any but C_Custom are chosen, the teleporter sets that class, if C_Custom IS chosen, ignores those and uses the cInv, cAugs and cSkinClassName variables for the class instead. 
enum cClass
{
	C_Medic,
	C_Soldier,
	C_Stealth,
	C_Sniper,
	C_Engineer,
	C_Custom
};
var() cClass ClassChoice;

//Array of class names for the inventory
var() class<inventory> cInv[16];
//Array of class names for the augmentations
var() class<Augmentation> cAugs[9];
//String of the bots class name.
var() string cSkinClassNameNSF, cSkinClassNameUNATCO, cSkinClassNameDM;
//Tag for the end-point location, can be any hidden object
var() name OutTag;
//Message to show on trigger
var() string ShowMessageString;

var(Events) class<Actor> LimitingClass;

replication
{
	//Executing ShowMessage clientside
   reliable if (Role == ROLE_Authority)
      ShowMessage;
} 

function BeginPlay()
{
}

function Trigger(Actor other,Pawn instigator)
{
	BeenTriggered(instigator);
}

function Touch(Actor other)
{
	if(IsRelevant(other))
	{
		BeenTriggered(other);
	}
}

//Spawns and gives the item to the player
function GiveItem(class<Inventory> GiveClass, DeusExPlayer Sender)
{
	local inventory anItem;

	if( GiveClass!=None )
	{			
		anItem = Sender.FindInventoryType(GiveClass.Class);
		if ((anItem != None) && (deusexpickup(anItem).bCanHaveMultipleCopies))
		{
			if ((deusexpickup(anItem).MaxCopies >= 0) && (deusexpickup(anItem).NumCopies >= deusexpickup(anItem).MaxCopies))
			{
				Sender.ClientMessage("Can not carry any more of these.");
				return;
			}
			
		}
		anItem=Spawn(GiveClass, Sender,, Sender.Location, Sender.Rotation);
		anItem.PickupMessage = "Class: Given";
		anItem.Frob(Sender,None);
		anItem.Destroy();
	}
}

//Gives the augmentation. Giving it twice, because the first adds it at level 1, the second add raises its level. 
function GiveAug(class<Augmentation> GiveAugClass, DeusExPlayer Sender)
{
	Sender.AugmentationSystem.GivePlayerAugmentation(GiveAugClass);
	//Sender.AugmentationSystem.GivePlayerAugmentation(GiveAugClass);
	Sender.AugmentationSystem.SetAllAugsToMaxLevel();
}

//Custom teleporter function, to avoid telefragging we turn off all collision, move the player, re-enable collision.
function AdvancedTeleport(vector NewLoc, DeusExPlayer Target)
{
	Target.SetCollision(false, false, false);
	Target.bCollideWorld = true;
	Target.GotoState('PlayerWalking');
	Target.SetLocation(NewLoc);
	Target.SetCollision(true, true , true);
	Target.SetPhysics(PHYS_Walking);
	Target.bCollideWorld = true;
	Target.GotoState('PlayerWalking');
	Target.ClientReStart();
}

//Dynamic loads the class of the bot the take the skin from
function SetSkin(string str, DeusExPlayer P)
{
	local class<Pawn> mySkin;
	local int i;

	//This converts a string like JCDouble in to DeusEx.JCDouble, the full string needed for dynamicload
	if ( InStr(str,".") == -1 )
	{
		str="DeusEx." $ str;
	}
	
	//Loads the character class and saves to mySkin variable
	mySkin = class<Pawn>( DynamicLoadObject( str, class'Class' ) );
	
	//If the skin was spawned successfully
	if(mySkin != None)
	{
		//Apply the skin
		P.Mesh = mySkin.default.Mesh;
		P.Texture = mySkin.default.Texture;
		P.Skin = mySkin.default.Skin;
		
		for(i=0;i<8;i++)
			P.Multiskins[i] = mySkin.default.Multiskins[i];
		
	}
	else P.ClientMessage("REPORT AS A BUG: Skin could not be found: "$str);
}

//Where the magic happens
//All skin choices are placeholders
function BeenTriggered(Actor instigator)
{
	local DeusExPlayer P;
	local Actor Target;
	local int i;
	P = DeusExPlayer(Instigator);
	
	if(P != None)
	{
		if(ClassChoice == C_Soldier)
		{
			GiveItem(class'WeaponAssaultGun', P);
			GiveItem(class'WeaponCombatKnife', P);
			GiveItem(class'WeaponPistol', P);
			GiveItem(class'WeaponEMPGrenade', P);
			GiveItem(class'WeaponLam', P);
			GiveItem(class'BioelectricCell', P);
			GiveItem(class'BioelectricCell', P);
			GiveItem(class'BioelectricCell', P);
			GiveAug(class'AugBallistic', P);
			GiveAug(Class'AugCombat', P);
			GiveAug(Class'AugPower', P);
			GiveAug(Class'AugEMP', P);
			GiveAug(Class'AugVision', P);
			if(TeamDMGame(Level.Game) != None) //Setting TEAM skin
			{
				if(P.PlayerReplicationInfo.Team == 0) //UNATCO
					SetSkin("CDX.SkinUNATCOSoldier", P);
				else
					SetSkin("CDX.SkinNSFSoldier", P); //NSF
			}
			else
				SetSkin("CDX.SkinDMSoldier", P); 
			
		}
		if(ClassChoice == C_Medic)
		{
			GiveItem(class'WeaponMiniCrossbow', P);
			GiveItem(class'WeaponPepperGun', P); // Kaiser: Placeholder for healing weapon
			GiveItem(class'Medkit', P);
			GiveItem(class'Medkit', P);
			GiveItem(class'Medkit', P);
			GiveItem(class'Medkit', P);
			GiveItem(class'Medkit', P);
			GiveAug(Class'AugEnviro', P);
			GiveAug(Class'AugHealing', P);
			if(TeamDMGame(Level.Game) != None) //Setting TEAM skin
			{
				if(P.PlayerReplicationInfo.Team == 0) //UNATCO
					SetSkin("CDX.SkinUNATCOMedic", P);
				else
					SetSkin("CDX.SkinNSFMedic", P); //NSF
			}
			else
				SetSkin("CDX.Doctor", P); 
		}
		if(ClassChoice == C_Stealth)
		{
			GiveItem(class'WeaponNanoSword', P);
			GiveItem(class'WeaponShuriken', P);
			GiveItem(class'BioelectricCell', P);
			GiveItem(class'WeaponGasGrenade', P);
			GiveItem(class'Lockpick', P);
			GiveItem(class'Lockpick', P);
			GiveItem(class'Lockpick', P);
			GiveAug(Class'AugEMP', P);
			GiveAug(Class'AugCloak', P);
			GiveAug(Class'AugRadarTrans', P);
			GiveAug(Class'AugSpeed', P);
			if(TeamDMGame(Level.Game) != None) //Setting TEAM skin
			{
				if(P.PlayerReplicationInfo.Team == 0) //UNATCO
					SetSkin("CDX.SkinUNATCOStealth", P);
				else
					SetSkin("CDX.SkinNSFStealth", P); //NSF
			}
			else
				SetSkin("DeusEx.JuanLebedev", P); 
		}
		if(ClassChoice == C_Engineer)
		{
			GiveItem(class'WeaponAssaultShotgun', P);
			GiveItem(class'WeaponCrowbar', P);
			GiveItem(class'BioelectricCell', P);
			GiveItem(class'BioelectricCell', P);
			GiveItem(class'BioelectricCell', P);
			GiveItem(class'WeaponLam', P);
			GiveItem(class'Multitool', P);
			GiveItem(class'Multitool', P);
			GiveItem(class'Multitool', P);
			GiveAug(Class'AugCombat', P);
			GiveAug(Class'AugEnviro', P);
			if(TeamDMGame(Level.Game) != None) //Setting TEAM skin
			{
				if(P.PlayerReplicationInfo.Team == 0) //UNATCO
					SetSkin("CDX.SkinUNATCOMechanic", P);
				else
					SetSkin("CDX.SkinNSFMechanic", P); //NSF
			}
			else
				SetSkin("CDX.SkinDMMechanic", P); 
		}
		if(ClassChoice == C_Sniper)
		{
			GiveItem(class'WeaponRifle', P);
			GiveItem(class'WeaponSawedoffShotgun', P);
			GiveItem(class'WeaponGasGrenade', P);
			GiveAug(Class'AugTarget', P);
			GiveAug(class'AugPower', P);
			if(TeamDMGame(Level.Game) != None) //Setting TEAM skin
			{
				if(P.PlayerReplicationInfo.Team == 0) //UNATCO
					SetSkin("DeusEx.Jock", P);
				else
					SetSkin("DeusEx.JuanLebedev", P); //NSF
			}
			else
				SetSkin("DeusEx.Jock", P); 
		}
		
		
		if(ClassChoice == C_Custom)
		{
			for(i=0;i<16;i++)
				if(cInv[i] != None)
					GiveItem(cInv[i], P);
					
			for(i=0;i<9;i++)
				if(cAugs[i] != None)
					GiveAug(cAugs[i], P);
			
			if(TeamDMGame(Level.Game) != None) //Setting TEAM skin
			{
				if(P.PlayerReplicationInfo.Team == 0) //UNATCO
					SetSkin(cSkinClassNameUNATCO, P);
				else
					SetSkin(cSkinClassNameNSF, P); //NSF
			}
			else
				SetSkin(cSkinClassNameDM, P); 
		}
		
		
		foreach AllActors(Class'Actor', Target)
			if(Target.bHidden && Target.Tag == OutTag)
				AdvancedTeleport(Target.Location, P);
			
		if(ShowMessageString != "")
		{
			SetOwner(P);
			ShowMessage(P,ShowMessageString); 
		}
	}
}

simulated function ShowMessage(DeusExPlayer Player, string Message)
{
  local HUDMissionStartTextDisplay    HUD;
  if ((Player.RootWindow != None) && (DeusExRootWindow(Player.RootWindow).HUD != None))
  {
    HUD = DeusExRootWindow(Player.RootWindow).HUD.startDisplay;
  }
  if(HUD != None)
  {
    HUD.shadowDist = 0;
    HUD.Message = "";
    HUD.setFont(Font'FontMenuSmall_DS');
    HUD.charIndex = 0;
    HUD.winText.SetText("");
    HUD.winTextShadow.SetText("");
    HUD.displayTime = 5.50;
    HUD.perCharDelay = 0.01;
    HUD.AddMessage(Message);
    HUD.StartMessage();
  }
}

defaultproperties
{
     LimitingClass=Class'Engine.PlayerPawn'
}
