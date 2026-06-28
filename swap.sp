#include <sourcemod>
#include <sdktools>
#include <tf2>

#define TEAM_SPEC 1
#define TEAM_RED  2
#define TEAM_BLU  3

public Plugin myinfo =
{
    name = "MYM Team Swap Bypass",
    author = "FrostyCirno & Google Gemini",
    description = "Allows players to type !swap to open a team selection menu.",
    version = "1.1",
    url = ""
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_swap", Command_Swap, "Opens the team swap menu.");
}

public Action Command_Swap(int client, int args)
{
    if (client == 0 || !IsClientInGame(client))
    {
        return Plugin_Handled;
    }

    Menu menu = new Menu(Menu_TeamHandler);
    menu.SetTitle("Select a Team:");

    menu.AddItem("2", "RED Team");
    menu.AddItem("3", "BLU Team");
    menu.AddItem("1", "Spectator");

    menu.ExitButton = true;
    menu.Display(client, 20);

    return Plugin_Handled;
}

public int Menu_TeamHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));

        int targetTeam = StringToInt(info);
        int currentTeam = GetClientTeam(param1);

        if (currentTeam == targetTeam)
        {
            PrintToChat(param1, "[SM] You are already on that team!");
            return 0;
        }

        if (targetTeam == TEAM_RED || targetTeam == TEAM_BLU)
        {
            int redCount = 0;
            int bluCount = 0;

            for (int i = 1; i <= MaxClients; i++)
            {
                if (IsClientInGame(i))
                {
                    int team = GetClientTeam(i);
                    if (team == TEAM_RED) redCount++;
                    else if (team == TEAM_BLU) bluCount++;
                }
            }

            if (currentTeam == TEAM_RED) redCount--;
            if (currentTeam == TEAM_BLU) bluCount--;

            ConVar cvarLimit = FindConVar("mp_teams_unbalance_limit");
            int unbalanceLimit = (cvarLimit != null) ? cvarLimit.IntValue : 0;

            if (unbalanceLimit > 0)
            {
                if (targetTeam == TEAM_RED && (redCount - bluCount) >= unbalanceLimit)
                {
                    PrintToChat(param1, "[SM] RED team has reached the unbalance limit!");
                    return 0;
                }
                if (targetTeam == TEAM_BLU && (bluCount - redCount) >= unbalanceLimit)
                {
                    PrintToChat(param1, "[SM] BLU team has reached the unbalance limit!");
                    return 0;
                }
            }
        }

        if (IsPlayerAlive(param1) && targetTeam != TEAM_SPEC)
        {
            ForcePlayerSuicide(param1);
        }

        ChangeClientTeam(param1, targetTeam);
        PrintToChat(param1, "[SM] Swapping teams...");
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}
