-- 
--[[
	Author: Lamible
	
	asrc.lua
	Experimental script to extract wav files from asrc files.
	Only tested with the Apollo Justice collection and some files don't work. 
]]

-- Check header
local function getHeader(f)
	local sign = f:read(4)
	if sign == "srcd" then
		-- 0x08 : size?
		f:read(4)
		local size = f:read(4)
		size = string.unpack("<L", size) -- Read a long
		-- 0x0C : format?
		local format = f:read(4)
		-- Lot of unknown data
		-- 0x34 : Loop?
		-- 0x35 : Loop start
		-- 0x39 : Loop end
		f:seek("set", 0x34)
		local t = f:read(9)
		local loop, ls, le = string.unpack("!1<BLL", t)
		f:seek("set", 0x4E)
		-- 0x4E have offset it seems
		local offset = f:read(4)
		offset = string.unpack("<L", offset)
		return {
			size = size,
			format = format,
			offset = offset,
			loop = loop,
			ls = ls,
			le = le
		}
		
	else
		return false
	end
end

local function extract(f, dst, offset, size)
	local fo = io.open(dst, "wb")
	if fo then
		f:seek("set", offset)
		local data = f:read(size)
		fo:write(data)
		fo:close()
	end
end

local function writeTxtp(dst, header, wav)
	local fo = io.open(dst, "wb")
	if fo then
		fo:write(wav)
		if header.loop ~= 0 then
			fo:write(string.format(" #I %d %d", header.ls, header.le))
		end
	end
end
	
local function open(src, dst)
	local f = io.open(src, "rb")
	if f then
		local header = getHeader(f)
		if header then
			extract(f, dst.."/"..src..".wav", header.offset, header.size)
			writeTxtp(dst.."/"..src..".txtp", header, src..".wav")
		end
	end
end

local args = {...}
if #args < 2 then
	print("Usage: asrc.lua <file> <outputDir>")
	print("The output directory have to exists")
	return
end
print(args[1])
open(args[1], args[2])
