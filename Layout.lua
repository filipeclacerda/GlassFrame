-- Fixed widget dimensions
local GW = 440   -- image area width
local GH = 275   -- image area height

function Initialize()
  SetLayout(1)
end

function Update()
  return ''
end

-- Rainmeter Lua 5.1 uses loadstring, not load
function CommandMeasure(args)
  local fn = loadstring(args)
  if fn then fn() end
end

function SetMode(mode)
  SetLayout(tonumber(mode))
end

function SetLayout(mode)
  for i = 1, 4 do
    SKIN:Bang('!HideMeter', 'Image' .. i)
  end

  if mode == 1 then
    Place(1, 0, 0, GW, GH)

  elseif mode == 2 then
    local hw = math.floor(GW / 2)
    Place(1, 0,  0, hw,      GH)
    Place(2, hw, 0, GW - hw, GH)

  elseif mode == 3 then
    local tw = math.floor(GW / 3)
    Place(1, 0,      0, tw,          GH)
    Place(2, tw,     0, tw,          GH)
    Place(3, tw * 2, 0, GW - tw * 2, GH)

  elseif mode == 4 then
    local hw = math.floor(GW / 2)
    local hh = math.floor(GH / 2)
    Place(1, 0,  0,  hw,      hh)
    Place(2, hw, 0,  GW - hw, hh)
    Place(3, 0,  hh, hw,      GH - hh)
    Place(4, hw, hh, GW - hw, GH - hh)
  end

  SKIN:Bang('!Redraw')
end

function Place(n, x, y, w, h)
  local name = 'Image' .. n
  SKIN:Bang('!SetOption', name, 'X', x)
  SKIN:Bang('!SetOption', name, 'Y', y)
  SKIN:Bang('!SetOption', name, 'W', w)
  SKIN:Bang('!SetOption', name, 'H', h)
  SKIN:Bang('!ShowMeter', name)
  SKIN:Bang('!UpdateMeter', name)
end
