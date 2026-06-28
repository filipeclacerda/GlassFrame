local BASE_W, PHOTO_H = 440, 274
local images, queue, history = {}, {}, {}
local cursor, elapsed = 1, 0
local controlsVisible, feedbackTicks = false, 0
local mode, scale, interval, paused, sourceMode, language

-- Rainmeter's Lua bang bridge expects the active Windows code page here.
local function ansi(...)
  return string.char(...)
end

local strings = {
  ['pt'] = {
    empty = 'Nenhuma foto encontrada\nClique para escolher uma pasta',
    paused = 'Pausado', playing = 'Reproduzindo',
    layout = 'Layout', settings = 'Configura' .. ansi(231,245) .. 'es',
    previous = 'Anterior', next = 'Pr' .. ansi(243) .. 'xima', play = 'Reproduzir / Pausar',
    scale = 'Escala'
  },
  ['en'] = {
    empty = 'No photos found\nClick to choose a folder',
    paused = 'Paused', playing = 'Playing',
    layout = 'Layout', settings = 'Settings',
    previous = 'Previous', next = 'Next', play = 'Play / Pause',
    scale = 'Scale'
  }
}

local function variable(name, fallback)
  local value = SKIN:GetVariable(name)
  if value == nil or value == '' then return fallback end
  return value
end

local function number(name, fallback)
  return tonumber(variable(name, tostring(fallback))) or fallback
end

local function tr(key)
  local tableKey = language == 'pt' and 'pt' or 'en'
  return strings[tableKey][key] or key
end

local function persist(key, value)
  SKIN:Bang('!WriteKeyValue', 'Variables', key, tostring(value), '#CURRENTPATH#Variables.inc')
  SKIN:Bang('!SetVariable', key, tostring(value))
end

local function readLines(path)
  local result, file = {}, io.open(path, 'r')
  if not file then return result end
  for line in file:lines() do
    line = line:gsub('\r$', '')
    if line ~= '' then table.insert(result, line) end
  end
  file:close()
  return result
end

local function exists(path)
  if not path or path == '' then return false end
  local file = io.open(path, 'rb')
  if file then file:close(); return true end
  return false
end

local function shuffle(values)
  for i = #values, 2, -1 do
    local j = math.random(i)
    values[i], values[j] = values[j], values[i]
  end
end

local function buildQueue()
  queue = {}
  for _, path in ipairs(images) do
    if exists(path) then table.insert(queue, path) end
  end
  if variable('PlayOrder', 'Random') == 'Random' then shuffle(queue) end
  cursor = 1
end

local function slotCount()
  if mode == 1 or mode == 5 then return 1 end
  return mode
end

local function rect(x, y, w, h, radius)
  local s = scale
  return string.format('Rectangle %.2f,%.2f,%.2f,%.2f,%.2f | Fill Color 20,20,28,255 | StrokeWidth 0',
    x*s, y*s, w*s, h*s, radius*s)
end

local function place(n, x, y, w, h, radius)
  local mask, slot = 'Mask' .. n, 'Slot' .. n
  SKIN:Bang('!SetOption', mask, 'Shape', rect(x, y, w, h, radius))
  SKIN:Bang('!SetOption', slot, 'X', string.format('%.2f', (x - 8) * scale))
  SKIN:Bang('!SetOption', slot, 'Y', string.format('%.2f', (y - 8) * scale))
  SKIN:Bang('!SetOption', slot, 'W', string.format('%.2f', (w + 16) * scale))
  SKIN:Bang('!SetOption', slot, 'H', string.format('%.2f', (h + 16) * scale))
  SKIN:Bang('!ShowMeter', mask)
end

local function applyLayout()
  for i = 1, 4 do
    SKIN:Bang('!HideMeter', 'Mask' .. i)
    SKIN:Bang('!HideMeter', 'Slot' .. i)
  end
  local g, x, y, w, h, r = 8, 8, 8, 424, 258, 14
  if mode == 1 then
    place(1, x, y, w, h, r)
  elseif mode == 2 then
    local cw = (w-g)/2
    place(1, x, y, cw, h, r); place(2, x+cw+g, y, cw, h, r)
  elseif mode == 3 then
    local cw = (w-2*g)/3
    place(1, x, y, cw, h, r); place(2, x+cw+g, y, cw, h, r)
    place(3, x+2*(cw+g), y, cw, h, r)
  elseif mode == 4 then
    local cw, ch = (w-g)/2, (h-g)/2
    place(1, x, y, cw, ch, r); place(2, x+cw+g, y, cw, ch, r)
    place(3, x, y+ch+g, cw, ch, r); place(4, x+cw+g, y+ch+g, cw, ch, r)
  else
    local d = h
    place(1, (BASE_W-d)/2, y, d, d, d/2)
  end
  SKIN:Bang('!UpdateMeterGroup', 'Slots')
end

local function currentSet()
  local set, count = {}, slotCount()
  if sourceMode == 'Manual' then
    for i = 1, count do
      local path = variable('Image' .. i, '')
      if exists(path) then table.insert(set, path) end
    end
    return set
  end
  if #queue == 0 then return set end
  for index = cursor, #queue do
    if exists(queue[index]) then table.insert(set, queue[index]) end
    if #set >= count then break end
  end
  return set
end

local function renderSet(explicitSet)
  local set = explicitSet or currentSet()
  for i = 1, 4 do
    local path = set[i]
    if path then
      SKIN:Bang('!SetOption', 'Slot' .. i, 'ImageName', path)
      SKIN:Bang('!ShowMeter', 'Slot' .. i)
    else
      SKIN:Bang('!HideMeter', 'Slot' .. i)
    end
  end
  if #set == 0 then
    SKIN:Bang('!SetOption', 'EmptyState', 'Text', tr('empty'))
    SKIN:Bang('!ShowMeter', 'EmptyState')
  else
    SKIN:Bang('!HideMeter', 'EmptyState')
  end
  SKIN:Bang('!UpdateMeterGroup', 'Slots')
  SKIN:Bang('!UpdateMeter', 'EmptyState')
  SKIN:Bang('!Redraw')
end

local function localize()
  local layoutIcons = {'[ ]', '[|]', '[||]', '[+]', '( )'}
  SKIN:Bang('!SetOption', 'Previous', 'ToolTipText', tr('previous'))
  SKIN:Bang('!SetOption', 'Next', 'ToolTipText', tr('next'))
  SKIN:Bang('!SetOption', 'PlayPause', 'ToolTipText', tr('play'))
  SKIN:Bang('!SetOption', 'LayoutButton', 'Text', layoutIcons[mode])
  SKIN:Bang('!SetOption', 'LayoutButton', 'ToolTipText', tr('layout') .. ' ' .. mode)
  SKIN:Bang('!SetOption', 'SettingsButton', 'ToolTipText', tr('settings'))
end

local function feedback(message)
  SKIN:Bang('!SetOption', 'Feedback', 'Text', message)
  SKIN:Bang('!ShowMeter', 'Feedback')
  SKIN:Bang('!UpdateMeter', 'Feedback')
  feedbackTicks = 2
end

function Initialize()
  math.randomseed(os.time())
  RefreshAll()
end

function RefreshAll()
  mode = math.max(1, math.min(5, number('Mode', 1)))
  scale = math.max(0.4, math.min(3.0, number('Scale', 1)))
  interval = math.max(5, number('SlideInterval', 30))
  paused = variable('Paused', '0') == '1'
  sourceMode = variable('SourceMode', 'Folder')
  language = variable('Language', 'en')
  images = readLines(SKIN:GetVariable('CURRENTPATH') .. 'ImageCatalog.txt')
  buildQueue()
  applyLayout()
  localize()
  renderSet()
end

function Update()
  if feedbackTicks > 0 then
    feedbackTicks = feedbackTicks - 1
    if feedbackTicks == 0 then
      SKIN:Bang('!HideMeter', 'Feedback')
      SKIN:Bang('!UpdateMeter', 'Feedback')
      SKIN:Bang('!Redraw')
    end
  end
  if sourceMode == 'Folder' and not paused and #queue > 0 then
    elapsed = elapsed + 1
    if elapsed >= interval then NextSet(false) end
  end
  return ''
end

function NextSet(manual)
  if sourceMode ~= 'Folder' or #queue == 0 then return end
  local snapshot = { cursor = cursor, queue = {} }
  for i, path in ipairs(queue) do snapshot.queue[i] = path end
  table.insert(history, snapshot)
  cursor = cursor + slotCount()
  if cursor > #queue then buildQueue() end
  elapsed = 0
  renderSet()
end

function PreviousSet()
  if sourceMode ~= 'Folder' or #history == 0 then return end
  local snapshot = table.remove(history)
  cursor, queue = snapshot.cursor, snapshot.queue
  elapsed = 0
  renderSet()
end

function TogglePause()
  paused = not paused
  persist('Paused', paused and '1' or '0')
  SKIN:Bang('!SetOption', 'PlayPause', 'Text', paused and '>' or 'II')
  SKIN:Bang('!UpdateMeter', 'PlayPause')
  feedback(paused and tr('paused') or tr('playing'))
  SKIN:Bang('!Redraw')
end

function CycleMode()
  mode = mode % 5 + 1
  persist('Mode', mode)
  applyLayout()
  localize()
  renderSet()
end

function AdjustScale(delta)
  scale = math.floor(math.max(0.4, math.min(3.0, scale + tonumber(delta))) * 10 + 0.5) / 10
  persist('Scale', string.format('%.1f', scale))
  applyLayout()
  localize()
  SKIN:Bang('!UpdateMeter', 'Background')
  SKIN:Bang('!UpdateMeterGroup', 'Controls')
  feedback(string.format('%s %.1fx', tr('scale'), scale))
  renderSet()
end

function ShowControls()
  controlsVisible = true
  SKIN:Bang('!ShowMeterGroup', 'Controls')
  SKIN:Bang('!SetOption', 'PlayPause', 'Text', paused and '>' or 'II')
  SKIN:Bang('!UpdateMeterGroup', 'Controls')
  SKIN:Bang('!Redraw')
end

function HideControls()
  controlsVisible = false
  SKIN:Bang('!HideMeterGroup', 'Controls')
  SKIN:Bang('!Redraw')
end
