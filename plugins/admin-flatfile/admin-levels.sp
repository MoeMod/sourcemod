/* 
 * admin-levels.sp
 * Reads access flags from the admin_levels.cfg file.  Do not compile this directly.
 * This file is part of SourceMod, Copyright (C) 2004-2007 AlliedModders LLC
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * Version: $Id$
 */

#define LEVEL_STATE_NONE		0
#define LEVEL_STATE_LEVELS		1
#define LEVEL_STATE_FLAGS		2

static Handle:g_hLevelParser = INVALID_HANDLE;
static g_LevelState = LEVEL_STATE_NONE;

/* :TODO: log line numbers? */

LoadDefaultLetters()
{
	for (new i='t'; i<'z'; i++)
	{
		g_FlagsSet[i-'a'] = false;
	}
	
	g_FlagLetters['a'-'a'] = Admin_Reservation;
	g_FlagLetters['b'-'a'] = Admin_Generic;
	g_FlagLetters['c'-'a'] = Admin_Kick;
	g_FlagLetters['d'-'a'] = Admin_Ban;
	g_FlagLetters['e'-'a'] = Admin_Unban;
	g_FlagLetters['f'-'a'] = Admin_Slay;
	g_FlagLetters['g'-'a'] = Admin_Changemap;
	g_FlagLetters['h'-'a'] = Admin_Convars;
	g_FlagLetters['i'-'a'] = Admin_Config;
	g_FlagLetters['j'-'a'] = Admin_Chat;
	g_FlagLetters['k'-'a'] = Admin_Vote;
	g_FlagLetters['l'-'a'] = Admin_Password;
	g_FlagLetters['m'-'a'] = Admin_RCON;
	g_FlagLetters['n'-'a'] = Admin_Cheats;
	g_FlagLetters['o'-'a'] = Admin_Custom1;
	g_FlagLetters['p'-'a'] = Admin_Custom2;
	g_FlagLetters['q'-'a'] = Admin_Custom3;
	g_FlagLetters['r'-'a'] = Admin_Custom4;
	g_FlagLetters['s'-'a'] = Admin_Custom5;
	g_FlagLetters['t'-'a'] = Admin_Custom6;
	g_FlagLetters['z'-'a'] = Admin_Root;
}

public SMCResult:ReadLevels_NewSection(Handle:smc, const String:name[], bool:opt_quotes)
{
	if (g_IgnoreLevel)
	{
		g_IgnoreLevel++;
		return SMCParse_Continue;
	}
	
	if (g_LevelState == LEVEL_STATE_NONE)
	{
		if (StrEqual(name, "Levels"))
		{
			g_LevelState = LEVEL_STATE_LEVELS;
		} else {
			g_IgnoreLevel++;
		}
	} else if (g_LevelState == LEVEL_STATE_LEVELS) {
		if (StrEqual(name, "Flags"))
		{
			g_LevelState = LEVEL_STATE_FLAGS;
		} else {
			g_IgnoreLevel++;
		}
	} else {
		g_IgnoreLevel++;
	}
	
	return SMCParse_Continue;
}

public SMCResult:ReadLevels_KeyValue(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	if (g_LevelState == LEVEL_STATE_FLAGS && !g_IgnoreLevel)
	{
		new chr = value[0];
		
		if (chr < 'a' || chr > 'z')
		{
			ParseError("Unrecognized character: \"%s\"", value);
			return SMCParse_Continue;
		}
		
		chr -= 'a';
		
		new AdminFlag:flag;
		
		if (StrEqual(key, "reservation"))
		{
			flag = Admin_Reservation;
		} else if (StrEqual(key, "kick")) {
			flag = Admin_Kick;
		} else if (StrEqual(key, "generic")) {
			flag = Admin_Generic;
		} else if (StrEqual(key, "ban")) {
			flag = Admin_Ban;
		} else if (StrEqual(key, "unban")) {
			flag = Admin_Unban;
		} else if (StrEqual(key, "slay")) {
			flag = Admin_Slay;
		} else if (StrEqual(key, "changemap")) {
			flag = Admin_Changemap;
		} else if (StrEqual(key, "cvars")) {
			flag = Admin_Convars;
		} else if (StrEqual(key, "config")) {
			flag = Admin_Config;
		} else if (StrEqual(key, "chat")) {
			flag = Admin_Chat;
		} else if (StrEqual(key, "vote")) {
			flag = Admin_Vote;
		} else if (StrEqual(key, "password")) {
			flag = Admin_Password;
		} else if (StrEqual(key, "rcon")) {
			flag = Admin_RCON;
		} else if (StrEqual(key, "cheats")) {
			flag = Admin_Cheats;
		} else if (StrEqual(key, "root")) {
			flag = Admin_Root;
		} else if (StrEqual(key, "custom1")) {
			flag = Admin_Custom1;
		} else if (StrEqual(key, "custom2")) {
			flag = Admin_Custom2;
		} else if (StrEqual(key, "custom3")) {
			flag = Admin_Custom3;
		} else if (StrEqual(key, "custom4")) {
			flag = Admin_Custom4;
		} else if (StrEqual(key, "custom5")) {
			flag = Admin_Custom5;
		} else if (StrEqual(key, "custom6")) {
			flag = Admin_Custom6;
		} else {
			ParseError("Unrecognized flag type: %s", key);
		}
		
		g_FlagLetters[chr] = flag;
		g_FlagsSet[chr] = true;
	}
	
	return SMCParse_Continue;
}

public SMCResult:ReadLevels_EndSection(Handle:smc)
{
	/* If we're ignoring, skip out */
	if (g_IgnoreLevel)
	{
		g_IgnoreLevel--;
		return SMCParse_Continue;
	}
	
	if (g_LevelState == LEVEL_STATE_FLAGS)
	{
		/* We're totally done parsing */
		g_LevelState = LEVEL_STATE_LEVELS;
		return SMCParse_Halt;
	} else if (g_LevelState == LEVEL_STATE_LEVELS) {
		g_LevelState = LEVEL_STATE_NONE;
	}
	
	return SMCParse_Continue;
}

static InitializeLevelParser()
{
	if (g_hLevelParser == INVALID_HANDLE)
	{
		g_hLevelParser = SMC_CreateParser();
		SMC_SetReaders(g_hLevelParser, 
				   	ReadLevels_NewSection,
				   	ReadLevels_KeyValue,
				   	ReadLevels_EndSection);
	}
}

RefreshLevels()
{
	LoadDefaultLetters();
	InitializeLevelParser();
	
	BuildPath(Path_SM, g_Filename, sizeof(g_Filename), "configs/admin_levels.cfg");
	
	/* Set states */
	InitGlobalStates();
	g_LevelState = LEVEL_STATE_NONE;
		
	new SMCError:err = SMC_ParseFile(g_hLevelParser, g_Filename);
	if (err != SMCError_Okay)
	{
		decl String:buffer[64];
		if (SMC_GetErrorString(err, buffer, sizeof(buffer)))
		{
			ParseError("%s", buffer);
		} else {
			ParseError("Fatal parse error");
		}
	}
}
