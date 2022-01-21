local Design = {}

function Design:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.base_note = 50
    o.root = o.root or 50
    o.scale_type = o.scale_type or "major"
    o.save = {"root", "scale_type", "root_index", "base_note", "points"}

    o.scale = musicutil.generate_scale(o.root % 12, o.scale_type, 12)
    o.root_index = 0
    for i, v in ipairs(o.scale) do
        if v == o.base_note then
            o.root_index = i
        end
    end
    o.points = 0

    o.p = {}
    o.p.slide = {
        m = mm:new({
            m = {{0.8, 0.2}, {0.8, 0.2}}
        }),
        v = {0, 1}
    }
    o.p.mult = {
        m = mm:new({
            m = {{0.5, 0.8, 0.05}, {0.2, 0.6, 0.2}, {0.05, 0.8, 0.15}}
        }),
        v = {-1, 0, 1}
    }
    o.p.coef = {
        m = mm:new({
            m = {{0.6, 0.3, 0.5, 0.5}, {0.7, 0.2, 0.5, 0.6}, {0.8, 0.15, 0.5, 0.6}, {0.8, 0.15, 0.5, 0.6}}
        }),
        v = {1, 2, 4}
    }
    o.p.adj = {
        m = mm:new({
            m = {{0.01, 0.9, 0.09}, {0.01, 0.25, 0.7}, {0.01, 0.7, 0.25}}
        }),
        v = {-7, 0, 7}
    }
    o.p.legato = {
        m = mm:new({
            m = {{0.1, 0.9, 0}, {0.1, 0.6, 0.3}, {0.05, 0.4, 0.3}}
        }),
        v = {0, 1, 2} -- rest, new, hold
    }
    o.p.accent = {
        m = mm:new({
            m = {{0.8, 0.2}, {0.8, 0.2}}
        }),
        v = {0, 1}
    }
    o.note_last = 0

    o.seq = s {{}}
    return o
end

function Design:randomize(amt)
    for k, p in pairs(self.p) do
        local m = p.m.m
        for row, rowv in ipairs(m) do
            for col, v in ipairs(rowv) do
                self.p[k].m.m[row][col] = self.p[k].m.m[row][col] + math.random() * amt
            end
        end
        self.p[k].m:normalize()
    end
end

-- sequence generates a sequence of n numbers
-- from current position 
function Design:sequence(n)
    local seqs = {}
    for k, p in pairs(self.p) do
        seqs[k] = p.m:sequence(n)
        for i, ind in ipairs(seqs[k]) do
            seqs[k][i] = self.p[k].v[ind]
        end
    end
    local notes = {}
    for i = 1, n do
        local note_index = self.root_index + seqs["adj"][i] + seqs["coef"][i] * seqs["mult"][i]
        local note=self.scale[note_index]
        while note > self.base_note+14 do 
            note=note-12 
        end
        while note < self.base_note-4 do 
            note=note+12
        end
        table.insert(notes,note)
    end
    local seq = {}
    for i = 1, n do
        table.insert(seq, {
            note = notes[i],
            legato = seqs["legato"][i],
            accent = seqs["accent"][i] == 1,
            slide = seqs["slide"][i] == 1
        })
    end
    self.seq:settable(seq)
end

function Design:encode()
    local d = {}
    for _, key in ipairs(self.save) do
        d[key] = self[key]
    end
    return json.encode(d)
end

function Design:decode(s)
    local d = json.decode(s)
    if d ~= nil then
        for _, k in ipairs(self.save) do
            self[k] = d[k]
        end
    end
end

function Design:draw(x, y, w, h, l)
    screen.level(l or 3)
    screen.rect(x, y, w, h)
    screen.fill()
    screen.blend_mode(1)
    for _, p in pairs(self.p) do
        p.m:draw(x, y, w, h, 1)
    end
    screen.blend_mode(0)
end

return Design
