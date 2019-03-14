;======================================================
; Relationship between the spread(s.d.^2) of the ensemble and
; the ensemble mean square error (MSE) to assess the DART performance
; 
; Prabhakar Shrestha
; E-mail: pshrestha@uni-bonn.de
;=======================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

function sprdError(sprd,mse,mae,iz,opt)
 begin
   if (opt.eq.0) then
     rat  = dim_avg_n(sprd(:,:,iz),0)/dim_avg_n(mse(:,:,iz),0)
   else if (opt.eq.1) then
     rat  = dim_avg_n(mae(:,:,iz),0)
   end if
   end if
   return(rat)
 end

begin

;------------------------------------------------------------------------------
;USER SETTINGS
;------------------------------------------------------------------------------

 diri      = "../nc_stat_data/"
 expN      = (/"WCDA_cos", "WCDA_clm","WCDA_pfl","OL"/)
 color     = (/"red","green","steel blue","grey37"/)
 vars      = (/"txx_cos","qvx_cos","swx_pfl", "tso_clm"/)
 scales    = (/1.0, 1000., 1., 1./)
 offsets   = (/273.15, 0., 0., 273.15/)

 ;; var_id  = 0
 alev      = 0    ;level for atmospheric field
 pltyp     = "x11"
;------------------------------------------------------------------------------
;USER SETTINGS END
;------------------------------------------------------------------------------

 varnm     = vars(var_id)
 scale     = scales(var_id)
 offset    = offsets(var_id)
 
 nc_fil1   = addfile(diri+expN(0)+"_"+varnm+".nc","r")
 nc_fil2   = addfile(diri+expN(1)+"_"+varnm+".nc","r")
 nc_fil3   = addfile(diri+expN(2)+"_"+varnm+".nc","r")
 nc_fil4   = addfile(diri+expN(3)+"_"+varnm+".nc","r")

 varread  = "ens"
 ens_01   = nc_fil1->$(varread)$
 ens_02   = nc_fil2->$(varread)$
 ens_03   = nc_fil3->$(varread)$
 ens_04   = nc_fil4->$(varread)$

 varread  = "obs"
 obs_01   = nc_fil1->$(varread)$
 obs_02   = nc_fil2->$(varread)$
 obs_03   = nc_fil3->$(varread)$
 obs_04   = nc_fil4->$(varread)$

 nc_fil1   = addfile(diri+"statistics_"+expN(0)+"_"+varnm+".nc","r")
 nc_fil2   = addfile(diri+"statistics_"+expN(1)+"_"+varnm+".nc","r")
 nc_fil3   = addfile(diri+"statistics_"+expN(2)+"_"+varnm+".nc","r")
 nc_fil4   = addfile(diri+"statistics_"+expN(3)+"_"+varnm+".nc","r")

 varread  = "MAE"
 mae_01   = nc_fil1->$(varread)$
 mae_02   = nc_fil2->$(varread)$
 mae_03   = nc_fil3->$(varread)$
 mae_04   = nc_fil4->$(varread)$

 varread  = "MSE"
 mse_01   = nc_fil1->$(varread)$
 mse_02   = nc_fil2->$(varread)$ 
 mse_03   = nc_fil3->$(varread)$
 mse_04   = nc_fil4->$(varread)$

 varread  = "ESPRD"
 sprd_01   = nc_fil1->$(varread)$
 sprd_02   = nc_fil2->$(varread)$
 sprd_03   = nc_fil3->$(varread)$
 sprd_04   = nc_fil4->$(varread)$
 
 hhl       = nc_fil1->hhl

;PLOT
;------------------------------------------------------------------------------
 fncps   = "~F21~"
 fncps_no = 21
 fncps_hgt = 0.032

 wks = gsn_open_wks(pltyp,"Figure_spreadError"+"_" + varnm)

 res                                     = True

 ;gsn Resources
 ;------------------------
 res@gsnDraw                             = False
 res@gsnFrame                            = False
 res@gsnLeftStringFontHeightF            = fncps_hgt
 res@gsnRightStringFontHeightF            = fncps_hgt
 res@gsnMaximize                         = True
 res@gsnLeftString                       = varnm

 ;tm Resources
 ;------------------------
 res@tmXBLabelFont                       = fncps_no
 res@tmYLLabelFont                       = fncps_no
 res@tmYLLabelFontHeightF                = fncps_hgt
 res@tmXBLabelFontHeightF                = fncps_hgt
 res@tmYROn                              = False
 res@tmXTOn                              = False
 res@tmXBMode                            = "Manual"
 ;res@tmXBTickStartF                      = 0.
 ;res@tmXBTickSpacingF                    = 10.
 res@tmLabelAutoStride                   = True

 ;ti Resources
 ;------------------------
 res@tiXAxisFontHeightF                  = fncps_hgt
 res@tiYAxisFontHeightF                  = fncps_hgt
 res@tiXAxisString                      = "Time (Days)"
 ;res@tiYAxisString                      = varstring ;"~F33~q~F21~~B~v~N~ (K)"

 ;vp Resources
 ;------------------------
 res@vpYF                                = 0.1
 res@vpWidthF                            = 0.9
 res@vpHeightF                           = 0.35

 ;xy Resources
 ;------------------------
 res@xyLineColors                       = color ;"grey"
 res@xyLineThicknessF                   = 4.
 res@xyMarkLineMode                     = "Lines"

 ;tr Resources
 ;------------------------
 ;res@trYMaxF = 2.5

; ncycle = 70
; nstart = 20
; time   = ispan(0,ncycle-1,1) + nstart 
 tempstr = str_split(varnm,"_")
 if (tempstr(1).eq."clm") then
   ntime =  8
 else
   ntime  = 9
 end if
 time        = ispan(0,ntime-1,1)
 rat_xx      = new((/4,ntime/),"float")

 opt = 1
 rat_xx(0,:) = sprdError(sprd_01,mse_01,mae_01,alev,opt)
 rat_xx(1,:) = sprdError(sprd_02,mse_02,mae_02,alev,opt)
 rat_xx(2,:) = sprdError(sprd_03,mse_03,mae_03,alev,opt)
 rat_xx(3,:) = sprdError(sprd_04,mse_04,mae_04,alev,opt) 

 plot = gsn_csm_xy(wks,time,rat_xx,res)

; delete(res@xyLineColors)
; res@xyLineColor = "black"
; dum  = gsn_csm_xy(wks,time,obs_01(:,tday,alev),res)
; overlay(plot,dum)
 draw(plot)
 frame(wks)

 ;
end
