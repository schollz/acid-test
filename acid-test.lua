-- acid test v0.1.0
-- generative acid basslines.
--
-- llllllll.co/t/acid-test
--
--
--
--    ▼ instructions below ▼
--
-- K2 modifies current sequence
-- K3 generates new sequence
-- E1 selects markov chain
-- E2 selects transition
-- E3 changes transition probability
-- K1+E1 selects saved sequence
-- K1+K3 loads saved sequence

if not string.find(package.cpath,"/home/we/dust/code/acid-test/lib/") then
  package.cpath=package.cpath..";/home/we/dust/code/acid-test/lib/?.so"
end
json=require("cjson")
lattice_=require("lattice")
s=require("sequins")
mm=include("acid-test/lib/mm")
design=include("acid-test/lib/design")
musicutil=require("musicutil")
hs=include('lib/halfsecond')

engine.name="AcidTest"

note_last=nil
fade_text=""
fade_time=0
shift=false

function init()
  -- setup midi
  midis={}
  midi_devices={"none"}
  midi_default=1
  for i,dev in pairs(midi.devices) do
    local name=string.lower(dev.name)
    if name~="virtual" and midi_default==1 then
      midi_default=i
    end
    name=name:gsub("-","")
    print("connected to "..name)
    table.insert(midi_devices,name)
    table.insert(midis,{
      last_note=nil,
      name=name,
    conn=midi.connect(dev.port)})
  end

  scale_names={}
  for i=1,#musicutil.SCALES do
    table.insert(scale_names,string.lower(musicutil.SCALES[i].name))
  end

  params:add_separator("acid test")
  params:add_group("sequences",6)
  params:add{type="number",id="sequence_length",name="sequence length",min=1,max=256,default=16}
  local evolutions={"none","every beat"}
  for i=2,128 do
    table.insert(evolutions,"every "..i.." beats")
  end
  params:add_option("evolve","evolve",evolutions)
  params:add{type="option",id="scale_mode",name="scale mode",
    options=scale_names,default=1,
  action=function() build_scale() end}
  params:add{type="number",id="root_note",name="root note",
    min=0,max=127,default=60,formatter=function(param) return musicutil.note_num_to_name(param:get(),true) end,
  action=function() build_scale() end}
  params:add{type="number",id="base_note",name="base note",
    min=0,max=127,default=57,formatter=function(param) return musicutil.note_num_to_name(param:get(),true) end,
  action=function() build_scale() end}
  params:add{type="number",id="velocity_spread",name="velocity spread",min=1,max=30,default=5}

  params:add_group("engine",4)
  params:add_option("out_engine","engine output",{"no","yes"},midi_default==1 and 2 or 1)
  params:add{type="control",id="bass vol",name="bass vol",controlspec=controlspec.new(-96,0,'lin',1,(midi_default==1 and-6 or-96),'',1/(96)),formatter=function(v)
    local val=math.floor(util.linlin(0,1,v.controlspec.minval,v.controlspec.maxval,v.raw)*10)/10
    return ((val<0) and "" or "+")..val.." dB"
  end}
  params:add{type="control",id="kick vol",name="kick vol",controlspec=controlspec.new(-96,-12,'lin',1,-96,'',1/(96-12)),formatter=function(v)
    local val=math.floor(util.linlin(0,1,v.controlspec.minval,v.controlspec.maxval,v.raw)*10)/10
    return ((val<0) and "" or "+")..val.." dB"
  end}
  params:add{type="control",id="snare vol",name="snare vol",controlspec=controlspec.new(-96,-12,'lin',1,-96,'',1/(96-12)),formatter=function(v)
    local val=math.floor(util.linlin(0,1,v.controlspec.minval,v.controlspec.maxval,v.raw)*10)/10
    return ((val<0) and "" or "+")..val.." dB"
  end}

  params:add_group("crow/jf",2)
  params:add_option("out_crow","crow output",{"no","yes"})
  params:add_option("out_crow_jf","crow jf output",{"no","yes"})

  params:add_group("midi",3)
  params:add{type="option",id="midi_out_device",name="midi out device",
    options=midi_devices,default=midi_default,action=function(x)
      all_notes_off()
    end
  }
  params:add{type="number",id="midi_out_channel",name="midi out channel",
    min=1,max=16,default=1,action=function(x)
      all_notes_off()
    end
  }
  params:add{type="number",id="midi_portamento_cc",name="midi portamento cc",min=1,max=127,default=5}

  -- initialize lattice
  lattice=lattice_:new()

  local tt=-1
  lattice_pattern=lattice:new_pattern{
    action=function()
      tt=tt+1
      if tt%8==0 then
        engine.acidTest_drum("kick",util.dbamp(params:get("kick vol")),0.0,0.0)
      elseif tt%4==0 then
        engine.acidTest_drum("snare",util.dbamp(params:get("snare vol")),0.0,0.0)
      end
      if params:get("evolve")>1 then
        if tt%(4*params:get("evolve"))==0 then
          designs[i]:sequence(params:get("sequence_length"),1)
        end
      end
      local v=designs[1].seq()
      if next(v)==nil then
        do
          return
        end
      end
      play(1,v,"bass")
    end,
    division=1/16

  }

  clock.run(function()
    while true do
      clock.sleep(1/10)
      redraw()
    end
  end)

  -- setup designs
  designs={}
  for i=1,2 do
    table.insert(designs,design:new())
    designs[i]:sequence(params:get("sequence_length"))
  end

  -- setup saving and loading
  params.action_write=function(filename,name)
    print("write",filename,name)
    local data={}
    for _,d in ipairs(designs) do
      table.insert(data,d:dump())
    end
    local fname=filename..".json"
    local file=io.open(fname,"w+")
    io.output(file)
    io.write(json.encode(data))
    io.close(file)
  end

  params.action_read=function(filename,silent)
    print("read",filename,silent)
    local fname=filename..".json"
    local f=io.open(fname,"rb")
    local content=f:read("*all")
    f:close()
    local data=json.decode(content)
    for i,s in ipairs(data) do
      designs[i]:load(s)
    end
  end

  hs.init()
  all_notes_off()

  redraw()
  lattice:start()

end

function all_notes_off()
  if midis[midi_devices[params:get("midi_out_device")]]==nil then
    do return end
  end
  if midis[midi_devices[params:get("midi_out_device")]].conn~=nil then
    for j=1,127 do
      midis[#midis].conn:note_off(j,nil,params:get("midi_out_channel"))
    end
  end
end

function cleanup()
  for _,m in pairs(midis) do
    for j=1,127 do
      if m.conn~=nil then
        m.conn:note_off(j)
      end
    end
  end
end

function enc(k,d)
  d=d<0 and-1 or 1
  if shift then
    if k==1 then
      designs[1]:sel_mem(d)
      fade_msg("seq "..designs[1].memsel)
    end
  else
    if k==1 then
      designs[1]:selp_delta(d)
    elseif k==2 then
      designs[1]:sel_delta(d)
    elseif k==3 then
      designs[1]:val_delta(d)
    end
  end
end

function key(k,z)
  if k==1 then
    shift=z==1
    do return end
  end
  if shift then
    if k==3 and z==1 then
      designs[1]:load_mem()
      fade_msg("loaded seq "..designs[1].memsel)
    end
  else
    if k==2 and z==1 then
      designs[1]:sequence(params:get("sequence_length"),math.random(1,2))
      fade_msg("seq "..(#designs[1].memory).." mut")
    elseif k==3 and z==1 then
      designs[1]:sequence(params:get("sequence_length"))
      fade_msg("seq "..(#designs[1].memory).." new")
    end
  end
end

function fade_msg(s)
  fade_time=15
  fade_text=s
end

function play(i,v,t)
  local m=midis[midi_devices[params:get("midi_out_device")]]

  local do_note_off=v.legato==0 -- rest
  do_note_off=do_note_off or (v.legato==1) -- new note
  if designs[i].note_last~=nil then
    do_note_off=do_note_off or (v.legato==2 and designs[i].note_last~=v.note) -- changing note, but hold
  end
  if do_note_off then
    do_note_off=designs[i].note_last
  else
    do_note_off=nil
  end

  local velocity=math.random(60-params:get("velocity_spread"),60+params:get("velocity_spread")) -- TODO: make the +5 optional
  if v.accent then
    velocity=velocity+math.random(30-params:get("velocity_spread"),30+params:get("velocity_spread"))
  end
  if m~=nil then
    if v.slide then
      m.conn:cc(params:get("midi_portamento_cc"),20)
    else
      m.conn:cc(params:get("midi_portamento_cc"),0)
    end
  end

  if v.legato==1 or (v.legato==2 and designs[i].note_last~=v.note) then
    -- new note
    -- print("note on: "..v.note)
    -- Audio engine out
    if params:get("out_engine")==2 then
      engine["acidTest_"..t](velocity/127*util.dbamp(params:get("bass vol")),v.note,0.0,0.0,v.slide and clock.get_beat_sec()/4 or 0)
      engine["acidTest_"..t.."_gate"](1)
    end
    if params:get("out_crow")==2 then
      -- add slide
      crow.slew[1]=v.slide and clock.get_beat_sec()/4 or 0 -- TODO figure out how to do crow slew
      crow.output[1].volts=(v.note-60)/12
      crow.output[2].execute()
    end
    if params:get("out_crow_jf")==2 then
      crow.ii.jf.play_note((v.note-60)/12,5)
    end
    if m~=nil then
      m.conn:note_on(v.note,velocity,params:get("midi_out_channel"))
    end
    designs[i].note_last=v.note
  end

  if do_note_off then
    -- rest / new note
    if designs[i].note_last~=nil then
      if params:get("out_engine")==2 then
        engine["acidTest_"..t.."_gate"](0)
      end
      if m~=nil then
        m.conn:note_off(do_note_off,nil,params:get("midi_out_channel"))
      end
      designs[i].note_last=nil
    end
  end

end

function redraw()
  screen.clear()
  for i=1,2 do
    designs[1]:draw_matrix()
  end

  if fade_time>0 then
    fade_time=fade_time-1
    screen.move(2,64-2)
    screen.level(util.clamp(fade_time,0,15))
    screen.text(fade_text)
  end
  screen.update()
end
