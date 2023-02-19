/* 				Register And Login

			   Creadits:
	                   - Kalcor
			   - pBlueG
			   - Yashas
			   - SyS
			   - LuminouZ for inspiration he register login ucp
			   - Airell change to no ucp system

    NOTE: Please don't remove the credits!

*/

/* Includes */
#include <a_samp>
#include <a_mysql>
#include <samp_bcrypt>
#include <easyDialog>

#define SERVER_NAME	"Register & Login"


#define MYSQL_HOST "127.0.0.1"
#define MYSQL_USER "root"
#define MYSQL_PASS ""
#define MYSQL_DB "ral" // ral means Register and Login

new MySQL:sqlcon;
new g_RaceCheck[MAX_PLAYERS char];
new temAccount[64];

#if !defined BCRYPT_HASH_LENGTH
	#define BCRYPT_HASH_LENGTH 250
#endif

#if !defined BCRYPT_COST
	#define BCRYPT_COST 12
#endif


forward PlayerCheck(playerid, rcc);
forward CheckPlayerAccount(playerid);
forward LoadAccountData(playerid);
forward HashPlayerPassword(playerid, hashid);
forward OnPlayerPasswordChecked(playerid, bool:success);

enum e_player_data {
	ID,
	Name[MAX_PLAYER_NAME],
	Money,
	Skin,

	bool:Spawned,
};

new PlayerData[MAX_PLAYERS][e_player_data];

stock GetName(playerid)
{
	new name[MAX_PLAYER_NAME];
 	GetPlayerName(playerid,name,sizeof(name));
	return name;
}

MysqlConnect()
{
	sqlcon = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DB);

	if(mysql_errno(sqlcon) != 0) {
		print("Failed to connect MYSQL");
		SendRconCommand("exit");
	}
	else {
		print("Success to connect MYSQL");
	}
}

stock CheckAccount(playerid)
{
	new query[202];
	format(query, sizeof(query), "SELECT * FROM `Account` WHERE `Name` = '%s' LIMIT 1;", GetName(playerid));
	mysql_tquery(sqlcon, query, "CheckPlayerAccount", "d", playerid);
	return 1;
}

public PlayerCheck(playerid, rcc)
{
	if(rcc != g_RaceCheck{playerid}) 
		return Kick(playerid);

	CheckAccount(playerid);
	return true;
}

public CheckPlayerAccount(playerid)
{
	new rows = cache_num_rows();
	new string[128];

	if(rows) {
		cache_get_value_name(0, "Name", temAccount[playerid]);
		format(string, sizeof(string), "Welcome Back to %s.\nName: %s\nType your password below to login.", SERVER_NAME, GetName(playerid));
		Dialog_Show(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", string, "Login", "Quit");
	}
	else {
		format(string, sizeof(string), "Welcome to %s.\nName: %s\nType your password below for register to server.", SERVER_NAME, GetName(playerid));
		Dialog_Show(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Register", string, "Register", "Quit");
	}
	return 1;
}

stock SaveAccount(playerid)
{
	new query[1012];
	if(PlayerData[playerid][Spawned])
	{
		format(query, sizeof(query), "UPDATE `Account` SET `Money` = '%d', `Skin` = '%d' WHERE `ID` = '%d'",
			GetPlayerMoney(playerid),
			PlayerData[playerid][Skin],
			PlayerData[playerid][ID]
		);
		mysql_tquery(sqlcon, query);
	}
	return 1;
}

public LoadAccountData(playerid)
{
	cache_get_value_name_int(0, "ID", PlayerData[playerid][ID]);
	cache_get_value_name(0, "Name", PlayerData[playerid][Name]);
	cache_get_value_name_int(0, "Money", PlayerData[playerid][Money]);
	cache_get_value_name_int(0, "Skin", PlayerData[playerid][Skin]);

	SetSpawnInfo(playerid, 0, PlayerData[playerid][Skin], 818.2922, -1342.9008, 13.5255, 85.9641, 0, 0, 0, 0, 0, 0);
	SpawnPlayer(playerid);
	SendClientMessage(playerid, -1, "Berhasil load account");
	return 1;
}

public HashPlayerPassword(playerid, hashid)
{
	new
		query[256],
		hash[BCRYPT_HASH_LENGTH];

	bcrypt_get_hash(hash, sizeof(hash));

	GetPlayerName(playerid, temAccount[playerid], MAX_PLAYER_NAME + 1);

	format(query, sizeof(query), "INSERT INTO `Account` (`Name`, `Password`) VALUES ('%s', '%s')", temAccount[playerid], hash);
	mysql_tquery(sqlcon, query);

	SendClientMessage(playerid, -1, "Account Berhasil terdaftar");
	PlayerData[playerid][Skin] = 2;
	CheckAccount(playerid);
	return 1;
}

public OnPlayerPasswordChecked(playerid, bool:success)
{
	new string[256];
    format(string, sizeof(string), "Welcome Back to %s.\nName: %s\nType your password below to login.", SERVER_NAME, GetName(playerid));
    
	if(!success)
        return Dialog_Show(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", string, "Login", "Quit");

	new query[256];
	format(query, sizeof(query), "SELECT * FROM `Account` WHERE `Name` = '%s' LIMIT 1;", GetName(playerid));
	mysql_tquery(sqlcon, query, "LoadAccountData", "d", playerid);
	return 1;
}

/* Gamemode Start! */

main()
{
	print("Basic Register And Login Mysql Bcrypt Loaded!");
}

public OnGameModeInit()
{
	MysqlConnect();
	return 1;
}

public OnGameModeExit()
{
	mysql_close(sqlcon);
	return 1;
}

public OnPlayerConnect(playerid)
{
	g_RaceCheck{playerid} ++;
	SetTimerEx("PlayerCheck", 500, false, "ii", playerid, g_RaceCheck{playerid});
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	SaveAccount(playerid);
	if(PlayerData[playerid][Spawned] == true) {
		PlayerData[playerid][Spawned] = false;
	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(!PlayerData[playerid][Spawned])
	{
		PlayerData[playerid][Spawned] = true;
		GivePlayerMoney(playerid, PlayerData[playerid][Money]);
		SetPlayerSkin(playerid, PlayerData[playerid][Skin]);
	}
	return 1;
}
Dialog:DIALOG_REGISTER(playerid, response, listitem, inputtext[])
{
	if(!response) 
		return Kick(playerid);

	new str[256];
	format(str, sizeof(str), "Welcome to %s\nName: %s\nERROR: Password length cannot below 7 or above 32!\nPlease insert your Password below to register", SERVER_NAME, GetName(playerid));

    if(strlen(inputtext) < 7)
		return Dialog_Show(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Register", str, "Register", "Quit");

    if(strlen(inputtext) > 32)
		return Dialog_Show(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Register", str, "Register", "Quit");

    bcrypt_hash(playerid, "HashPlayerPassword", inputtext, BCRYPT_COST);
	return 1;
}

Dialog:DIALOG_LOGIN(playerid, response, listitem, inputtext[])
{
	if(!response)
	    return Kick(playerid);
	        
    if(strlen(inputtext) < 1)
    {
		new string[256];
        format(string, sizeof(string), "Welcome Back to %s.\nName: %s\nType your password below to login.", SERVER_NAME, GetName(playerid));
        Dialog_Show(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", string, "Login", "Quit");
        return 1;
	}
	new pwQuery[256], hash[BCRYPT_HASH_LENGTH];
	mysql_format(sqlcon, pwQuery, sizeof(pwQuery), "SELECT Password FROM Account WHERE Name = '%e' LIMIT 1", GetName(playerid));
	mysql_query(sqlcon, pwQuery);
		
    cache_get_value_name(0, "Password", hash, sizeof(hash));
        
    bcrypt_verify(playerid, "OnPlayerPasswordChecked", inputtext, hash);
	return 1;
}
