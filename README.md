# Source Vote

- ``sourcevotereload`` reload cvars and configurations only admins with the flag "g"

## Map Vote
Creates map vote system when coop/versus/survival/survivalversus ends

- ``startvote`` start voting system only admins with the flag "g"
- ``sm_cvar sourceVoteVoteFile "addons/sourcemod/configs/source_vote.cfg"`` change the vote file.
- ``sm_cvar sourceVoteSecondsToVote 10`` change the seconds to vote for a map.

To disable exec ``sm_cvar sourceVoteDisableMapVote 1``

### How it works
- After the end of the round the server will ask for a map vote, the maps to vote is randomly selected between the map list.
- Most voted map of course will be selected.
- For left 4 dead 2, if no maps are voted in survival will remain on the same map, otherwises a random will be selected
- No more room in hell, if no maps are voted will remain on the same map

## Vote Kick Protection
Protects admins from being vote kicked, also when admin call a kick vote insta kicks the player without vote

To disable exec ``sm_cvar sourceVoteDisableAdminVoteKickProtection 1``

### How it works
- The plugin listen for the call vote and check the caller and the kicker privileges

## Vote Back To Lobby Protection
Remove the back to lobby call vote, and show a message to the player saying this feature is disabled on the server, if the client has the flag ADMFLAG_CHANGEMAP ("g") he can use the vote to lobby

To disable exec ``sm_cvar sourceVoteDisableBackToLobbyProtection 1``

### How it works
- The plugin listen for the call vote and stop before working

## Ban
``!startban <userid> <"Cheating in versus mode">`` command to ban players with given userid, the ban will automatically go to the ``sm_cvar sourceVoteBanFile "cfg/bans.cfg"`` includes the comment saying the reason, game and ban date, a menu is also available by using only ``!startban``

The command requires the admin flag: "d"

To view userid you can use the command ``status`` in game console

### How it works
- Plugin execute the command ``banid 0 "steamid..." kick`` to ban the player, and also include that command in ``sm_cvar sourceVoteBanFile "cfg/bans.cfg"``, but you will need to exec the cfg on ``server.cfg`` -> ``exec bans.cfg``

## CVARS
- sourceVoteDebug
- > Enable debug logging
- sourceVoteVoteFile
- > Vote file path
- sourceVoteBanFile
- > Ban file path
- sourceVoteSecondsToVote
- > Seconds to vote for a map
- sourceVoteDisableMapVote
- > Disable map vote system
- sourceVoteDisableAdminVoteKickProtection
- > Disable admin vote kick protection
- sourceVoteDisableBackToLobbyProtection
- > Disable back to lobby and restart campaign protection

## Requirements
- Sourcemod and metamod

## Usage
1. Download the plugin from the latest release:
[Releases Section](https://github.com/LeandroTheDev/source_vote/releases)

2. Place the compiled .smx file into the following folder on your server: addons/sourcemod/plugins/

3. Map configuration can be found on addons/sourcemod/configs/source_vote.cfg, (After first run)

4. (Left 4 Dead 2 Survival Servers) Add to server.cfg: ``sm_cvar sv_pz_endgame_vote_post_period 30``, for survival versus and versus vote system work propertly

5. Run the server

## Compiling

- Use the compiler from sourcemod to compile the source_vote.sp

## CONFIGURATIONS EXAMPLE
``Versus or Coop``
```ini
"Left4Rank"
{
    "mapCount"       "14"

    "mapCodes"
    {
        "0"  "c1m1_hotel"
        "1"  "c2m1_highway"
        "2"  "c3m1_plankcountry"
        "3"  "c4m1_milltown_a"
        "4"  "c5m1_waterfront"
        "5"  "c6m1_riverbank"
        "6"  "c7m1_docks"
        "7"  "c8m1_apartment"
        "8"  "c9m1_alleys"
        "9"  "c10m1_caves"
        "10" "c11m1_greenhouse"
        "11" "c12m1_hilltop"
        "12" "c13m1_alpinecreek"
        "13" "c14m1_junkyard"
    }

    "mapNames"
    {
        "0"  "Dead Center"
        "1"  "Dark Carnival"
        "2"  "Swamp Fever"
        "3"  "Hard Rain"
        "4"  "The Parish"
        "5"  "The Passing"
        "6"  "The Sacrifice"
        "7"  "No Mercy"
        "8"  "Crash Course"
        "9"  "Death Toll"
        "10" "Dead Air"
        "11" "Blood Harvest"
        "12" "Cold Stream"
        "13" "The Last Stand"
    }

}
```
``Survival``
```ini
"Left4Rank"
{
    "mapCount"       "40"

    "mapCodes"
    {
        "0"  "c1m2_streets"
        "1"  "c1m4_atrium"
        "2"  "c2m1_highway"
        "3"  "c2m4_barns"
        "4"  "c2m5_concert"
        "5"  "c3m1_plankcountry"
        "6"  "c3m3_shantytown"
        "7"  "c3m4_plantation"
        "8"  "c4m1_milltown_a"
        "9"  "c4m2_sugarmill_a"
        "10" "c4m3_sugarmill_b"
        "11" "c5m1_waterfront"
        "12" "c5m2_park"
        "13" "c5m3_cemetery"
        "14" "c5m4_quarter"
        "15" "c5m5_bridge"
        "16" "c6m1_riverbank"
        "17" "c6m2_bedlam"
        "18" "c6m3_port"
        "19" "c7m1_docks"
        "20" "c7m3_port"
        "21" "c8m2_subway"
        "22" "c8m3_sewers"
        "23" "c8m4_interior"
        "24" "c8m5_rooftop"
        "25" "c9m1_alleys"
        "26" "c9m2_lots"
        "27" "c10m2_drainage"
        "28" "c10m3_ranchhouse"
        "29" "c10m4_mainstreet"
        "30" "c10m5_houseboat"
        "31" "c11m2_offices"
        "32" "c11m3_garage"
        "33" "c11m4_terminal"
        "34" "c11m5_runway"
        "35" "c12m2_traintunnel"
        "36" "c12m3_bridge"
        "37" "c12m5_cornfield"
        "38" "c13m3_memorialbridge"
        "39" "c13m4_cutthroatcreek"
    }

    "mapNames"
    {
        "0"  "Dead Center - Gun Shop"
        "1"  "Dead Center - Mall Atrium"
        "2"  "Dark Carnival - Motel"
        "3"  "Dark Carnival - Stadium Gate"
        "4"  "Dark Carnival - Concert"
        "5"  "Swamp Fever - Gator Village"
        "6"  "Swamp Fever - Shanty Town"
        "7"  "Swamp Fever - Plantation"
        "8"  "Hard Rain - Burger Tank"
        "9"  "Hard Rain - Sugar Mill"
        "10" "Hard Rain - Cane Field"
        "11" "The Parish - Water Front"
        "12" "The Parish - Park"
        "13" "The Parish - Cemetery"
        "14" "The Parish - Float"
        "15" "The Parish - Bridge"
        "16" "The Passing - Riverbank"
        "17" "The Passing - Underground"
        "18" "The Passing - Port"
        "19" "The Sacrifice - Traincar"
        "20" "The Sacrifice - Port Finale"
        "21" "No Mercy - The Generator Room"
        "22" "No Mercy - The Gas Station"
        "23" "No Mercy - The Hospital"
        "24" "No Mercy - The Rooftop"
        "25" "Crash Course - The Alleys"
        "26" "Crash Course - The Truck Depot"
        "27" "Death Toll - The Floodgate"
        "28" "Death Toll - The Church"
        "29" "Death Toll - The Street"
        "30" "Death Toll - The Boat House"
        "31" "Dead Air - The Crane"
        "32" "Dead Air - The Construction Site"
        "33" "Dead Air - The Terminal"
        "34" "Dead Air - The Runway"
        "35" "Blood Harvest - The Warehouse"
        "36" "Blood Harvest - The Bridge"
        "37" "Blood Harvest - The Farmhouse"
        "38" "Cold Stream - Junkyard"
        "39" "Cold Stream - Waterworks"
    }

}
```

``No more room in hell``
```ini
"SourceVote"
{
    "gv_MapCount"       "34"

    "gv_MapCodes"
    {
        "0"  "nmo_anxiety"
        "1"  "nmo_asylum"
        "2"  "nmo_boardwalk"
        "3"  "nmo_broadway"
        "4"  "nmo_broadway2"
        "5"  "nmo_brooklyn"
        "6"  "nmo_cabin"
        "7"  "nmo_chinatown"
        "8"  "nmo_cleopas"
        "9"  "nmo_fema"
        "10"  "nmo_junction"
        "11"  "nmo_lakeside"
        "12"  "nmo_quarantine"
        "13"  "nmo_rockpit"
        "14"  "nmo_shelter"
        "15"  "nmo_shoreline"
        "16"  "nmo_suzhou"
        "17"  "nmo_toxteth"
        "18"  "nmo_toxtethdark"
        "19"  "nmo_underground"
        "20"  "nmo_zephyr"
        "21"  "nms_arpley"
        "22"  "nms_camilla"
        "23"  "nms_campblood"
        "24"  "nms_drugstore"
        "25"  "nms_favela"
        "26"  "nms_flooded"
        "27"  "nms_isolated"
        "28"  "nms_laundry"
        "29"  "nms_midwest"
        "30"  "nms_northway"
        "31"  "nms_notid"
        "32"  "nms_ransack"
        "33"  "nms_silence"
    }

    "gv_MapNames"
    {
        "0"  "Anxiety"
        "1"  "Asylum"
        "2"  "Boardwalk"
        "3"  "Broadway"
        "4"  "Broadway 2"
        "5"  "Brooklyn"
        "6"  "Cabin"
        "7"  "Chinatown"
        "8"  "Cleopas"
        "9"  "Fema"
        "10"  "Junction"
        "11"  "Lakeside"
        "12"  "Quarantine"
        "13"  "Rockpit"
        "14"  "Shelter"
        "15"  "Shoreline"
        "16"  "Suzhou"
        "17"  "Toxteth"
        "18"  "Toxteth Dark"
        "19"  "Underground"
        "20"  "Zephyr"
        "21"  "Arpley"
        "22"  "Camilla"
        "23"  "Camp Blood"
        "24"  "Drugs Store"
        "25"  "Favela"
        "26"  "Flooded"
        "27"  "Isolated"
        "28"  "Laundry"
        "29"  "Midwest"
        "30"  "North Way"
        "31"  "Not Id"
        "32"  "Ransack"
        "33"  "Silence"
    }

}
```