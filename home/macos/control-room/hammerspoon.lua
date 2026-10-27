-- Control Room — Hammerspoon voice + hotkey layer.
-- Managed by Home Manager (home/macos/control-room). Settings come from
-- ~/.config/control-room/config.json; edit the Nix options, not this file.
-- Personal additions can go in ~/.hammerspoon/local.lua (not managed).

local cfgPath = os.getenv("HOME") .. "/.config/control-room/config.json"
local cfg = hs.json.read(cfgPath) or {}
local voice = cfg.voice or {}
local hk = cfg.hotkeys or {}
local bin = cfg.bin or {}

local CR = bin.controlRoom or "control-room"
local SOX = voice.sox or "sox"
local TMP = os.getenv("TMPDIR") or "/tmp/"
local PATH_ENV = { PATH = (bin.path or "") .. ":/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin" }

hs.console.clearConsole()
hs.alert.defaultStyle.textSize = 18
hs.alert.defaultStyle.radius = 10

local function crTask(args, onDone)
  local t = hs.task.new(CR, function(code, out, err)
    if onDone then onDone(code, out or "", err or "") end
  end, args)
  t:setEnvironment(PATH_ENV)
  t:start()
  return t
end

-- ---------------------------------------------------------------------------
-- Push-to-talk recorder (hold the hotkey, speak, release)
-- ---------------------------------------------------------------------------

local recorder = nil
local recStarted = 0
local recFile = nil
local listening = nil
local menubar = hs.menubar.new()

local function setMenu(state)
  if not menubar then return end
  local icons = { idle = "⌁", rec = "● REC", busy = "…" }
  menubar:setTitle(icons[state] or "⌁")
end
setMenu("idle")

local function startRecording(mode)
  if recorder then return end
  recFile = TMP .. "control-room-" .. mode .. ".wav"
  os.remove(recFile)
  recorder = hs.task.new(SOX, nil, { "-q", "-d", "-r", "16000", "-c", "1", "-b", "16", recFile })
  recorder:setEnvironment(PATH_ENV)
  recorder:start()
  recStarted = hs.timer.secondsSinceEpoch()
  setMenu("rec")
  listening = hs.alert.show(mode == "dictate" and "🎙 Dictating…" or "🎙 Listening…", "forever")
  if voice.chime ~= false then hs.sound.getByName("Tink"):play() end
end

local function stopRecording(onFile)
  if not recorder then return end
  local task, file = recorder, recFile
  recorder = nil
  if listening then hs.alert.closeSpecific(listening); listening = nil end
  local held = hs.timer.secondsSinceEpoch() - recStarted
  task:interrupt() -- SIGINT lets sox finalise the WAV header
  setMenu("busy")
  hs.timer.doAfter(0.25, function()
    if held < 0.35 then
      setMenu("idle")
      hs.alert.show("Hold the key while you speak")
      return
    end
    onFile(file)
  end)
end

local function handleCommand(file)
  crTask({ "voice", "--json", "--audio", file }, function(code, out)
    setMenu("idle")
    local ok, res = pcall(hs.json.decode, out)
    if not ok or not res then
      hs.alert.show("control-room error — see ~/.local/state/control-room")
      return
    end
    if res.heard and res.heard ~= "" then
      hs.alert.show("“" .. res.heard .. "”\n" .. (res.say or ""), 3)
    else
      hs.alert.show(res.say or "Didn't catch that", 2)
    end
    if res.type_text then hs.eventtap.keyStrokes(res.type_text) end
    if res.say and res.say ~= "" and voice.speak ~= false
        and (res.action == "status" or res.action == "read") then
      hs.speech.new():speak(res.say)
    end
  end)
end

local function handleDictation(file)
  crTask({ "transcribe", file }, function(code, out)
    setMenu("idle")
    local text = (out or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then hs.alert.show("Didn't hear anything"); return end
    hs.eventtap.keyStrokes(text)
    if voice.dictateSubmit then hs.eventtap.keyStroke({}, "return") end
  end)
end

local function bindHold(spec, mode, handler)
  if not spec or not spec.key then return end
  hs.hotkey.bind(spec.mods or {}, spec.key,
    function() startRecording(mode) end,
    function() stopRecording(handler) end)
end

if voice.enable ~= false then
  bindHold(hk.voiceCommand, "command", handleCommand)
  bindHold(hk.voiceDictate, "dictate", handleDictation)
end

-- ---------------------------------------------------------------------------
-- Plain hotkeys
-- ---------------------------------------------------------------------------

local function bindRun(spec, args, alertResult)
  if not spec or not spec.key then return end
  hs.hotkey.bind(spec.mods or {}, spec.key, function()
    crTask(args, function(_, out)
      if alertResult and out ~= "" then hs.alert.show(out, 3) end
    end)
  end)
end

bindRun(hk.focusControlRoom, { "focus", "control", "room" }, false)
bindRun(hk.status, { "status", "--speak" }, true)
bindRun(hk.deskReset, { "desk", "reset" }, true)
for name, spec in pairs(hk.desks or {}) do
  bindRun(spec, { "desk", name }, true)
end

if menubar then
  menubar:setMenu(function()
    return {
      { title = "Status", fn = function() crTask({ "status", "--speak" }, function(_, o) hs.alert.show(o, 3) end) end },
      { title = "Focus control room", fn = function() crTask({ "focus", "control", "room" }) end },
      { title = "Bring control room up", fn = function() crTask({ "up", "--revive" }, function(_, o) hs.alert.show(o, 3) end) end },
      { title = "Reset desk", fn = function() crTask({ "desk", "reset" }) end },
      { title = "-" },
      { title = "Reload Hammerspoon", fn = hs.reload },
    }
  end)
end

pcall(dofile, os.getenv("HOME") .. "/.hammerspoon/local.lua")
hs.alert.show("Control room voice ready", 1.5)
