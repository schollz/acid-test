local MM={}

function MM:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self

  o.m=o.m or {{0,0},{0,0}}
  o.save={"m"}

  o:normalize()
  return o
end

function MM:print()
    for row,m in ipairs(self.m) do
        local s=""
        for col,v in ipairs(m) do
            s=s..v.." "
        end
        print(s)
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
function MM:sequence(start,n)
    local v={}
    for i=1,n do 
        if i>1 then
            start=v[i-1]
        end
        table.insert(v,self:next(start))
    end
    return v
end

-- returns next index from current
function MM:next(cur)
    local r=math.random()
    for i,v in ipairs(self.m[cur]) do
        if r<=v then
            return i 
        end
        r=r-v
    end
end


function MM:encode()
  local d={}
  for _,key in ipairs(self.save) do
    d[key]=self[key]
  end
  d.ptn=self:dump_patterns()
  return json.encode(d)
end

function MM:decode(s)
  local d=json.decode(s)
  if d~=nil then
    for _,k in ipairs(self.save) do
      self[k]=d[k]
    end
  end
end

return MM
