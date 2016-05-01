fn ReadStr bstream =
(
   local str = ""
   while true do
   (
      str0 = ReadByte bstream #unsigned
	  if str0 == 0 then exit
      str+= bit.intAsChar str0
   )
   str
)
