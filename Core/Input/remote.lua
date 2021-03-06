local keyboard = libs.keyboard;
local mouse = libs.mouse;

--@help Release key(s)
actions.KeyDown = function (...)
	keyboard.down(unpack({...}));
end

--@help Hold down key(s)
actions.KeyUp = function (...)
	keyboard.up(unpack({...}));
end

--@help Press key(s)
actions.Press = function (...)
	keyboard.press(unpack({...}));
end

--@help Press keyboard stroke
actions.Stroke = function (...)
	keyboard.stroke(unpack({...}));
end

--@help Send text
actions.Text = function (text)
	keyboard.text(text);
end

--@help Press mouse button
actions.MouseDown = function(...)
	mouse.down(unpack({...}));
end

--@help Release mouse button
actions.MouseUp = function(...)
	mouse.up(unpack({...}));
end

--@help Perform mouse button click
actions.Click = function(...)
	mouse.click(unpack({...}));
end

--@help Perform mouse button click
actions.DblClick = function(...)
	mouse.double(unpack({...}));
end

--@help Perform relative mouse movement
actions.MoveBy = function(x, y)
	mouse.moveraw(x,y);
end

--@help Perform absolute mouse movement
actions.MoveTo = function (x, y)
	mouse.moveto(x, y);
end

--@help Perform absolute (px) mouse movement
actions.MoveToPx = function (x, y)
	mouse.moveto(x, y);
end

--@help Perform vertical mouse scroll
actions.Vert = function(amount)
	mouse.vscroll(amount);
end

--@help Perform horizontal mouse scroll
actions.Horz = function(amount)
	mouse.hscroll(amount);
end

--@help Perform zoom in
actions.ZoomIn = function ()
	mouse.zoomin();
end

--@help Perform zoom out
actions.ZoomOut = function ()
	mouse.zoomout();
end