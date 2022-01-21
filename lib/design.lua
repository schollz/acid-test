local Design = {}

function Design:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.base_note = 57
    o.root = o.root or 60
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
            m = {{0.8, 0.2}, {0.9, 0.13}}
        }),
        v = {0, 1}
    }
    o.p.bass_or_lead = {
        m = mm:new({
            m = {{0.6, 0.4}, {0.4, 0.6}}
        }),
        v = {0, 1} -- 0=bass, 1=lead
    }
    o.p.bass_mult = {
        m = mm:new({
            m = {{0.01, 0.9, 0.15}, {0.3, 0.4, 0.3}, {0.01, 0.9, 0.1}}
        }),
        v = {-1, 0, 1}
    }
    o.p.bass_coef = {
        m = mm:new({
            m = {{10, 2, 1}, {15, 2, 1}, {30, 2, 1}}
        }),
        v = {1, 2, 3}
    }
    o.p.lead_mult = {
        m = mm:new({
            m = {{1, 3, 2}, {2, 6, 2}, {2, 3, 1}}
        }),
        v = {-1, 0, 1}
    }
    o.p.lead_coef = {
        m = mm:new({
            m = {{8, 4, 2}, {20, 5, 2}, {50, 2, 2}}
        }),
        v = {1, 2, 3}
    }
    o.p.lead_legato = {
        m = mm:new({
            m = {{5, 30, 0}, {1, 20, 8}, {2, 30, 3}}
        }),
        v = {0, 1, 2} -- rest, new, hold
    }
    o.p.bass_legato = {
        m = mm:new({
            m = {{1, 30, 0}, {1, 20, 20}, {2, 30, 3}}
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
function Design:sequence(n, changes)
    if changes~=nil and changes==0 then
        do return end
    end
    local seqs = {}
    for k, p in pairs(self.p) do
        seqs[k] = p.m:sequence(n)
        for i, ind in ipairs(seqs[k]) do
            seqs[k][i] = self.p[k].v[ind]
        end
    end
    local notes = {}
    local legatos = {}
    local root_choose = {0, -2, -3, 1}
    local root_index = self.root_index -- + root_choose[math.random(1,#root_choose)]
    local last_lead_note = root_index
    local last_bass_note = root_index
    for i = 1, n do
        if seqs["bass_coef"][i] == 3 and seqs["bass_mult"][i] == 1 then
            seqs["bass_coef"][i] = 4
        end
        local note_index = last_bass_note + seqs["bass_coef"][i] * seqs["bass_mult"][i]
        last_bass_note = note_index
        local legato = seqs["bass_legato"][i]
        if seqs["bass_or_lead"][i] == 1 then
            note_index = last_lead_note + seqs["lead_coef"][i] * seqs["lead_mult"][i]
            last_lead_note = note_index
            legato = seqs["lead_legato"][i]
        end
        local note = self.scale[note_index] + (seqs["bass_or_lead"][i] == 1 and 12 or 0)
        table.insert(notes, note)
        table.insert(legatos, legato)
    end
    local seq = {}
    for i = 1, n do
        table.insert(seq, {
            note = notes[i],
            legato = legatos[i],
            accent = seqs["accent"][i] == 1,
            slide = seqs["slide"][i] == 1,
            bass = seqs["bass_or_lead"][i] == 0
        })
    end
    if changes == nil then
        self.seq:settable(seq)
    else
        for i = 1, changes do
            self.seq[math.random(1, #seq)] = seq[i]
        end
    end
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
