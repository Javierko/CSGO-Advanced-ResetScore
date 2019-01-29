#pragma semicolon 1

#define DEBUG

#define PL_AUTOR "Javierkoo21"
#define PL_VER "1.0.0"

//includes
#include <sourcemod>
#include <cstrike>
#include <colors>

//strings
char g_szTag[64];

//convars
ConVar g_cvTag;
ConVar g_cvAlive;
ConVar g_cvVip;
ConVar g_cvMvp;
ConVar g_cvScore;

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
    > Plugin Start <
*/

public void OnPluginStart()
{
    //Translations
    LoadTranslations("AdvancedRS.phrases");
    
	//Commands
    RegConsoleCmd("sm_rs", Command_ResetScore);
    RegConsoleCmd("sm_resetscore", Command_ResetScore);

    //Cvars
    g_cvTag = CreateConVar("sm_ars_tag", "{darkred}[SM]{default}", "Sets tag for messages.");
    g_cvTag.AddChangeHook(OnConVarChanged);
    g_cvTag.GetString(g_szTag, sizeof(g_szTag));
    g_cvAlive = CreateConVar("sm_ars_alive", "0", "1 - Enable only for alive players, 0 - enable for death + alive players", _, true, 0.0, true, 1.0);
    g_cvVip = CreateConVar("sm_ars_vip", "0", "1 - Enable only for VIP players, 0 - enable for everyone", _, true, 0.0, true, 1.0);
    g_cvMvp = CreateConVar("sm_ars_mvp", "0", "1 - Disable reseting MVP, 0 - enable reseting MVP", _, true, 0.0, true, 1.0);
    g_cvScore = CreateConVar("sm_ars_score", "0", "1 - Disable reseting score, 0 - enable reseting score", _, true, 0.0, true, 1.0);

    AutoExecConfig(true, "AdvancedResetScore");
}

/*
    > Cvars hook <
*/

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if(convar == g_cvTag)
    {
        strcopy(g_szTag, sizeof(g_szTag), newValue);
    }
}

/*
    > Commands <
*/

public Action Command_ResetScore(int client, int args)
{
    if(IsValidClient(client))
    {
        if(g_cvVip.BoolValue && !IsClientVIP(client))
        {
            CReplyToCommand(client, "%s %t", g_szTag, "ars_onlyvip");

            return Plugin_Handled;
        }

        if(g_cvAlive.BoolValue)
        {
            if(IsPlayerAlive(client))
            {
                if(g_cvMvp.BoolValue && g_cvScore.BoolValue)
                    Func_ResetScore(client, true, true);
                else if(g_cvMvp.BoolValue && !g_cvScore.BoolValue)
                    Func_ResetScore(client, true, false);
                else if(!g_cvMvp.BoolValue && g_cvScore.BoolValue)
                    Func_ResetScore(client, false, true);
                else if(!g_cvMvp.BoolValue && !g_cvScore.BoolValue)
                    Func_ResetScore(client, false, false);

                CReplyToCommand(client, "%s %t", g_szTag, "ars_reseted");
            }
            else
            {
                CReplyToCommand(client, "%s %t", g_szTag, "ars_youdeath");
            }
        }
        else
        {
            if(g_cvMvp.BoolValue && g_cvScore.BoolValue)
                Func_ResetScore(client, true, true);
            else if(g_cvMvp.BoolValue && !g_cvScore.BoolValue)
                Func_ResetScore(client, true, false);
            else if(!g_cvMvp.BoolValue && g_cvScore.BoolValue)
                Func_ResetScore(client, false, true);
            else if(!g_cvMvp.BoolValue && !g_cvScore.BoolValue)
                Func_ResetScore(client, false, false);

            CReplyToCommand(client, "%s %t", g_szTag, "ars_reseted");
        }
    }

    return Plugin_Handled;
}

/*
    > Stocks <
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

stock bool IsClientVIP(int client)
{
    return CheckCommandAccess(client, "", ADMFLAG_RESERVATION);
}

stock bool IsValidClient(int client) 
{
    if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client) || IsClientSourceTV(client) || IsClientReplay(client))
    {
        return false;
    }
    
    return true;
}