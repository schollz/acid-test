local MM={}

function MM:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self

  o.m=o.m or {{0,0},{0,0}}
  o.vs={}

  o:normalize()
  return o
end

function MM:print()
  for row,m in ipairs(self.m) do
    local ss=""
    for col,v in ipairs(m) do
      ss=ss..v.." "
    end
    print(ss)
  end
end

function MM:normalize()
  for row,m0 in ipairs(self.m) do
    local total=0
    for col,v in ipairs(m0) do
      total=total+v
    end
    for col,_ in ipairs(m0) do
      if total>0 then
        self.m[row][col]=self.m[row][col]/total
      end
    end
  end
end

-- sequence generates a sequence of n numbers
-- from current position
function MM:sequence(n,changes)
  if changes==nil or next(self.vs)==nil or n==changes then
    -- generate from scratch
    local v={}
    local start=math.random(1,#self.m)
    for i=1,n do
      local n=self:nextv(start)
      table.insert(v,n)
      start=n
    end  
    self.vs=v
  else
    -- generate randomly based on current markov chain
    local ordering={}
    local v={}
    local v2={}
    for i,v0 in ipairs(self.vs) do 
      table.insert(ordering,i)
      table.insert(v,v0)
      table.insert(v2,v0)
    end
    table.shuffle(ordering)
    for i_=1,changes do 
      local i=ordering[i_]
      local h=i-1 
      if h<1 then
        h=#v2
      end
      print(v[h])
      v2[i]=self:nextv(v[h])
    end
    self.vs=v2
  end
  local vreturn={}
  for _,v0 in ipairs(self.vs) do 
    table.insert(vreturn,v0)
  end
  return vreturn
end

-- returns next index from current
function MM:nextv(cur)
  local r=math.random()
  if self.m[cur]==nil then
    print("uh oh")
    print("want "..cur)
    self:print()
    return cur 
  end
  for i,v in ipairs(self.m[cur]) do
    if r<=v then
      return i
    end
    r=r-v
  end
end

function MM:dump()
  return {m=self.m,vs=self.vs}
end

function MM:load(m)
  self.m=m.m 
  self.vs=m.vs
end

function MM:draw(x,y,w,h,l)
  xs={x,x+w}
  ys={y,y+h}
  screen.level(l or 15)
  for i,row in ipairs(self.m) do
    x0=util.linlin(0,1,xs[1],xs[2],row[1])
    y0=util.linlin(0,1,ys[1],ys[2],row[2])
    if i>1 then
      screen.line_width((i+3)/3)
      screen.line(x0,y0)
      screen.stroke()
    end
    screen.move(x0,y0)
  end
  for i,row in ipairs(self.m) do
    x0=util.linlin(0,1,xs[1],xs[2],row[1])
    y0=util.linlin(0,1,ys[1],ys[2],row[2])
    screen.circle(x0,y0,(i+3)/2)
    screen.move(x0,y0)
    screen.fill()
  end
end

return MM
