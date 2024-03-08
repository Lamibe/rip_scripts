-- 
--[[
	Author: Lamible
	
	asrc.lua
	Experimental script to extract wav files from asrc files.
	Only tested with the Apollo Justice collection and some files may not work.
	
	This script is broken. It expect to be run with the directory of the file as the working directory and the destination have to exists
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
		-- 0x3C : Number of unknown 8-byte chunks(in the form 0xFFFFFFFF . unknown increasing long)
		t = f:read(4)
		local nbUnk = string.unpack("L", t)
		f:seek("cur", nbUnk * 8 + 0xD)
		-- 0xD bytes after this we have the offset
		local offset = f:read(4)
		offset = string.unpack("<L", offset)
		-- Followed by size of the WAV header? Not needed
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
