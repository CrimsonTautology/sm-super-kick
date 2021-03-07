/**
 * vim: set ts=4 :
 * =============================================================================
 * Super kick
 * Kick players really far
 *
 * Copyright 2021 CrimsonTautology
 * =============================================================================
 *
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.10.0"
#define PLUGIN_NAME "[FoF] Super Kick"

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = "CrimsonTautology",
    version = PLUGIN_VERSION,
    description = "Kick people very far",
    url = "https://github.com/CrimsonTautology/sm-super-kick"
};

char g_HitSounds[][] =
{
    "ambient/explosions/explode_1.wav",
    "ambient/explosions/explode_2.wav",
    "ambient/explosions/explode_3.wav",
    "ambient/explosions/explode_4.wav",
    "ambient/explosions/explode_5.wav",
    "ambient/explosions/explode_6.wav",
    "ambient/explosions/explode_7.wav",
    "ambient/explosions/explode_8.wav",
    "ambient/explosions/explode_9.wav",
};

char g_YellSounds[][] =
{
    "player/fallscream1.wav",
    "player/fallscream2.wav",
};

ConVar g_EnabledCvar;
ConVar g_ForceCvar;

public void OnPluginStart()
{
    CreateConVar("sm_super_kick_version", PLUGIN_VERSION, PLUGIN_NAME,
            FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
    g_EnabledCvar = CreateConVar("sm_super_kick", "1",
            "Set to 1 to enable Super Kick");
    g_ForceCvar = CreateConVar("sm_super_kick_force", "800.0",
            "Force applied by a kick");

    for(int i=1; i<=MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
        }
    }

    AutoExecConfig();
}

public void OnMapStart()
{
    for(int i=0; i < sizeof(g_HitSounds); i++)
    {
        PrecacheSound(g_HitSounds[i]);
    }

    for(int i=0; i < sizeof(g_YellSounds); i++)
    {
        PrecacheSound(g_YellSounds[i]);
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

bool IsSuperKickEnabled()
{
    return g_EnabledCvar.BoolValue;
}

float SuperKickPushForce()
{
    return g_ForceCvar.FloatValue;
}

void EmitHitSoundToAll(int entity)
{
    int pitch = GetRandomInt(85, 110);
    int index = GetRandomInt(0, sizeof(g_HitSounds) - 1);

    EmitSoundToAll(
            g_HitSounds[index], entity, SNDCHAN_AUTO, SNDLEVEL_TRAIN,
            SND_CHANGEPITCH, SNDVOL_NORMAL, pitch);

}

void EmitYellSoundToAll(int entity)
{
    int pitch = GetRandomInt(85, 110);
    int index = GetRandomInt(0, sizeof(g_YellSounds) - 1);

    EmitSoundToAll(
            g_YellSounds[index], entity, SNDCHAN_AUTO, SNDLEVEL_SCREAMING,
            SND_CHANGEPITCH, SNDVOL_NORMAL, pitch);
}

Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype,
        int& weapon, float damageForce[3], float damagePosition[3])
{
    if(!IsSuperKickEnabled()) return Plugin_Continue;
    if(!(0 < victim <= MaxClients)) return Plugin_Continue;
    if(!(0 < attacker <= MaxClients)) return Plugin_Continue;
    if(attacker == victim) return Plugin_Continue;

    // hit by a kick
    if(weapon == -1 && damagetype == 268435456)
    {
        PushPlayer(victim, attacker, SuperKickPushForce());

        EmitHitSoundToAll(attacker);
        EmitYellSoundToAll(victim);
    }

    return Plugin_Continue;
}

void PushPlayer(int victim, int attacker, float force)
{
    float push[3], attacker_origin[3], victim_origin[3], victim_velocity[3];

    // get original base velocity of vicitm
    GetEntPropVector(victim, Prop_Data, "m_vecBaseVelocity", victim_velocity);

    // build push vector
    GetClientAbsOrigin(attacker, attacker_origin);
    GetClientAbsOrigin(victim, victim_origin);
    MakeVectorFromPoints(attacker_origin, victim_origin, push);
    NormalizeVector(push, push);
    ScaleVector(push, force);

    AddVectors(push, victim_velocity, victim_velocity);

    // avoid friction
    victim_velocity[2] = 350.0;

    // set new base velocity of victim to send them flying
    SetEntPropVector(victim, Prop_Data, "m_vecBaseVelocity", victim_velocity);
}
