-- uhf 
-- v2.0
--
-- your tape transmitted thru 
-- late-night static and
-- broken antenna frequencies
--
-- KEY3: change channel  
-- KEY1 hold: tv guide
-- ENC1: volume
-- ENC2: speed + random
-- ENC3: pitch + random
--
-- change the channel to begin

engine.name = 'Glut'
fileselect = require 'fileselect'
util = require 'util'

chosen_directory = "tape/"
VOICES = 1
shift = 0
channel = 0
screen_dirty = true
dirs = {}
wavs = {}
ps = {"jitter", "size", "density", "spread", "reverb_mix", "reverb_room", "reverb_damp" }

function randomsample()
  -- TODO: smarter scan of audio to check subfolders/etc
  --chosen_directory = dirs[math.random(#dirs)]
  --print("chosen: " .. chosen_directory)
  wavs = util.scandir(_path.audio .. chosen_directory)
  -- keep only .wav files
  local clean_wavs = {}
  for index, data in ipairs(wavs) do
    if string.match(data, ".wav") then
      table.insert(clean_wavs, data)
    end
  end
  --for index, data in ipairs(clean_wavs) do
    --print(data)
  --end
  samp = _path.audio .. chosen_directory .. clean_wavs[math.random(#clean_wavs)]
  return (samp)
end

function audio_folders()
  dirs = util.scandir(_path.audio)
  for index, data in ipairs(dirs) do
    print(data)
  end
  --chosen_directory = (dirs[math.random(#dirs)])
end

function randomparams()
  params:set("speed", math.random(-200,200))
  params:set("jitter", math.random(0,500))
  params:set("size", math.random(1,500))
  params:set("density", math.random(0,512))
  params:set("pitch", math.random(-24,0))
  params:set("spread", math.random(0,100))
  params:set("reverb_mix", math.random(0,100))
  params:set("reverb_room", math.random(0,100))
  params:set("reverb_damp", math.random(0,100))
end

function init()
  audio_folders()
  local SCREEN_FRAMERATE = 15
  local screen_refresh_metro = metro.init()
  screen_refresh_metro.event = function()
    if screen_dirty then
      screen_dirty = false
      redraw()
    end
  end
  screen_refresh_metro:start(1 / SCREEN_FRAMERATE)
  
  local sep = ": "

  params:add_taper("reverb_mix", "*"..sep.."mix", 0, 100, 50, 0, "%")
  params:set_action("reverb_mix", function(value) engine.reverb_mix(value / 100) end)

  params:add_taper("reverb_room", "*"..sep.."room", 0, 100, 50, 0, "%")
  params:set_action("reverb_room", function(value) engine.reverb_room(value / 100) end)

  params:add_taper("reverb_damp", "*"..sep.."damp", 0, 100, 50, 0, "%")
  params:set_action("reverb_damp", function(value) engine.reverb_damp(value / 100) end)
  
  params:add_separator()

  params:add_file("sample", sep.."sample")
  params:set_action("sample", function(file) engine.read(1, file) end)

  params:add_taper("volume", sep.."volume", -60, 20, 0, 0, "dB")
  params:set_action("volume", function(value) engine.volume(1, math.pow(10, value / 20)) end)

  params:add_taper("speed", sep.."speed", -200, 200, 100, 0, "%")
  params:set_action("speed", function(value) engine.speed(1, value / 100) end)

  params:add_taper("jitter", sep.."jitter", 0, 500, 0, 5, "ms")
  params:set_action("jitter", function(value) engine.jitter(1, value / 1000) end)

  params:add_taper("size", sep.."size", 1, 500, 100, 5, "ms")
  params:set_action("size", function(value) engine.size(1, value / 1000) end)

  params:add_taper("density", sep.."density", 0, 512, 20, 6, "hz")
  params:set_action("density", function(value) engine.density(1, value) end)

  params:add_taper("pitch", sep.."pitch", -24, 24, 0, 0, "st")
  params:set_action("pitch", function(value) engine.pitch(1, math.pow(0.5, -value / 12)) end)

  params:add_taper("spread", sep.."spread", 0, 100, 0, 0, "%")
  params:set_action("spread", function(value) engine.spread(1, value / 100) end)

  params:add_taper("fade", sep.."att / dec", 1, 9000, 1000, 3, "ms")
  params:set_action("fade", function(value) engine.envscale(1, value / 1000) end)

  params:bang()
end

function reset_voice()
  engine.seek(1, 0)
end

function start_voice()
  engine.gate(1, 1)
end

function enc(n, d)
  if n == 1 then
    params:delta("volume", d)
  elseif n == 2 then
    params:delta("speed", d)
    params:delta((ps[math.random(#ps)]), d)
    screen_dirty = true
  elseif n == 3 then
    params:delta("pitch", d)
    params:delta((ps[math.random(#ps)]), d)
    screen_dirty = true
  end
end

function key(n, z)
  if n == 1 then
    shift = z
    screen_dirty = true
  elseif n == 2 then
    if z == 1 then
    else
      --previous channel TODO
      --channel = channel - 1
      --screen_dirty = true
    end
  elseif n == 3 then
    if z == 1 then
    else
      channel = channel + 1
      reset_voice()
      params:set("sample", randomsample())
      randomparams()
      start_voice()
      screen_dirty = true
    end
  end
end

function printround(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function drawtv()
  --random screen pixels
  local heighta = math.random(1,30)
  local heightb = math.random(31,64)
  for x=1,heighta do
    for i=1,128 do
      screen.level(math.random(0, 4))
      screen.rect(i,x,1,1)
      screen.fill()
    end
  end
  for x=heighta+1,heightb-1 do
    for i=1,128 do
      screen.level(math.random(0, 6))
      screen.rect(i,x,1,1)
      screen.fill()
    end
  end
  for x=heightb,64 do
    for i=1,128 do
      screen.level(math.random(0, 10))
      screen.rect(i,x,1,1)
      screen.fill()
    end
  end
end

function cleanfilename()
  return(string.gsub(params:get("sample"), "home/we/dust/audio/", ""))
end

function guidetext(parameter, measure)
  return(parameter .. ": " .. printround(params:get("1"..parameter), 1) .. measure)
end

function redraw()
  screen.clear()
  screen.aa(1)
  screen.line_width(1.0)
  
  if shift == 0 then
    drawtv()
  else 
    -- tv guide
    screen.level(2)
    screen.rect(0,0,128,30)
    screen.fill()
    screen.level(3)
    screen.rect(0,30,128,42)
    screen.fill()
    screen.level(4)
    screen.rect(0,43,128,21)
    screen.fill()
    screen.font_face(1)
    screen.font_size(8)
    screen.move(3, 10)
    screen.level(0)
    screen.text(cleanfilename())
    screen.move(2, 8)
    screen.level(13)
    screen.text(cleanfilename())
    -- glitch title
    screen.move(35, 28)
    screen.level(1)
    screen.text(cleanfilename())
    screen.move(55, 52)
    screen.level(3)
    screen.text(cleanfilename())
    
    screen.level(0)
    screen.move(3, 18)
    screen.text(guidetext("speed", "%"))
    screen.level(13)
    screen.move(2, 16)
    screen.text(guidetext("speed", "%"))
    screen.level(0)
    screen.move(3, 26)
    screen.text(guidetext("jitter", "ms"))
    screen.level(13)
    screen.move(2, 24)
    screen.text(guidetext("jitter", "ms"))
    screen.level(1)
    screen.move(3, 34)
    screen.text(guidetext("size", "ms"))
    screen.level(14)
    screen.move(2, 32)
    screen.text(guidetext("size", "ms"))
    screen.level(2)
    screen.move(3, 42)
    screen.text(guidetext("density", "hz"))
    screen.level(15)
    screen.move(2, 40)
    screen.text(guidetext("density", "hz"))
    screen.level(2)
    screen.move(3, 50)
    screen.text(guidetext("pitch", "st"))
    screen.level(15)
    screen.move(2, 48)
    screen.text(guidetext("pitch", "st"))
    screen.level(2)
    screen.move(3,58)
    screen.text(guidetext("spread", "%"))
    screen.level(15)
    screen.move(2,56)
    screen.text(guidetext("spread", "%"))
  end

  -- channel number
  screen.level(0)
  screen.rect(109,6,18,16)
  screen.fill()
  screen.level(2)
  screen.rect(108,4,18,16)
  screen.fill()
  screen.font_face(3)
  screen.font_size(12)
  screen.move(111,17)
  screen.level(0)
  screen.text(channel)
  screen.move(110,15)
  screen.level(15)
  screen.text(channel)
  
  screen.update()
end
