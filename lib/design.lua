local Design={}

function Design:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self

  o.memory={}
  o.p={}
  o.p.slide={
    m=mm:new({
    m={{0.8,0.2},{0.9,0.13}}}),
  v={0,1}}
  o.p.bass_or_lead={
    m=mm:new({
    m={{0.6,0.4},{0.4,0.6}}}),
    v={0,1} -- 0=bass, 1=lead
  }
  o.p.bass_mult={
    m=mm:new({
    m={{0.01,0.9,0.15},{0.3,0.4,0.3},{0.01,0.9,0.1}}}),
  v={-1,0,1}}
  o.p.bass_coef={
    m=mm:new({
    m={{10,2,1},{15,2,1},{30,2,1}}}),
  v={1,2,3}}
  o.p.lead_mult={
    m=mm:new({
    m={{1,3,2},{2,6,2},{2,3,1}}}),
  v={-1,0,1}}
  o.p.lead_coef={
    m=mm:new({
    m={{8,4,2},{20,5,2},{50,2,2}}}),
  v={1,2,3}}
  o.p.lead_note={
    m=mm:new({
    m={{5,30,0},{1,20,8},{2,30,3}}}),
    v={0,1,2} -- rest, new, hold
  }
  o.p.bass_note={
    m=mm:new({
    m={{1,30,0},{1,20,20},{2,30,3}}}),
    v={0,1,2} -- rest, new, hold
  }
  o.p.accent={
    m=mm:new({
    m={{0.8,0.2},{0.8,0.2}}}),
  v={0,1}}

  o.memsel=1
  o.sels={}
  o.sel=1
  o.selp=1
  for k,_ in pairs(o.p) do
    table.insert(o.sels,k)
  end
  table.sort(o.sels)
  o.note_last=0

  o.seq=s {{}}
  return o
end

function Design:sel_mem(d)
  if next(self.memory)==nil then
    do return end
  end
  print(d)
  self.memsel=util.clamp(self.memsel+d,1,#self.memory)
end

function Design:load_mem(d)
  if next(self.memory)==nil then
    do return end
  end
  if self.memory[self.memsel]==nil then
    do return end
  end
  self.seq:settable(json.decode(self.memory[self.memsel]))
end

function Design:selp_delta(d)
  self.selp=util.clamp(self.selp+d,1,#self.sels)
end

function Design:sel_delta(d)
  local name=self.sels[self.selp]
  self.sel=util.clamp(self.sel+d,1,math.pow(#self.p[name].m.m,2))
end

function Design:val_delta(d)
  local name=self.sels[self.selp]
  if name==nil then
    do return end
  end
  local m=self.p[name].m.m
  local v=self.p[name].v
  local sel=util.clamp(self.sel,1,#m*#m)
  local sels={{1,1},{2,2},{3,3},{1,2},{2,3},{3,2},{2,1},{1,3},{3,1}}
  if #m==2 then
    sels={{1,1},{2,2},{1,2},{2,1}}
  end
  sel=sels[sel]
  self.p[name].m.m[sel[1]][sel[2]]=self.p[name].m.m[sel[1]][sel[2]]*(1+d/10)
  self.p[name].m:normalize()
end

function Design:randomize(amt)
  for k,p in pairs(self.p) do
    local m=p.m.m
    for row,rowv in ipairs(m) do
      for col,v in ipairs(rowv) do
        self.p[k].m.m[row][col]=self.p[k].m.m[row][col]+math.random()*amt
      end
    end
    self.p[k].m:normalize()
  end
end

-- sequence generates a sequence of n numbers
-- from current position
function Design:sequence(n,changes)
  if changes~=nil and changes==0 then
    do return end
  end
  if self.seq.length>1 then
    table.insert(self.memory,json.encode(self.seq.data))
  end

  local scale=musicutil.generate_scale(params:get("root_note")%12,scale_names[params:get("scale_mode")],12)
  local root_index=params:get("root_note")
  for i,v in ipairs(scale) do
    if v==params:get("base_note") then
      root_index=i
    end
  end

  local seqs={}
  for k,p in pairs(self.p) do
    seqs[k]=p.m:sequence(n)
    for i,ind in ipairs(seqs[k]) do
      seqs[k][i]=self.p[k].v[ind]
    end
  end
  local notes={}
  local legatos={}
  local root_choose={0,-2,-3,1}
  local last_lead_note=root_index
  local last_bass_note=root_index
  for i=1,n do
    if seqs["bass_coef"][i]==3 and seqs["bass_mult"][i]==1 then
      seqs["bass_coef"][i]=4
    end
    local note_index=last_bass_note+seqs["bass_coef"][i]*seqs["bass_mult"][i]
    last_bass_note=note_index
    local legato=seqs["bass_note"][i]
    if seqs["bass_or_lead"][i]==1 then
      note_index=last_lead_note+seqs["lead_coef"][i]*seqs["lead_mult"][i]
      last_lead_note=note_index
      legato=seqs["lead_note"][i]
    end
    local note=scale[note_index]+(seqs["bass_or_lead"][i]==1 and 12 or 0)
    table.insert(notes,note)
    table.insert(legatos,legato)
  end
  local seq={}
  for i=1,n do
    table.insert(seq,{
      note=notes[i],
      legato=legatos[i],
      accent=seqs["accent"][i]==1,
      slide=seqs["slide"][i]==1,
      bass=seqs["bass_or_lead"][i]==0
    })
  end
  if changes==nil then
    self.seq:settable(seq)
  else
    for i=1,changes do
      self.seq[math.random(1,#seq)]=seq[i]
    end
  end
end

function Design:dump()
  local d={}
  for name,p in pairs(self.p) do
    d[name]=p.m:dump()
  end
  d["memory"]=self.memory
  return json.encode(d)
end

function Design:load(s)
  local d=json.decode(s)
  if d~=nil then
    for name,_ in pairs(self.p) do
      self.p[name].m:load(d[name])
    end
    self.memory=d["memory"]
  end
end

function Design:draw(x,y,w,h,l)
  screen.level(l or 3)
  screen.rect(x,y,w,h)
  screen.fill()
  screen.blend_mode(1)
  for _,p in pairs(self.p) do
    p.m:draw(x,y,w,h,1)
  end
  screen.blend_mode(0)
end

local pi=3.14159

function Design:draw_matrix()
  screen.aa(1)
  local name=self.sels[self.selp]
  if name==nil then
    do return end
  end
  local m=self.p[name].m.m
  local v={}
  for _,vv in ipairs(self.p[name].v) do
    table.insert(v,vv)
  end
  if name=="bass_note" or name=="lead_note" then
    v={"rest","new","hold"}
  elseif name=="accent" or name=="slide" then
    v={"off","on"}
  elseif name=="bass_or_lead" then
    v={"bass","lead"}
  elseif name=="lead_coef" or name=="bass_coef" then
    for i,vv in ipairs(v) do
      v[i]="+"..vv
    end
  elseif name=="lead_mult" or name=="bass_mult" then
    for i,vv in ipairs(v) do
      v[i]="x"..vv
    end
  end
  name=name:gsub("_"," ")

  local sel=util.clamp(self.sel,1,#m*#m)
  local sels={{1,1},{2,2},{3,3},{1,2},{2,3},{3,2},{2,1},{1,3},{3,1}}
  if #m==2 then
    sels={{1,1},{2,2},{1,2},{2,1}}
  end
  sel=sels[sel]

  if #m==3 then

    screen.level(5)
    screen.font_face(0)
    screen.move(128-1,64-2)
    screen.text_right(name)
    -- all circles
    for i=1,#m do
      local x=36*i-8
      local y=32
      local r=10
      screen.line_width(1)
      screen.level(5)
      screen.move(x+r,y)
      screen.circle(x,y,r)
      screen.fill()
      screen.level(5)
      screen.circle(x,y,r)
      screen.stroke()
    end

    -- med arrows
    for i=1,#m-1 do
      local x=36*i+7
      local y=32
      local r=17
      if i==sel[1] and i+1==sel[2] then
        screen.line_width(3)
      else
        screen.line_width(1)
      end
      screen.level(math.floor(util.linlin(0,1,2,15,m[i][i+1])))
      screen.arc(x,y,r,pi*4.9/4,2*pi-pi/5)
      screen.stroke()
      screen.move(x+r-4,y-10)
      screen.line(x+r-4-6,y-10-1)
      screen.stroke()
      screen.move(x+r-4,y-10)
      screen.line(x+r-4+2,y-10-4)
      screen.stroke()
    end

    -- big arrow
    local x=36*2-8+2
    local y=32+11
    local r=42
    if 1==sel[1] and 3==sel[2] then
      screen.line_width(3)
    else
      screen.line_width(1)
    end
    screen.level(math.floor(util.linlin(0,1,2,15,m[1][3])))
    screen.arc(x,y,r,pi*4.7/4,pi*4.7/4)
    screen.stroke()
    screen.arc(x,y,r,pi*4.7/4,2*pi-pi/5.4)
    screen.stroke()
    screen.move(x+r-8,y-10-15)
    screen.line(x+r-8-6,y-10-15-2)
    screen.stroke()
    screen.move(x+r-8,y-10-15+2)
    screen.line(x+r-8+3,y-10-15-3)
    screen.stroke()

    -- self circles
    for i=1,#m do
      local x=36*i-8-13
      local y=32
      local r=5
      if i==sel[1] and i==sel[2] then
        screen.line_width(3)
      else
        screen.line_width(1)
      end
      screen.level(math.floor(util.linlin(0,1,2,15,m[i][i])))
      screen.arc(x,y,r,pi/3.3,pi*3/1.9)
      screen.stroke()
      screen.move(x-r-2+8,y-r)
      screen.line(x-r-2+6,y-r+3)
      screen.stroke()
      screen.move(x-r-2+8,y-r)
      screen.line(x-r-2+6,y-r+3-6)
      screen.stroke()
    end

    -- med arrows
    for i=1,#m do
      local x=36*i-8
      local y=32
      local r=10
      screen.level(5)
      screen.line_width(1)
      screen.move(x+r,y)
      screen.circle(x,y,r)
      screen.stroke()
    end
    for i=1,#m-1 do
      local x=36*i+7
      local y=32
      local r=17
      if i+1==sel[1] and i==sel[2] then
        screen.line_width(3)
      else
        screen.line_width(1)
      end
      screen.level(math.floor(util.linlin(0,1,2,15,m[i+1][i])))
      screen.arc(x,y,r,pi*4.7/4+pi,1.9*pi-pi/5+pi*1.05)
      screen.stroke()
      screen.move(x-r+5,y+12)
      screen.line(x-r+3,y+12+4)
      screen.stroke()
      screen.move(x-r+5,y+12)
      screen.line(x-r+11,y+11)
      screen.stroke()
    end

    -- big arrow
    local x=36*2-16+2
    local y=32-12
    local r=42
    if 3==sel[1] and 1==sel[2] then
      screen.line_width(3)
    else
      screen.line_width(1)
    end
    screen.level(math.floor(util.linexp(0,1,2,15,m[3][1])))
    screen.arc(x,y,r,pi*4.7/4+pi,pi*0.81)
    screen.stroke()
    screen.move(24,44)
    screen.line(24-3,44+3)
    screen.stroke()
    screen.move(24,44)
    screen.line(24+6,44+3)
    screen.stroke()

    -- -- text
    screen.level(0)
    for i=1,#m do
      local x=36*i-8
      local y=32+2
      local r=10
      screen.move(x,y)
      screen.font_size(8)
      screen.font_face(0)
      screen.text_center(v[i])
    end
  elseif #m==2 then

    screen.level(5)
    screen.font_face(0)
    screen.move(128-1,64-2)
    screen.text_right(name)
    -- all circles
    for _,i in ipairs({1,3}) do
      local x=36*i-8
      local y=32
      local r=10
      screen.line_width(1)
      screen.level(5)
      screen.move(x+r,y)
      screen.circle(x,y,r)
      screen.fill()
      screen.level(5)
      screen.circle(x,y,r)
      screen.stroke()
    end

    -- big arrow
    local x=36*2-8+2
    local y=32+11
    local r=42
    if 1==sel[1] and 2==sel[2] then
      screen.line_width(3)
    else
      screen.line_width(1)
    end
    screen.level(math.floor(util.linlin(0,1,2,15,m[1][2])))
    screen.arc(x,y,r,pi*4.7/4,pi*4.7/4)
    screen.stroke()
    screen.arc(x,y,r,pi*4.7/4,2*pi-pi/5.4)
    screen.stroke()
    screen.move(x+r-8,y-10-15)
    screen.line(x+r-8-6,y-10-15-2)
    screen.stroke()
    screen.move(x+r-8,y-10-15+2)
    screen.line(x+r-8+3,y-10-15-3)
    screen.stroke()

    -- self circles
    for i,j in ipairs({1,3}) do
      local x=36*j-8-13
      local y=32
      local r=5
      if i==sel[1] and i==sel[2] then
        screen.line_width(3)
      else
        screen.line_width(1)
      end
      screen.level(math.floor(util.linlin(0,1,2,15,m[i][i])))
      screen.arc(x,y,r,pi/3.3,pi*3/1.9)
      screen.stroke()
      screen.move(x-r-2+8,y-r)
      screen.line(x-r-2+6,y-r+3)
      screen.stroke()
      screen.move(x-r-2+8,y-r)
      screen.line(x-r-2+6,y-r+3-6)
      screen.stroke()
    end

    -- big arrow
    local x=36*2-16+2
    local y=32-12
    local r=42
    if 2==sel[1] and 1==sel[2] then
      screen.line_width(3)
    else
      screen.line_width(1)
    end
    screen.level(math.floor(util.linlin(0,1,2,15,m[2][1])))
    screen.arc(x,y,r,pi*4.7/4+pi,pi*0.81)
    screen.stroke()
    screen.move(24,44)
    screen.line(24-3,44+3)
    screen.stroke()
    screen.move(24,44)
    screen.line(24+6,44+3)
    screen.stroke()

    -- -- text
    screen.level(0)
    for i,j in ipairs({1,3}) do
      local x=36*j-8
      local y=32+2
      local r=10
      screen.move(x,y)
      screen.font_size(8)
      screen.font_face(0)
      screen.text_center(v[i])
    end
  end

end
return Design
