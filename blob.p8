pico-8 cartridge // http://www.pico-8.com
version 35
__lua__
-- untitled blob game
-- by cpiod for 7drl22

function _init()
 ents={}
 local b=ent()+cmp("blob",{first=10,last=63,tx=12,ty=12})
 b+=cmp("pos",{x=2,y=7})
 b+=cmp("class",{c=0})
 b+=cmp("render",{char=32})
 add(ents,b)
 add_monster()
 current_blob=b
 update_tiles()
 palt(0,false)
 screen_dx=0
 screen_dy=0
 show_map=false
 cls()
end


-- libs

-- bresenham line algorithm
-- adapted from roguebasin
function los_line(x1, y1, x2, y2, transparent)
 local dx=x2-x1
 local ix=dx>0 and 1 or -1
 local dx=2*abs(dx)

 local dy=y2-y1
 local iy=dy>0 and 1 or -1
 local dy=2*abs(dy)
 
 if(not transparent(x1,y1)) return false
 
 if dx>=dy then
  local error=dy-dx/2
 
  while x1!=x2 do
   if (error>0) or ((error==0) and (ix>0)) then
    error=error-dx
    y1=y1+iy
   end
 
   error=error+dy
   x1=x1+ix
   if(not transparent(x1,y1)) return false
  end
 else
  error=dx-dy/2
 
  while y1!=y2 do
   if (error>0) or ((error==0) and (iy>0)) then
    error=error-dy
    x1=x1+ix
   end
 
   error=error+dx
   y1=y1+iy
   if(not transparent(x1,y1)) return false
  end
 end
 return true
end

--tiny ecs v1.1
--by katrinakitten
--adapted by cpiod

function ent()
 return setmetatable({},{
  __index=function(self,a)
   for k,t in pairs(self) do
    local r=t[a]
    if(r) return r
   end
   return nil
  end,
  __newindex=function(self,a,v)
   for k,t in pairs(self) do
    local r=t[a]
    if(r) t[a]=v return
   end
   printh("not found! "..a)
   assert(false)
  end,
  __add=function(self,cmp)
   assert(cmp._cn)
   rawset(self,cmp._cn,cmp)
   return self
  end,
  __sub=function(self,cn)
   assert(rawget(e,cn)!=nil) -- le composant existait
   self[cn]=nil
   return self
  end
  })
end

function cmp(cn,t)
 t=t or {}
 t._cn=cn
 return t
end

function sys(cns,f)
 return function(ents,...)
  assert(ents)
  for e in all(ents) do
   for cn in all(cns) do
    if(rawget(e,cn)==nil) goto _
   end
   f(e,...)
   ::_::
  end
 end
end
-->8
-- update

function _update()
 update_input()
 player_input()
end

function try_move(x,y,p,pressed,short,long)
 -- wall?
 if(not fget(mget(x,y),0)) return
 e=check_collision(x,y)
 -- collision
 if e then
  if e.blob then
   if pressed or short then
    shake=3
    whoshake={e,current_blob}
    return
   elseif long then
    merge(e)
   else
    assert(false)
   end
  else -- not a blob
   return
  end
 end
 -- successful move
 if short or long then
  screen_dx=(x-p.x)*5
  screen_dy=(y-p.y)*5  
  p.x=x
  p.y=y
  update_tiles()
 end

end

function change_focus()
 local tmp=nil
 local nxt=false
 for e in all(ents) do
  if e.blob!=nil then
   if(tmp==nil) tmp=e
   if(nxt) nxt=false current_blob=e break
   if(e==current_blob) nxt=true
  end
 end
 -- if last of the list
 if(nxt) current_blob=tmp
end

-- todo ameliorer
-- where is the @ on screen ?
update_tx_ty=sys({"blob"},
function(b)
 local c=(b.first+b.last)\2
 local tx,ty=unpack(hilb[c])
 b.tx=tx*3+1
 b.ty=ty*3+1
end)

function split_blob()
 local b=current_blob
 local s=(b.last+b.first)\2
 local b2=ent()
 b2+=cmp("blob",{first=s+1,last=b.last,tx=-1,ty=-1})
 b2+=cmp("class",{c=b.c+1})
 b2+=cmp("pos",{x=b.x+1,y=b.y})
 b2+=cmp("render",{char=b.char})
 add(ents,b2)
 b.last=s
 update_tx_ty(ents)
 update_tiles()
end

function merge(b2)
 local b=current_blob
 bm = b2.first > b.first and b2 or b
 curr_last=min(b2.last,b.last)
 while(bm.first!=curr_last+1) do
  for e in all(ents) do
   -- potentiellement nil
   if e.last==bm.first-1 then
    local tmpl=bm.last
    bm.last=e.first+(bm.last-bm.first)
    bm.first=e.first
    e.first=tmpl-(e.last-e.first)
    e.last=tmpl
    break
   end
  end
 end
 b.first=min(b2.first,b.first)
 b.last=max(b2.last,b.last)
 del(ents,b2)
 update_tx_ty(ents)
 update_tiles()
end
-->8
-- draw

hx=2
hy=2
skip=0
shake=0
whoshake={}

function _draw()
 dithering()
 draw_background_entities()
 if(show_map) draw_map()
end

function draw_map()
 rectfill(20,20,108,108,0)
 for x=0,39 do
  local sx=24+2*x
  for y=0,39 do
   local sy=24+2*y
   m=mget(x,y)
   if m==1 then
    rectfill(sx,sy,sx+1,sy+1,1)
   elseif m==2 then
    rectfill(sx,sy,sx+1,sy+1,6)
			elseif m==4 then
			 fillp(▒-.5)
			 rectfill(sx,sy,sx+1,sy+1,0x16)
			 fillp()
			elseif m==3 then
			 fillp(▒-.5)
			 rectfill(sx,sy,sx+1,sy+1,0x61)
			 fillp()
   end
  end
 end
	fillp(▒-.5)
 for e in all(ents) do
	 local p=rawget(e,"pos")
	 if p then
	 	local c=class_attr[rawget(e,"class").c]
	 	local col=(c.c1<<4)+c.c1
	 	if rawget(e,"blob")==nil then
 	 	col=(c.c1<<4)+c.c2
	 	end
	  local sx=24+2*p.x
	  local sy=24+2*p.y
	  rectfill(sx,sy,sx+1,sy+1,col)
	 end
	end
	fillp()
end

function draw_background_entities()
	if(screen_dx>0) screen_dx-=1
	if(screen_dy>0) screen_dy-=1
	if(screen_dx<0) screen_dx+=1
	if(screen_dy<0) screen_dy+=1
	palt(1,true)
	if(shake>0) shake-=1
	-- tiles
	for x=0,23 do
	 for y=0,23 do
 	 local i=x+24*y
 	 -- tile dead ?
	  if tiles[i]!=nil then
	   local mx=tiles[i].x
	   local my=tiles[i].y
    local m=mget(mx,my)
    if(m!=0) then
	    local sx=hx+5*x
	    local sy=hy+5*y-1
	    if tiles[i].b==current_blob then
	     sx+=screen_dx
	     sy+=screen_dy
	    end
	    if shake>0 then
	     local b=tiles[i].b
      if b==whoshake[1] or b==whoshake[2] then
       sx+=rnd(2)-1
       sy+=rnd(2)-1
      end
					end
					spr(32+m,sx,sy)
	    for e in all(ents) do
	     local p=rawget(e,"pos")
	     if p!=nil and mx==p.x and my==p.y then
						 local ch=rawget(e,"render").char
 	     local col=class_attr[rawget(e,"class").c].c1
  	    pal(6,col)
  	    spr(ch,sx,sy)
  	    pal(6,6)
	     end
	    end
    end
 	 end
	 end
	end
	palt(1,false)
end

function dithering()
-- for x=0,127 do
-- for y=0,127 do
	for i=1,600 do
	 local x=rnd(127)
	 local y=rnd(127)
	 local c=nil
	 local r=1
	 if x<hx or x>=hx+5*24 or y<hy or y>=hy+5*24 then
	  c=0
	 else
	  local tx=(x-hx)\5
	  local ty=(y-hy)\5
	  local t=tiles[tx+ty*24]
	  if t and t.f then
 	  local thres=.2 -- color
 	  local chance=.2
		  -- current blob has bigger frontier
	   if(t.b==current_blob) r=3 thres=.9
	   -- to avoid artifacts
	   if(screen_dx!=0 or screen_dy!=0) chance=.6
	   if rnd()<chance then
				 local colors=class_attr[rawget(t.b,"class").c]
					if rnd()>thres then
		    c=colors.c2
		   else
		    c=colors.c1
		   end
    end
	  elseif t then
	   c=1
	   r=2
	  else
	   c=0
	  end
	 end
  if(c!=nil) circfill(x,y,r,c)
	end
end
-->8
-- components
-- blob: first last tx ty
-- monster: hp
-- pos: x y
-- class: c
-- render: char

-- systems

function check_collision(x,y)
 for e in all(ents) do
  if(e.x==x and e.y==y) return e
 end
end
-->8
-- map generation

-- map values
-- 1: open
-- 2: wall

-- flags:
-- 0: traversable
-- 1: transparent
-->8
-- tiles

-- hilbert/cells init (once)
hilb={[0]={0,0},{0,1},{1,1},{1,0},{2,0},{3,0},{3,1},{2,1},{2,2},{3,2},{3,3},{2,3},{1,3},{1,2},{0,2},{0,3},{0,4},{1,4},{1,5},{0,5},{0,6},{0,7},{1,7},{1,6},{2,6},{2,7},{3,7},{3,6},{3,5},{2,5},{2,4},{3,4},{4,4},{5,4},{5,5},{4,5},{4,6},{4,7},{5,7},{5,6},{6,6},{6,7},{7,7},{7,6},{7,5},{6,5},{6,4},{7,4},{7,3},{7,2},{6,2},{6,3},{5,3},{4,3},{4,2},{5,2},{5,1},{4,1},{4,0},{5,0},{6,0},{6,1},{7,1},{7,0}}
cells={}
tiles={}

for i=0,#hilb do
 local x,y=unpack(hilb[i])
 cells[x+y*8]=i
end

create_tiles=sys({"blob"},
function(b)
 for c=b.first,b.last do
  local cxb,cyb=unpack(hilb[c])
  cx=3*cxb
  cy=3*cyb
  local x=b.x+cx-b.tx
  local y=b.y+cy-b.ty
  local first=b.first
  local last=b.last
  for dx=0,2 do
   for dy=0,2 do
    local i=(cx+dx)+(cy+dy)*24
    local f=is_frontier(first,last,cxb,cyb,dx,dy)
    if(dy!=1) f=f or is_frontier(first,last,cxb,cyb,dx,1)
    if(dx!=1) f=f or is_frontier(first,last,cxb,cyb,1,dy)
    tiles[i]={x=x+dx,y=y+dy,b=b,f=f}
   end
  end
 end
end)

function is_frontier(first,last,cxb,cyb,dx,dy)
 cxb+=dx-1
 cyb+=dy-1
 local n=cells[cxb+cyb*8]
 return n==nil or cxb<0 or cyb<0 or cxb>7 or cyb>7 or n<first or n>last
end

function update_tiles()
 tiles={}
 create_tiles(ents)
end

-->8
-- spawn
class_attr={[0]={c1=10,c2=9},
{c1=8,c2=4},
{c1=11,c2=3},
{c1=14,c2=2},
{c1=12,c2=1}}

-- class:
-- 0: move speed
-- 1: dps
-- 2: range
-- 3: atk speed
-- 4: armor

function add_monster()
 local e=ent()+cmp("monster",{hp=2})
 e+=cmp("pos",{x=5,y=5})
 e+=cmp("class",{c=0})
 e+=cmp("render",{char=e.hp+15})
 add(ents,e)
end
-->8
--input

input={[0]=0,0,0,0,0,0}
short={[0]=false,false,false,false,false,false}
long={[0]=false,false,false,false,false,false}
dir={[0]={-1,0},{1,0},{0,-1},{0,1}}

function update_input()
 for i=0,5 do
  -- should have been consumed
  short[i]=false
  long[i]=false
  if btn(i) then
   if(input[i]>=0) input[i]+=1
   if input[i]==15 then
    long[i]=true
    input[i]=0
   end
  else -- release
   if input[i]>0 then
    short[i]=true
   end
   input[i]=0
  end
 end
end

function player_input()
 if show_map then
  if(short[4]) show_map=false
 else
	 local p=current_blob.pos
	 local x,y=p.x,p.y
	 local move=false
	 for i=0,3 do
	  if short[i] or long[i] or input[i]>0 then
	   x=p.x+dir[i][1]
	   y=p.y+dir[i][2]
	   try_move(x,y,p,input[i]>0,short[i],long[i])
	  end
	 end
	 
	 if(btnp(❎)) change_focus()
	 if(input[4]>3) shake=2 whoshake={current_blob}
	 if(short[4]) show_map=true
	 if long[4] then
	  input[4]=-1
	  if current_blob.last-current_blob.first>4 then
	   split_blob()
	  end
	 end
 end
 
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000060060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000666666000660000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000060060000006600000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000060060000000060066666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000600000666666000006600000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000060060000660000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11011111100111111000111110111111100011111011111110001111100011111000111100000000000000000000000000000000000000000000000000000000
10601111066011110666011106001111066601110600111106660111066601110666011100000000000000000000000000000000000000000000000000000000
06601111100601111006011106060111066011110666011110060111060601110606011100000000000000000000000000000000000000000000000000000000
10601111106011111066011106660111106601110606011110601111066601110666011100000000000000000000000000000000000000000000000000000000
06660111066601110666011110060111066601110666011110601111066601111006011100000000000000000000000000000000000000000000000000000000
10001111100011111000111111101111100011111000111111011111100011111110111100000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000
11011111111111111000111110111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10601111111111110666011106011111110111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06060111110111110666011110601111106011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06001111106011110666011110060111066601110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10660111110111111000111106601111106011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11001111111111111111111110011111110111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888eeeeee888eeeeee888777777888eeeeee888eeeeee888eeeeee888eeeeee888eeeeee888888888ff8ff8888228822888222822888888822888888228888
8888ee888ee88ee88eee88778887788ee888ee88ee8e8ee88ee888ee88ee8eeee88ee888ee88888888ff888ff888222222888222822888882282888888222888
888eee8e8ee8eeee8eee8777778778eeeee8ee8eee8e8ee8eee8eeee8eee8eeee8eeeee8ee88888888ff888ff888282282888222888888228882888888288888
888eee8e8ee8eeee8eee8777888778eeee88ee8eee888ee8eee888ee8eee888ee8eeeee8ee88888888ff888ff888222222888888222888228882888822288888
888eee8e8ee8eeee8eee8777877778eeeee8ee8eeeee8ee8eeeee8ee8eee8e8ee8eeeee8ee88888888ff888ff888822228888228222888882282888222288888
888eee888ee8eee888ee8777888778eee888ee8eeeee8ee8eee888ee8eee888ee8eeeee8ee888888888ff8ff8888828828888228222888888822888222888888
888eeeeeeee8eeeeeeee8777777778eeeeeeee8eeeeeeee8eeeeeeee8eeeeeeee8eeeeeeee888888888888888888888888888888888888888888888888888888
16111611161616111611161611111616161611711c1c111711111611161116161611161116161111161616161171177711c11111111111111111111111111111
16661611166116611661161611111616166617111c1c111711111666161116611661166116161111161616661777111111c11111111111111111111111111111
11161611161616111611161611111616111611711c1c111711111116161116161611161116161111161611161171177711c11111111111111111111111111111
16611166161616661666161616661666166611171ccc11711111166111661616166616661616166616661666111111111ccc1111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1bbb11711cc111111ccc1ccc1c1c1ccc117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11b1171111c1111111c11c1c1c1c1c11111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11b1171111c1111111c11cc11c1c1cc1111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11b1171111c1117111c11c1c1c1c1c11111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11b111711ccc171111c11c1c11cc1ccc117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1166161616661616166617111ccc1171111111661616166616161666111111111cc1111111111111111111111111111111111111111111111111111111111111
1611161616161616161111711c1c11171111161116161616161616111111177711c1111111111111111111111111111111111111111111111111111111111111
1666166616661661166111171c1c11171111166616661666166116611777111111c1111111111111111111111111111111111111111111111111111111111111
1116161616161616161111711c1c11171111111616161616161616111111177711c1111111111111111111111111111111111111111111111111111111111111
1661161616161616166617111ccc1171111116611616161616161666111111111ccc111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ddd1ddd1d111ddd11dd111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11d111d11d111d111d11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11d111d11d111dd11ddd111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11d111d11d111d11111d111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11d11ddd1ddd1ddd1dd1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111161611111ccc11111ccc1ccc11111ee111ee1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111161617771c1c1111111c111c11111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111116111111c1c11111ccc11cc11111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111161617771c1c11711c11111c11111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111161611111ccc17111ccc1ccc11111eee1ee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1111161611111ccc11111ccc1ccc11111ee111ee111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e1e1111161617771c1c1111111c111c11111e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ee11111166611111c1c11111ccc11cc11111e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e1e1111111617771c1c11711c11111c11111e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e1e1111166611111ccc17111ccc1ccc11111eee1ee1111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11ee11ee1eee1e11111116661111161611111ccc1c1c171716161111111111111111111111111111111111111111111111111111111111111111111111111111
1e1e1e111e1e1e1111111161177716161171111c1c1c117116161111111111111111111111111111111111111111111111111111111111111111111111111111
1e1e1e111eee1e11111111611111116117771ccc1ccc177716661111111111111111111111111111111111111111111111111111111111111111111111111111
1e1e1e111e1e1e11111111611777161611711c11111c117111161111111111111111111111111111111111111111111111111111111111111111111111111111
1ee111ee1e1e1eee111116661111161611111ccc111c171716661111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111ddd1ddd1d111ddd11111dd11ddd1ddd1dd111111ddd1111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111d111d11d111d1111111d1d1d111d1d1d1d1111111d1111111111111111111111111111111111111111111111111111111111111111111111111111
1ddd111111d111d11d111dd111111d1d1dd11ddd1d1d111111dd1111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111d111d11d111d1111111d1d1d111d1d1d1d111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111d11ddd1ddd1ddd11111ddd1ddd1d1d1ddd111111d11111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee111116661666161116661166177116661177117111111cc11ccc1c1111111eee1e1e1eee1ee1111111111111111111111111111111111111111111111111
1e11111111611161161116111611171111611117117117771c1c11c11c11111111e11e1e1e111e1e111111111111111111111111111111111111111111111111
1ee1111111611161161116611666171111611117117111111c1c11c11c11111111e11eee1ee11e1e111111111111111111111111111111111111111111111111
1e11111111611161161116111116171111611117111117771c1c11c11c11111111e11e1e1e111e1e111111111111111111111111111111111111111111111111
1e11111111611666166616661661177116661177117111111c1c1ccc1ccc111111e11e1e1eee1e1e111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e1111ee11ee1eee1e11111116661616111116661666161116661166177116661177111116161111111111111111111111111111111111111111111111111111
1e111e1e1e111e1e1e11111116661616177711611161161116111611171111611117111116161111111111111111111111111111111111111111111111111111
1e111e1e1e111eee1e11111116161161111111611161161116611666171111611117111111611111111111111111111111111111111111111111111111111111
1e111e1e1e111e1e1e11111116161616177711611161161116111116171111611117111116161111111111111111111111111111111111111111111111111111
1eee1ee111ee1e1e1eee111116161616111111611666166616661661177116661177117116161111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e1111ee11ee1eee1e11111116661616111116661666161116661166177116661177111116161111111111111111111111111111111111111111111111111111
1e111e1e1e111e1e1e11111116661616177711611161161116111611171111611117111116161111111111111111111111111111111111111111111111111111
1e111e1e1e111eee1e11111116161666111111611161161116611666171111611117111116661111111111111111111111111111111111111111111111111111
1e111e1e1e111e1e1e11111116161116177711611161161116111116171111611117111111161111111111111111111111111111111111111111111111111111
1eee1ee111ee1e1e1eee111116161666111111611666166616661661177116661177117116661111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e1111ee11ee1eee1e111111166611111bbb11bb1bbb1bbb11711666161611111666161611711111111111111111111111111111111111111111111111111111
1e111e1e1e111e1e1e111111166617771bbb1b111b1111b117111666161611111666161611171111111111111111111111111111111111111111111111111111
1e111e1e1e111eee1e111111161611111b1b1b111bb111b117111616116111111616166611171111111111111111111111111111111111111111111111111111
1e111e1e1e111e1e1e111111161617771b1b1b1b1b1111b117111616161611711616111611171111111111111111111111111111111111111111111111111111
1eee1ee111ee1e1e1eee1111161611111b1b1bbb1bbb11b111711616161617111616166611711111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1eee11711666117111111ccc117111111eee1e1e1eee1ee11111111111111111111111111111111111111111111111111111111111111111111111111111
11e11e1117111666117117771c1c1117111111e11e1e1e111e1e1111111111111111111111111111111111111111111111111111111111111111111111111111
11e11ee117111616117111111c1c1117111111e11eee1ee11e1e1111111111111111111111111111111111111111111111111111111111111111111111111111
11e11e1117111616111117771c1c1117111111e11e1e1e111e1e1111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1111711616117111111ccc1171111111e11e1e1eee1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e1111ee11ee1eee1e1111111166161611111616161611111ccc171716161111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e111e1e1e1111111611161617771616161611711c11117116161111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e111eee1e1111111666116111111666116117771ccc177711611111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e111e1e1e111111111616161777161616161171111c117116161111111111111111111111111111111111111111111111111111111111111111
11111eee1ee111ee1e1e1eee11111661161611111616161611111ccc171716161111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e1111ee11ee1eee1e1111111166161611111616161611111ccc1717161611111cc111111111111111111111111111111111111111111111111111111111
11111e111e1e1e111e1e1e1111111611161617771616161611711c1111711616111111c111111111111111111111111111111111111111111111111111111111
11111e111e1e1e111eee1e1111111666166611111666166617771ccc17771666177711c111111111111111111111111111111111111111111111111111111111
11111e111e1e1e111e1e1e111111111611161777161611161171111c11711116111111c111111111111111111111111111111111111111111111111111111111
11111eee1ee111ee1e1e1eee11111661166611111616166611111ccc1717166611111ccc11111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1eee111116661666161116661166177116661177111116661111111111661616166616661666166116661111166616111166166611111eee1e1e1eee
111111e11e111111116111611611161116111711116111171111161617771777161116161616161616111616116111111616161116161616111111e11e1e1e11
111111e11ee11111116111611611166116661711116111171111166111111111161116161661166116611616116111111661161116161661111111e11eee1ee1
111111e11e111111116111611611161111161711116111171111161617771777161116161616161616111616116111111616161116161616111111e11e1e1e11
11111eee1e111111116116661666166616611771166611771171166611111111116611661616161616661616116116661666166616611666111111e11e1e1eee
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111116616161111111111661166166616661666166111111661161611111111111111111111111111111111111111111111111111111111111111111111
11111111161116161171177716111611161616111611161611111616161611111111111111111111111111111111111111111111111111111111111111111111
11111111166611611777111116661611166116611661161611111616116111111111111111111111111111111111111711111111111111111111111111111111
11111111111616161171177711161611161616111611161611111616161611111111111111111111111111111111111771111111111111111111111111111111
11111111166116161111111116611166161616661666161616661666161611111111111111111111111111111111111777111111111111111111111111111111
11111111111111118888811111111111111111111111111111111111111111111111111111111111111111111111111777711111111111111111111111111111
11111111116616168888811111111111111111111111111111111111111111111111111111111111111111111111111771111111111111111111111111111111
11111111161116168888811111111111111111111111111111111111111111111111111111111111111111111111111117111111111111111111111111111111
11111111166616668888811111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111611168888811111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111166116668888811111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1eee11111166161616661616166617111ccc11111eee1e1e1eee1ee11111111111111111111111111111111111111111111111111111111111111111
111111e11e1111111611161616161616161111711c1c111111e11e1e1e111e1e1111111111111111111111111111111111111111111111111111111111111111
111111e11ee111111666166616661661166111171c1c111111e11eee1ee11e1e1111111111111111111111111111111111111111111111111111111111111111
111111e11e1111111116161616161616161111711c1c111111e11e1e1e111e1e1111111111111111111111111111111111111111111111111111111111111111
11111eee1e1111111661161616161616166617111ccc111111e11e1e1eee1e1e1111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888828282228882822882228222888888888888888888888888888888888888888882228222822282228882822282288222822288866688
82888828828282888888828282828828882888828282888888888888888888888888888888888888888888828282828288828828828288288282888288888888
82888828828282288888822282228828882888228282888888888888888888888888888888888888888882228282822288228828822288288222822288822288
82888828828282888888888288828828882888828282888888888888888888888888888888888888888882888282888288828828828288288882828888888888
82228222828282228888888288828288822282228222888888888888888888888888888888888888888882228222888282228288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
0003000301000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0102010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010102010101010101010101010101010101010101020202020202020101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020102010101010101010101010101010101010202020101010101010202020101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020202020201010101010202020201010101010202020202020201010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010102010101030101010201010202010101010101010101010102020202010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010102010101010101020201010102010101010101010101010101010102020201010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101020101010102010101010101010101010101010101010201010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010202010101010101010102010101010101010202010101010101010202010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101020201010101040101010202010101010102020101020101010101010102010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0104010102010101010101010101010101010101010202010101020201010101010102010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010102010101020202020101010101010101010201010101010201010101010102010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010102010101020101020201010101010101020201010101010102010101010102010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101040102010101010101010201010101010101020101010101010102010101010102010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010102010101010101010201010101010101020101010101010102010101010102010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010102010101010101010202010101010102020101010101010102010101010102010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010102010101010101010102010101010202010101010101010202010101010102010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101020101010101010102020202020101010101010101020201010101010201010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101020201010101010101010101010101010101010202020101010101010201010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010201010101010101010101010101010202020201010101010101010201010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010201010102020201010101010101020201010101010101010101010201010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101020201010202010202010101010102020101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101020202020201010102020101010102020101010101010102020101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101020101010101020202020202020202010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
