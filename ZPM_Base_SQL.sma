#include <amxmodx>
#include <vault>
#include <eG>
#include <zombieplague>
#include <dbi>
#include <hamsandwich>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <engine>
#include <register_system>

new Sql:sql
new Result:result
new error[33]

new coin[33]

new const log_file[] = "ZStore_GiftCoin.txt"

public plugin_init()
{
	register_plugin("[ZPM] Base", "1.0", "EmeraldGhost")
	set_task(300.0, "Task_Timer", 123476, _, _, "b");
	
	register_concmd("gift_coin", "cmd_gift_coin", ADMIN_ALL, "- gift_coin <玩家> <数量> : 赠送金币给对方")
	
	// Connect SQL
	new sql_host[64], sql_user[64], sql_pass[64], sql_db[64]
	get_cvar_string("amx_sql_host", sql_host, 63)
	get_cvar_string("amx_sql_user", sql_user, 63)
	get_cvar_string("amx_sql_pass", sql_pass, 63)
	get_cvar_string("amx_sql_db", sql_db, 63)

	sql = dbi_connect(sql_host, sql_user, sql_pass, sql_db, error, 32)

	if (sql == SQL_FAILED)
	{
		server_print("[Store] Could not connect to SQL database. %s", error)
	}
}

public plugin_precache()
{
	precache_sound("zmParadise/Store/coin_sound.wav")
	precache_sound("zmParadise/Store/coinlose_sound.wav")
}

public plugin_natives()
{
	register_native("zpm_base_get_coin", "native_get_coin", 1)
	register_native("zpm_base_set_coin", "native_set_coin", 1)
}

public client_putinserver(id)
{
	coin[id] = 0
	load_data(id)
}

public client_disconnect(id)
{
	save_data(id)
	coin[id] = 0
}

public Base_BD(id)
{
	coin[id] = 99999
	save_data(id)
}

public save_data(id)
{ 
	if(!is_user_logged(id))
		return;

	new authid[32]
	get_user_name(id, authid, 31)
	replace_all(authid, 32, "`", "\`")
	replace_all(authid, 32, "'", "\'")
	
	dbi_query(sql, "UPDATE store SET coin='%d' WHERE name = '%s'", coin[id], authid)
}

public load_data(id) 
{
	new authid[32] 
	get_user_name(id,authid,31)
	replace_all(authid, 32, "`", "\`")
	replace_all(authid, 32, "'", "\'")

	result = dbi_query(sql, "SELECT coin FROM store WHERE name='%s'", authid)

	if(result == RESULT_NONE)
	{
	dbi_query(sql, "INSERT INTO store(name,coin) VALUES('%s','%d')", authid, coin[id])
	}
	else if(result <= RESULT_FAILED)
	{
		server_print("[Store] SQL error. (Load)")
	}
	else
	{
		coin[id] = dbi_field(result, 1)
		dbi_free_result(result)
	}
}

public native_get_coin(id) return coin[id];
public native_set_coin(id, iamount)
{
	coin[id] = iamount
	save_data(id)
	return coin[id];
}

public zp_round_ended(winteam)
{
	new mapname[64]
	get_mapname(mapname, 63)
	
	new wjsl = get_playersnum(0)
	if(wjsl <= 4) return PLUGIN_HANDLED
		
	for(new i = 1; i < 33; i++)
	{
		if(is_user_alive(i) && !zp_get_user_zombie(i))
		{
			coin[i] ++
			PlaySound(i, "zmParadise/Store/coin_sound.wav")
			if(containi(mapname, "ze_") == 0)
			{
				coin[i] ++
				client_printc(i, "\g[Store] \y由于本回合逃脱成功, 你获得了 \t2 \y枚金币.")
			}
			else client_printc(i, "\g[Store] \y由于回合结束你仍然幸存, 你获得了 \t1 \y枚金币.")
			save_data(i)
		}
	}
	return PLUGIN_HANDLED
}

public Task_Timer()
{
	new wjsl = get_playersnum(0)
	
	for(new i=1;i<33;i++)
	{
		if(is_user_alive(i) && wjsl > 3)
		{
			coin[i] ++
			PlaySound(i, "zmParadise/Store/coin_sound.wav")
			client_printc(i, "\g[Store] \y由于在线游玩 5 分钟, 你获得了 \t1 \y枚金币.")
			save_data(i)
		}
	}
	return HAM_IGNORED
}

public cmd_gift_coin(id, level, cid) 
{ 
    new arg_name[25], arg_amount[10]

    read_argv(1, arg_name, 25) 
    read_argv(2, arg_amount, 10)

	if(str_to_num(arg_amount) < 1)
	{
		if(!(get_user_flags(id) & ADMIN_IMMUNITY))
        {
		client_print(id, print_console, "[Gift] Coin amount invalid")
		return PLUGIN_HANDLED
		}
	}
	
	if(coin[id] <= str_to_num(arg_amount))
	{
		client_print(id, print_console, "[Gift] No enough coin to gift")
		return PLUGIN_HANDLED
	}
	
	new name[32]
    get_user_name(id,name,31)
	
	if(containi(arg_name, "@all") == 0)
	{
	    if(!(get_user_flags(id) & ADMIN_IMMUNITY))
            return PLUGIN_HANDLED;
	
		for(new i = 1; i < 33; i++)
		{
			if(is_user_connected(i) && is_user_logged(i))
			{
			    coin[i] += str_to_num(arg_amount)
				PlaySound(i, "zmParadise/Store/coin_sound.wav")
			}
		}
		
		log_gift_all(id, str_to_num(arg_amount))
		client_printc(0, "\g[Store] \y管理员 \g%s\y 赠送了所有人 \g%d \y枚金币.", name, str_to_num(arg_amount))
		return PLUGIN_HANDLED;
	}
	else if(containi(arg_name, "@humans") == 0)
	{
	    if(!(get_user_flags(id) & ADMIN_IMMUNITY))
            return PLUGIN_HANDLED;
	
		for(new i = 1; i < 33; i++)
		{
			if(is_user_connected(i) && is_user_logged(i) && !zp_get_user_zombie(i))
			{
			    coin[i] += str_to_num(arg_amount)
				PlaySound(i, "zmParadise/Store/coin_sound.wav")
			}
		}
		
		log_gift_human(id, str_to_num(arg_amount))
		client_printc(0, "\g[Store] \y管理员 \g%s\y 赠送了所有人类 \g%d \y枚金币.", name, str_to_num(arg_amount))
		return PLUGIN_HANDLED;
	}
	else if(containi(arg_name, "@zombies") == 0)
	{
	    if(!(get_user_flags(id) & ADMIN_IMMUNITY))
            return PLUGIN_HANDLED;
	
		for(new i = 1; i < 33; i++)
		{
			if(is_user_connected(i) && is_user_logged(i) && zp_get_user_zombie(i))
			{
			    coin[i] += str_to_num(arg_amount)
				PlaySound(i, "zmParadise/Store/coin_sound.wav")
			}
		}
		
		log_gift_zombie(id, str_to_num(arg_amount))
		client_printc(0, "\g[Store] \y管理员 \g%s\y 赠送了所有丧尸 \g%d \y枚金币.", name, str_to_num(arg_amount))
		return PLUGIN_HANDLED;
	}
	else if(containi(arg_name, "@alive") == 0)
	{
	    if(!(get_user_flags(id) & ADMIN_IMMUNITY))
            return PLUGIN_HANDLED;
	
		for(new i = 1; i < 33; i++)
		{
			if(is_user_connected(i) && is_user_logged(i) && is_user_alive(i))
			{
			    coin[i] += str_to_num(arg_amount)
				PlaySound(i, "zmParadise/Store/coin_sound.wav")
			}
		}
		
		log_gift_alive(id, str_to_num(arg_amount))
		client_printc(0, "\g[Store] \y管理员 \g%s\y 赠送了所有存活玩家 \g%d \y枚金币.", name, str_to_num(arg_amount))
		return PLUGIN_HANDLED;
	}

    new target = cmd_target(id, arg_name, 2)

    if (!target) 
    { 
        client_print(id, print_console, "[Gift] Player not found") 
        return PLUGIN_HANDLED
    }

    coin[target] += str_to_num(arg_amount)
	PlaySound(target, "zmParadise/Store/coin_sound.wav")
	client_printc(target, "\g[Store] \y你获得了 \t%d \y枚金币.", str_to_num(arg_amount))
	
	coin[id] -= str_to_num(arg_amount)
	PlaySound(id, "zmParadise/Store/coinlose_sound.wav")
	client_printc(id, "\g[Store] \y你失去了 \t%d \y枚金币.", str_to_num(arg_amount))

	client_printc(0, "\g[Store] \g%s\y 赠送了\g %d \y金币给 \g%s\y .", name, str_to_num(arg_amount) , arg_name)
	log_gift(id, arg_name, str_to_num(arg_amount))
    return PLUGIN_HANDLED 
}

public log_gift(id, target[], amount)
{
    new name[32]
    get_user_name(id,name,31)
	
	log_to_file(log_file, "[Gift] %s 赠送 %d 金币给 %s", name, amount, target)
}

public log_gift_all(id, amount)
{
    new name[32]
    get_user_name(id,name,31)
	
	log_to_file(log_file, "[GiftAll] %s 赠送 %d 金币", name, amount)
}

public log_gift_alive(id, amount)
{
    new name[32]
    get_user_name(id,name,31)
	
	log_to_file(log_file, "[GiftAlive] %s 赠送 %d 金币", name, amount)
}

public log_gift_zombie(id, amount)
{
    new name[32]
    get_user_name(id,name,31)
	
	log_to_file(log_file, "[GiftZB] %s 赠送 %d 金币", name, amount)
}

public log_gift_human(id, amount)
{
    new name[32]
    get_user_name(id,name,31)
	
	log_to_file(log_file, "[GiftHuman] %s 赠送 %d 金币", name, amount)
}