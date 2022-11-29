#include <sourcemod>
#include <clientprefs>

public Plugin myinfo = 
{ 
	name = "Hud hitgroup marker", 
	author = "Palonez", 
	description = "Hud hitgroup marker", 
	version = "1.2", 
	url = "https://github.com/Quake1011/" 
};

#define HitData 11
#define HG_None -1
#define HG_DmgHealth 0			//урон по хп
#define HG_DmgArmor 1			//урон по броне
#define HG_HitHead 2			//голова
#define HG_HitChest 3			//грудь
#define HG_HitBelly 4			//живот
#define HG_HitLeftArm 5			//левая рука
#define HG_HitRightArm 6		//правая рука
#define HG_HitLeftLeg 7			//левая нога
#define HG_HitRightLeg 8		//правая нога
#define HG_HitNeck 9			//шея
#define HG_HitAll 10			//общее кол-во попаданий

ConVar hModeOut, hHoldTime, hXpos, hYpos, hAllInfo, hColor, hMethod, hCasual, hHit, hCountHitEvery;
bool bOMode, bAllInfo, bMethod, bCounting;
float fHoldTime, fXpos, fYpos;
int g_iHits[MAXPLAYERS+1][MAXPLAYERS+1][HitData];
char sColor[12], sRGB[3][3+1];
Handle KillHint[MAXPLAYERS+1];
char sHintColors[2][6+1];

public void OnPluginStart()
{
	HookConVarChange(hModeOut = CreateConVar("hg_output_mode", "1", "Режим отображения [0 - после попадания | 1 - после смерти]"), OnCVChange);
	bOMode = hModeOut.BoolValue;
	
	HookConVarChange(hHoldTime = CreateConVar("hg_holdtime", "3.0", "Время отображения"), OnCVChange);
	fHoldTime = hHoldTime.FloatValue;
	
	HookConVarChange(hXpos = CreateConVar("hg_x", "0.05", "Позиция по X"), OnCVChange);
	fXpos = hXpos.FloatValue;
	
	HookConVarChange(hYpos = CreateConVar("hg_y", "0.5", "Позиция по Y"), OnCVChange);
	fYpos = hYpos.FloatValue;
	
	HookConVarChange(hAllInfo = CreateConVar("hg_allinfo", "1", "Тип отображения [0 - выводить только попадания | 1 - выводить всю информацию]"), OnCVChange);
	bAllInfo = hAllInfo.BoolValue;
	
	HookConVarChange(hColor = CreateConVar("hg_hud_color", "0 255 0", "Цвет худа RGB"), OnCVChange);
	hColor.GetString(sColor, sizeof(sColor));
	for(int i = 0; i < sizeof(sColor); i++) if(sColor[i] == ' ') sColor[i] = '-'; 
	ExplodeString(sColor, "-", sRGB, sizeof(sRGB), sizeof(sRGB[]));
	
	HookConVarChange(hMethod = CreateConVar("hg_method", "0", "Метод отображения [0 - HUD | 1 - Hint (сверху)]"), OnCVChange);
	bMethod = hMethod.BoolValue;
	
	HookConVarChange(hHit = CreateConVar("hg_hint_hit_color", "FF0000", "Цвет отметки попадания HEX"), OnCVChange);
	hHit.GetString(sHintColors[0], sizeof(sHintColors[]));
	
	HookConVarChange(hCasual = CreateConVar("hg_hint_casual_color", "00FF00", "Стартовый цвет мест попаданий HEX"), OnCVChange);
	hCasual.GetString(sHintColors[1], sizeof(sHintColors[]));
	
	HookConVarChange(hCountHitEvery = CreateConVar("hg_count_hit", "1", "Покраска всей части тела, без вывода счетчиков [0 - да | 1 - нет]"), OnCVChange);
	bCounting = hCountHitEvery.BoolValue;

	HookEvent("player_hurt", PlayerHurt);
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", PlayerDeath);
	
	AutoExecConfig(true, "hud_hitgroups");
}

public void OnCVChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == hModeOut) bOMode = convar.BoolValue;
	else if(convar == hHoldTime) fHoldTime = convar.FloatValue;
	else if(convar == hXpos) fXpos = convar.FloatValue;
	else if(convar == hYpos) fYpos = convar.FloatValue;
	else if(convar == hAllInfo) bAllInfo = convar.BoolValue;
	else if(convar == hColor) 
	{
		convar.GetString(sColor, sizeof(sColor));
		for(int i = 0; i < sizeof(sColor); i++) if(sColor[i] == ' ') sColor[i] = '-'; 
		ExplodeString(sColor, "-", sRGB, sizeof(sRGB), sizeof(sRGB[]));
	}
	else if(convar == hMethod) bMethod = convar.BoolValue;
	else if(convar == hHit) convar.GetString(sHintColors[0], sizeof(sHintColors[]));
	else if(convar == hCasual) convar.GetString(sHintColors[1], sizeof(sHintColors[]));
	else if(convar == hCountHitEvery) bCounting = convar.BoolValue;
}

public void PlayerSpawn(Event hEvent, const char[] sEvent, bool bdb)
{
	Reset(GetClientOfUserId(hEvent.GetInt("userid")));
}

public void OnClientDisconnect(int iClient)
{
	Reset(iClient);
}

public void PlayerHurt(Event hEvent, const char[] sEvent, bool bdb)
{
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(iAttacker)
	{
		g_iHits[iAttacker][iClient][HG_DmgHealth] += hEvent.GetInt("dmg_health");
		g_iHits[iAttacker][iClient][HG_DmgArmor] += hEvent.GetInt("dmg_armor");
		int iHB = hEvent.GetInt("hitgroup") + 1;
		if(1 < iHB < 11)
		{
			g_iHits[iAttacker][iClient][iHB]++;
			g_iHits[iAttacker][iClient][HG_HitAll]++;
		}
	}
	if(!bOMode) GOINFOTOHUD(iAttacker, fHoldTime, fXpos, fYpos, iClient);
}

public void PlayerDeath(Event hEvent, const char[] sEvent, bool bdb)
{
	if(bOMode) GOINFOTOHUD(GetClientOfUserId(hEvent.GetInt("userid")), fHoldTime, fXpos, fYpos, GetClientOfUserId(hEvent.GetInt("attacker")));
}

void GOINFOTOHUD(int iClient, float fTime, float x, float y, int iAttacker)
{
	if(0 < iAttacker <= MaxClients && 0 < iClient <= MaxClients)
	{
		if(IsClientInGame(iAttacker) && IsClientInGame(iClient))
		{
			if(!IsFakeClient(iClient))
			{
				char buffer[2][512];
				if(bMethod)
				{
					Event winr = CreateEvent("cs_win_panel_round");
					if(!bCounting)Format(buffer[0], sizeof(buffer[]), "<pre><font color=\"#%s\">       ( )</font>\n       <font color=\"#%s\">|</font>\n       <font color=\"#%s\">----</font><font color=\"#%s\">+</font><font color=\"#%s\">----</font>\n       <font color=\"#%s\">|</font>\n       <font color=\"#%s\">/</font> <font color=\"#%s\">\\</font>\n       <font color=\"#%s\">_/</font>   <font color=\"#%s\">\\_</font>\n", g_iHits[iClient][iAttacker][HG_HitHead] > 0 ? sHintColors[0] : sHintColors[1],g_iHits[iClient][iAttacker][HG_HitNeck] > 0 ? sHintColors[0] : sHintColors[1],g_iHits[iClient][iAttacker][HG_HitRightArm] > 0 ? sHintColors[0] : sHintColors[1],g_iHits[iClient][iAttacker][HG_HitChest] > 0 ? sHintColors[0] : sHintColors[1],g_iHits[iClient][iAttacker][HG_HitLeftArm] > 0 ? sHintColors[0] : sHintColors[1],g_iHits[iClient][iAttacker][HG_HitBelly] > 0 ? sHintColors[0] : sHintColors[1],g_iHits[iClient][iAttacker][HG_HitRightLeg] > 0 ? sHintColors[0] : sHintColors[1],g_iHits[iClient][iAttacker][HG_HitLeftLeg] > 0 ? sHintColors[0] : sHintColors[1],g_iHits[iClient][iAttacker][HG_HitRightLeg] > 0 ? sHintColors[0] : sHintColors[1],g_iHits[iClient][iAttacker][HG_HitLeftLeg] > 0 ? sHintColors[0] : sHintColors[1]);
					else Format(buffer[0], sizeof(buffer[]), "<pre><font color=\"#%s\">       (%i)</font>\n       <font color=\"#%s\">%i</font>\n       --<font color=\"#%s\">%i</font>--<font color=\"#%s\">[%i]</font>--<font color=\"#%s\">%i</font>--\n       <font color=\"#%s\">[%i]</font>\n       <font color=\"#%s\">%i</font> <font color=\"#%s\">%i</font>\n       _/   \\_\n", g_iHits[iClient][iAttacker][HG_HitHead] > 0 ? sHintColors[0] : sHintColors[1], g_iHits[iClient][iAttacker][HG_HitHead],g_iHits[iClient][iAttacker][HG_HitNeck] > 0 ? sHintColors[0] : sHintColors[1], g_iHits[iClient][iAttacker][HG_HitNeck],g_iHits[iClient][iAttacker][HG_HitRightArm] > 0 ? sHintColors[0] : sHintColors[1], g_iHits[iClient][iAttacker][HG_HitRightArm],g_iHits[iClient][iAttacker][HG_HitChest] > 0 ? sHintColors[0] : sHintColors[1], g_iHits[iClient][iAttacker][HG_HitChest],g_iHits[iClient][iAttacker][HG_HitLeftArm] > 0 ? sHintColors[0] : sHintColors[1], g_iHits[iClient][iAttacker][HG_HitLeftArm],g_iHits[iClient][iAttacker][HG_HitBelly] > 0 ? sHintColors[0] : sHintColors[1], g_iHits[iClient][iAttacker][HG_HitBelly],g_iHits[iClient][iAttacker][HG_HitRightLeg] > 0 ? sHintColors[0] : sHintColors[1], g_iHits[iClient][iAttacker][HG_HitRightLeg],g_iHits[iClient][iAttacker][HG_HitLeftLeg] > 0 ? sHintColors[0] : sHintColors[1], g_iHits[iClient][iAttacker][HG_HitLeftLeg]);
					Format(buffer[1], sizeof(buffer[]), "        TOTAL HITS: %i\n        HEALTH: %i\n         ARMOR: %i</pre>", g_iHits[iClient][iAttacker][HG_HitAll], g_iHits[iClient][iAttacker][HG_DmgHealth], g_iHits[iClient][iAttacker][HG_DmgArmor]);
					if(bAllInfo) StrCat(buffer[0], sizeof(buffer[]), buffer[1]);
					else StrCat(buffer[0], sizeof(buffer[]), "</pre>");
					winr.SetString("funfact_token", buffer[0]);
					winr.FireToClient(iClient);
					if(KillHint[iClient] == null) KillHint[iClient] = CreateTimer(fTime, Killer, iClient);
				}
				else
				{
					SetHudTextParams(x, y, fTime, StringToInt(sRGB[0]), StringToInt(sRGB[1]), StringToInt(sRGB[2]), 255, 2, 0.0 , 0.0, 0.0);
					Format(buffer[0], sizeof(buffer[]), "\b\b\b\b\b\b(%i)\n \b\b\b\b\b\b%i\n \b\b\b --%i--[%i]--%i--\n \b\b\b\b\b  [%i]\n \b\b\b\b     %i %i\n\b\b\b\b\b_/   \\_\n", g_iHits[iClient][iAttacker][HG_HitHead],g_iHits[iClient][iAttacker][HG_HitNeck],g_iHits[iClient][iAttacker][HG_HitRightArm],g_iHits[iClient][iAttacker][HG_HitChest],g_iHits[iClient][iAttacker][HG_HitLeftArm],g_iHits[iClient][iAttacker][HG_HitBelly],g_iHits[iClient][iAttacker][HG_HitRightLeg],g_iHits[iClient][iAttacker][HG_HitLeftLeg]);
					Format(buffer[1], sizeof(buffer[]), " \b\b\bTOTAL HITS: %i\n \b\b\b\bHEALTH: %i\n \b\b\b\bARMOR: %i", g_iHits[iClient][iAttacker][HG_HitAll], g_iHits[iClient][iAttacker][HG_DmgHealth], g_iHits[iClient][iAttacker][HG_DmgArmor]);
					if(bAllInfo) StrCat(buffer[0], sizeof(buffer[]), buffer[1]);
					ShowHudText(iClient, -1, buffer[0]);
				}
			}
		}		
	}		
}

public Action Killer(Handle hTimer, any iClient)
{
	Event killerEvent = CreateEvent("round_start");
	killerEvent.FireToClient(iClient);
	killerEvent.Cancel();
	if(KillHint[iClient]) KillHint[iClient] = null;
	return Plugin_Continue;
}

void Reset(int iClient)
{
	for(int i = 0; i <= sizeof(g_iHits[][]) - 1; i++)
		for(int k = 0; k <= MaxClients; k++)
			g_iHits[iClient][k][i] = 0;
}