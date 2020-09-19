#pragma semicolon 1

#define DEBUG

#define PL_AUTOR "Javierkoo21"
#define PL_VER "1.0.1"
#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++)

//Includes
#include <sourcemod>
#include <cstrike>
#include <colors>

//Strings
char g_szTag[64];

//Booleans
bool g_bVipFlag[MAXPLAYERS + 1];
bool g_bAdminFlag[MAXPLAYERS + 1];

//Convars
ConVar g_cvTag;
ConVar g_cvAlive;
ConVar g_cvVip;
ConVar g_cvMvp;
ConVar g_cvScore;
ConVar g_cvVipFlag;
ConVar g_cvAdminFlag;

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[CS:GO] Advanced ResetScore plugin",
	author = PL_AUTOR,
	description = "CS:GO advanced resetscore plugin",
	version = PL_VER,
	url = "http://github.com/javierko"
};

/*
    > Plugin Start 
*/

public void OnPluginStart()
{
    //Translations
    LoadTranslations("AdvancedRS.phrases");   
    
    //Commands
    RegConsoleCmd("sm_rs", Command_ResetScore);
    RegConsoleCmd("sm_resetscore", Command_ResetScore);
    RegConsoleCmd("sm_setscore", Command_SetScore);

    //Cvars
    g_cvTag = CreateConVar("sm_ars_tag", "{darkred}[SM]{default}", "Sets tag for messages.");
    g_cvTag.AddChangeHook(OnConVarChanged);
    g_cvTag.GetString(g_szTag, sizeof(g_szTag));
    g_cvAlive = CreateConVar("sm_ars_alive", "0", "1 - Enable only for alive players, 0 - enable for death + alive players", _, true, 0.0, true, 1.0);
    g_cvVip = CreateConVar("sm_ars_vip", "0", "1 - Enable only for VIP players, 0 - enable for everyone", _, true, 0.0, true, 1.0);
    g_cvMvp = CreateConVar("sm_ars_mvp", "0", "1 - Disable reseting MVP, 0 - enable reseting MVP", _, true, 0.0, true, 1.0);
    g_cvScore = CreateConVar("sm_ars_score", "0", "1 - Disable reseting score, 0 - enable reseting score", _, true, 0.0, true, 1.0);
    g_cvVipFlag = CreateConVar("sm_ars_vipflag", "a", "Flag for access");
    g_cvAdminFlag = CreateConVar("sm_ars_adminflag", "b", "Flag for access");

    AutoExecConfig(true, "AdvancedResetScore");

    //Disable backups
    Func_DisableBackupScore();

    LoopClients(i)
    {
        if(IsValidClient(i))
        {
            OnClientPostAdminCheck(i);
        }
    }
}

/*
    > Cvars hook
*/

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if(convar == g_cvTag)
    {
        strcopy(g_szTag, sizeof(g_szTag), newValue);
    }
}

/*
    > Map start
*/

public void OnMapStart()
{
    Func_DisableBackupScore();
}

/*
    > Commands
*/

public Action Command_ResetScore(int client, int args)
{
    if(IsValidClient(client))
    {
        if(g_cvVip.BoolValue && !g_bVipFlag[client])
        {
            CReplyToCommand(client, "%s %t", g_szTag, "ars_onlyvip");

            return Plugin_Handled;
        }

        if(g_cvAlive.BoolValue)
        {
            if(IsPlayerAlive(client))
            {
	    	Func_ResetScore(client, g_cvMvp.BoolValue, g_cvScore.BoolValue);

                CReplyToCommand(client, "%s %t", g_szTag, "ars_reseted");
            }
            else
            {
                CReplyToCommand(client, "%s %t", g_szTag, "ars_youdeath");
            }
        }
        else
        {
            Func_ResetScore(client, g_cvMvp.BoolValue, g_cvScore.BoolValue);

            CReplyToCommand(client, "%s %t", g_szTag, "ars_reseted");
        }
    }

    return Plugin_Handled;
}

public Action Command_SetScore(int client, int args)
{
    if(IsValidClient(client))
    {
        if(g_bAdminFlag[client])
        {
            if(args != 6)
            {
                CReplyToCommand(client, "%s Use: /setscore <name or #userid> <kills> <deaths> <assists> <mvp> <score>", g_szTag);

                return Plugin_Handled;
            }

            char szArgs[64];
            GetCmdArg(1, szArgs, sizeof(szArgs));

            char szTargetName[MAX_TARGET_LENGTH];
            int iTargets[MAXPLAYERS], iTargetCount;
            bool bIsThatML;

            if((iTargetCount = ProcessTargetString(szArgs, client, iTargets, MAXPLAYERS, COMMAND_TARGET_NONE, szTargetName, sizeof(szTargetName), bIsThatML)) <= 0)
            {
                ReplyToTargetError(client, iTargetCount);

                return Plugin_Handled;
            }

            for(int i = 0; i < iTargetCount; i++)
            {
                int iTarget = iTargets[i];

                int iArgs2, iArgs3, iArgs4, iArgs5, iArgs6;

                char szArgs2[128];
                GetCmdArg(2, szArgs2, sizeof(szArgs2));
                iArgs2 = StringToInt(szArgs2);

                char szArgs3[128];
                GetCmdArg(3, szArgs3, sizeof(szArgs3));
                iArgs3 = StringToInt(szArgs3);

                char szArgs4[128];
                GetCmdArg(4, szArgs4, sizeof(szArgs4));
                iArgs4 = StringToInt(szArgs4);

                char szArgs5[128];
                GetCmdArg(5, szArgs5, sizeof(szArgs5));
                iArgs5 = StringToInt(szArgs5); 

                char szArgs6[128];
                GetCmdArg(6, szArgs6, sizeof(szArgs6));
                iArgs6 = StringToInt(szArgs6);

                Func_SetScore(iTarget, iArgs2, iArgs3, iArgs4, iArgs5, iArgs6);

                CReplyToCommand(client, "%s %t", g_szTag, "ars_setscoreA", iTarget, iArgs2, iArgs3, iArgs4, iArgs5, iArgs6);
                CReplyToCommand(iTarget, "%s %t", g_szTag, "ars_setscoreP", client, iArgs2, iArgs3, iArgs4, iArgs5, iArgs6);
            }
        }
        else
        {
            CReplyToCommand(client, "%s %t", g_szTag, "ars_onlyadmin");
        }
    }

    return Plugin_Handled;
}

/*
    > Flag check
*/

public void OnClientPostAdminCheck(int client)
{
    char szVipFlags[32], szAdminFlags[32];
    g_cvVipFlag.GetString(szVipFlags, sizeof(szVipFlags));
    g_cvAdminFlag.GetString(szAdminFlags, sizeof(szAdminFlags));

    if(IsValidClient(client))
    {
        g_bVipFlag[client] = CheckAdminFlag(client, szVipFlags);
        g_bAdminFlag[client] = CheckAdminFlag(client, szAdminFlags);
    }
}

public void OnRebuildAdminCache(AdminCachePart part)
{
    char szVipFlags[32], szAdminFlags[32];
    g_cvVipFlag.GetString(szVipFlags, sizeof(szVipFlags));
    g_cvAdminFlag.GetString(szAdminFlags, sizeof(szAdminFlags));

    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i))
        {
            g_bVipFlag[i] = CheckAdminFlag(i, szVipFlags);
            g_bAdminFlag[i] = CheckAdminFlag(i, szAdminFlags);
        }
    }
}

/*
    > Stocks
*/

void Func_ResetScore(int client, bool mvp = false, bool score = false)
{
    SetEntProp(client, Prop_Data, "m_iFrags", 0);
    SetEntProp(client, Prop_Data, "m_iDeaths", 0);

    if(!mvp)
        CS_SetMVPCount(client, 0);

    CS_SetClientAssists(client, 0);
    
    if(!score)
        CS_SetClientContributionScore(client, 0);
}

void Func_SetScore(int client, int kills, int deaths, int assists, int mvp, int score)
{
    SetEntProp(client, Prop_Data, "m_iFrags", kills);
    SetEntProp(client, Prop_Data, "m_iDeaths", deaths);
    CS_SetClientAssists(client, assists);
    CS_SetMVPCount(client, mvp);
    CS_SetClientContributionScore(client, score);
}

void Func_DisableBackupScore()
{
    ServerCommand("mp_backup_round_file \"\"");
    ServerCommand("mp_backup_round_file_last \"\"");
    ServerCommand("mp_backup_round_file_pattern \"\"");
    ServerCommand("mp_backup_round_auto 0");
}

stock bool IsValidClient(int client) 
{
    if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client) || IsClientSourceTV(client) || IsClientReplay(client))
    {
        return false;
    }
    
    return true;
}

//Credits: Hexar10 - https://github.com/Hexer10/HexVips/blob/master/addons/sourcemod/scripting/include/hexstocks.inc#L49-L69
stock bool CheckAdminFlag(int client, const char[] flags)
{
	int iCount = 0;
	char sflagNeed[22][8], sflagFormat[64];
	bool bEntitled = false;
	
	Format(sflagFormat, sizeof(sflagFormat), flags);
	ReplaceString(sflagFormat, sizeof(sflagFormat), " ", "");
	iCount = ExplodeString(sflagFormat, ",", sflagNeed, sizeof(sflagNeed), sizeof(sflagNeed[]));
	
	for (int i = 0; i < iCount; i++)
	{
		if ((GetUserFlagBits(client) & ReadFlagString(sflagNeed[i]) == ReadFlagString(sflagNeed[i])) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
		{
			bEntitled = true;
			break;
		}
	}
	
	return bEntitled;
}
