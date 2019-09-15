pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

function _init() title_init() end

--> 8
-- scenes
-- main game loop


function title_init()
    g_time = 0
    _update60 = title_update
    _draw = title_draw
    
end
function title_update()
    g_time+=1
    if (btn(4) and btn(5)) maingame_init()
end
function title_draw()
    cls()
    coprint(cor("press keys to start"), 58,80,7,5)
end

room = {x = 1, y = 0}
iscoll = false
isready = true

function maingame_init()
    _update60 = maingame_update
    _draw = maingame_draw
    player:init()
    load_room(room.x, room.y)
    g_time = 0
end

function maingame_update()
    g_time+=1
    player:update()
    if (isready and btnp(4)) then
        console_init()
    end
end

function maingame_draw()
    -- layersort down -> top
    cls()
    map(room.x*16, room.y*16, 0, 0, 16, 16)
    --sspr(8*8, 0, 2*8, 2*8, 40, 40) -- show machine
    player:draw()
    --oprint(tile_flag_at(flr(player.x / 8), flr(player.y / 8), 1), 58,70,7,5)
    coprint(cor("helloworld!"), 58,80,7,5)
    --print("x "..player.x, 40, 90, 7, 5)
    --print("y "..player.y, 70, 90, 7, 5)
    --print(#objects, 58, 120, 7, 5)
    --print(iscoll, 78, 120, 7, 5)
    --print("tile(x) "..flr(player.x / 8), 20, 100, 7, 5)
    --print("tile(y) "..flr(player.y / 8), 70, 100, 7, 5)
    --print(player.dir, 58, 110, 7, 5)  
end

isdone = false
command_str = ""

function console_init()
    next_x = 2
    next_y = 2
    _update60 = console_update
    _draw = console_draw
    title_str = {"mICROSOFT wINDOWS [10.0.18.295]",
    "(c) 2019 mICROSOFT cORPORATIOIN. cOPY rIGHT.",
    ""}
end

command_list = {
    "cd ..",
    "top",
    "ipconfig",
    "exit",
}
command_index = 1
function console_update()
    if (btnp(2)) then
        command_index += 1
        if (command_index > #command_list) then
            command_index = 1
        end
        command_str = command_list[command_index]
    elseif (btnp(3)) then
        command_index -= 1
        if (command_index < 1) then
            command_index = #command_list
        end
        command_str = command_list[command_index]
    end

    if (command_index == 4 and btnp(4)) then
        maingame_init()
    end

end

function console_draw()
    cls()
    console_print(title_str, start_x, start_y)
    if (command_str ~= "") then 
        command_draw("c:\\uSERS\\gAMEsHELL>"..command_str, next_x, next_y)
    else
        command_draw("c:\\uSERS\\gAMEsHELL>", next_x, next_y)
    end
end

start_x = 2
start_y = 2

function command_draw(str, x, y)
    print(str, x, y, 12)
end

function console_print(str , x, y)
    local temp_x, temp_y = x, y
    for i=1, #str do
        print(str[i], temp_x, temp_y, 7)
        temp_y += 10
    end
    next_x, next_y = temp_x, temp_y
end

--> 8
-- player entity

player = {}

function player:init(x, y)
    self.x = x or 20
    self.y = y or 20
    --self.obj = object_init("player", x, y)
    self.spr = 64
    self.speed = 0.5
    self.dir = "r" 
end

function player:update()
    local x = self.x
    local y = self.y

    if (btn(2)) then 
        self.dir = "u"
        y -= self.speed
    elseif (btn(3)) then 
        self.dir = "d"
        y += self.speed
    elseif (btn(0)) then 
        self.dir = "l"
        x -= self.speed
    elseif (btn(1)) then 
        self.dir = "r"
        x += self.speed
    end
    -- need x, y (sprite left-top) to map tile 'x', 'y'
    -- left-top -> right and down need + 1

    -- only one point
    -- todo: collision area
    iscoll = false
    local other
    for i = 1, #objects do
        other = objects[i]
        if (other ~= nil and other != self.obj and
            other.x+other.hitbox.x+other.hitbox.w > x and
            other.y+other.hitbox.y+other.hitbox.h > y and
            other.x+other.hitbox.x < x+8 and
            other.y+other.hitbox.y < y+8) then
            iscoll = true
        end
    end
    if (not iscoll) then
        self.x = x
        self.y = y
    end

    -- load scene
    if (self.x >= 120) then
        --isright = true
        load_room(room.x+1, room.y)
        self:init(0, self.y)
    elseif (self.x < 0) then
        load_room(room.x-1, room.y)
        self:init(120, self.y)
    elseif (self.y >= 120) then
        load_room(room.x, room.y+1)
        self:init(self.x, 0)
    elseif (self.y < 0) then
        load_room(room.x, room.y-1)
        self:init(self.x, 120)
    end

end

function player:draw()
    spr(self.spr, self.x, self.y)
end
--> 8
-- system

-- collision

function tile_flag_at(x,y,flag)
    if fget(tile_at(x, y), flag) then
        return true
    end
	return false
end

function tile_at(x, y)
    -- todo: motify each room
    size={x=16,y=16}
    return mget(room.x*size.x + x, room.y*size.y + y)
end

--> 8
-- entity

types = {}

objects = {}

-- object type, object position(t-l)
function object_init(type, x, y)
    local obj = {}
    obj.x = x
    obj.y = y
    -- default top-left 8x8
    obj.hitbox = {x=0, y=0, w=8, h=8}

    -- collide with type obj or not
    obj.collide = function(type, x, y)
        local other

        for i = 1, #objects do
            other = objects[i]
            if (other ~= nil and other != obj and
             other.x+other.hitbox.x+other.hitbox.w > obj.x+obj.hitbox.x+ox and
             other.y+other.hitbox.y+other.hitbox.h > obj.y+obj.hitbox.y+oy and
             other.x+other.hitbox.x < obj.x+obj.hitbox.x+obj.hitbox.w+ox and
             other.y+other.hitbox.y < obj.y+obj.hitbox.y+obj.hitbox.h+oy) then
                return other
            end
        end
        return nil
    end
    add(objects, obj)
end

-- room
function load_room(x, y)
    for obj in all(objects) do
        del(objects, obj)
    end

    room.x = x
    room.y = y
    -- only do init scene and save scene data
    -- todo: for-loop each tile object in objects{}
    
    -- full screen (or half
    for i = 0, 15 do 
        for j = 0, 15 do
            local tile = mget(room.x*16+i, room.y*16+j)
            if tile_flag_at(i, j, 1) then
                object_init("wall", i*8, j*8)
            end
        end
    end
    -- map(room.x*16, room.y*16, 0, 0, 16, 8)
end

--> 8
-- helper

function oprint(s, x, y, c, o)
    print(s, x-1, y, o)
    print(s, x+1, y, o)
    print(s, x, y-1, o)
    print(s, x, y+1, o)
    print(s, x, y, c)
end

local chrs="avddakljkleauip12u9089$#u)*($#"

function cor(s)
    local i=(flr(g_time/3))%#s+1
    local id=flr(g_time/5)%#chrs+1
    local c=sub(chrs,id,id)
    s=sub(s,1,i-1)..c..sub(s,i+1,#s)
    
    return s
end

function coprint(s,y,c,o)
    oprint(s,64-#s*2,y,o or 0,c or 7)
end

__gfx__
00000000333332330101010100000000010101010000000000000000000000000000777777777000000000000000000000000000000000000000000000000000
00000000555552351010101200000000201010100000000000000000000000000007077777770700000000000000000000000000000000000000000000000000
00700700535552550101010200000000210101010000000000000000000000000007070000070700000000000000000000000000000000000000000000000000
00077000222222221010101200011000201010100000000000000000000000000007077777770700000000000000000000000000000000000000000000000000
00077000332333330101010200100010210101010000000000000000000000000007000077770700000000000000000000000000000000000000000000000000
00700700552355551010101200011000201010100000000000000000000000000007077777770700000000000000000000000000000000000000000000000000
00000000552555350101010200000000210101010000000000000000000000000007070000070700000000000000000000000000000000000000000000000000
00000000222222221010101200000000201010100000000000000000000000000007077777770700000000000000000000000000000000000000000000000000
00000000000000000101010201010101210101010222222222222220000000000007000000000700000000000000000000000000000000000000000000000000
00000000000000001010101210101010201010102010101010101012000000000007077707770700000000000000000000000000000000000000000000000000
00000000000000000101010201010101210101012101010101010102000000000007007000700700000000000000000000000000000000000000000000000000
00000000000000001010101210101010201010102010101010101012000000000007000000000700000000000000000000000000000000000000000000000000
00000000000000000101010201010101210101012101010101010102000000000007777777707700000000000000000000000000000000000000000000000000
00000000000000001010101210101010201010102010101010101012000000000007770000777700000000000000000000000000000000000000000000000000
00000000000000000101010201010101210101012101010101010102000000000007770000777700000000000000000000000000000000000000000000000000
00000000000000001010101210101010201010102010101010101012000000000007770007077700000000000000000000000000000000000000000000000000
00000000000000000000000055555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000001010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000001010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000001010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666660006666600066666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06666666066666660666666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
066ffff6066ffff6066ffff600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06f0ff0606f0ff0606f0ff0600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06fffff006fffff006fffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00222200002222000022220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007000700700070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000020002000000000000000000000000000202020202000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1313131313131313131313131313131313131313131313131313131313131313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1312010101010101010101141313131312010101010101010101010101141313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1312000000000000000000141313131312c00000000000000000000000141313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
131200000000030000000001010101010100c0c0000000000000000000141313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
13120000030000030000000000c0c0c0c0c0c000000000000000000000141313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1312000000000000000003152323232316c00000000000000000000000141313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1313232323232323232323131313131312000000000000000000000000141313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1313131313131313131313131313131313232323232323160000001523131313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1313131313131313131313131313131313131313131313120000001413131313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1313131313131313131313131313131302010101010101010000000101141313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1201010101010101010101010101010101000000000000000000000000141313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000000000000000000000000000000000141313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000000000000000000000000000000000141313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1316000000000000000000000000000000000000000000000000000000141313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1312000000030000030000000000000000000000000000000000000000141313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1313232323231603001523232323232323232323232323232323232323131313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1313131313131200001413131313131313131313131313131313131313131313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1201010101010100000101010101010101010101010101010101010101141313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000000000000000000000000000000000141313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000000000000000000000000000000000141313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000000000000000000000000000000000141313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000000000000000000000000000000000141313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000000000000000000000000000000015131313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000000000000000000000000000000014131313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000000000000000000000000000000014131313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000000000000000000000000000000014131313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000000000000000000000000000000014131313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000000000000000000000000000000014131313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000000000000000000000000000000001011413131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1200000000000000000000000000000000000000000000000000000000001413131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1323232323232323232323232323232323232323232323232323232323231313131313131300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
