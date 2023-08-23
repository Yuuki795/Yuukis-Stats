#include <sourcemod>
#include <morecolors>
#include <tf2>
#include <tf2_stocks>

Database DB;

public Plugin info =
{
	name = "Yuuki's Stats",
	author = "Yuuki",
	description = "A way to track player stats",
	version = "2.0",
	url = "N/A"
};

public void OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath);
    Database.Connect(GotDatabase, "yuukistats");
}

public void OnPluginEnd()
{
    DB = null
}

public void OnClientPostAdminCheck(int client)
{
    char auth[32];
    GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
    if(!StrEqual(auth, "BOT"))
    {
        char query[255];
        FormatEx(query, sizeof(query), "SELECT EXISTS(SELECT * FROM sb_stats WHERE steamID = '%s');", auth);

        
        DB.Query(DoesUserExist, query, client);
    }   
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int attackerId = event.GetInt("attacker");
    int attacker = GetClientOfUserId(attackerId);

    int victimId = event.GetInt("userid");
    int victim = GetClientOfUserId(victimId);

    int assistId = event.GetInt("assister");
    int assister = GetClientOfUserId(assistId);

    char attackerSID[24];
    char victimSID[24];
    char assisterSID[24];

    char attackerName[128];
    char victimName[128];
    char assisterName[128];
    if(attacker != 0)
    {
        GetClientAuthId(attacker, AuthId_Steam2, attackerSID, sizeof(attackerSID));
    }
    GetClientAuthId(victim, AuthId_Steam2, victimSID, sizeof(victimSID));
    if(assister != 0)
    {
        GetClientAuthId(assister, AuthId_Steam2, assisterSID, sizeof(assisterSID));
        
    }
    

    GetClientName(attacker, attackerName, sizeof(attackerName));
    GetClientName(victim, victimName, sizeof(victimName));

    if(assister != 0)
    {
        GetClientName(assister, assisterName, sizeof(assisterName));
        //PrintToChatAll("%s", assisterName)
    }

    if(StrEqual(attackerSID, victimSID) || attacker == 0)
    {
        char query[255];

        FormatEx(query, sizeof(query), "SELECT points, deaths FROM sb_stats WHERE steamID = '%s'", victimSID);
        DB.Query(OnSuicide, query, victim);
    }
    else
    {
        //TODO: Dead ringer checks i cant figure it out yet
        /*if(GetPlayerWeaponSlot(victim, 4) == 573 || GetPlayerWeaponSlot(victim, 4) == 595 || GetPlayerWeaponSlot(victim, 4) == 278)
        {
            char query[255];
            FormatEx(query, sizeof(query), "SELECT points FROM sb_stats WHERE steamID = '%s'", attackerSID);
            DB.Query(OnFeignKill, query, attacker);
        }*/
        //else
        //{
            char query[255];
            FormatEx(query, sizeof(query), "SELECT points, kills FROM sb_stats WHERE steamID = '%s'", attackerSID);
            DB.Query(OnKill, query, attacker);

            if(assister != 0)
            {
                char query2[255];
                FormatEx(query2, sizeof(query2), "SELECT points, assists FROM sb_stats WHERE steamID = '%s'", assisterSID);
                DB.Query(OnKillAssist, query, assister);
            }
            char query3[255];
            FormatEx(query3, sizeof(query3), "SELECT points, deaths FROM sb_stats WHERE steamID = '%s'", victimSID);
            DB.Query(OnDeath, query3, victim);
        //}
    }

}

public void GotDatabase(Database db, const char[] error, any data)
{
    if (db == null)
    {
        LogError("[YS] Cannot Connect to MySQL Server: %s", error);
    } 
    else 
    {
        DB = db;
        PrintToServer("[YS] Connected to DB successfuly!");
    }
}

// Query Functions

public void UpdateUser(Database db, DBResultSet results, const char[] error, any data)
{
    //LogError("Query failed! %s", error);
    if (db == null || results == null || error[0] != '\0')
    {
        LogError("Query failed! %s", error);
    }

    /* Make sure the client didn't disconnect while the thread was running */
    if (data == 0)
    {
        return;
    }
}

public void OnSuicide(Database db, DBResultSet results, const char[] error, any data)
{
    if (db == null || results == null || error[0] != '\0')
    {
        LogError("Query failed! %s", error);
    }

    /* Make sure the client didn't disconnect while the thread was running */
    if (data == 0)
    {
        return;
    }
    if(results.FetchRow())
    {
        int points;
        int deaths;
        char pointsString[128];
        char authId[32];
        char query[150];

        GetClientAuthId(data, AuthId_Steam2, authId, sizeof(authId));

        points = results.FetchInt(0);
        deaths = results.FetchInt(1);

        IntToString(points - 5, pointsString, sizeof(pointsString))

        FormatEx(query, sizeof(query), "UPDATE `sb_stats` SET `points`='%d',`deaths`='%d' WHERE steamID = '%s'", points - 5, deaths + 1, authId);
        DB.Query(UpdateUser, query, data);
        CPrintToChat(data, "{green}[YS]{white} You lost {red}5 (%s){white} points for killing yourself!", pointsString)
   }
}

public void DoesUserExist(Database db, DBResultSet results, const char[] error, any data)
{
    if (db == null || results == null || error[0] != '\0')
    {
        LogError("Query failed! %s", error);
    }

    //PrintToServer("test");
    if(results.FetchRow())
    {
        char userexists[32];
        results.FetchString(0, userexists, sizeof(userexists))
        if(!StrEqual(userexists, "1"))
        {
            new String:authId[32];
            char query[255];

            GetClientAuthId(data, AuthId_Steam2, authId, sizeof(authId))

            FormatEx(query, sizeof(query), "INSERT INTO sb_stats VALUES ('%s', 0, 0, 0, 0)", authId);

            DB.Query(UpdateUser, query, data);

            PrintToServer("[YS] User Added.");
        }
        else
        {
            PrintToServer("[YS] User Already Exists.");
        }
    }
    
}

public void OnKill(Database db, DBResultSet results, const char[] error, any data)
{
    if (db == null || results == null || error[0] != '\0')
    {
        LogError("Query failed! %s", error);
    }

    /* Make sure the client didn't disconnect while the thread was running */
    if (data == 0)
    {
        return;
    }
    else
    {
        if(results.FetchRow())
        {
            int points;
            int kills;
            char pointsString[32];
            char attackerSID[24];

            points = results.FetchInt(0);
            kills = results.FetchInt(1);

            GetClientAuthId(data, AuthId_Steam2, attackerSID, sizeof(attackerSID));
            IntToString(points + 5, pointsString, sizeof(pointsString));

            char query[255];
            FormatEx(query, sizeof(query), "UPDATE `sb_stats` SET `points`='%d',`kills`='%d' WHERE steamID = '%s'", points + 5, kills + 1, attackerSID);
            DB.Query(UpdateUser, query, data);

            CPrintToChat(data, "{green}[YS]{white} You have gained {green}5 (%s){white} points for killing a player!", pointsString)
        }
    }
}

public void OnFeignKill(Database db, DBResultSet results, const char[] error, any data)
{
    if (db == null || results == null || error[0] != '\0')
    {
        LogError("Query failed! %s", error);
    }

    /* Make sure the client didn't disconnect while the thread was running */
    if (data == 0)
    {
        return;
    }
    else
    {
        if(results.FetchRow())
        {
            int points;
            char pointsString[32];

            points = results.FetchInt(0);
            IntToString(points + 5, pointsString, sizeof(pointsString));

            CPrintToChat(data, "{green}[YS]{white} You have gained {green}5 (%s){white} points for killing a player!", pointsString)
        }
    }
}

public void OnDeath(Database db, DBResultSet results, const char[] error, any data)
{  
    if (db == null || results == null || error[0] != '\0')
    {
        LogError("Query failed! %s", error);
    }

    /* Make sure the client didn't disconnect while the thread was running */
    if (data == 0)
    {
        return;
    }
    else
    {
        if(results.FetchRow())
        {
            int points;
            int deaths;
            char pointsString[32];
            char victimSID[24];

            points = results.FetchInt(0);
            deaths = results.FetchInt(1);

            GetClientAuthId(data, AuthId_Steam2, victimSID, sizeof(victimSID));
            IntToString(points - 5, pointsString, sizeof(pointsString));

            char query[255];
            FormatEx(query, sizeof(query), "UPDATE `sb_stats` SET `points`='%d',`deaths`='%d' WHERE steamID = '%s'", points - 5, deaths + 1, victimSID);
            DB.Query(UpdateUser, query, data);

            CPrintToChat(data, "{green}[YS]{white} You lost {red}5 (%s){white} points from dying to a player!", pointsString)
        }
    }
}

public void OnKillAssist(Database db, DBResultSet results, const char[] error, any data)
{
    //LogError("Query failed! %s", error);
    if (db == null || results == null || error[0] != '\0')
    {
        LogError("Query failed! %s", error);
    }

    /* Make sure the client didn't disconnect while the thread was running */
    if (data == 0)
    {
        PrintToChatAll("test")
        return;
    }
    else
    {
        if(results.FetchRow())
        {
            int points;
            int assists;
            char pointsString[32];
            char assisterSID[24];

            points = results.FetchInt(0);
            assists = results.FetchInt(1);

            GetClientAuthId(data, AuthId_Steam2, assisterSID, sizeof(assisterSID));
            IntToString(points + 3, pointsString, sizeof(pointsString));

            char query[255];
            FormatEx(query, sizeof(query), "UPDATE `sb_stats` SET `points`='%s',`assists`='%s' WHERE steamID = '%s'", points + 3, assists + 1, assisterSID);
            DB.Query(UpdateUser, query, data);

            CPrintToChat(data, "{green}[YS]{white} You have gained {green}3 (%s){white} points for assisting in killing a player!", pointsString)
        }
    }
}

public void OnSentryKill(Database db, DBResultSet results, const char[] error, any data)
{
    if (db == null || results == null || error[0] != '\0')
    {
        LogError("Query failed! %s", error);
    }

    /* Make sure the client didn't disconnect while the thread was running */
    if (data == 0)
    {
        return;
    }
    else
    {
        if(results.FetchRow())
        {
            int points;
            int kills;
            char pointsString[32];
            char attackerSID[24];

            points = results.FetchInt(0);
            kills = results.FetchInt(1);

            GetClientAuthId(data, AuthId_Steam2, attackerSID, sizeof(attackerSID));
            IntToString(points + 5, pointsString, sizeof(pointsString));

            char query[255];
            FormatEx(query, sizeof(query), "UPDATE `sb_stats` SET `points`='%d',`kills`='%d' WHERE steamID = '%s'", points + 5, kills + 1, attackerSID);
            DB.Query(UpdateUser, query, data);

            CPrintToChat(data, "{green}[YS]{white} You have gained {green}5 (%s){white} points for killing a player!", pointsString)
        }
    }
}

public void OnSentryDeath(Database db, DBResultSet results, const char[] error, any data)
{  
    if (db == null || results == null || error[0] != '\0')
    {
        LogError("Query failed! %s", error);
    }

    /* Make sure the client didn't disconnect while the thread was running */
    if (data == 0)
    {
        return;
    }
    else
    {
        if(results.FetchRow())
        {
            int points;
            int deaths;
            char pointsString[32];
            char victimSID[24];

            points = results.FetchInt(0);
            deaths = results.FetchInt(1);

            GetClientAuthId(data, AuthId_Steam2, victimSID, sizeof(victimSID));
            IntToString(points - 5, pointsString, sizeof(pointsString));

            char query[255];
            FormatEx(query, sizeof(query), "UPDATE `sb_stats` SET `points`='%d',`deaths`='%d' WHERE steamID = '%s'", points - 5, deaths + 1, victimSID);
            DB.Query(UpdateUser, query, data);

            CPrintToChat(data, "{green}[YS]{white} You lost {red}5 (%s){white} points from dying to a player!", pointsString)
        }
    }
}
