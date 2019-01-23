undef("extract_ensemble")
function extract_ensemble(fnames,varname,opt)
begin
 
 iys      = opt@extent(0)
 iye      = opt@extent(1)
 ixs      = opt@extent(2)
 ixe      = opt@extent(3)
 data_var = new((/opt@nens,opt@ntime/),"float")

 do nf = 0, opt@nens-1
   tsmpF  = addfile(fnames(nf)+".nc","r")
   dimvar = dimsizes(dimsizes(tsmpF->$(varname)$))
   if (dimvar.eq.3) then
     data_var(nf,:)  = dim_avg_n(dim_avg_n(tsmpF->$(varname)$(:,iys:iye,ixs:ixe),2),1)
   else
     iz = opt@izlev
     data_var(nf,:)      = dim_avg_n(dim_avg_n(tsmpF->$(varname)$(:,iz,iys:iye,ixs:ixe),2),1)
   end if
 end do
 return(data_var)
end
