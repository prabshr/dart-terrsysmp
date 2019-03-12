function debugmessage(pfxmessage,dvar)
 begin
   dmessage = pfxmessage
   do im = 0, dimsizes(dvar)-1
     dmessage = dmessage + " " + im + "," + dvar(im)
   end do
   return(dmessage)
 end

