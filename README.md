# Left 4 Vote
Creates campaign vote system when versus ended

## Requirements
- Sourcemod and metamod

## Usage
1. Download the plugin from the latest release:
[Releases Section](https://github.com/LeandroTheDev/left_4_vote/releases)

2. Place the compiled .smx file into the following folder on your server: addons/sourcemod/plugins/

3. Map configuration can be found on addons/sourcemod/configs/left_4_vote.cfg, (After first run)

4. Add to server.cfg: ``sm_cvar sv_pz_endgame_vote_post_period 30``

5. Run the server

## Compiling

- Use the compiler from sourcemod to compile the left_4_vote.sp

## CONFIGURATIONS EXAMPLE
``Versus``
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
``Survival Versus``
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
