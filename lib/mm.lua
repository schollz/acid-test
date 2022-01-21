local MM = {}

function MM:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.m = o.m or {{0, 0}, {0, 0}}
    o.save = {"m"}

    o:normalize()
    return o
end

function MM:print()
    for row, m in ipairs(self.m) do
        local ss = ""
        for col, v in ipairs(m) do
            ss = ss .. v .. " "
        end
        print(ss)
    end
end

function MM:normalize()
    for row, m0 in ipairs(self.m) do
        local total = 0
        for col, v in ipairs(m0) do
            total = total + v
        end
        for col, _ in ipairs(m0) do
            if total > 0 then
                self.m[row][col] = self.m[row][col] / total
            end
        end
    end
end

-- sequence generates a sequence of n numbers
-- from current position 
function MM:sequence(n, start)
    if start == nil then
        start = 0
        for i, _ in ipairs(self.m) do
            start = start + self:next(i)
        end
        start = math.floor(util.round(start / #self.m))
    end
    local v = {}
    for i = 1, n do
        if i > 1 then
            start = v[i - 1]
        end
        table.insert(v, self:next(start))
    end
    return v
end

-- returns next index from current
function MM:next(cur)
    local r = math.random()
    for i, v in ipairs(self.m[cur]) do
        if r <= v then
            return i
        end
        r = r - v
    end
end

function MM:encode()
    local d = {}
    for _, key in ipairs(self.save) do
        d[key] = self[key]
    end
    d.ptn = self:dump_patterns()
    return json.encode(d)
end

function MM:decode(s)
    local d = json.decode(s)
    if d ~= nil then
        for _, k in ipairs(self.save) do
            self[k] = d[k]
        end
    end
end

function MM:draw(x, y, w, h, l)
    xs = {x, x + w}
    ys = {y, y + h}
    screen.level(l or 15)
    for i, row in ipairs(self.m) do
        x0 = util.linlin(0, 1, xs[1], xs[2], row[1])
        y0 = util.linlin(0, 1, ys[1], ys[2], row[2])
        if i > 1 then
            screen.line_width((i + 3) /3)
            screen.line(x0, y0)
            screen.stroke()
        end
        screen.move(x0, y0)
    end
    for i, row in ipairs(self.m) do
        x0 = util.linlin(0, 1, xs[1], xs[2], row[1])
        y0 = util.linlin(0, 1, ys[1], ys[2], row[2])
        screen.circle(x0, y0, (i + 3) / 2)
        screen.move(x0, y0)
        screen.fill()
    end
end

return MM
