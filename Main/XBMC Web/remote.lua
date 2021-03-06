local tid = -1;

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------

events.focus = function ()
	host = settings.host;
	port = settings.port;
	password = settings.password;
	
	test();
	
	tid = libs.timer.interval(update_status, 1000);
	update_library();
end

events.blur = function ()
	libs.timer.cancel(tid);
end

function test()
	-- Verify that XBMC is accessible otherwise show some nice help information
	local resp = send("JSONRPC.Version");
	if (resp == nil) then
		libs.server.update({
			type = "dialog",
			title = "XBMC Connection",
			text = "A connection to XBMC could not be established." ..
				"We recommend using the latest version of XBMC.\n\n" ..
				"1. Make sure XBMC is running on your computer.\n\n" ..
				"2. Enable the Webserver in System > Services > Webserver.\n\n" ..
				"3. Allow remote control in System > Remote control.\n\n" ..
				"4. Unified Remote is pre-configured to use port 80 and no password.\n\n" ..
				"You may have to restart XBMC after enabling the web interface for the changes to take effect.",
			children = {{ type = "button", text = "OK" }}
		});
	end
end

------------------------------------------------------------------------
-- Web Request
------------------------------------------------------------------------

function send(method, params)
	local req = {};
	req.jsonrpc = "2.0";
	req.id = 1;
	if (method ~= nil) then req.method = method; end
	if (params ~= nil) then req.params = params; end
	
	-- Send a JSON-RPC request
	local host = settings.host;
	local port = settings.port;
	local url = "http://" .. host .. ":" .. port .. "/jsonrpc";
	
	local json = libs.data.tojson(req);
	local resp = libs.http.request({
		method = "post",
		url = url,
		mime = "application/json",
		content = json
	});
	if (resp ~= nil and resp.status == 200) then
		return libs.data.fromjson(resp.content);
	else
		print("error: " .. resp.content);
		libs.server.update({ id = "title", text = "[Not Connected]" });
		return nil;
	end
end

------------------------------------------------------------------------
-- Status
------------------------------------------------------------------------

function update_status()
	local resp = send("Player.GetItem", { playerid = player() });
	layout.title.text = resp.result.item.label;
end

local stack = {};
local items = {};
local show = 0;
local season = 0;
local artist = "";
local album = ""

function movies(items)
	local resp = send("VideoLibrary.GetMovies");
	if (resp.result.movies ~= nil) then
		for k,v in pairs(resp.result.movies) do
			table.insert(items, { text = v.label .. " (" .. v.movieid .. ")", id = v.movieid });
		end
	else
		empty(items);
	end
end

function tvshows(items)
	local resp = send("VideoLibrary.GetTvShows");
	if (resp.result.tvshows ~= nil) then
		for k,v in pairs(resp.result.tvshows) do
			table.insert(items, { text = v.label .. " (" .. v.tvshowid .. ")", id = v.tvshowid });
		end
	else
		empty(items);
	end
end

function tvseasons(items)
	local resp = send("VideoLibrary.GetSeasons", { tvshowid = show });
	if (resp.result.seasons ~= nil) then
		for k,v in pairs(resp.result.seasons) do
			table.insert(items, { text = v.label, id = k });
		end
	else
		empty(items);
	end
end

function tvepisodes(items)
	local resp = send("VideoLibrary.GetEpisodes", { tvshowid = show, season = season });
	if (resp.result.episodes ~= nil) then
		for k,v in pairs(resp.result.episodes) do
			table.insert(items, { text = v.label, id = v.episodeid });
		end
	else
		empty(items);
	end
end

function artists(items)
	local resp = send("AudioLibrary.GetArtists");
	if (resp.result.artists ~= nil) then
		for k,v in pairs(resp.result.artists) do
			table.insert(items, { text = v.label, id = v.artistid });
		end
	else
		empty(items);
	end
end

function albums(items)
	local resp = send("AudioLibrary.GetAlbums");
	if (resp.result.albums ~= nil) then
		for k,v in pairs(resp.result.albums) do
			table.insert(items, { text = v.label, id = v.albumid });
		end
	else
		empty(items);
	end
end

function songs(items)
	local resp = send("AudioLibrary.GetSongs", {asdf =asdf});
	if (resp.result.songs ~= nil) then
		for k,v in pairs(resp.result.songs) do
			table.insert(items, { text = v.label, id = v.songid });
		end
	else
		empty(items);
	end
end

function empty(items)
	table.insert(items, { text = "Empty" });
end

function loading(items)
	local items = {};
	table.insert(items, { type = "item", text = "Loading..." });
	libs.server.update({ id = "list", children = items });
end

function update_library()
	loading(items);
	
	items = {}
	local state = "";
	if (#stack > 0) then
		state = stack[#stack];
	end
	if (state == "") then
		table.insert(items, { text = "Music" });
		table.insert(items, { text = "Movies" });
		table.insert(items, { text = "TV Shows" });
	elseif (state == "Music") then
		table.insert(items, { text = "Artists" });
		table.insert(items, { text = "Albums" });
		table.insert(items, { text = "Songs" });
	elseif (state == "Artists") then
		artists(items);
	elseif (state == "Albums") then
		albums(items);
	elseif (state == "Songs") then
		songs(items);
	elseif (state == "AlbumSongs") then
		empty(items);
	elseif (state == "ArtistSongs") then
		empty(items);
	elseif (state == "Movies") then
		movies(items);
	elseif (state == "TV Shows") then
		tvshows(items);
	elseif (state == "Seasons") then
		tvseasons(items);
	elseif (state == "Episodes") then
		tvepisodes(items);
	end
	for k,v in pairs(items) do
		v.type = "item";
	end
	libs.server.update({ id = "list", children = items });
end

actions.library_select = function (i)
	local state = "";
	if (#stack > 0) then
		state = stack[#stack];
	end
	local text = items[i+1].text;
	local id = items[i+1].id;
	if (state == "") then
		table.insert(stack, text);
	elseif (state == "Music") then
		table.insert(stack, text);
	elseif (state == "Movies") then
		if (id ~= nil) then
			print("movie: " .. id);
			send("Player.Open", { item = { movieid = id } });
		end
	elseif (state == "TV Shows") then
		if (id ~= nil) then
			show = id;
			table.insert(stack, "Seasons");
		end
	elseif (state == "Seasons") then
		if (id ~= nil) then
			season = id;
			table.insert(stack, "Episodes");
		end
	elseif (state == "Episodes") then
		if (id ~= nil) then
			send("Player.Open", { item = { episodeid = id } });
		end
	elseif (state == "Artists") then
		if (id ~= nil) then
			artist = id;
			table.insert(stack, "ArtistSongs");
		end
	elseif (state == "Albums") then
		if (id ~= nil) then
			album = id;
			table.insert(stack, "AlbumSongs");
		end
	end
	update_library();
end

actions.library_back = function ()
	if (#stack > 0) then
		table.remove(stack);
		update_library();
	end
end

------------------------------------------------------------------------
-- Actions
------------------------------------------------------------------------

function player ()
	local resp = send("Player.GetActivePlayers");
	return resp.result[1].playerid;
end

function volume ()
	local resp = send("Application.GetProperties", { properties = { "volume" } });
	return resp.result.volume;
end

function input(key)
	send("Input." .. key);
end

actions.play_pause = function ()
	send("Player.PlayPause", { playerid = player() });
end

actions.stop = function ()
	send("Player.Stop", { playerid = player() });
end

actions.next = function ()
	send("Player.GoNext", { playerid = player() });
end

actions.previous = function ()
	send("Player.GoPrevious", { playerid = player() });
end

actions.rewind = function ()
	send("Player.SetSpeed", { playerid = player(), speed = "decrement" });
end

actions.forward = function ()
	send("Player.SetSpeed", { playerid = player(), speed = "increment" });
end

actions.set_volume = function (vol)
	if (vol > 100) then vol = 100; end
	if (vol < 0) then vol = 0; end
	send("Application.SetVolume", { volume = vol });
end

actions.volume_up = function ()
	actions.set_volume(volume() + 10);
end

actions.volume_down = function ()
	actions.set_volume(volume() - 10);
end

actions.volume_mute = function ()
	send("Application.SetMute", { mute = "toggle" });
end

actions.left = function ()
	input("Left");
end

actions.right = function ()
	input("Right");
end

actions.up = function ()
	input("Up");
end

actions.down = function ()
	input("Down");
end

actions.select = function ()
	input("Select");
end

actions.back = function ()
	input("Back");
end

actions.menu = function ()
	input("ContextMenu");
end

actions.osd = function ()
	input("ShowOSD");
end

actions.home = function ()
	input("Home");
end

actions.info = function ()
	input("Info");
end

actions.fullscreen = function ()
	send("GUI.SetFullscreen", { fullscreen = "toggle" });
end
