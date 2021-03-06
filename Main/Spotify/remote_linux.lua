-- metadata
meta.id = "Unified.Spotify"
meta.name = "Spotify"
meta.author = "Unified Intents"
meta.description = "Spotify basic media remote control."
meta.platform = "linux"

local task = libs.task;
local keyboard = libs.keyboard;
local timer = libs.timer;
local server = libs.server;

local tid = -1;
local playing = false;
local title = "";

events.focus = function ()
	tid = timer.interval(actions.update, 500);
end

events.blur = function ()
	timer.cancel(tid);
end

--@help Update status information
actions.update = function ()
	local _title = "";
	local _playing = true;
	
	if (_title == "") then
		_title = "[Not Playing]";
		_playing = false;
	end
	
	if (_title ~= title) then
		title = _title;
		server.update({ id = "info", text = title });
	end
	
	if (_playing ~= playing) then
		playing = _playing;
		if (playing) then
			server.update({ id = "p", icon = "pause" });
		else
			server.update({ id = "p", icon = "play" });
		end
	end
end

--@help Start playback
actions.play = function()
	if (not playing) then
		actions.play_pause();
	end
end

--@help Pause playback
actions.pause = function()
	if (playing) then
		actions.play_pause();
	end
end

--@help Toggle playback state
actions.play_pause = function()
    os.execute("dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause");
end

--@help Lower volume
actions.volume_down = function()
	keyboard.press("volumedown");
end

--@help Raise volume
actions.volume_up = function()
    keyboard.press("volumeup");
end

--@help Mute volume
actions.volume_mute = function()
    keyboard.press("volumemute");
end

--@help Next track
actions.next = function()
    os.execute("dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next");
end

--@help Previous track
actions.previous = function()
    os.execute("dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous");
end

--@help Stop playback
actions.stop = function()
    os.execute("dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Stop");
end