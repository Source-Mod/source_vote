#include <sourcemod>
#include <nextmap>

public Plugin myinfo =
{
    name        = "Source Vote",
    author      = "LeansBoboDev",
    description = "Player vote system",
    version     = "2.1",
    url         = "https://github.com/LeansBoboDev/source_vote"
};

bool   gv_NMRIH_IsDeadPlayer[MAXPLAYERS];
int    gv_NMRIH_PlayerTokens[MAXPLAYERS];
bool   gv_NMRIH_IsPracticing = true;
Handle gv_VoteTimer          = null;

// #region Griefing Vote (NMRIH)
float  gv_NMRIH_KillTimestamps[MAXPLAYERS][2];
bool   gv_GriefingVoteActive        = false;
int    gv_GriefingVoteAccused       = 0;
int    gv_GriefingVoteYesCount      = 0;
Handle gv_GriefingVoteTimer         = null;
bool   gv_DisableGriefingVote       = false;
float  gv_GriefingKillWindowSeconds = 120.0;
int    gv_GriefingVoteSeconds       = 20;
int    gv_GriefingBanMinutesPerVote = 15;
// #endregion Griefing Vote (NMRIH)

int    gv_BanTargetMap[MAXPLAYERS];
int    gv_KickTargetMap[MAXPLAYERS];
int    gv_ReportTargetMap[MAXPLAYERS];
bool   gv_ShouldDebug = false;
int    gv_MapCount    = 0;
char   gv_MapCodes[99][64];
char   gv_MapNames[99][64];
char   gv_BanPath[PLATFORM_MAX_PATH];
char   gv_VotePath[PLATFORM_MAX_PATH];
char   gv_ReportPath[PLATFORM_MAX_PATH];
int    gv_SecondsToVote                  = 10;
bool   gv_DisableMapVote                 = false;
bool   gv_DisableAdminVoteKickProtection = false;
bool   gv_DisableBackToLobbyProtection   = false;
float  gv_TfExtendMinutes                = 10.0;
bool   gv_WarnPluginMessages             = true;
bool   gv_DisableReportReminder          = false;
int    gv_ReportReminderMinutes          = 30;
Handle gv_ReportReminderTimer            = null;

char   gv_Gamemode[64];
char   gv_Game[64];

ConVar g_ShouldDebug;
ConVar g_VotePath;
ConVar g_BanFilePath;
ConVar g_ReportFilePath;
ConVar g_SecondsToVote;
ConVar g_DisableMapVote;
ConVar g_DisableAdminVoteKickProtection;
ConVar g_DisableBackToLobbyProtection;
ConVar g_TfExtendMinutes;
ConVar g_WarnPluginMessages;
ConVar g_DisableGriefingVote;
ConVar g_GriefingKillWindowSeconds;
ConVar g_GriefingVoteSeconds;
ConVar g_GriefingBanMinutesPerVote;
ConVar g_DisableReportReminder;
ConVar g_ReportReminderMinutes;

void   ReadVariables()
{
    gv_ShouldDebug = g_ShouldDebug.BoolValue;
    PrintToServer("[SourceVote] Should debug is enabled: %b", gv_ShouldDebug);

    g_VotePath.GetString(gv_VotePath, sizeof(gv_VotePath));
    PrintToServer("[SourceVote] Using vote file: %s", gv_VotePath);

    g_BanFilePath.GetString(gv_BanPath, sizeof(gv_BanPath));
    PrintToServer("[SourceVote] Using ban file: %s", gv_BanPath);

    g_ReportFilePath.GetString(gv_ReportPath, sizeof(gv_ReportPath));
    PrintToServer("[SourceVote] Using report file: %s", gv_ReportPath);

    gv_SecondsToVote = g_SecondsToVote.IntValue;
    PrintToServer("[SourceVote] Seconds to Vote: %d", gv_SecondsToVote);

    GetGameFolderName(gv_Game, sizeof(gv_Game));

    if (StrEqual(gv_Game, "left4dead2"))
    {
        GetConVarString(FindConVar("mp_gamemode"), gv_Gamemode, sizeof(gv_Gamemode));
        PrintToServer("[SourceVote] Loaded gv_Gamemode: %s", gv_Gamemode);
    }
    else {
        gv_Gamemode = "Unsuported"
    }

    gv_DisableMapVote = g_DisableMapVote.BoolValue;
    PrintToServer("[SourceVote] Map vote is disabled: %b", gv_DisableMapVote);

    gv_DisableAdminVoteKickProtection = g_DisableAdminVoteKickProtection.BoolValue;
    PrintToServer("[SourceVote] Admin vote kick protection is disabled: %b", gv_DisableAdminVoteKickProtection);

    gv_DisableBackToLobbyProtection = g_DisableBackToLobbyProtection.BoolValue;
    PrintToServer("[SourceVote] Back to lobby protection is disabled: %b", gv_DisableBackToLobbyProtection);

    gv_TfExtendMinutes = g_TfExtendMinutes.FloatValue;
    PrintToServer("[SourceVote] TF2 map extend minutes: %f", gv_TfExtendMinutes);

    gv_WarnPluginMessages = g_WarnPluginMessages.BoolValue;
    PrintToServer("[SourceVote] Warn plugin messages disabled: %b", gv_WarnPluginMessages);

    gv_DisableGriefingVote = g_DisableGriefingVote.BoolValue;
    PrintToServer("[SourceVote] Griefing Vote is disabled: %b", gv_DisableGriefingVote);

    gv_GriefingKillWindowSeconds = g_GriefingKillWindowSeconds.FloatValue;
    PrintToServer("[SourceVote] Griefing Vote kill window seconds: %f", gv_GriefingKillWindowSeconds);

    gv_GriefingVoteSeconds = g_GriefingVoteSeconds.IntValue;
    PrintToServer("[SourceVote] Griefing Vote seconds: %d", gv_GriefingVoteSeconds);

    gv_GriefingBanMinutesPerVote = g_GriefingBanMinutesPerVote.IntValue;
    PrintToServer("[SourceVote] Griefing Vote ban minutes per yes vote: %d", gv_GriefingBanMinutesPerVote);

    gv_DisableReportReminder = g_DisableReportReminder.BoolValue;
    PrintToServer("[SourceVote] Report reminder is disabled: %b", gv_DisableReportReminder);

    gv_ReportReminderMinutes = g_ReportReminderMinutes.IntValue;
    PrintToServer("[SourceVote] Report reminder minutes: %d", gv_ReportReminderMinutes);

    StartReportReminderTimer();
}

void StartReportReminderTimer()
{
    if (gv_ReportReminderTimer != null)
    {
        KillTimer(gv_ReportReminderTimer);
        gv_ReportReminderTimer = null;
    }

    if (gv_DisableReportReminder || gv_ReportReminderMinutes <= 0)
        return;

    gv_ReportReminderTimer = CreateTimer(float(gv_ReportReminderMinutes * 60), ReportReminderTimer, 0, TIMER_REPEAT);
}

public Action ReportReminderTimer(Handle timer)
{
    PrintToChatAll("[SourceVote] Use !report to report a player that is misbehaving.");
    return Plugin_Continue;
}

bool gvf_Hooked_L4D2_VersusMatchFinished    = false;
bool gvf_Hooked_L4D2_RoundEndSurvival       = false;
bool gvf_Hooked_L4D2_VersusRematchStart     = false;
bool gvf_Hooked_L4D2_FinaleStart            = false;
bool gvf_Hooked_L4D2_SurvivalVersusRoundEnd = false;
bool gvf_Hooked_NMRIH_PlayerDeath           = false;
bool gvf_Hooked_NMRIH_PlayerSpawn           = false;
bool gvf_Hooked_NMRIH_ExtractionComplete    = false;
bool gvf_Hooked_NMRIH_ExtractionExpire     = false;
bool gvf_Hooked_NMRIH_TokenEarned           = false;
bool gvf_Hooked_NMRIH_MapComplete           = false;
bool gvf_Hooked_NMRIH_RoundBegin            = false;
bool gvf_Hooked_TF_MapTimeRemaining         = false;
int  gv_SurvivalVersus_RoundCount           = 0;
bool gv_TF_VoteTriggered                    = false;
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
            }
            else if (StrEqual(gv_Game, "nmrih")) {
                WriteFileLine(file, "\"SourceVote\"");
                WriteFileLine(file, "{");

                WriteFileLine(file, "    \"mapCount\"       \"34\"");
                WriteFileLine(file, "");

                WriteFileLine(file, "    \"mapCodes\"");
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

                WriteFileLine(file, "    \"mapNames\"");
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

                WriteFileLine(file, "    \"mapCount\"       \"21\"");
                WriteFileLine(file, "");

                WriteFileLine(file, "    \"mapCodes\"");
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

                WriteFileLine(file, "    \"mapNames\"");
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
            else if (StrEqual(gv_Game, "tf2classified")) {
                WriteFileLine(file, "\"SourceVote\"");
                WriteFileLine(file, "{");

                WriteFileLine(file, "    \"mapCount\"       \"76\"");
                WriteFileLine(file, "");

                WriteFileLine(file, "    \"mapCodes\"");
                WriteFileLine(file, "    {");
                WriteFileLine(file, "        \"0\"  \"4arena_flask\"");
                WriteFileLine(file, "        \"1\"  \"4arena_floodgate\"");
                WriteFileLine(file, "        \"2\"  \"4dom_hydro\"");
                WriteFileLine(file, "        \"3\"  \"4dom_krepost\"");
                WriteFileLine(file, "        \"4\"  \"4koth_frigid\"");
                WriteFileLine(file, "        \"5\"  \"4plr_sisyphus\"");
                WriteFileLine(file, "        \"6\"  \"arena_badlands\"");
                WriteFileLine(file, "        \"7\"  \"arena_granary\"");
                WriteFileLine(file, "        \"8\"  \"arena_lumberyard\"");
                WriteFileLine(file, "        \"9\"  \"arena_nucleus\"");
                WriteFileLine(file, "        \"10\"  \"arena_offblast_final\"");
                WriteFileLine(file, "        \"11\"  \"arena_ravine\"");
                WriteFileLine(file, "        \"12\"  \"arena_sawmill\"");
                WriteFileLine(file, "        \"13\"  \"arena_watchtower\"");
                WriteFileLine(file, "        \"14\"  \"cp_5gorge\"");
                WriteFileLine(file, "        \"15\"  \"cp_amaranth\"");
                WriteFileLine(file, "        \"16\"  \"cp_badlands\"");
                WriteFileLine(file, "        \"17\"  \"cp_coldfront\"");
                WriteFileLine(file, "        \"18\"  \"cp_degrootkeep\"");
                WriteFileLine(file, "        \"19\"  \"cp_dustbowl\"");
                WriteFileLine(file, "        \"20\"  \"cp_egypt_final\"");
                WriteFileLine(file, "        \"21\"  \"cp_fastlane\"");
                WriteFileLine(file, "        \"22\"  \"cp_foundry\"");
                WriteFileLine(file, "        \"23\"  \"cp_freight_final1\"");
                WriteFileLine(file, "        \"24\"  \"cp_furnace_rc\"");
                WriteFileLine(file, "        \"25\"  \"cp_gorge\"");
                WriteFileLine(file, "        \"26\"  \"cp_granary\"");
                WriteFileLine(file, "        \"27\"  \"cp_gravelpit\"");
                WriteFileLine(file, "        \"28\"  \"cp_gullywash\"");
                WriteFileLine(file, "        \"29\"  \"cp_junction_final\"");
                WriteFileLine(file, "        \"30\"  \"cp_mountainlab\"");
                WriteFileLine(file, "        \"31\"  \"cp_powerhouse\"");
                WriteFileLine(file, "        \"32\"  \"cp_steel\"");
                WriteFileLine(file, "        \"33\"  \"cp_tidal_v4\"");
                WriteFileLine(file, "        \"34\"  \"cp_well\"");
                WriteFileLine(file, "        \"35\"  \"cp_yukon_final\"");
                WriteFileLine(file, "        \"36\"  \"ctf_2fort\"");
                WriteFileLine(file, "        \"37\"  \"ctf_doublecross\"");
                WriteFileLine(file, "        \"38\"  \"ctf_landfall\"");
                WriteFileLine(file, "        \"39\"  \"ctf_pelican_peak\"");
                WriteFileLine(file, "        \"40\"  \"ctf_sawmill\"");
                WriteFileLine(file, "        \"41\"  \"ctf_turbine\"");
                WriteFileLine(file, "        \"42\"  \"ctf_well\"");
                WriteFileLine(file, "        \"43\"  \"dom_oilcanyon\"");
                WriteFileLine(file, "        \"44\"  \"dom_railway\"");
                WriteFileLine(file, "        \"45\"  \"dom_sawtooth\"");
                WriteFileLine(file, "        \"46\"  \"itemtest\"");
                WriteFileLine(file, "        \"47\"  \"itemtest_4team\"");
                WriteFileLine(file, "        \"48\"  \"koth_badlands\"");
                WriteFileLine(file, "        \"49\"  \"koth_harvest_event\"");
                WriteFileLine(file, "        \"50\"  \"koth_harvest_final\"");
                WriteFileLine(file, "        \"51\"  \"koth_lakeside_final\"");
                WriteFileLine(file, "        \"52\"  \"koth_nucleus\"");
                WriteFileLine(file, "        \"53\"  \"koth_sawmill\"");
                WriteFileLine(file, "        \"54\"  \"koth_viaduct\"");
                WriteFileLine(file, "        \"55\"  \"pl_badwater\"");
                WriteFileLine(file, "        \"56\"  \"pl_barnblitz\"");
                WriteFileLine(file, "        \"57\"  \"pl_frontier_final\"");
                WriteFileLine(file, "        \"58\"  \"pl_goldrush\"");
                WriteFileLine(file, "        \"59\"  \"pl_hoodoo_final\"");
                WriteFileLine(file, "        \"60\"  \"pl_jinn\"");
                WriteFileLine(file, "        \"61\"  \"pl_thundermountain\"");
                WriteFileLine(file, "        \"62\"  \"plr_hightower\"");
                WriteFileLine(file, "        \"63\"  \"plr_nightfall_final\"");
                WriteFileLine(file, "        \"64\"  \"plr_pipeline\"");
                WriteFileLine(file, "        \"65\"  \"tc_hydro\"");
                WriteFileLine(file, "        \"66\"  \"td_caper\"");
                WriteFileLine(file, "        \"67\"  \"td_sunnyside\"");
                WriteFileLine(file, "        \"68\"  \"vip_avanti\"");
                WriteFileLine(file, "        \"69\"  \"vip_badwater\"");
                WriteFileLine(file, "        \"70\"  \"vip_harbor\"");
                WriteFileLine(file, "        \"71\"  \"vip_mineside\"");
                WriteFileLine(file, "        \"72\"  \"vip_trainyard\"");
                WriteFileLine(file, "        \"73\"  \"vipr_2bridge\"");
                WriteFileLine(file, "        \"74\"  \"vipr_chopper\"");
                WriteFileLine(file, "        \"75\"  \"vipr_drizzle\"");
                WriteFileLine(file, "    }");
                WriteFileLine(file, "");

                WriteFileLine(file, "    \"mapNames\"");
                WriteFileLine(file, "    {");
                WriteFileLine(file, "        \"0\"  \"Flask\"");
                WriteFileLine(file, "        \"1\"  \"Floodgate\"");
                WriteFileLine(file, "        \"2\"  \"Hydro (Domination)\"");
                WriteFileLine(file, "        \"3\"  \"Krepost (Domination)\"");
                WriteFileLine(file, "        \"4\"  \"Frigid (KOTH)\"");
                WriteFileLine(file, "        \"5\"  \"Sisyphus (Payload Race)\"");
                WriteFileLine(file, "        \"6\"  \"Badlands (Arena)\"");
                WriteFileLine(file, "        \"7\"  \"Granary (Arena)\"");
                WriteFileLine(file, "        \"8\"  \"Lumberyard (Arena)\"");
                WriteFileLine(file, "        \"9\"  \"Nucleus (Arena)\"");
                WriteFileLine(file, "        \"10\"  \"Offblast (Arena)\"");
                WriteFileLine(file, "        \"11\"  \"Ravine (Arena)\"");
                WriteFileLine(file, "        \"12\"  \"Sawmill (Arena)\"");
                WriteFileLine(file, "        \"13\"  \"Watchtower (Arena)\"");
                WriteFileLine(file, "        \"14\"  \"5Gorge\"");
                WriteFileLine(file, "        \"15\"  \"Amaranth\"");
                WriteFileLine(file, "        \"16\"  \"Badlands\"");
                WriteFileLine(file, "        \"17\"  \"Coldfront\"");
                WriteFileLine(file, "        \"18\"  \"Degroot Keep\"");
                WriteFileLine(file, "        \"19\"  \"Dustbowl\"");
                WriteFileLine(file, "        \"20\"  \"Egypt\"");
                WriteFileLine(file, "        \"21\"  \"Fastlane\"");
                WriteFileLine(file, "        \"22\"  \"Foundry\"");
                WriteFileLine(file, "        \"23\"  \"Freight\"");
                WriteFileLine(file, "        \"24\"  \"Furnace Creek\"");
                WriteFileLine(file, "        \"25\"  \"Gorge\"");
                WriteFileLine(file, "        \"26\"  \"Granary\"");
                WriteFileLine(file, "        \"27\"  \"Gravel Pit\"");
                WriteFileLine(file, "        \"28\"  \"Gullywash\"");
                WriteFileLine(file, "        \"29\"  \"Junction\"");
                WriteFileLine(file, "        \"30\"  \"Mountain Lab\"");
                WriteFileLine(file, "        \"31\"  \"Powerhouse\"");
                WriteFileLine(file, "        \"32\"  \"Steel\"");
                WriteFileLine(file, "        \"33\"  \"Tidal\"");
                WriteFileLine(file, "        \"34\"  \"Well\"");
                WriteFileLine(file, "        \"35\"  \"Yukon\"");
                WriteFileLine(file, "        \"36\"  \"2Fort\"");
                WriteFileLine(file, "        \"37\"  \"Double Cross\"");
                WriteFileLine(file, "        \"38\"  \"Landfall\"");
                WriteFileLine(file, "        \"39\"  \"Pelican Peak\"");
                WriteFileLine(file, "        \"40\"  \"Sawmill (CTF)\"");
                WriteFileLine(file, "        \"41\"  \"Turbine\"");
                WriteFileLine(file, "        \"42\"  \"Well (CTF)\"");
                WriteFileLine(file, "        \"43\"  \"Oil Canyon\"");
                WriteFileLine(file, "        \"44\"  \"Railway\"");
                WriteFileLine(file, "        \"45\"  \"Sawtooth\"");
                WriteFileLine(file, "        \"46\"  \"Item Test\"");
                WriteFileLine(file, "        \"47\"  \"Item Test (4 Team)\"");
                WriteFileLine(file, "        \"48\"  \"Badlands (KOTH)\"");
                WriteFileLine(file, "        \"49\"  \"Harvest (Halloween)\"");
                WriteFileLine(file, "        \"50\"  \"Harvest\"");
                WriteFileLine(file, "        \"51\"  \"Lakeside\"");
                WriteFileLine(file, "        \"52\"  \"Nucleus (KOTH)\"");
                WriteFileLine(file, "        \"53\"  \"Sawmill (KOTH)\"");
                WriteFileLine(file, "        \"54\"  \"Viaduct\"");
                WriteFileLine(file, "        \"55\"  \"Badwater Basin\"");
                WriteFileLine(file, "        \"56\"  \"Barnblitz\"");
                WriteFileLine(file, "        \"57\"  \"Frontier\"");
                WriteFileLine(file, "        \"58\"  \"Gold Rush\"");
                WriteFileLine(file, "        \"59\"  \"Hoodoo\"");
                WriteFileLine(file, "        \"60\"  \"Jinn\"");
                WriteFileLine(file, "        \"61\"  \"Thunder Mountain\"");
                WriteFileLine(file, "        \"62\"  \"Hightower\"");
                WriteFileLine(file, "        \"63\"  \"Nightfall\"");
                WriteFileLine(file, "        \"64\"  \"Pipeline\"");
                WriteFileLine(file, "        \"65\"  \"Hydro (Territorial Control)\"");
                WriteFileLine(file, "        \"66\"  \"Caper (Training)\"");
                WriteFileLine(file, "        \"67\"  \"Sunnyside (Training)\"");
                WriteFileLine(file, "        \"68\"  \"Avanti (VIP)\"");
                WriteFileLine(file, "        \"69\"  \"Badwater (VIP)\"");
                WriteFileLine(file, "        \"70\"  \"Harbor (VIP)\"");
                WriteFileLine(file, "        \"71\"  \"Mineside (VIP)\"");
                WriteFileLine(file, "        \"72\"  \"Trainyard (VIP)\"");
                WriteFileLine(file, "        \"73\"  \"2Bridge (VIP Raid)\"");
                WriteFileLine(file, "        \"74\"  \"Chopper (VIP Raid)\"");
                WriteFileLine(file, "        \"75\"  \"Drizzle (VIP Raid)\"");
                WriteFileLine(file, "    }");
                WriteFileLine(file, "");
                WriteFileLine(file, "}");
            }
            CloseHandle(file);
            PrintToServer("[SourceVote] Configuration file created: %s", gv_VotePath);
        }
        else
        {
            PrintToServer("[SourceVote] Cannot create default file in: %s", gv_VotePath);
            return;
        }
    }
    // #endregion Default Configuration Creation

    // #region Configuration Load
    KeyValues kv = new KeyValues("SourceVote");
    if (!kv.ImportFromFile(gv_VotePath))
    {
        delete kv;
        PrintToServer("[SourceVote] Cannot load configuration file: %s", gv_VotePath);
    }
    // Loading from file
    else {
        gv_MapCount = kv.GetNum("mapCount", 5);
        if (kv.JumpToKey("mapCodes"))
        {
            for (int i = 0; i < gv_MapCount; i++)
            {
                char key[8];
                Format(key, sizeof(key), "%d", i);
                kv.GetString(key, gv_MapCodes[i], 64);
                PrintToServer("[SourceVote] Map Code [%d]: %s", i, gv_MapCodes[i]);
            }
            kv.GoBack();
            PrintToServer("[SourceVote] Map Codes Loaded: %d", gv_MapCount);
        }
        else {
            PrintToServer("[SourceVote] WARNING: mapCodes section not found in config!");
        }
        if (kv.JumpToKey("mapNames"))
        {
            for (int i = 0; i < gv_MapCount; i++)
            {
                char key[8];
                Format(key, sizeof(key), "%d", i);
                kv.GetString(key, gv_MapNames[i], 64);
                PrintToServer("[SourceVote] Map Name [%d]: %s", i, gv_MapNames[i]);
            }
            kv.GoBack();
            PrintToServer("[SourceVote] Map Names Loaded: %d", gv_MapCount);
        }
        else {
            PrintToServer("[SourceVote] WARNING: mapNames section not found in config! Disabling map vote.");
            gv_MapCount = 0;
        }
    }
    // #endregion Configuration Load

    // #region Map Vote
    if (gv_DisableMapVote == false && gv_MapCount > 0)
    {
        SafeUnhook("versus_match_finished", RoundEndBasic, EventHookMode_Post, gvf_Hooked_L4D2_VersusMatchFinished);
        SafeUnhook("round_end", RoundEndSurvival, EventHookMode_Post, gvf_Hooked_L4D2_RoundEndSurvival);
        SafeUnhook("round_end", RoundEndSurvivalVersus, EventHookMode_Post, gvf_Hooked_L4D2_SurvivalVersusRoundEnd);
        SafeUnhook("finale_start", RoundEndBasic, EventHookMode_Post, gvf_Hooked_L4D2_FinaleStart);
        SafeUnhook("player_death", OnPlayerDeath, EventHookMode_Post, gvf_Hooked_NMRIH_PlayerDeath);
        SafeUnhook("player_spawn", OnPlayerSpawn, EventHookMode_Post, gvf_Hooked_NMRIH_PlayerSpawn);
        SafeUnhook("extraction_complete", RoundEndBasic, EventHookMode_Post, gvf_Hooked_NMRIH_ExtractionComplete);
        SafeUnhook("extraction_expire", RoundEndBasic, EventHookMode_Post, gvf_Hooked_NMRIH_ExtractionExpire);
        SafeUnhook("token_earned", OnPlayerReceiveToken, EventHookMode_Post, gvf_Hooked_NMRIH_TokenEarned);
        SafeUnhook("map_complete", FunctionTest, EventHookMode_Post, gvf_Hooked_NMRIH_MapComplete);
        SafeUnhook("nmrih_round_begin", OnRoundBegin, EventHookMode_Post, gvf_Hooked_NMRIH_RoundBegin);
        SafeUnhook("tf_map_time_remaining", OnTfMapTimeRemaining, EventHookMode_Post, gvf_Hooked_TF_MapTimeRemaining);
        SafeUnhookUserMsg("PZEndGamePanelMsg", VersusRematchStart, true, gvf_Hooked_L4D2_VersusRematchStart);

        if (StrEqual(gv_Game, "left4dead2"))
        {
            if (StrEqual(gv_Gamemode, "versus"))
            {
                PrintToServer("[SourceVote] versus detected");
                SafeHookUserMsg("PZEndGamePanelMsg", VersusRematchStart, true, gvf_Hooked_L4D2_VersusRematchStart);
            }
            else if (StrEqual(gv_Gamemode, "mutation15")) {
                PrintToServer("[SourceVote] survival versus detected");
                SafeHook("round_end", RoundEndSurvivalVersus, EventHookMode_Post, gvf_Hooked_L4D2_SurvivalVersusRoundEnd);
            }
            else if (StrEqual(gv_Gamemode, "scavenge")) {
                PrintToServer("[SourceVote] scavenge detected");
                SafeHookUserMsg("PZEndGamePanelMsg", VersusRematchStart, true, gvf_Hooked_L4D2_VersusRematchStart);
            }
            else if (StrEqual(gv_Gamemode, "survival")) {
                PrintToServer("[SourceVote] survival detected");
                SafeHook("round_end", RoundEndSurvival, EventHookMode_Post, gvf_Hooked_L4D2_RoundEndSurvival);
            }
            else if (StrEqual(gv_Gamemode, "coop")) {
                PrintToServer("[SourceVote] coop detected");
                SafeHook("finale_start", RoundEndBasic, EventHookMode_Post, gvf_Hooked_L4D2_FinaleStart);
            }
            else
                PrintToServer("[SourceVote] Unsuported gv_Gamemode: %s", gv_Gamemode);
        }
        else if (StrEqual(gv_Game, "nmrih")) {
            SafeHook("player_death", OnPlayerDeath, EventHookMode_Post, gvf_Hooked_NMRIH_PlayerDeath);
            SafeHook("player_spawn", OnPlayerSpawn, EventHookMode_Post, gvf_Hooked_NMRIH_PlayerSpawn);
            SafeHook("extraction_complete", RoundEndBasic, EventHookMode_Post, gvf_Hooked_NMRIH_ExtractionComplete);
            SafeHook("extraction_expire", RoundEndBasic, EventHookMode_Post, gvf_Hooked_NMRIH_ExtractionExpire);
            SafeHook("token_earned", OnPlayerReceiveToken, EventHookMode_Post, gvf_Hooked_NMRIH_TokenEarned);
            SafeHook("map_complete", FunctionTest, EventHookMode_Post, gvf_Hooked_NMRIH_MapComplete);
            SafeHook("nmrih_round_begin", OnRoundBegin, EventHookMode_Post, gvf_Hooked_NMRIH_RoundBegin);
        }
        else if (IsTF2Game()) {
            gv_TF_VoteTriggered = false;
            SafeHook("tf_map_time_remaining", OnTfMapTimeRemaining, EventHookMode_Post, gvf_Hooked_TF_MapTimeRemaining);
        }
    }
    // #endregion Map Vote

    // #region Protections
    // #endregion Protections
}

void SafeHook(const char[] event, EventHook callback, EventHookMode mode, bool& state)
{
    if (!state)
    {
        HookEventEx(event, callback, mode);
        state = true;
    }
}

void SafeUnhook(const char[] event, EventHook callback, EventHookMode mode, bool& state)
{
    if (state)
    {
        UnhookEvent(event, callback, mode);
        state = false;
    }
}

void SafeHookUserMsg(const char[] msgname, MsgHook callback, bool intercept, bool& state)
{
    if (!state)
    {
        UserMsg msgId = GetUserMessageId(msgname);
        if (msgId != INVALID_MESSAGE_ID)
        {
            HookUserMessage(view_as<UserMsg>(msgId), callback, intercept);
            state = true;
        }
    }
}

void SafeUnhookUserMsg(const char[] msgname, MsgHook callback, bool intercept, bool& state)
{
    if (state)
    {
        UserMsg msgId = GetUserMessageId(msgname);
        if (msgId != INVALID_MESSAGE_ID)
        {
            UnhookUserMessage(view_as<UserMsg>(msgId), callback, intercept);
            state = false;
        }
    }
}

public void OnPluginStart()
{
    g_ShouldDebug = CreateConVar(
        "sourceVoteDebug",
        "0",    // default value
        "Should Debug",
        FCVAR_NONE,
        true,    // has min
        0.0,     // min value
        true,    // has max
        1.0      // max value
    );

    g_VotePath = CreateConVar(
        "sourceVoteVoteFile",
        "addons/sourcemod/configs/source_vote.cfg",    // default value
        "Vote File",
        FCVAR_NONE,
        false,    // has min
        0.0,      // min value
        false,    // has max
        0.0       // max value
    );

    g_BanFilePath = CreateConVar(
        "sourceVoteBanFile",
        "cfg/bans.cfg",    // default value
        "Ban File",
        FCVAR_NONE,
        false,    // has min
        0.0,      // min value
        false,    // has max
        0.0       // max value
    );

    g_ReportFilePath = CreateConVar(
        "sourceVoteReportFile",
        "cfg/reports.cfg",    // default value
        "Report File",
        FCVAR_NONE,
        false,    // has min
        0.0,      // min value
        false,    // has max
        0.0       // max value
    );

    g_SecondsToVote = CreateConVar(
        "sourceVoteSecondsToVote",
        "10",    // default value
        "Seconds To Vote",
        FCVAR_NONE,
        true,    // has min
        0.0,     // min value
        true,    // has max
        999.0    // max value
    );

    g_DisableMapVote = CreateConVar(
        "sourceVoteDisableMapVote",
        "0",    // default value
        "Disable Map Vote",
        FCVAR_NONE,
        true,    // has min
        0.0,     // min value
        true,    // has max
        1.0      // max value
    );

    g_DisableAdminVoteKickProtection = CreateConVar(
        "sourceVoteDisableAdminVoteKickProtection",
        "0",    // default value
        "Disable Admin Vote Kick Protection",
        FCVAR_NONE,
        true,    // has min
        0.0,     // min value
        true,    // has max
        1.0      // max value
    );

    g_DisableBackToLobbyProtection = CreateConVar(
        "sourceVoteDisableBackToLobbyProtection",
        "0",    // default value
        "Disable Back To Lobby Protection",
        FCVAR_NONE,
        true,    // has min
        0.0,     // min value
        true,    // has max
        1.0      // max value
    );

    g_TfExtendMinutes = CreateConVar(
        "sourceVoteTfExtendMinutes",
        "10",    // default value
        "Minutes added to mp_timelimit when TF2 players vote to keep the current map",
        FCVAR_NONE,
        true,     // has min
        0.0,      // min value
        false,    // has max
        0.0       // max value
    );

    g_WarnPluginMessages = CreateConVar(
        "sourceVoteWarnPluginMessages",
        "1",    // default value
        "Warn players with cl_showpluginmessages disabled that they won't see vote messages",
        FCVAR_NONE,
        true,    // has min
        0.0,     // min value
        true,    // has max
        1.0      // max value
    );

    g_DisableGriefingVote = CreateConVar(
        "sourceVoteDisableGriefingVote",
        "0",    // default value
        "Disable the automatic griefing vote when a player kills 2 players in a short time (NMRIH)",
        FCVAR_NONE,
        true,    // has min
        0.0,     // min value
        true,    // has max
        1.0      // max value
    );

    g_GriefingKillWindowSeconds = CreateConVar(
        "sourceVoteGriefingKillWindowSeconds",
        "120",    // default value
        "Time window in seconds to detect 2 kills by the same player and trigger the griefing vote",
        FCVAR_NONE,
        true,     // has min
        1.0,      // min value
        false,    // has max
        0.0       // max value
    );

    g_GriefingVoteSeconds = CreateConVar(
        "sourceVoteGriefingVoteSeconds",
        "20",    // default value
        "Seconds players have to vote if the accused player was griefing",
        FCVAR_NONE,
        true,    // has min
        1.0,     // min value
        true,    // has max
        999.0    // max value
    );

    g_GriefingBanMinutesPerVote = CreateConVar(
        "sourceVoteGriefingBanMinutesPerVote",
        "15",    // default value
        "Ban minutes applied per 'yes' vote when a player is voted as griefing",
        FCVAR_NONE,
        true,     // has min
        1.0,      // min value
        false,    // has max
        0.0       // max value
    );

    g_DisableReportReminder = CreateConVar(
        "sourceVoteDisableReportReminder",
        "0",    // default value
        "Disable the periodic chat reminder about the !report command",
        FCVAR_NONE,
        true,    // has min
        0.0,     // min value
        true,    // has max
        1.0      // max value
    );

    g_ReportReminderMinutes = CreateConVar(
        "sourceVoteReportReminderMinutes",
        "30",    // default value
        "Minutes between chat reminders telling players about the !report command",
        FCVAR_NONE,
        true,     // has min
        1.0,      // min value
        false,    // has max
        0.0       // max value
    );

    AddCommandListener(Vote_Print, "callvote");
    AddCommandListener(Votekick_Protection, "callvote");
    AddCommandListener(Votebacktolobby_Protection, "callvote");

    ReadVariables();
    ReadConfigs();

    RegConsoleCmd("startvote", CommandStartVote, "Start voting system");
    RegConsoleCmd("startban", CommandBan, "Ban someone");
    RegConsoleCmd("startkick", CommandKick, "Kick someone");
    RegConsoleCmd("sourcevotereload", CommandSourceVoteReload, "Reload Cvars and Configs");
    RegConsoleCmd("report", CommandReport, "Report a player");

    PrintToServer("[SourceVote] initialized");
}

public void OnMapStart()
{
    gv_NMRIH_IsPracticing = true;
}

public void OnClientPutInServer(int client)
{
    WarnShowPluginMessagesDisabled(client);
}

void WarnShowPluginMessagesDisabled(int client)
{
    if (!gv_WarnPluginMessages || client == 0 || IsFakeClient(client))
        return;

    QueryClientConVar(client, "cl_showpluginmessages", OnShowPluginMessagesQueried);
}

public void OnShowPluginMessagesQueried(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
    if (result != ConVarQuery_Okay || !IsClientInGame(client))
        return;

    if (StringToInt(cvarValue) == 0)
    {
        PrintToChat(client, "[SourceVote] Your 'cl_showpluginmessages' is disabled, you won't see vote messages in chat. Type 'cl_showpluginmessages 1' in your console to enable them.");
    }
}

public OnServerEnterHibernation()
{
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        gv_NMRIH_IsDeadPlayer[i]      = false;
        gv_NMRIH_KillTimestamps[i][0] = 0.0;
        gv_NMRIH_KillTimestamps[i][1] = 0.0;
    }

    if (gv_VoteTimer != null)
    {
        KillTimer(gv_VoteTimer);
        gv_VoteTimer = null;
    }

    if (gv_GriefingVoteTimer != null)
    {
        KillTimer(gv_GriefingVoteTimer);
        gv_GriefingVoteTimer = null;
    }
    gv_GriefingVoteActive   = false;
    gv_GriefingVoteAccused  = 0;
    gv_GriefingVoteYesCount = 0;

    gv_NMRIH_IsPracticing   = true;
}

public Action Vote_Print(int client, const char[] command, int argc)
{
    char subcommand[64];
    char targetRaw[128];
    GetCmdArg(1, subcommand, sizeof(subcommand));
    GetCmdArg(2, targetRaw, sizeof(targetRaw));

    PrintToServer("[SourceVote] Someone called a callvote, command: %s, subcommand: %s, argc: %d, target: %s", command, subcommand, argc, targetRaw);
    return Plugin_Continue;
}

public Action Votekick_Protection(int client, const char[] command, int argc)
{
    if (gv_DisableAdminVoteKickProtection)
        return Plugin_Continue;

    char subcommand[64];
    char targetRaw[128];
    GetCmdArg(1, subcommand, sizeof(subcommand));
    GetCmdArg(2, targetRaw, sizeof(targetRaw));

    // Vote kick
    if (StrEqual(command, "callvote") && argc == 2 && StrEqual(subcommand, "kick", false))
    {
        int kickedClient = GetClientOfUserId(StringToInt(targetRaw));

        // Kicked player is any admin — block regardless of who is kicking
        if (IsValidClient(kickedClient))
        {
            if (GetUserFlagBits(kickedClient) & ADMFLAG_GENERIC)
            {
                char kickerName[128];
                GetClientName(client, kickerName, sizeof(kickerName));
                PrintToServer("[SourceVote] cancelling %s votekick, because the kicked client is any admin", kickerName);
                char steamId[32];
                GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
                PrintToChat(kickedClient, "[SourceVote] %s is trying to kick you, but you are any admin, show him some respect, their id: %s", kickerName, steamId);
                return Plugin_Stop;
            }
        }

        // Kicker has kick flag — insta kick (target is guaranteed non-admin at this point)
        if (IsValidClient(client))
        {
            if (GetUserFlagBits(client) & ADMFLAG_KICK)
            {
                ServerCommand("kickid %d", StringToInt(targetRaw));
                PrintToChat(client, "[SourceVote] User insta kicked because you have kick flag");
                return Plugin_Stop;
            }
        }
    }

    return Plugin_Continue;
}

public Action Votebacktolobby_Protection(int client, const char[] command, int argc)
{
    if (gv_DisableBackToLobbyProtection)
        return Plugin_Continue;

    char targetRaw[128];
    GetCmdArg(2, targetRaw, sizeof(targetRaw));

    // Back to lobby
    if (StrEqual(command, "callvote") && argc == 1)
    {
        if (!(GetUserFlagBits(client) & ADMFLAG_CHANGEMAP))
        {
            char voteClientName[128];
            GetClientName(client, voteClientName, sizeof(voteClientName));
            PrintToChatAll("[SourceVote] %s back to lobby and restart is not allowed on this server", voteClientName);
            return Plugin_Stop
        }
    }
    // Start new campaign
    else if (StrEqual(command, "callvote") && argc == 2)
    {
        // Start new campaign command
        if (StrContains(targetRaw, "L4D") == 0)
        {
            char voteClientName[128];
            GetClientName(client, voteClientName, sizeof(voteClientName));
            PrintToChatAll("[SourceVote] %s start new campaign is not allowed on this server", voteClientName);
            return Plugin_Stop;
        }
    }
    return Plugin_Continue;
}

//
// #region Commands
//
public Action CommandStartVote(int client, int args)
{
    if (client != 0 && !IsValidClient(client))
        return Plugin_Stop;
    if (client != 0 && !(CheckCommandAccess(client, "sm_startvote", ADMFLAG_CHANGEMAP)))
    {
        PrintToChat(client, "[ERROR] Only admins can use this command.");
        return Plugin_Stop;
    }

    GenerateMapVote();

    InitMapVote();

    PrintToChat(client, "[SourceVote] Vote started");

    return Plugin_Handled;
}

public Action CommandSourceVoteReload(int client, int args)
{
    if (client != 0 && !IsValidClient(client))
        return Plugin_Stop;
    if (client != 0 && !CheckCommandAccess(client, "sm_sourcevotereload", ADMFLAG_BAN))
    {
        PrintToChat(client, "[ERROR] Only admins can use this command.");
        return Plugin_Stop;
    }

    ReadVariables();
    ReadConfigs();

    if (client == 0)
        PrintToServer("[SourceVote] Variables reloaded.");
    else
        PrintToChat(client, "[SourceVote] Variables reloaded.");

    return Plugin_Handled;
}

// #region Ban
public Action CommandBan(int client, int args)
{
    if (client != 0 && !IsValidClient(client)) return Plugin_Stop;
    if (client != 0 && !(CheckCommandAccess(client, "sm_startban", ADMFLAG_BAN)))
    {
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
        PrintToChat(client, "[SourceVote] startban usage: startban <userid> <reason>");
        return Plugin_Stop;
    }

    if (!IsValidClient(bannedClient))
    {
        PrintToChat(client, "[SourceVote] Client is invalid.");
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
        PrintToChat(client, "[SourceVote] No avaible players to ban.");
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
            PrintToChat(client, "[SourceVote] Player not found.");
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

    menu.AddItem("Cheating", "Cheating");
    menu.AddItem("Griefing", "Griefingg");
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
            PrintToChat(client, "[SourceVote] Invalid player.");
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
        PrintToServer("[SourceVote] Failed to open file: %s", gv_BanPath);
        PrintToServer("[SourceVote] FileExists=%d", FileExists(gv_BanPath));
        return;
    }

    WriteFileLine(file, "// Game: %s, Reason: %s, Date: %s", game, reason, date);
    WriteFileLine(file, "banid 0 %s", steamId);
    CloseHandle(file);

    ServerCommand("banid 0 %s kick", steamId);
    KickClient(bannedClient, "You have been permanently banned. Reason: %s", reason);
    PrintToChat(client, "[SourceVote] Player permantly banned. Reason: %s", reason);
}
// #endregion Ban

// #region Kick
public Action CommandKick(int client, int args)
{
    if (client != 0 && !IsValidClient(client)) return Plugin_Stop;
    if (client != 0 && !(CheckCommandAccess(client, "sm_startkick", ADMFLAG_KICK)))
    {
        PrintToChat(client, "[ERROR] Only admins can use this command.");
        return Plugin_Stop;
    }

    // No arguments open the menu
    if (args == 0)
    {
        ShowPlayerSelectMenuKick(client);
        return Plugin_Handled;
    }

    int kickedClient = GetCmdArgInt(1);
    if (kickedClient == 0)
    {
        PrintToChat(client, "[SourceVote] startkick usage: startkick <userid> <reason>");
        return Plugin_Stop;
    }

    if (!IsValidClient(kickedClient))
    {
        PrintToChat(client, "[SourceVote] Client is invalid.");
        return Plugin_Stop;
    }

    char reason[128];
    GetCmdArg(2, reason, sizeof(reason));
    if (StrEqual(reason, ""))
    {
        strcopy(reason, sizeof(reason), "Unknown");
    }

    ExecuteKick(client, kickedClient, reason);
    return Plugin_Handled;
}

void ShowPlayerSelectMenuKick(int client)
{
    Menu menu = new Menu(MenuHandler_PlayerSelectKick);
    menu.SetTitle("Select player to kick:");

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
        PrintToChat(client, "[SourceVote] No avaible players to kick.");
        delete menu;
        return;
    }

    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void MenuHandler_PlayerSelectKick(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char userId[16];
        menu.GetItem(param2, userId, sizeof(userId));

        int kickedClient = GetClientOfUserId(StringToInt(userId));
        if (kickedClient == 0 || !IsValidClient(kickedClient))
        {
            PrintToChat(client, "[SourceVote] Player not found.");
        }

        gv_KickTargetMap[client] = kickedClient;
        ShowReasonMenuKick(client);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

void ShowReasonMenuKick(int client)
{
    Menu menu = new Menu(MenuHandler_ReasonSelectKick);
    menu.SetTitle("Kick Reason:");

    menu.AddItem("Cheating", "Cheating / Hacks");
    menu.AddItem("Griefing", "Griefing / Trolling");
    menu.AddItem("Harassment", "Harassment / Spam");
    menu.AddItem("Exploiting", "Exploiting / Bug Abuse");
    menu.AddItem("Unkown", "Unkown");

    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void MenuHandler_ReasonSelectKick(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char reason[128];
        menu.GetItem(param2, reason, sizeof(reason));

        int kickedClient = gv_KickTargetMap[client];
        if (!IsValidClient(kickedClient))
        {
            PrintToChat(client, "[SourceVote] Invalid player.");
        }

        gv_KickTargetMap[client] = 0;
        ExecuteKick(client, kickedClient, reason);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

void ExecuteKick(int client, int kickedClient, const char[] reason)
{
    KickClient(kickedClient, "You have been kicked. Reason: %s", reason);
    PrintToChat(client, "[SourceVote] Player kicked. Reason: %s", reason);
}
// #endregion Kick

// #region Report
public Action CommandReport(int client, int args)
{
    if (client == 0)
        return Plugin_Stop;
    if (!IsValidClient(client))
        return Plugin_Stop;

    ShowReportPlayerMenu(client);
    return Plugin_Handled;
}

void ShowReportPlayerMenu(int client)
{
    Menu menu = new Menu(MenuHandler_ReportPlayerSelect);
    menu.SetTitle("Select player to report:");

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
        PrintToChat(client, "[SourceVote] No avaible players to report.");
        delete menu;
        return;
    }

    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void MenuHandler_ReportPlayerSelect(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char userId[16];
        menu.GetItem(param2, userId, sizeof(userId));

        int reportedClient = GetClientOfUserId(StringToInt(userId));
        if (reportedClient == 0 || !IsValidClient(reportedClient))
        {
            PrintToChat(client, "[SourceVote] Player not found.");
        }

        gv_ReportTargetMap[client] = reportedClient;
        ShowReportReasonMenu(client);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

void ShowReportReasonMenu(int client)
{
    Menu menu = new Menu(MenuHandler_ReportReasonSelect);
    menu.SetTitle("Report Reason:");

    menu.AddItem("Cheater", "Cheater");
    menu.AddItem("Griefing", "Griefing");
    menu.AddItem("Toxic", "Toxic");

    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void MenuHandler_ReportReasonSelect(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char reason[32];
        menu.GetItem(param2, reason, sizeof(reason));

        int reportedClient = gv_ReportTargetMap[client];
        if (!IsValidClient(reportedClient))
        {
            PrintToChat(client, "[SourceVote] Invalid player.");
        }
        else
        {
            gv_ReportTargetMap[client] = 0;
            ExecuteReport(client, reportedClient, reason);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

void ExecuteReport(int client, int reportedClient, const char[] reason)
{
    char reportingName[MAX_NAME_LENGTH];
    char reportingSteamId[32];
    GetClientName(client, reportingName, sizeof(reportingName));
    GetClientAuthId(client, AuthId_Steam2, reportingSteamId, sizeof(reportingSteamId), true);

    char reportedName[MAX_NAME_LENGTH];
    char reportedSteamId[32];
    GetClientName(reportedClient, reportedName, sizeof(reportedName));
    GetClientAuthId(reportedClient, AuthId_Steam2, reportedSteamId, sizeof(reportedSteamId), true);

    Handle file;
    if (!FileExists(gv_ReportPath))
        file = OpenFile(gv_ReportPath, "w");
    else
        file = OpenFile(gv_ReportPath, "a");

    if (file == INVALID_HANDLE)
    {
        PrintToServer("[SourceVote] Failed to open file: %s", gv_ReportPath);
        PrintToServer("[SourceVote] FileExists=%d", FileExists(gv_ReportPath));
        return;
    }

    WriteFileLine(file, "%s:%s,%s:%s,%s", reportingName, reportingSteamId, reportedName, reportedSteamId, reason);
    CloseHandle(file);

    PrintToChat(client, "[SourceVote] Player reported. Reason: %s", reason);
}

void ExecuteAutoReport(int reportedClient, const char[] reason)
{
    if (!IsValidClient(reportedClient))
        return;

    char reportedName[MAX_NAME_LENGTH];
    char reportedSteamId[32];
    GetClientName(reportedClient, reportedName, sizeof(reportedName));
    GetClientAuthId(reportedClient, AuthId_Steam2, reportedSteamId, sizeof(reportedSteamId), true);

    Handle file;
    if (!FileExists(gv_ReportPath))
        file = OpenFile(gv_ReportPath, "w");
    else
        file = OpenFile(gv_ReportPath, "a");

    if (file == INVALID_HANDLE)
    {
        PrintToServer("[SourceVote] Failed to open file: %s", gv_ReportPath);
        PrintToServer("[SourceVote] FileExists=%d", FileExists(gv_ReportPath));
        return;
    }

    WriteFileLine(file, "SourceVote (Auto):SERVER,%s:%s,%s", reportedName, reportedSteamId, reason);
    CloseHandle(file);
}
// #endregion Report
//
// #endregion Commands
//

//
// #region Events
//
public void RoundEndBasic(Event event, const char[] name, bool dontBroadcast)
{
    GenerateMapVote();

    InitMapVote();
}

// #region Left 4 Dead 2
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

public Action VersusRematchStart(UserMsg msg_id, BfRead hMsg, const int[] players, int playersNum, bool reliable, bool init)
{
    return Plugin_Handled;
}

public void RoundEndSurvivalVersus(Event event, const char[] name, bool dontBroadcast)
{
    int reason = event.GetInt("reason");

    // Restart from hibernation
    if (reason == 8) return;

    // Scenario Restart
    if (reason == 0) return;

    // Chapter ended
    if (reason == 6) return;

    gv_SurvivalVersus_RoundCount++;
    PrintToServer("[SourceVote] SurvivalVersus round ended, count: %d", gv_SurvivalVersus_RoundCount);

    if (gv_SurvivalVersus_RoundCount % 2 == 0)
    {
        PrintToServer("[SourceVote] SurvivalVersus generating map vote");
        GenerateMapVote();
        InitMapVote();
    }
}
// #endregion Left 4 Dead 2

// #region No More Room in Hell
public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int userid   = event.GetInt("userid");
    int client   = GetClientOfUserId(userid);

    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if (IsValidClient(attacker) && attacker != client)
        RegisterNMRIHKill(attacker);

    if (client == 0)
        return;

    if (gv_NMRIH_PlayerTokens[client] > 0)
    {
        gv_NMRIH_PlayerTokens[client] = gv_NMRIH_PlayerTokens[client] - 1;
        return;
    }

    gv_NMRIH_IsDeadPlayer[client] = true;
    if (gv_ShouldDebug)
    {
        char clientName[128];
        GetClientName(client, clientName, sizeof(clientName));
        PrintToServer("[SourceVote-OnPlayerDeath] %s IsDeadPlayer: %b", clientName, gv_NMRIH_IsDeadPlayer[client]);
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
                PrintToServer("[SourceVote-OnPlayerDeath] %s is alive ignoring map vote");
            }
            return;
        }
    }

    if (gv_NMRIH_IsPracticing)
    {
        PrintToServer("[SourceVote-OnPlayerDeath] map vote ignored, is practicing");
        return;
    }

    GenerateMapVote();
    InitMapVote();
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");
    int client = GetClientOfUserId(userid);

    if (client == 0)
        return;

    gv_NMRIH_IsDeadPlayer[client] = false;
}

public void OnPlayerReceiveToken(Event event, const char[] name, bool dontBroadcast)
{
    int client = event.GetInt("player_id");
    if (client > 0)
        gv_NMRIH_PlayerTokens[client] = event.GetInt("tokens");
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
    gv_NMRIH_IsDeadPlayer[client] = true;

    return true;
}

public void OnClientDisconnect(int client)
{
    gv_NMRIH_IsDeadPlayer[client]      = false;
    gv_NMRIH_KillTimestamps[client][0] = 0.0;
    gv_NMRIH_KillTimestamps[client][1] = 0.0;
}

public void OnRoundBegin(Event event, const char[] name, bool dontBroadcast)
{
    gv_NMRIH_IsPracticing = false;
    if (gv_ShouldDebug)
        PrintToServer("[SourceVote-OnRoundBegin] Survival started, map vote enabled");

    for (int i = 0; i < MAXPLAYERS; i++)
    {
        gv_NMRIH_KillTimestamps[i][0] = 0.0;
        gv_NMRIH_KillTimestamps[i][1] = 0.0;
    }
}

public void FunctionTest(Event event, const char[] name, bool dontBroadcast)
{
    PrintToServer("!!!!!!!!!!!!!!!!!!!!!!! TEST map_complete");
}

// #region Griefing Vote
void RegisterNMRIHKill(int attacker)
{
    if (gv_DisableGriefingVote)
        return;

    float now                            = GetGameTime();
    float previousKillTime               = gv_NMRIH_KillTimestamps[attacker][1];

    gv_NMRIH_KillTimestamps[attacker][0] = previousKillTime;
    gv_NMRIH_KillTimestamps[attacker][1] = now;

    // No previous kill registered yet, this is the first one in the window
    if (previousKillTime <= 0.0)
        return;

    float elapsed = now - previousKillTime;
    if (elapsed > gv_GriefingKillWindowSeconds)
        return;

    // Reset window so the same 2 kills don't retrigger the vote repeatedly
    gv_NMRIH_KillTimestamps[attacker][0] = 0.0;
    gv_NMRIH_KillTimestamps[attacker][1] = 0.0;

    if (gv_ShouldDebug)
        PrintToServer("[SourceVote] Client %d killed 2 players within %.1f seconds, triggering griefing vote", attacker, elapsed);

    TriggerGriefingVote(attacker);
}

void TriggerGriefingVote(int accused)
{
    if (!IsValidClient(accused))
        return;

    ExecuteAutoReport(accused, "Auto-detected: killed 2 players in a short time");

    if (gv_GriefingVoteActive)
    {
        if (gv_ShouldDebug)
            PrintToServer("[SourceVote] Griefing Vote already active, ignoring new trigger for client %d", accused);
        return;
    }

    gv_GriefingVoteActive   = true;
    gv_GriefingVoteAccused  = accused;
    gv_GriefingVoteYesCount = 0;

    char accusedName[MAX_NAME_LENGTH];
    GetClientName(accused, accusedName, sizeof(accusedName));
    PrintToChatAll("[SourceVote] %s killed 2 players in a short time, vote if he was griefing!", accusedName);

    ShowGriefingVoteMenu(accused, accusedName);

    gv_GriefingVoteTimer = CreateTimer(float(gv_GriefingVoteSeconds + 1), FinishGriefingVote, 0, TIMER_FLAG_NO_MAPCHANGE);
}

void ShowGriefingVoteMenu(int accused, const char[] accusedName)
{
    char title[192];
    Format(title, sizeof(title), "%s killed 2 players in a short time.\nWas he griefing?", accusedName);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i) || i == accused)
            continue;

        Menu menu = new Menu(MenuHandler_GriefingVote);
        menu.SetTitle(title);

        menu.AddItem("yes", "Yes, he was griefing");
        menu.AddItem("no", "No, it was an accident");

        menu.ExitButton = true;
        menu.Display(i, gv_GriefingVoteSeconds);
    }
}

public int MenuHandler_GriefingVote(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[8];
        menu.GetItem(param2, info, sizeof(info));

        if (gv_GriefingVoteActive && StrEqual(info, "yes"))
        {
            gv_GriefingVoteYesCount++;
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

public Action FinishGriefingVote(Handle timer)
{
    gv_GriefingVoteTimer    = null;

    int accused             = gv_GriefingVoteAccused;
    int yesCount            = gv_GriefingVoteYesCount;

    gv_GriefingVoteActive   = false;
    gv_GriefingVoteAccused  = 0;
    gv_GriefingVoteYesCount = 0;

    if (yesCount <= 0)
    {
        if (gv_ShouldDebug)
            PrintToServer("[SourceVote] Griefing Vote finished with no yes votes.");
        return Plugin_Stop;
    }

    if (!IsValidClient(accused))
    {
        PrintToServer("[SourceVote] Griefing Vote finished but the accused player is no longer connected.");
        return Plugin_Stop;
    }

    int  banMinutes = yesCount * gv_GriefingBanMinutesPerVote;

    char reason[128];
    Format(reason, sizeof(reason), "Griefing vote: %d player(s) voted yes", yesCount);

    BanClient(accused, banMinutes, BANFLAG_AUTO, reason, reason);
    PrintToChatAll("[SourceVote] Player banned for %d minutes. Reason: %s", banMinutes, reason);

    ExecuteAutoReport(accused, reason);

    return Plugin_Stop;
}
// #endregion Griefing Vote
// #endregion No More Room in Hell
//
// #endregion No More Room in Hell
//

// #region Team Fortress 2
public void OnTfMapTimeRemaining(Event event, const char[] name, bool dontBroadcast)
{
    int seconds = event.GetInt("seconds");

    // Time was pushed back (map extended / new map loaded), allow the vote to trigger again
    if (seconds >= 60)
    {
        gv_TF_VoteTriggered = false;
        return;
    }

    if (gv_TF_VoteTriggered)
        return;

    gv_TF_VoteTriggered = true;

    PrintToServer("[SourceVote] TF2 map time remaining: %d, starting vote", seconds);

    GenerateMapVote();
    InitMapVote();
}
// #endregion Team Fortress 2

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
        PrintToServer("[SourceVote] Cleaned votes variables");

    // Map count is lower than MAX_VOTE_MAPS
    // so we add all available maps index to the variable
    if (MAX_VOTE_MAPS >= gv_MapCount)
    {
        for (int i = 0; i < gv_MapCount; i++)
        {
            gv_AvailableMapIndexesVotes[i] = i;

            if (gv_ShouldDebug)
                PrintToServer("[SourceVote] Fixed map added to random: %s", gv_MapNames[gv_AvailableMapIndexesVotes[i]]);
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
                PrintToServer("[SourceVote] New map added to random: %s", gv_MapNames[randomIndex]);

            if (availableMapIndexesVotesCount >= MAX_VOTE_MAPS - 1) break;
        }
    }

    if (gv_ShouldDebug)
        PrintToServer("[SourceVote] Maps randomized");
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

        WarnShowPluginMessagesDisabled(client);

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
                    if ((StrEqual(gv_Gamemode, "mutation15") || StrEqual(gv_Gamemode, "scavenge") || StrEqual(gv_Gamemode, "survival") || StrEqual(gv_Gamemode, "versus")) && gv_MapCount >= MAX_VOTE_MAPS)
                    {
                        if (gv_ShouldDebug)
                            PrintToServer("[SourceVote] Survival detected, trying to create rematch...");

                        char mapCode[64];
                        GetCurrentMap(mapCode, sizeof(mapCode));

                        // Get current map index
                        int mapIndex = -1;
                        for (int x = 0; x < gv_MapCount; x++)
                        {
                            if (gv_ShouldDebug)
                                PrintToServer("[SourceVote] STRINGS DIFFERENCE: %s, %s", gv_MapCodes[x], mapCode);
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

                            if (StrEqual(gv_Gamemode, "mutation15") || StrEqual(gv_Gamemode, "scavenge") || StrEqual(gv_Gamemode, "versus"))
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
                                PrintToServer("[SourceVote] Rematch created for client: %d, map: %s", client, gv_MapNames[mapIndex]);
                            continue;
                        }
                        else {
                            if (gv_ShouldDebug)
                                PrintToServer("[SourceVote] FAILED TO CREATE REMATCH FOR: %d", client);
                        }
                    }
                }
                else if (StrEqual("nmrih", gv_Game) || IsTF2Game()) {
                    if (gv_ShouldDebug)
                        PrintToServer("[SourceVote] trying to create rematch...");

                    char mapCode[64];
                    GetCurrentMap(mapCode, sizeof(mapCode));

                    // Get current map index
                    int mapIndex = -1;
                    for (int x = 0; x < gv_MapCount; x++)
                    {
                        if (gv_ShouldDebug)
                            PrintToServer("[SourceVote] STRINGS DIFFERENCE: %s, %s", gv_MapCodes[x], mapCode);
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
                            PrintToServer("[SourceVote] Rematch created for client: %d, map: %s", client, gv_MapNames[mapIndex]);
                        continue;
                    }
                    else {
                        if (gv_ShouldDebug)
                            PrintToServer("[SourceVote] FAILED TO CREATE REMATCH FOR: %d", client);
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

        PrintToServer("[SourceVote] Menu generated for: %d", client);
    }

    gv_VoteTimer = CreateTimer(float(gv_SecondsToVote + 1), VoteFinish, 0, TIMER_FLAG_NO_MAPCHANGE);
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
        PrintToServer("[SourceVote] %d voted to: %s", client, gv_MapCodes[mapIndex]);
    }
    return 0;
}

public Action VoteFinish(Handle timer)
{
    gv_VoteTimer    = null;

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
        PrintToServer("[SourceVote] No votes registered.");

        // Left 4 Dead 2 Handling
        if (StrEqual("left4dead2", gv_Game))
        {
            if (StrEqual(gv_Gamemode, "mutation15") || StrEqual(gv_Gamemode, "scavenge") || StrEqual(gv_Gamemode, "survival"))
            {
                // If is survival mode choose the rematch option
                winnerIndex = 0
            }
            else {
                // Choose a random index from the selected maps for voting
                winnerIndex = GetRandomInt(0, MAX_VOTE_MAPS - 1);
            }
        }
        else if (StrEqual("nmrih", gv_Game) || IsTF2Game())
        {
            winnerIndex = 0;
        }
        else {
            // Choose a random index from the selected maps for voting
            winnerIndex = GetRandomInt(0, MAX_VOTE_MAPS - 1);
        }

        PrintToServer("[SourceVote] Random map selected: %d", winnerIndex);
    }
    else {
        PrintToServer("[SourceVote] Player map selected: %d", winnerIndex);
    }

    int mapIndex = gv_AvailableMapIndexesVotes[winnerIndex];

    PrintToServer("[SourceVote] Next Map Index: %d", mapIndex);

    strcopy(gv_VotedMapCode, sizeof(gv_VotedMapCode), gv_MapCodes[mapIndex]);

    PrintToServer("[SourceVote] Next Map Code: %s", gv_VotedMapCode);

    PrintToChatAll("Most voted map: %s with %d votes.", gv_MapNames[mapIndex], maxVotes);

    if (StrEqual(gv_Gamemode, "survival") || StrEqual(gv_Gamemode, "mutation15") || StrEqual(gv_Gamemode, "scavenge") || StrEqual(gv_Game, "nmrih"))
    {
        char currentMap[64];
        GetCurrentMap(currentMap, sizeof(currentMap));

        if (!StrEqual(currentMap, gv_VotedMapCode))
        {
            PrintToServer("[SourceVote] Map code is not the same, %s / %s", currentMap, gv_VotedMapCode);
            if (StrEqual(gv_Gamemode, "scavenge"))
                CreateTimer(2.0, VoteChangeLevelScavengeTimer);
            else
                CreateTimer(2.0, VoteChangeLevelTimer);
        }
        else {
            PrintToServer("[SourceVote] Map code is the same, ignoring...");
        }
    }
    else if (IsTF2Game())
    {
        char currentMap[64];
        GetCurrentMap(currentMap, sizeof(currentMap));

        if (StrEqual(currentMap, gv_VotedMapCode))
        {
            ConVar timelimit = FindConVar("mp_timelimit");
            float  newLimit  = timelimit.FloatValue + gv_TfExtendMinutes;
            timelimit.SetFloat(newLimit);

            PrintToServer("[SourceVote] TF2 map kept, extended mp_timelimit to: %f", newLimit);
            PrintToChatAll("[SourceVote] Map extended by %.0f minutes.", gv_TfExtendMinutes);
        }
        else {
            SetNextMap(gv_VotedMapCode);
            PrintToServer("[SourceVote] TF2 next map set to: %s", gv_VotedMapCode);
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

// Scavenge requires setting mp_gamemode before changelevel, otherwise gascans disappear.
// Plain changelevel without the cvar set bugs scavenge mode.
public Action VoteChangeLevelScavengeTimer(Handle timer)
{
    ServerCommand("sm_cvar mp_gamemode scavenge\n");
    CreateTimer(0.5, VoteChangeLevelTimer);

    return Plugin_Stop;
}

//
// #region Utils
//
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

stock bool IsTF2Game()
{
    return StrEqual(gv_Game, "tf") || StrEqual(gv_Game, "tf2classified");
}
//
// #endregion
//