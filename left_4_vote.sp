#include <sourcemod>

public Plugin myinfo =
{
    name        = "Left 4 Vote",
    author      = "LeandroTheDev",
    description = "Player vote system",
    version     = "1.0",
    url         = "https://github.com/LeandroTheDev/left_4_vote"
};

int  mapCount = 0;
char mapCodes[99][64];
char mapNames[99][64];

bool shouldDebug = false;

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

    char path[PLATFORM_MAX_PATH] = "addons/sourcemod/configs/left_4_vote.cfg";

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
            PrintToServer("[Left 4 Vote] Cannot create default file.");
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

    HookEventEx("versus_match_finished", RoundEnd, EventHookMode_Post);

    RegConsoleCmd("startvote", CommandStartVote, "Start voting system");

    PrintToServer("[Left 4 Vote] Initialized");
}

public Action CommandStartVote(int client, int args)
{
    if (!IsValidClient(client)) return Plugin_Handled;

    PrintToChat(client, "%d", GetUserFlagBits(client));
    if (!(GetUserFlagBits(client) & ADMFLAG_GENERIC))
    {
        PrintToChat(client, "[ERROR] Only admins can use this command.");
        return Plugin_Handled;
    }

    GenerateMapVote();

    InitMapVote();

    PrintToChat(client, "[Left 4 Vote] Vote started");

    return Plugin_Handled;
}

/// REGION EVENTS
#define MAX_VOTE_MAPS 9
int  g_SelectedIndices[MAX_VOTE_MAPS];    // Array to hold the randomly selected map indices for the vote
int  g_SelectedCount = 0;                 // Number of maps selected for the vote
int  g_Votes[MAX_VOTE_MAPS];              // Map Votes
char g_MapCode[64];                       // Voted map code
public void RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    GenerateMapVote();

    InitMapVote();
}

public void GenerateMapVote()
{
    // Reset previous votes
    for (int i = 0; i < MAX_VOTE_MAPS; i++)
    {
        g_Votes[i] = 0;
    }

    if (shouldDebug)
        PrintToServer("[Left 4 Vote] Cleaned votes variables");

    // Randomly select maps once for all players
    g_SelectedCount = (mapCount < MAX_VOTE_MAPS) ? mapCount : MAX_VOTE_MAPS;

    if (shouldDebug)
        PrintToServer("[Left 4 Vote] Total maps: %d", g_SelectedCount);

    int count = 0;

    while (count < g_SelectedCount)
    {
        int  randIndex       = GetRandomInt(0, mapCount - 1);

        // Check if this map index has already been selected
        bool alreadySelected = false;
        for (int i = 0; i < count; i++)
        {
            if (g_SelectedIndices[i] == randIndex)
            {
                alreadySelected = true;
                break;
            }
        }

        // If not already selected, add to the list
        if (!alreadySelected)
        {
            g_SelectedIndices[count] = randIndex;
            count++;

            if (shouldDebug)
                PrintToServer("[Left 4 Vote] New map added to random: %s", mapNames[randIndex]);
        }
    }
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

        // Add each randomly selected map to the menu with IDs 1 to g_SelectedCount
        for (int j = 0; j < g_SelectedCount; j++)
        {
            int  idx = g_SelectedIndices[j];
            char menuId[2];
            Format(menuId, sizeof(menuId), "%d", j + 1);

            menu.AddItem(menuId, mapNames[idx]);
        }

        menu.Display(client, 5);    // Show the menu with a 5 second timeout

        if (shouldDebug)
            PrintToServer("[Left 4 Vote] Menu generated for: %d", client);
    }

    CreateTimer(7.0, VoteFinish, 0, TIMER_FLAG_NO_MAPCHANGE);
}

public int VoteMenuHandler(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param, info, sizeof(info));

        int selection = StringToInt(info) - 1;

        // Check if the selection is valid
        if (selection <= g_SelectedCount)
        {
            g_Votes[selection]++;

            int  mapIndex = g_SelectedIndices[selection];
            char chosenMapName[64];
            strcopy(chosenMapName, sizeof(chosenMapName), mapNames[mapIndex]);

            PrintToChat(client, "Voted #%d: %s", selection, chosenMapName);
            PrintToServer("[Left 4 Vote] %d voted to: %s", client, mapCodes[mapIndex]);
        }
        else
        {
            PrintToChat(client, "Invalid selection.");
        }
    }
    return 0;
}

public Action VoteFinish(Handle timer)
{
    int maxVotes    = -1;
    int winnerIndex = -1;

    // Find the index of the map with the highest votes
    for (int i = 0; i < g_SelectedCount; i++)
    {
        if (g_Votes[i] > maxVotes)
        {
            maxVotes    = g_Votes[i];
            winnerIndex = i;
        }
    }

    if (winnerIndex == -1)
    {
        PrintToServer("[Left 4 Vote] No votes registered.");

        // Choose a random index from the selected maps for voting
        winnerIndex = GetRandomInt(0, g_SelectedCount - 1);
    }

    int mapIndex = g_SelectedIndices[winnerIndex];
    strcopy(g_MapCode, sizeof(g_MapCode), mapCodes[mapIndex]);
    if (shouldDebug)
    {
        PrintToServer("[Left 4 Vote] Next Map Index: %d", mapIndex);
        PrintToServer("[Left 4 Vote] Next Map Code: %d", g_MapCode);
    }

    PrintToChatAll("Most voted map: %s with %d votes.", g_MapCode, maxVotes);

    CreateTimer(3.0, VoteChangeLevelTimer);

    return Plugin_Stop;
}

public Action VoteChangeLevelTimer(Handle timer)
{
    // Execute the changelevel command with the selected map
    ServerCommand("changelevel %s\n", g_MapCode);

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
