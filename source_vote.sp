#include <sourcemod>

public Plugin myinfo =
{
    name        = "Source Vote",
    author      = "LeandroTheDev",
    description = "Player vote system",
    version     = "1.0",
    url         = "https://github.com/LeandroTheDev/source_vote"
};

static bool gv_NMRIH_IsDeadPlayer[MAXPLAYERS];

int         gv_BanTargetMap[MAXPLAYERS];
bool        gv_ShouldDebug = false;
int         gv_MapCount    = 0;
char        gv_MapCodes[99][64];
char        gv_MapNames[99][64];
char        gv_BanPath[PLATFORM_MAX_PATH];
char        gv_VotePath[PLATFORM_MAX_PATH];
int         gv_SecondsToVote                  = 10;
bool        gv_DisableMapVote                 = false;
bool        gv_DisableAdminVoteKickProtection = false;
bool        gv_DisableBackToLobbyProtection   = false;

char        gv_Gamemode[64];
char        gv_Game[64];

ConVar      g_ShouldDebug;
ConVar      g_VotePath;
ConVar      g_BanFilePath;
ConVar      g_SecondsToVote;
ConVar      g_DisableMapVote;
ConVar      g_DisableAdminVoteKickProtection;
ConVar      g_DisableBackToLobbyProtection;

void        ReadVariables()
{
    gv_ShouldDebug = g_ShouldDebug.BoolValue;
    PrintToServer("[Source Vote] Should debug is enabled: %b", gv_ShouldDebug);

    g_VotePath.GetString(gv_VotePath, sizeof(gv_VotePath));
    PrintToServer("[Source Vote] Using vote file: %s", gv_VotePath);

    g_BanFilePath.GetString(gv_BanPath, sizeof(gv_BanPath));
    PrintToServer("[Source Vote] Using ban file: %s", gv_BanPath);

    gv_SecondsToVote = g_SecondsToVote.IntValue;
    PrintToServer("[Source Vote] Seconds to Vote: %d", gv_SecondsToVote);

    GetGameFolderName(gv_Game, sizeof(gv_Game));

    if (StrEqual(gv_Game, "nmrih", false))
    {
        gv_Gamemode = "Unsuported"
    }
    else {
        GetConVarString(FindConVar("mp_gamemode"), gv_Gamemode, sizeof(gv_Gamemode));
        PrintToServer("[Source Vote] Loaded gv_Gamemode: %s", gv_Gamemode);
    }

    gv_DisableMapVote = g_DisableMapVote.BoolValue;
    PrintToServer("[Source Vote] Map vote is disabled: %b", gv_DisableMapVote);

    gv_DisableAdminVoteKickProtection = g_DisableAdminVoteKickProtection.BoolValue;
    PrintToServer("[Source Vote] Admin vote kick protection is disabled: %b", gv_DisableAdminVoteKickProtection);

    gv_DisableBackToLobbyProtection = g_DisableBackToLobbyProtection.BoolValue;
    PrintToServer("[Source Vote] Back to lobby protection is disabled: %b", gv_DisableBackToLobbyProtection);
}

void ReadConfigs()
{
    // #region Default Configuration Creation
    if (!FileExists(gv_VotePath))
    {
        Handle file = OpenFile(gv_VotePath, "w");
        if (file != null)
        {
            if (StrEqual(gv_Game, "left4dead2"))
            {
                WriteFileLine(file, "\"SourceVote\"");
                WriteFileLine(file, "{");

                WriteFileLine(file, "    \"gv_MapCount\"       \"5\"");
                WriteFileLine(file, "");

                WriteFileLine(file, "    \"gv_MapCodes\"");
                WriteFileLine(file, "    {");
                WriteFileLine(file, "        \"0\"  \"c1m1_hotel\"");
                WriteFileLine(file, "        \"1\"  \"c2m1_highway\"");
                WriteFileLine(file, "        \"2\"  \"c3m1_plankcountry\"");
                WriteFileLine(file, "        \"3\"  \"c4m1_milltown_a\"");
                WriteFileLine(file, "        \"4\"  \"c5m1_waterfront\"");
                WriteFileLine(file, "    }");
                WriteFileLine(file, "");

                WriteFileLine(file, "    \"gv_MapNames\"");
                WriteFileLine(file, "    {");
                WriteFileLine(file, "        \"0\"  \"Dead Center\"");
                WriteFileLine(file, "        \"1\"  \"Dark Carnival\"");
                WriteFileLine(file, "        \"2\"  \"Swamp Fever\"");
                WriteFileLine(file, "        \"3\"  \"Hard Rain\"");
                WriteFileLine(file, "        \"4\"  \"The Parish\"");
                WriteFileLine(file, "    }");
                WriteFileLine(file, "");
                WriteFileLine(file, "}");
            }
            else if (StrEqual(gv_Game, "nmrih")) {
                WriteFileLine(file, "\"SourceVote\"");
                WriteFileLine(file, "{");

                WriteFileLine(file, "    \"gv_MapCount\"       \"34\"");
                WriteFileLine(file, "");

                WriteFileLine(file, "    \"gv_MapCodes\"");
                WriteFileLine(file, "    {");
                WriteFileLine(file, "        \"0\"  \"nmo_anxiety\"");
                WriteFileLine(file, "        \"1\"  \"nmo_asylum\"");
                WriteFileLine(file, "        \"2\"  \"nmo_boardwalk\"");
                WriteFileLine(file, "        \"3\"  \"nmo_broadway\"");
                WriteFileLine(file, "        \"4\"  \"nmo_broadway2\"");
                WriteFileLine(file, "        \"5\"  \"nmo_brooklyn\"");
                WriteFileLine(file, "        \"6\"  \"nmo_cabin\"");
                WriteFileLine(file, "        \"7\"  \"nmo_chinatown\"");
                WriteFileLine(file, "        \"8\"  \"nmo_cleopas\"");
                WriteFileLine(file, "        \"9\"  \"nmo_fema\"");
                WriteFileLine(file, "        \"10\"  \"nmo_junction\"");
                WriteFileLine(file, "        \"11\"  \"nmo_lakeside\"");
                WriteFileLine(file, "        \"12\"  \"nmo_quarantine\"");
                WriteFileLine(file, "        \"13\"  \"nmo_rockpit\"");
                WriteFileLine(file, "        \"14\"  \"nmo_shelter\"");
                WriteFileLine(file, "        \"15\"  \"nmo_shoreline\"");
                WriteFileLine(file, "        \"16\"  \"nmo_suzhou\"");
                WriteFileLine(file, "        \"17\"  \"nmo_toxteth\"");
                WriteFileLine(file, "        \"18\"  \"nmo_toxtethdark\"");
                WriteFileLine(file, "        \"19\"  \"nmo_underground\"");
                WriteFileLine(file, "        \"20\"  \"nmo_zephyr\"");
                WriteFileLine(file, "        \"21\"  \"nms_arpley\"");
                WriteFileLine(file, "        \"22\"  \"nms_camilla\"");
                WriteFileLine(file, "        \"23\"  \"nms_campblood\"");
                WriteFileLine(file, "        \"24\"  \"nms_drugstore\"");
                WriteFileLine(file, "        \"25\"  \"nms_favela\"");
                WriteFileLine(file, "        \"26\"  \"nms_flooded\"");
                WriteFileLine(file, "        \"27\"  \"nms_isolated\"");
                WriteFileLine(file, "        \"28\"  \"nms_laundry\"");
                WriteFileLine(file, "        \"29\"  \"nms_midwest\"");
                WriteFileLine(file, "        \"30\"  \"nms_northway\"");
                WriteFileLine(file, "        \"31\"  \"nms_notid\"");
                WriteFileLine(file, "        \"32\"  \"nms_ransack\"");
                WriteFileLine(file, "        \"33\"  \"nms_silence\"");
                WriteFileLine(file, "    }");
                WriteFileLine(file, "");

                WriteFileLine(file, "    \"gv_MapNames\"");
                WriteFileLine(file, "    {");
                WriteFileLine(file, "        \"0\"  \"Anxiety\"");
                WriteFileLine(file, "        \"1\"  \"Asylum\"");
                WriteFileLine(file, "        \"2\"  \"Boardwalk\"");
                WriteFileLine(file, "        \"3\"  \"Broadway\"");
                WriteFileLine(file, "        \"4\"  \"Broadway 2\"");
                WriteFileLine(file, "        \"5\"  \"Brooklyn\"");
                WriteFileLine(file, "        \"6\"  \"Cabin\"");
                WriteFileLine(file, "        \"7\"  \"Chinatown\"");
                WriteFileLine(file, "        \"8\"  \"Cleopas\"");
                WriteFileLine(file, "        \"9\"  \"Fema\"");
                WriteFileLine(file, "        \"10\"  \"Junction\"");
                WriteFileLine(file, "        \"11\"  \"Lakeside\"");
                WriteFileLine(file, "        \"12\"  \"Quarantine\"");
                WriteFileLine(file, "        \"13\"  \"Rockpit\"");
                WriteFileLine(file, "        \"14\"  \"Shelter\"");
                WriteFileLine(file, "        \"15\"  \"Shoreline\"");
                WriteFileLine(file, "        \"16\"  \"Suzhou\"");
                WriteFileLine(file, "        \"17\"  \"Toxteth\"");
                WriteFileLine(file, "        \"18\"  \"Toxteth Dark\"");
                WriteFileLine(file, "        \"19\"  \"Underground\"");
                WriteFileLine(file, "        \"20\"  \"Zephyr\"");
                WriteFileLine(file, "        \"21\"  \"Arpley\"");
                WriteFileLine(file, "        \"22\"  \"Camilla\"");
                WriteFileLine(file, "        \"23\"  \"Camp Blood\"");
                WriteFileLine(file, "        \"24\"  \"Drugs Store\"");
                WriteFileLine(file, "        \"25\"  \"Favela\"");
                WriteFileLine(file, "        \"26\"  \"Flooded\"");
                WriteFileLine(file, "        \"27\"  \"Isolated\"");
                WriteFileLine(file, "        \"28\"  \"Laundry\"");
                WriteFileLine(file, "        \"29\"  \"Midwest\"");
                WriteFileLine(file, "        \"30\"  \"North Way\"");
                WriteFileLine(file, "        \"31\"  \"Not Id\"");
                WriteFileLine(file, "        \"32\"  \"Ransack\"");
                WriteFileLine(file, "        \"33\"  \"Silence\"");
                WriteFileLine(file, "    }");
                WriteFileLine(file, "");
                WriteFileLine(file, "}");
            }
            else if (StrEqual(gv_Game, "tf")) {
                WriteFileLine(file, "\"SourceVote\"");
                WriteFileLine(file, "{");

                WriteFileLine(file, "    \"gv_MapCount\"       \"21\"");
                WriteFileLine(file, "");

                WriteFileLine(file, "    \"gv_MapCodes\"");
                WriteFileLine(file, "    {");
                WriteFileLine(file, "        \"0\"  \"pl_badwater\"");
                WriteFileLine(file, "        \"1\"  \"pl_barnblitz\"");
                WriteFileLine(file, "        \"2\"  \"pl_bloodwater\"");
                WriteFileLine(file, "        \"3\"  \"pl_borneo\"");
                WriteFileLine(file, "        \"4\"  \"pl_breadspace\"");
                WriteFileLine(file, "        \"5\"  \"pl_fifthcurve_event\"");
                WriteFileLine(file, "        \"6\"  \"pl_cactuscanyon\"");
                WriteFileLine(file, "        \"7\"  \"pl_camber\"");
                WriteFileLine(file, "        \"8\"  \"pl_cashworks\"");
                WriteFileLine(file, "        \"9\"  \"pl_chilly\"");
                WriteFileLine(file, "        \"10\"  \"pl_corruption\"");
                WriteFileLine(file, "        \"11\"  \"pl_embargo\"");
                WriteFileLine(file, "        \"12\"  \"pl_emerge\"");
                WriteFileLine(file, "        \"13\"  \"pl_enclosure_final\"");
                WriteFileLine(file, "        \"14\"  \"pl_frontier_final\"");
                WriteFileLine(file, "        \"15\"  \"pl_frostcliff\"");
                WriteFileLine(file, "        \"16\"  \"pl_sludgepit_event\"");
                WriteFileLine(file, "        \"17\"  \"pl_goldrush\"");
                WriteFileLine(file, "        \"18\"  \"pl_rumble_event\"");
                WriteFileLine(file, "        \"19\"  \"pl_hasslecastle\"");
                WriteFileLine(file, "        \"20\"  \"pl_millstone_event\"");
                WriteFileLine(file, "    }");
                WriteFileLine(file, "");

                WriteFileLine(file, "    \"gv_MapNames\"");
                WriteFileLine(file, "    {");
                WriteFileLine(file, "        \"0\"  \"Bad Water\"");
                WriteFileLine(file, "        \"1\"  \"Barn Blitzs\"");
                WriteFileLine(file, "        \"2\"  \"Blood Water\"");
                WriteFileLine(file, "        \"3\"  \"Borneo\"");
                WriteFileLine(file, "        \"4\"  \"Bread Space\"");
                WriteFileLine(file, "        \"5\"  \"Fifth Curve\"");
                WriteFileLine(file, "        \"6\"  \"Cactus Canyon\"");
                WriteFileLine(file, "        \"7\"  \"Camber\"");
                WriteFileLine(file, "        \"8\"  \"Cashworks\"");
                WriteFileLine(file, "        \"9\"  \"Chilly\"");
                WriteFileLine(file, "        \"10\"  \"Corruption\"");
                WriteFileLine(file, "        \"11\"  \"Embargo\"");
                WriteFileLine(file, "        \"12\"  \"Emerge\"");
                WriteFileLine(file, "        \"13\"  \"Enclosure\"");
                WriteFileLine(file, "        \"14\"  \"Frontier\"");
                WriteFileLine(file, "        \"15\"  \"Frost Cliff\"");
                WriteFileLine(file, "        \"16\"  \"Sludgepit\"");
                WriteFileLine(file, "        \"17\"  \"Goldrush\"");
                WriteFileLine(file, "        \"18\"  \"Rumble\"");
                WriteFileLine(file, "        \"19\"  \"Hassle Castle\"");
                WriteFileLine(file, "        \"20\"  \"Millstone\"");
                WriteFileLine(file, "        \"21\"  \"Zephyr\"");
                WriteFileLine(file, "    }");
                WriteFileLine(file, "");
                WriteFileLine(file, "}");
            }
            CloseHandle(file);
            PrintToServer("[Source Vote] Configuration file created: %s", gv_VotePath);
        }
        else
        {
            PrintToServer("[Source Vote] Cannot create default file in: %s", gv_VotePath);
            return;
        }
    }
    // #endregion Default Configuration Creation

    // #region Configuration Load
    KeyValues kv = new KeyValues("SourceVote");
    if (!kv.ImportFromFile(gv_VotePath))
    {
        delete kv;
        PrintToServer("[Source Vote] Cannot load configuration file: %s", gv_VotePath);
    }
    // Loading from file
    else {
        gv_MapCount = kv.GetNum("gv_MapCount", 5);
        if (kv.JumpToKey("gv_MapCodes"))
        {
            for (int i = 0; i < gv_MapCount; i++)
            {
                char key[8];
                Format(key, sizeof(key), "%d", i);
                kv.GetString(key, gv_MapCodes[i], 64);
            }
            kv.GoBack();
            PrintToServer("[Source Vote] Map Codes Loaded!");
        }
        if (kv.JumpToKey("gv_MapNames"))
        {
            for (int i = 0; i < gv_MapCount; i++)
            {
                char key[8];
                Format(key, sizeof(key), "%d", i);
                kv.GetString(key, gv_MapNames[i], 64);
            }
            kv.GoBack();
            PrintToServer("[Source Vote] Map Names Loaded!");
        }
    }
    // #endregion Configuration Load

    // #region Map Vote
    if (gv_DisableMapVote == false)
    {
        if (StrEqual(gv_Game, "left4dead2"))
        {
            if (StrEqual(gv_Gamemode, "versus"))
            {
                PrintToServer("[Source Vote] versus detected");
                HookEventEx("versus_match_finished", RoundEndBasic, EventHookMode_Post);
            }
            else if (StrEqual(gv_Gamemode, "mutation15")) {
                PrintToServer("[Source Vote] survival versus detected");
                HookEventEx("round_end", RoundEndSurvivalVersus, EventHookMode_Post);
            }
            else if (StrEqual(gv_Gamemode, "survival")) {
                PrintToServer("[Source Vote] survival detected");
                HookEventEx("round_end", RoundEndSurvival, EventHookMode_Post);
            }
            else if (StrEqual(gv_Gamemode, "coop")) {
                PrintToServer("[Source Vote] coop detected");
                HookEventEx("finale_start", RoundEndBasic, EventHookMode_Post);
            }
            else
                PrintToServer("[Source Vote] Unsuported gv_Gamemode: %s", gv_Gamemode);
        }
        else if (StrEqual(gv_Game, "nmrih")) {
            HookEvent("player_death", OnPlayerDeath, EventHookMode_PostNoCopy);
            HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_PostNoCopy);
            HookEvent("extraction_complete", RoundEndBasic, EventHookMode_PostNoCopy);
            HookEvent("map_complete", FunctionTest, EventHookMode_PostNoCopy);
        }
        else if (StrEqual(gv_Game, "tf")) {
            // teamplay_game_over ???
        }
    }
    // #endregion Map Vote

    // #region Protections
    if (gv_DisableAdminVoteKickProtection == false)
    {
        PrintToServer("[Source Vote] vote kick protection for admins is enabled");
        AddCommandListener(Votekick_Protection, "callvote");
    }
    if (gv_DisableBackToLobbyProtection)
    {
        PrintToServer("[Source Vote] vote back to lobby protection is enabled");
        AddCommandListener(Votebacktolobby_Protection, "callvote");
    }
    // #endregion Protections
}

public void OnPluginStart()
{
    g_ShouldDebug = CreateConVar(
        "sourceVote_Debug",
        "0",    // default value
        "Should Debug",
        FCVAR_NONE,
        true,    // has min
        0.0,     // min value
        true,    // has max
        1.0      // max value
    );

    g_VotePath = CreateConVar(
        "sourceVote_VoteFile",
        "addons/sourcemod/configs/source_vote.cfg",    // default value
        "Vote File",
        FCVAR_NONE,
        false,    // has min
        0.0,      // min value
        false,    // has max
        0.0       // max value
    );

    g_BanFilePath = CreateConVar(
        "sourceVote_BanFile",
        "cfg/bans.cfg",    // default value
        "Ban File",
        FCVAR_NONE,
        false,    // has min
        0.0,      // min value
        false,    // has max
        0.0       // max value
    );

    g_SecondsToVote = CreateConVar(
        "sourceVote_SecondsToVote",
        "10",    // default value
        "Seconds To Vote",
        FCVAR_NONE,
        true,    // has min
        0.0,     // min value
        true,    // has max
        999.0    // max value
    );

    g_DisableMapVote = CreateConVar(
        "sourceVote_DisableMapVote",
        "0",    // default value
        "Disable Map Vote",
        FCVAR_NONE,
        true,    // has min
        0.0,     // min value
        true,    // has max
        1.0      // max value
    );

    g_DisableAdminVoteKickProtection = CreateConVar(
        "sourceVote_DisableAdminVoteKickProtection",
        "0",    // default value
        "Disable Admin Vote Kick Protection",
        FCVAR_NONE,
        true,    // has min
        0.0,     // min value
        true,    // has max
        1.0      // max value
    );

    g_DisableBackToLobbyProtection = CreateConVar(
        "sourceVote_DisableBackToLobbyProtection",
        "0",    // default value
        "Disable Back To Lobby Protection",
        FCVAR_NONE,
        true,    // has min
        0.0,     // min value
        true,    // has max
        1.0      // max value
    );

    ReadVariables();
    ReadConfigs();

    RegConsoleCmd("startvote", CommandStartVote, "Start voting system");
    RegConsoleCmd("startban", CommandBan, "Ban someone");
    RegConsoleCmd("sourcevotereload", CommandSourceVoteReload, "Reload Cvars and Configs");

    AddCommandListener(Vote_Print, "callvote");

    PrintToServer("[Source Vote] initialized");
}

public OnServerEnterHibernation()
{
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        gv_NMRIH_IsDeadPlayer[i] = false;
    }
}

public Action Vote_Print(int client, const char[] command, int argc)
{
    char targetRaw[128];
    GetCmdArg(2, targetRaw, sizeof(targetRaw));

    PrintToServer("[Source Vote] Someone called a callvote, command: %s, argument: %d, target: %s", command, argc, targetRaw);
    return Plugin_Continue;
}

public Action Votekick_Protection(int client, const char[] command, int argc)
{
    char targetRaw[128];
    GetCmdArg(2, targetRaw, sizeof(targetRaw));

    // Vote kick
    if (StrEqual(command, "callvote") && argc == 2)
    {
        // Start new campaign command
        if (StrEqual("L4D2C1", targetRaw))
            return Plugin_Continue;

        int kickedClient = GetClientOfUserId(StringToInt(targetRaw));

        // Requested kick player is any admin
        if (IsValidClient(client))
        {
            if (GetUserFlagBits(client) & ADMFLAG_GENERIC)
            {
                ServerCommand("kickid %d", StringToInt(targetRaw));
                PrintToChat(client, "[Source Vote] User insta kicked because you are the admin");
                return Plugin_Stop;
            }
        }

        // Kicked player is any admin
        if (IsValidClient(kickedClient))
        {
            if (GetUserFlagBits(kickedClient) & ADMFLAG_GENERIC)
            {
                char kickerName[128];
                GetClientName(client, kickerName, sizeof(kickerName));
                PrintToServer("[Source Vote] cancelling %s votekick, because the kicked client is any admin", kickerName);
                char steamId[32];
                GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
                PrintToChat(kickedClient, "[Source Vote] %s is trying to kick you, but you are any admin, show him some respect, their id: %s", kickerName, steamId);
                return Plugin_Stop;
            }
        }
    }

    return Plugin_Continue;
}

public Action Votebacktolobby_Protection(int client, const char[] command, int argc)
{
    char targetRaw[128];
    GetCmdArg(2, targetRaw, sizeof(targetRaw));

    // Back to lobby
    if (StrEqual(command, "callvote") && argc == 1)
    {
        if (!(GetUserFlagBits(client) & ADMFLAG_CHANGEMAP))
        {
            char voteClientName[128];
            GetClientName(client, voteClientName, sizeof(voteClientName));
            PrintToChatAll("[Source Vote] %s back to lobby is not allowed on this server", voteClientName);
            return Plugin_Stop
        }
    }
    // Start new campaign
    else if (StrEqual(command, "callvote") && argc == 2)
    {
        // Start new campaign command
        if (StrEqual("L4D2C1", targetRaw))
        {
            char voteClientName[128];
            GetClientName(client, voteClientName, sizeof(voteClientName));
            PrintToChatAll("[Source Vote] %s start new campaign is not allowed on this server", voteClientName);
            return Plugin_Stop;
        }
    }
    return Plugin_Continue;
}

public Action CommandStartVote(int client, int args)
{
    if (!IsValidClient(client)) return Plugin_Stop;

    if (!(CheckCommandAccess(client, "sm_startvote", ADMFLAG_CHANGEMAP)))
    {
        PrintToChat(client, "[ERROR] Only admins can use this command.");
        return Plugin_Stop;
    }

    GenerateMapVote();

    InitMapVote();

    PrintToChat(client, "[Source Vote] Vote started");

    return Plugin_Handled;
}

public Action CommandSourceVoteReload(int client, int args)
{
    if (client != 0 && !IsValidClient(client))
        return Plugin_Stop;

    if (client != 0 && !CheckCommandAccess(client, "sm_startban", ADMFLAG_BAN))
    {
        PrintToChat(client, "[ERROR] Only admins can use this command.");
        return Plugin_Stop;
    }

    ReadVariables();
    ReadConfigs();

    if (client == 0)
        PrintToServer("[Source Vote] Variables reloaded.");
    else
        PrintToChat(client, "[Source Vote] Variables reloaded.");

    return Plugin_Handled;
}

// #region Ban
public Action CommandBan(int client, int args)
{
    if (!IsValidClient(client)) return Plugin_Stop;
    if (!(CheckCommandAccess(client, "sm_startban", ADMFLAG_BAN)))
    {
        PrintToServer("%d", GetUserFlagBits(client));
        PrintToChat(client, "[ERROR] Only admins can use this command.");
        return Plugin_Stop;
    }

    // No arguments open the menu
    if (args == 0)
    {
        ShowPlayerSelectMenu(client);
        return Plugin_Handled;
    }

    int bannedClient = GetCmdArgInt(1);
    if (bannedClient == 0)
    {
        PrintToChat(client, "[Source Vote] startban usage: startban <userid> <reason>");
        return Plugin_Stop;
    }

    if (!IsValidClient(bannedClient))
    {
        PrintToChat(client, "[Source Vote] Client is invalid.");
        return Plugin_Stop;
    }

    char reason[128];
    GetCmdArg(2, reason, sizeof(reason));
    if (StrEqual(reason, ""))
    {
        strcopy(reason, sizeof(reason), "Unknown");
    }

    ExecuteBan(client, bannedClient, reason);
    return Plugin_Handled;
}

void ShowPlayerSelectMenu(int client)
{
    Menu menu = new Menu(MenuHandler_PlayerSelect);
    menu.SetTitle("Select player to ban:");

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i) || i == client)
            continue;

        char name[MAX_NAME_LENGTH];
        char userId[16];
        GetClientName(i, name, sizeof(name));
        IntToString(GetClientUserId(i), userId, sizeof(userId));

        menu.AddItem(userId, name);
    }

    if (menu.ItemCount == 0)
    {
        PrintToChat(client, "[Source Vote] No avaible players to ban.");
        delete menu;
        return;
    }

    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void MenuHandler_PlayerSelect(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char userId[16];
        menu.GetItem(param2, userId, sizeof(userId));

        int bannedClient = GetClientOfUserId(StringToInt(userId));
        if (bannedClient == 0 || !IsValidClient(bannedClient))
        {
            PrintToChat(client, "[Source Vote] Player not found.");
        }

        gv_BanTargetMap[client] = bannedClient;
        ShowReasonMenu(client);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

void ShowReasonMenu(int client)
{
    Menu menu = new Menu(MenuHandler_ReasonSelect);
    menu.SetTitle("Ban Reason:");

    menu.AddItem("Cheating", "Cheating / Hacks");
    menu.AddItem("Griefing", "Griefing / Trolling");
    menu.AddItem("Harassment", "Harassment / Spam");
    menu.AddItem("Exploiting", "Exploiting / Bug Abuse");
    menu.AddItem("Unkown", "Unkown");

    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void MenuHandler_ReasonSelect(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char reason[128];
        menu.GetItem(param2, reason, sizeof(reason));

        int bannedClient = gv_BanTargetMap[client];
        if (!IsValidClient(bannedClient))
        {
            PrintToChat(client, "[Source Vote] Invalid player.");
        }

        gv_BanTargetMap[client] = 0;
        ExecuteBan(client, bannedClient, reason);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

void ExecuteBan(int client, int bannedClient, const char[] reason)
{
    char steamId[32];
    GetClientAuthId(bannedClient, AuthId_Steam2, steamId, sizeof(steamId), true);

    char date[32];
    FormatTime(date, sizeof(date), "%Y-%m-%d %H:%M:%S", GetTime());

    char game[64];
    GetGameFolderName(game, sizeof(game));

    Handle file;
    if (!FileExists(gv_BanPath))
        file = OpenFile(gv_BanPath, "w");
    else
        file = OpenFile(gv_BanPath, "a");

    if (file == INVALID_HANDLE)
    {
        PrintToServer("[Source Vote] Failed to open file: %s", gv_BanPath);
        PrintToServer("[Source Vote] FileExists=%d", FileExists(gv_BanPath));
        return;
    }

    WriteFileLine(file, "// Game: %s, Reason: %s, Date: %s", game, reason, date);
    WriteFileLine(file, "banid 0 %s", steamId);
    CloseHandle(file);

    ServerCommand("banid 0 %s kick", steamId);
    KickClient(bannedClient, "You have been permanently banned. Reason: %s");
    PrintToChat(client, "[Source Vote] Player permantly banned. Reason: %s", reason);
}
// #endregion Ban

/// REGION EVENTS
public void RoundEndBasic(Event event, const char[] name, bool dontBroadcast)
{
    GenerateMapVote();

    InitMapVote();
}

// #region Left 4 Dead 2
static bool gv_ShouldMapVote = false;

public void RoundEndSurvivalVersus(Event event, const char[] name, bool dontBroadcast)
{
    int reason = event.GetInt("reason");

    // Restart from hibernation
    if (reason == 8) return;

    // Scenario Restart
    if (reason == 0) return;

    // Chapter ended
    if (reason == 6) return;

    if (!gv_ShouldMapVote)
    {
        gv_ShouldMapVote = true;
        PrintToServer("[Source Vote] First round ended, next round map vote will be called");
        return;
    }
    gv_ShouldMapVote = false;

    GenerateMapVote();

    InitMapVote();
}

public void RoundEndSurvival(Event event, const char[] name, bool dontBroadcast)
{
    int reason = event.GetInt("reason");

    // Restart from hibernation
    if (reason == 8) return;

    // Scenario Restart
    if (reason == 0) return;

    // Chapter ended
    if (reason == 6) return;

    GenerateMapVote();

    InitMapVote();
}
// #endregion Left 4 Dead 2

// #region No More Room in Hell
public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");

    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client))
    {
        return;
    }

    gv_NMRIH_IsDeadPlayer[client] = true;
    if (gv_ShouldDebug)
    {
        char clientName[128];
        GetClientName(client, clientName, sizeof(clientName));
        PrintToServer("[Source Vote-OnPlayerDeath] %s IsDeadPlayer: %b", clientName, gv_NMRIH_IsDeadPlayer[client]);
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i))
            continue;

        if (!gv_NMRIH_IsDeadPlayer[i])
        {
            if (gv_ShouldDebug)
            {
                char clientName[128];
                GetClientName(i, clientName, sizeof(clientName));
                PrintToServer("[Source Vote-OnPlayerDeath] %s is alive ignoring map vote");
            }
            return;
        }
    }

    GenerateMapVote();
    InitMapVote();
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");

    int client = GetClientOfUserId(userid);
    if (!IsValidClient(client))
    {
        return;
    }

    gv_NMRIH_IsDeadPlayer[client] = false;

    if (gv_ShouldDebug)
    {
        char clientName[128];
        GetClientName(client, clientName, sizeof(clientName));
        PrintToServer("[Source Vote-OnPlayerSpawn] %s IsDeadPlayer: %b", clientName, gv_NMRIH_IsDeadPlayer[client]);
    }
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
    gv_NMRIH_IsDeadPlayer[client] = true;

    if (gv_ShouldDebug)
    {
        char clientName[128];
        GetClientName(client, clientName, sizeof(clientName));
        PrintToServer("[Source Vote-OnClientConnect] %s IsDeadPlayer: %b", clientName, gv_NMRIH_IsDeadPlayer[client]);
    }

    return true;
}

public void OnClientDisconnect(int client)
{
    gv_NMRIH_IsDeadPlayer[client] = false;

    if (gv_ShouldDebug)
    {
        char clientName[128];
        GetClientName(client, clientName, sizeof(clientName));
        PrintToServer("[Source Vote-OnClientDisconnect] %s IsDeadPlayer: %b", clientName, gv_NMRIH_IsDeadPlayer[client]);
    }
}

public void FunctionTest(Event event, const char[] name, bool dontBroadcast)
{
    PrintToServer("!!!!!!!!!!!!!!!!!!!!!!! TEST map_complete");
}
// #endregion No More Room in Hell

#define MAX_VOTE_MAPS 8
int  gv_AvailableMapIndexesVotes[MAX_VOTE_MAPS];
int  gv_Votes[MAX_VOTE_MAPS];
char gv_VotedMapCode[64];

public void GenerateMapVote()
{
    // Reset all votes
    for (int i = 0; i < MAX_VOTE_MAPS; i++)
    {
        gv_AvailableMapIndexesVotes[i] = -1;
        gv_Votes[i]                    = 0;
    }

    if (gv_ShouldDebug)
        PrintToServer("[Source Vote] Cleaned votes variables");

    // Map count is lower than MAX_VOTE_MAPS
    // so we add all available maps index to the variable
    if (MAX_VOTE_MAPS >= gv_MapCount)
    {
        for (int i = 0; i < gv_MapCount; i++)
        {
            gv_AvailableMapIndexesVotes[i] = i;

            if (gv_ShouldDebug)
                PrintToServer("[Source Vote] Fixed map added to random: %s", gv_MapNames[gv_AvailableMapIndexesVotes[i]]);
        }
    }
    // Random pickup map indexs
    else {
        int availableMapIndexesVotesCount = 0;
        for (int i = 0; i < gv_MapCount; i++)
        {
            int  randomIndex = GetRandomInt(0, gv_MapCount - 1);
            bool exist       = false;
            for (int j = 0; j < MAX_VOTE_MAPS; j++)
            {
                if (gv_AvailableMapIndexesVotes[j] == randomIndex)
                {
                    exist = true;
                    break;
                }
            }

            if (exist) continue;
            gv_AvailableMapIndexesVotes[availableMapIndexesVotesCount] = randomIndex;
            availableMapIndexesVotesCount++;

            if (gv_ShouldDebug)
                PrintToServer("[Source Vote] New map added to random: %s", gv_MapNames[randomIndex]);

            if (availableMapIndexesVotesCount >= MAX_VOTE_MAPS - 1) break;
        }
    }

    if (gv_ShouldDebug)
        PrintToServer("[Source Vote] Maps randomized");
}

public void InitMapVote()
{
    // Get all online players
    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));

    // Send the same menu with the selected maps to each online player
    for (int i = 0; i <= MaxClients; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;

        Menu menu = new Menu(VoteMenuHandler);
        menu.SetTitle("Map Vote");

        for (int j = 0; j < MAX_VOTE_MAPS; j++)
        {
            // Generate Rematch
            if (j == 0)
            {
                // Left 4 Dead 2 Handling
                if (StrEqual("left4dead2", gv_Game))
                {
                    // Survival Versus create the Rematch button
                    if ((StrEqual(gv_Gamemode, "mutation15") || StrEqual(gv_Gamemode, "survival")) && gv_MapCount >= MAX_VOTE_MAPS)
                    {
                        if (gv_ShouldDebug)
                            PrintToServer("[Source Vote] Survival detected, trying to create rematch...");

                        char mapCode[64];
                        GetCurrentMap(mapCode, sizeof(mapCode));

                        // Get current map index
                        int mapIndex = -1;
                        for (int x = 0; x < gv_MapCount; x++)
                        {
                            if (gv_ShouldDebug)
                                PrintToServer("[Source Vote] STRINGS DIFFERENCE: %s, %s", gv_MapCodes[x], mapCode);
                            if (StrEqual(gv_MapCodes[x], mapCode))
                            {
                                mapIndex = x;
                                break;
                            }
                        }

                        // Check if we can find the actual map index
                        if (mapIndex != -1)
                        {
                            char menuId[2];
                            Format(menuId, sizeof(menuId), "%d", j + 1);

                            if (StrEqual(gv_Gamemode, "mutation15"))
                            {
                                menu.AddItem(menuId, "Rematch");
                            }
                            else if (StrEqual(gv_Gamemode, "survival"))
                            {
                                menu.AddItem(menuId, "Keep Map");
                            }
                            // Replace first option with the rematch option
                            gv_AvailableMapIndexesVotes[j] = mapIndex;

                            if (gv_ShouldDebug)
                                PrintToServer("[Source Vote] Rematch created for client: %d, map: %s", client, gv_MapNames[mapIndex]);
                            continue;
                        }
                        else {
                            if (gv_ShouldDebug)
                                PrintToServer("[Source Vote] FAILED TO CREATE REMATCH FOR: %d", client);
                        }
                    }
                }
                else if (StrEqual("nmrih", gv_Game)) {
                    if (gv_ShouldDebug)
                        PrintToServer("[Source Vote] trying to create rematch...");

                    char mapCode[64];
                    GetCurrentMap(mapCode, sizeof(mapCode));

                    // Get current map index
                    int mapIndex = -1;
                    for (int x = 0; x < gv_MapCount; x++)
                    {
                        if (gv_ShouldDebug)
                            PrintToServer("[Source Vote] STRINGS DIFFERENCE: %s, %s", gv_MapCodes[x], mapCode);
                        if (StrEqual(gv_MapCodes[x], mapCode))
                        {
                            mapIndex = x;
                            break;
                        }
                    }

                    // Check if we can find the actual map index
                    if (mapIndex != -1)
                    {
                        char menuId[2];
                        Format(menuId, sizeof(menuId), "%d", j + 1);

                        menu.AddItem(menuId, "Keep Map");
                        // Replace first option with the rematch option
                        gv_AvailableMapIndexesVotes[j] = mapIndex;

                        if (gv_ShouldDebug)
                            PrintToServer("[Source Vote] Rematch created for client: %d, map: %s", client, gv_MapNames[mapIndex]);
                        continue;
                    }
                    else {
                        if (gv_ShouldDebug)
                            PrintToServer("[Source Vote] FAILED TO CREATE REMATCH FOR: %d", client);
                    }
                }
            }

            int index = gv_AvailableMapIndexesVotes[j];
            if (index == -1) break;

            char menuId[2];
            Format(menuId, sizeof(menuId), "%d", j + 1);

            menu.AddItem(menuId, gv_MapNames[index]);
        }

        menu.Display(client, gv_SecondsToVote);

        PrintToServer("[Source Vote] Menu generated for: %d", client);
    }

    CreateTimer(float(gv_SecondsToVote + 1), VoteFinish, 0, TIMER_FLAG_NO_MAPCHANGE);
}

public int VoteMenuHandler(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param, info, sizeof(info));

        int selection = StringToInt(info) - 1;
        gv_Votes[selection]++;

        int  mapIndex = gv_AvailableMapIndexesVotes[selection];
        char chosenMapName[64];
        strcopy(chosenMapName, sizeof(chosenMapName), gv_MapNames[mapIndex]);

        PrintToChat(client, "Voted #%d: %s", selection + 1, chosenMapName);
        PrintToServer("[Source Vote] %d voted to: %s", client, gv_MapCodes[mapIndex]);
    }
    return 0;
}

public Action VoteFinish(Handle timer)
{
    int maxVotes    = 0;
    int winnerIndex = -1;

    // Find the index of the map with the highest votes
    for (int i = 0; i < MAX_VOTE_MAPS; i++)
    {
        if (gv_Votes[i] > maxVotes)
        {
            maxVotes    = gv_Votes[i];
            winnerIndex = i;
        }
    }

    if (winnerIndex == -1)
    {
        PrintToServer("[Source Vote] No votes registered.");

        // Left 4 Dead 2 Handling
        if (StrEqual("left4dead2", gv_Game))
        {
            if (StrEqual(gv_Gamemode, "mutation15") || StrEqual(gv_Gamemode, "survival"))
            {
                // If is survival mode choose the rematch option
                winnerIndex = 0
            }
            else {
                // Choose a random index from the selected maps for voting
                winnerIndex = GetRandomInt(0, MAX_VOTE_MAPS - 1);
            }
        }
        if (StrEqual("nmrih", gv_Game))
        {
            winnerIndex = 0;
        }
        else {
            // Choose a random index from the selected maps for voting
            winnerIndex = GetRandomInt(0, MAX_VOTE_MAPS - 1);
        }

        PrintToServer("[Source Vote] Random map selected: %d", winnerIndex);
    }
    else {
        PrintToServer("[Source Vote] Player map selected: %d", winnerIndex);
    }

    int mapIndex = gv_AvailableMapIndexesVotes[winnerIndex];

    PrintToServer("[Source Vote] Next Map Index: %d", mapIndex);

    strcopy(gv_VotedMapCode, sizeof(gv_VotedMapCode), gv_MapCodes[mapIndex]);

    PrintToServer("[Source Vote] Next Map Code: %s", gv_VotedMapCode);

    PrintToChatAll("Most voted map: %s with %d votes.", gv_MapNames[mapIndex], maxVotes);

    if (StrEqual(gv_Gamemode, "survival") || StrEqual(gv_Game, "nmrih"))
    {
        char currentMap[64];
        GetCurrentMap(currentMap, sizeof(currentMap));

        if (!StrEqual(currentMap, gv_VotedMapCode))
        {
            PrintToServer("[Source Vote] Map code is not the same, %s / %s", currentMap, gv_VotedMapCode);
            CreateTimer(2.0, VoteChangeLevelTimer);
        }
        else {
            PrintToServer("[Source Vote] Map code is the same, ignoring...");
        }
    }
    else {
        CreateTimer(2.0, VoteChangeLevelTimer);
    }

    return Plugin_Stop;
}

public Action VoteChangeLevelTimer(Handle timer)
{
    // Execute the changelevel command with the selected map
    ServerCommand("changelevel %s\n", gv_VotedMapCode);

    return Plugin_Stop;    // Stop the timer after execution
}

/// REGION Utils

stock void GetOnlinePlayers(int[] onlinePlayers, int playerSize)
{
    int arrayIndex = 0;
    for (int i = 1; i < MaxClients; i += 1)
    {
        if (arrayIndex >= playerSize)
        {
            break;
        }

        int client = i;

        if (!IsValidClient(client))
        {
            continue;
        }

        onlinePlayers[arrayIndex] = client;
        arrayIndex++;
    }
}

stock bool IsValidClient(client)
{
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || IsFakeClient(client))
    {
        return false;
    }
    return IsClientInGame(client);
}
