#include <sourcemod>

public Plugin myinfo =
{
    name        = "Left 4 Vote",
    author      = "LeandroTheDev",
    description = "Player vote system",
    version     = "1.0",
    url         = "https://github.com/LeandroTheDev/left_4_vote"
};

int       mapCount = 0;
char      mapCodes[99][64];
char      mapNames[99][64];
char      ban_path[PLATFORM_MAX_PATH];

const int SECONDS_TO_VOTE = 10;

char      gamemode[64];
bool      shouldDebug = false;

public void OnPluginStart()
{
    char commandLine[512];
    if (GetCommandLine(commandLine, sizeof(commandLine)))
    {
        if (StrContains(commandLine, "-debug") != -1)
        {
            PrintToServer("[Left 4 Vote] Debug is enabled");
            shouldDebug = true;
        }
    }

    char path[PLATFORM_MAX_PATH];
    if (!GetCommandLineParam("-voteFile", path, sizeof(path)))
    {
        PrintToServer("[Left 4 Vote] Missing -voteFile parameter, using default: addons/sourcemod/configs/left_4_vote.cfg");
        path = "addons/sourcemod/configs/left_4_vote.cfg";
    }
    else {
        if (path[0] == EOS)
        {
            PrintToServer("[Left 4 Vote] -voteFile is empty, using default: addons/sourcemod/configs/left_4_vote.cfg");
            path = "addons/sourcemod/configs/left_4_vote.cfg";
        }
        else {
            PrintToServer("[Left 4 Vote] -voteFile path: %s", path);
        }
    }

    if (!GetCommandLineParam("-banFile", ban_path, sizeof(ban_path)))
    {
        PrintToServer("[Left 4 Vote] Missing -banFile parameter, using default: cfg/bans.cfg");
        ban_path = "cfg/bans.cfg";
    }
    else {
        if (ban_path[0] == EOS)
        {
            PrintToServer("[Left 4 Vote] -banFile is empty, using default: cfg/bans.cfg");
            ban_path = "cfg/bans.cfg";
        }
        else {
            PrintToServer("[Left 4 Vote] -banFile path: %s", ban_path);
        }
    }

    if (!FileExists(path))
    {
        Handle file = OpenFile(path, "w");
        if (file != null)
        {
            WriteFileLine(file, "\"Left4Rank\"");
            WriteFileLine(file, "{");

            WriteFileLine(file, "    \"mapCount\"       \"5\"");
            WriteFileLine(file, "");

            WriteFileLine(file, "    \"mapCodes\"");
            WriteFileLine(file, "    {");
            WriteFileLine(file, "        \"0\"  \"c1m1_hotel\"");
            WriteFileLine(file, "        \"1\"  \"c2m1_highway\"");
            WriteFileLine(file, "        \"2\"  \"c3m1_plankcountry\"");
            WriteFileLine(file, "        \"3\"  \"c4m1_milltown_a\"");
            WriteFileLine(file, "        \"4\"  \"c5m1_waterfront\"");
            WriteFileLine(file, "    }");
            WriteFileLine(file, "");

            WriteFileLine(file, "    \"mapNames\"");
            WriteFileLine(file, "    {");
            WriteFileLine(file, "        \"0\"  \"Dead Center\"");
            WriteFileLine(file, "        \"1\"  \"Dark Carnival\"");
            WriteFileLine(file, "        \"2\"  \"Swamp Fever\"");
            WriteFileLine(file, "        \"3\"  \"Hard Rain\"");
            WriteFileLine(file, "        \"4\"  \"The Parish\"");
            WriteFileLine(file, "    }");
            WriteFileLine(file, "");
            WriteFileLine(file, "}");
            CloseHandle(file);
            PrintToServer("[Left 4 Vote] Configuration file created: %s", path);
        }
        else
        {
            PrintToServer("[Left 4 Vote] Cannot create default file in: %s", path);
            return;
        }
    }

    KeyValues kv = new KeyValues("Left4Rank");
    if (!kv.ImportFromFile(path))
    {
        delete kv;
        PrintToServer("[Left 4 Vote] Cannot load configuration file: %s", path);
    }
    // Loading from file
    else {
        mapCount = kv.GetNum("mapCount", 5);
        if (kv.JumpToKey("mapCodes"))
        {
            for (int i = 0; i < mapCount; i++)
            {
                char key[8];
                Format(key, sizeof(key), "%d", i);
                kv.GetString(key, mapCodes[i], 64);
            }
            kv.GoBack();
            PrintToServer("[Left 4 Vote] mapCodes Loaded!");
        }
        if (kv.JumpToKey("mapNames"))
        {
            for (int i = 0; i < mapCount; i++)
            {
                char key[8];
                Format(key, sizeof(key), "%d", i);
                kv.GetString(key, mapNames[i], 64);
            }
            kv.GoBack();
            PrintToServer("[Left 4 Vote] mapNames Loaded!");
        }
    }

    if (!(StrContains(commandLine, "-disableMapVote", false) != -1))
    {
        GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
        if (StrEqual(gamemode, "versus"))
        {
            PrintToServer("[Left 4 Vote] versus detected");
            HookEventEx("versus_match_finished", RoundEndVersus, EventHookMode_Post);
        }
        else if (StrEqual(gamemode, "mutation15")) {
            PrintToServer("[Left 4 Vote] survival versus detected");
            HookEventEx("round_end", RoundEndSurvivalVersus, EventHookMode_Post);
        }
        else if (StrEqual(gamemode, "survival")) {
            PrintToServer("[Left 4 Vote] survival detected");
            HookEventEx("round_end", RoundEndSurvival, EventHookMode_Post);
        }
        else if (StrEqual(gamemode, "coop")) {
            PrintToServer("[Left 4 Vote] coop detected");
            HookEventEx("finale_start", RoundEndCoop, EventHookMode_Post);
        }
        else
            PrintToServer("[Left 4 Vote] Unsuported gamemode: %s", gamemode);
    }

    RegConsoleCmd("startvote", CommandStartVote, "Start voting system");
    RegConsoleCmd("startban", CommandBan, "Ban someone");

    if (!(StrContains(commandLine, "-disableMdisableVoteKickProtectionpVote", false) != -1))
    {
        PrintToServer("[Left 4 Vote] vote kick protection for admins is enabled");
        AddCommandListener(Votekick_Protection, "callvote");
    }
    if (!(StrContains(commandLine, "-disableBackToLobbyProtection", false) != -1))
    {
        PrintToServer("[Left 4 Vote] vote back to lobby protection is enabled");
        AddCommandListener(Votekick_Protection, "callvote");
    }

    PrintToServer("[Left 4 Vote] initialized");
}

public Action Votekick_Protection(int client, const char[] command, int argc)
{
    char targetRaw[128];
    GetCmdArg(2, targetRaw, sizeof(targetRaw));

    // Vote kick
    if (StrEqual(command, "callvote") && argc == 2)
    {
        int kickedClient = GetClientOfUserId(StringToInt(targetRaw));

        // Requested kick player is any admin
        if (IsValidClient(client))
        {
            if (GetUserFlagBits(client) & ADMFLAG_GENERIC)
            {
                ServerCommand("kickid %d", StringToInt(targetRaw));
                PrintToChat(client, "[Left 4 Vote] User insta kicked because you are the admin");
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
                PrintToServer("[Left 4 Vote] cancelling %s votekick, because the kicked client is any admin", kickerName);
                PrintToChat(kickedClient, "[Left 4 Vote] %s is trying to kick you, but you are any admin, show him some respect", kickerName);
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

    PrintToServer("[Left 4 Vote] %d called: %s, argument: %d, to: %s", client, command, argc, targetRaw);

    // Back to lobby
    if (StrEqual(command, "callvote") && argc == 1)
    {
        char voteClientName[128];
        GetClientName(client, voteClientName, sizeof(voteClientName));
        PrintToChatAll("[Left 4 Vote] %s back to lobby is not allowed on this server", voteClientName);
        return Plugin_Stop
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

    PrintToChat(client, "[Left 4 Vote] Vote started");

    return Plugin_Handled;
}

public Action CommandBan(int client, int args)
{
    if (!IsValidClient(client)) return Plugin_Stop;

    if (!(CheckCommandAccess(client, "sm_startban", ADMFLAG_BAN)))
    {
        PrintToServer("%d", GetUserFlagBits(client))
            PrintToChat(client, "[ERROR] Only admins can use this command.");
        return Plugin_Stop;
    }

    int bannedClient = GetCmdArgInt(1);

    if (bannedClient == 0)
    {
        PrintToChat(client, "[Left 4 Vote] startban usage: startban <userid> <reason>");
        return Plugin_Stop;
    }

    if (!IsValidClient(bannedClient))
    {
        PrintToChat(client, "[Left 4 Vote] Client is invalid.");
        return Plugin_Stop;
    }

    char reason[128];
    GetCmdArg(2, reason, sizeof(reason));

    if (StrEqual(reason, ""))
    {
        reason = "Unkown"
    }

    char steamId[32];
    GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId), true);
    char date[32];
    FormatTime(date, sizeof(date), "%Y-%m-%d %H:%M:%S", GetTime());
    char game[64];
    GetGameFolderName(game, sizeof(game));

    Handle file;
    if (!FileExists(ban_path))
    {
        file = OpenFile(ban_path, "w");
    }
    else
    {
        file = OpenFile(ban_path, "a");
    }

    if (file == INVALID_HANDLE)
    {
        LogError("[BAN] Failed to open file: %s", ban_path);
        LogError("[BAN] FileExists=%d", FileExists(ban_path));
        return Plugin_Stop;
    }

    WriteFileLine(file, "// Game: %s, Reason: %s, Data: %s", game, reason, date);
    WriteFileLine(file, "banid 0 %s", steamId);
    CloseHandle(file);

    ServerCommand("banid 0 %s kick", steamId);

    PrintToChat(client, "[Left 4 Vote] Player permantly banned");

    return Plugin_Handled;
}

/// REGION EVENTS
public void RoundEndVersus(Event event, const char[] name, bool dontBroadcast)
{
    GenerateMapVote();

    InitMapVote();
}

public void RoundEndCoop(Event event, const char[] name, bool dontBroadcast)
{
    GenerateMapVote();

    InitMapVote();
}

static bool shouldMapVote = false;

public void RoundEndSurvivalVersus(Event event, const char[] name, bool dontBroadcast)
{
    int reason = event.GetInt("reason");

    // Restart from hibernation
    if (reason == 8) return;

    // Scenario Restart
    if (reason == 0) return;

    // Chapter ended
    if (reason == 6) return;

    if (!shouldMapVote)
    {
        shouldMapVote = true;
        PrintToServer("[Left 4 Vote] First round ended, next round map vote will be called");
        return;
    }
    shouldMapVote = false;

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

#define MAX_VOTE_MAPS 8
int  availableMapIndexesVotes[MAX_VOTE_MAPS];
int  votes[MAX_VOTE_MAPS];
char votedMapCode[64];

public void GenerateMapVote()
{
    // Reset all votes
    for (int i = 0; i < MAX_VOTE_MAPS; i++)
    {
        availableMapIndexesVotes[i] = -1;
        votes[i]                    = 0;
    }

    if (shouldDebug)
        PrintToServer("[Left 4 Vote] Cleaned votes variables");

    // Map count is lower than MAX_VOTE_MAPS
    // so we add all available maps index to the variable
    if (MAX_VOTE_MAPS >= mapCount)
    {
        for (int i = 0; i < mapCount; i++)
        {
            availableMapIndexesVotes[i] = i;

            if (shouldDebug)
                PrintToServer("[Left 4 Vote] Fixed map added to random: %s", mapNames[availableMapIndexesVotes[i]]);
        }
    }
    // Random pickup map indexs
    else {
        int availableMapIndexesVotesCount = 0;
        for (int i = 0; i < mapCount; i++)
        {
            int  randomIndex = GetRandomInt(0, mapCount - 1);
            bool exist       = false;
            for (int j = 0; j < MAX_VOTE_MAPS; j++)
            {
                if (availableMapIndexesVotes[j] == randomIndex)
                {
                    exist = true;
                    break;
                }
            }

            if (exist) continue;
            availableMapIndexesVotes[availableMapIndexesVotesCount] = randomIndex;
            availableMapIndexesVotesCount++;

            if (shouldDebug)
                PrintToServer("[Left 4 Vote] New map added to random: %s", mapNames[randomIndex]);

            if (availableMapIndexesVotesCount >= MAX_VOTE_MAPS - 1) break;
        }
    }

    if (shouldDebug)
        PrintToServer("[Left 4 Vote] Maps randomized");
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
                // Survival Versus create the Rematch button
                if ((StrEqual(gamemode, "mutation15") || StrEqual(gamemode, "survival")) && mapCount >= MAX_VOTE_MAPS)
                {
                    if (shouldDebug)
                        PrintToServer("[Left 4 Vote] Versus Survival detected, trying to create rematch...");

                    char mapCode[64];
                    GetCurrentMap(mapCode, sizeof(mapCode));

                    // Get current map index
                    int mapIndex = -1;
                    for (int x = 0; x < mapCount; x++)
                    {
                        if (shouldDebug)
                            PrintToServer("[Left 4 Vote] STRINGS DIFFERENCE: %s, %s", mapCodes[x], mapCode);
                        if (StrEqual(mapCodes[x], mapCode))
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

                        if (StrEqual(gamemode, "mutation15"))
                        {
                            menu.AddItem(menuId, "Rematch");
                        }
                        else if (StrEqual(gamemode, "survival"))
                        {
                            menu.AddItem(menuId, "Keep Map");
                        }
                        // Replace first option with the rematch option
                        availableMapIndexesVotes[j] = mapIndex;

                        if (shouldDebug)
                            PrintToServer("[Left 4 Vote] Rematch created for client: %d, map: %s", client, mapNames[mapIndex]);
                        continue;
                    }
                    else {
                        if (shouldDebug)
                            PrintToServer("[Left 4 Vote] FAILED TO CREATE REMATCH FOR: %d", client);
                    }
                }
            }

            int index = availableMapIndexesVotes[j];
            if (index == -1) break;

            char menuId[2];
            Format(menuId, sizeof(menuId), "%d", j + 1);

            menu.AddItem(menuId, mapNames[index]);
        }

        menu.Display(client, SECONDS_TO_VOTE);

        PrintToServer("[Left 4 Vote] Menu generated for: %d", client);
    }

    CreateTimer(float(SECONDS_TO_VOTE + 1), VoteFinish, 0, TIMER_FLAG_NO_MAPCHANGE);
}

public int VoteMenuHandler(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param, info, sizeof(info));

        int selection = StringToInt(info) - 1;
        votes[selection]++;

        int  mapIndex = availableMapIndexesVotes[selection];
        char chosenMapName[64];
        strcopy(chosenMapName, sizeof(chosenMapName), mapNames[mapIndex]);

        PrintToChat(client, "Voted #%d: %s", selection + 1, chosenMapName);
        PrintToServer("[Left 4 Vote] %d voted to: %s", client, mapCodes[mapIndex]);
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
        if (votes[i] > maxVotes)
        {
            maxVotes    = votes[i];
            winnerIndex = i;
        }
    }

    if (winnerIndex == -1)
    {
        PrintToServer("[Left 4 Vote] No votes registered.");

        if (StrEqual(gamemode, "mutation15") || StrEqual(gamemode, "survival"))
        {
            // If is survival mode choose the rematch option
            winnerIndex = 0
        }
        else {
            // Choose a random index from the selected maps for voting
            winnerIndex = GetRandomInt(0, MAX_VOTE_MAPS - 1);
        }

        PrintToServer("[Left 4 Vote] Random map selected: %d", winnerIndex);
    }
    else {
        PrintToServer("[Left 4 Vote] Player map selected: %d", winnerIndex);
    }

    int mapIndex = availableMapIndexesVotes[winnerIndex];

    PrintToServer("[Left 4 Vote] Next Map Index: %d", mapIndex);

    strcopy(votedMapCode, sizeof(votedMapCode), mapCodes[mapIndex]);

    PrintToServer("[Left 4 Vote] Next Map Code: %s", votedMapCode);

    PrintToChatAll("Most voted map: %s with %d votes.", mapNames[mapIndex], maxVotes);

    if (StrEqual(gamemode, "survival"))
    {
        char currentMap[64];
        GetCurrentMap(currentMap, sizeof(currentMap));

        if (!StrEqual(currentMap, votedMapCode))
        {
            PrintToServer("[Left 4 Vote] Map code is not the same, %s / %s", currentMap, votedMapCode);
            CreateTimer(2.0, VoteChangeLevelTimer);
        }
        else {
            PrintToServer("[Left 4 Vote] Map code is the same, ignoring...");
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
    ServerCommand("changelevel %s\n", votedMapCode);

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
