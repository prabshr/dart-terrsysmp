;======================================================
; Vertical Profile of time averaged response
; we do not plot the last time as it is contained in the
; next cycle data for COSMO and ParFlow
; for plotting CLM data, care should be taken because the
; ouput does not start from zero, and the last time should
; be plotted as it is not contained in the next one ! 
; Virtual Potential Temperature Profile
;Usage: ncl var_id=0 plot_verticaProfile_mae.ncl 
; 
; Prabhakar Shrestha
; E-mail: pshrestha@uni-bonn.de
;=======================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin

;------------------------------------------------------------------------------
;USER SETTINGS
;------------------------------------------------------------------------------

 diri      = "../stat_data_d100/"
 fils      = (/"WCDA_cos_","WCDA_clm_","WCDA_pfl_","OL_run_"/)

 color      = (/"red","green","steel blue","grey37"/)
 labels     = (/"WCDA_cos", "WCDA_clm","WCDA_pfl","OL"/)
 varname    = "MAE"  ; Variable to extract from the files
 filsfxs    = (/"theta","qvx_cos","swx_pfl", "tso_clm"/)
 ;; var_id  = 0

 filsfx     = filsfxs(var_id)

 if (filsfx.eq."tso_clm") then
   xyString   = (/"[K]", "HGT [m]"/)
   time       = (/3, 6, 9, 12, 15, 18, 21, 24/)
   tloc       = time/3 - 1
   trX       = (/0.2,1.5/)
   trY       = (/0, 1.0/)
   freverse  = True
 end if

 if (filsfx.eq."thetaV") then
   time = (/0, 3, 6, 9, 12, 15, 18, 21/)
   tloc = time/3 
   xyString = (/"~F33~q~F21~~B~v~N~ [K]", "HGT [m]"/)
   trX       = (/0.1,0.5/)
   trY       = (/0, 2000/)
   freverse  = False
 end if

 if (filsfx.eq."theta") then
   time = (/0, 3, 6, 9, 12, 15, 18, 21/)
   tloc = time/3
   xyString = (/"~F33~q~F21~~N~ [K]", "HGT [m]"/)
   trX       = (/0.1,1.0/)
   trY       = (/0, 2000/)
   freverse  = False
 end if

 if (filsfx.eq."qvx_cos") then
   time = (/0, 3, 6, 9, 12, 15, 18, 21/)
   tloc = time/3
   xyString = (/"QV [g/kg]", "HGT [m]"/)
   trX       = (/0.10,1.0/)
   trY       = (/0, 2000/)
   freverse  = False
 end if

 if (filsfx.eq."swx_pfl") then
   time      = (/0, 3, 6, 9, 12, 15, 18, 21/)
   tloc = time/3
   xyString  = (/"S~B~w~N~ [-]", "Depth [m]"/)
   trX       = (/1.E-3,0.10/)
   trY       = (/0, 1.0/)
   freverse  = True
 end if

;------------------------------------------------------------------------------
;USER SETTINGS END
;------------------------------------------------------------------------------

 nc_fil1   = addfile(diri+"statistics_"+fils(0)+filsfx+".nc","r")
 nc_fil2   = addfile(diri+"statistics_"+fils(1)+filsfx+".nc","r")
 nc_fil3   = addfile(diri+"statistics_"+fils(2)+filsfx+".nc","r")
 nc_fil4   = addfile(diri+"statistics_"+fils(3)+filsfx+".nc","r")

 stat_01   = nc_fil1->$(varname)$
 stat_02   = nc_fil2->$(varname)$ 
 stat_03   = nc_fil3->$(varname)$
 stat_04   = nc_fil4->$(varname)$

 hhl       = nc_fil1->hhl
 ;
 ndim      = dimsizes(stat_01)
 ndim_ic   = ndim(0)

 ;Averaging over simulation period
 ;------------------------------------
 var_01       = dim_sum_n(stat_01,0)/ndim_ic
 var_02       = dim_sum_n(stat_02,0)/ndim_ic
 var_03       = dim_sum_n(stat_03,0)/ndim_ic
 var_04       = dim_sum_n(stat_04,0)/ndim_ic

 
 ;----------------------------
 ;PLOT
 ;----------------------------
 fncps        = "~F21~"
 fncps_no     = 21
 fncps_hgt    = 0.025
 pltyp        = "x11"

 wks = gsn_open_wks(pltyp,"Figure_statistics_"+filsfx)

 nplot  = dimsizes(time)
 plot   = new(nplot,"graphic") 

 res                                     = True

 ;gsn Resources
 ;------------------------
 res@gsnDraw                             = False
 res@gsnFrame                            = False

 ;tm Resources
 ;------------------------
 res@tmXBLabelFont                       = fncps_no
 res@tmYLLabelFont                       = fncps_no
 res@tmYLLabelFontHeightF                = fncps_hgt
 res@tmXBLabelFontHeightF                = fncps_hgt
 res@tmYROn                              = False
 res@tmXTOn                              = False
 res@tmLabelAutoStride                   = True

 ;ti Resources
 ;------------------------
 res@tiXAxisFontHeightF                  = fncps_hgt
 res@tiYAxisFontHeightF                  = fncps_hgt

 ;vp Resources
 ;------------------------
 ;res@vpYF                                = 0.65 ;7
 res@vpWidthF                            = 0.25
 res@vpHeightF                           = 0.5

 ;tr Resources
 ;------------------------
 res@trYMaxF     = trY(1)
 res@trYMinF     = trY(0)
 res@trYReverse  = freverse
 res@trXMaxF     = trX(1)
 res@trXMinF     = trX(0)
 res@trXLog      = True
 
 ;xy Resources
 ;------------------------
 res@xyLineColor                         = "black"
 res@xyLineThicknessF                    = 4.
 res@xyMarkLineMode                      = "MarkLines"
 

 do ip = 0, nplot-1 
   if (ip.lt.4) then
     res@tiXAxisString = ""
   else
     res@tiXAxisString = xyString(0) 
   end if
   if (ip.eq.0 .or. ip.eq.4) then
     res@tiYAxisString = xyString(1)    
   else
     res@tiYAxisString = ""
   end if 
   res@xyLineColor     = color(0) 
   printVarSummary(hhl)
   printVarSummary(var_01(tloc(ip),:))
   plot(ip)         = gsn_csm_xy(wks,var_01(tloc(ip),:),hhl,res)
   ; 
   res@xyLineColor                         = color(1)  ; 
   res@gsnLeftString = "Time: " + sprinti("%0.2i",time(ip)) + "00 LT"
   dum          = gsn_csm_xy(wks,var_02(tloc(ip),:),hhl,res)
   overlay(plot(ip),dum)
   ;
   res@xyLineColor                         = color(2)  ;
   dum2          = gsn_csm_xy(wks,var_03(tloc(ip),:),hhl,res)
   overlay(plot(ip),dum2)
   ;
   res@xyLineColor                         = color(3)  ;
   dum3          = gsn_csm_xy(wks,var_04(tloc(ip),:),hhl,res)
   overlay(plot(ip),dum3)

   delete(res@gsnLeftString)
 end do
 
 resP                   = True
 resP@txString          = varname 
 resP@gsnFrame          = False  
 gsn_panel(wks,plot,(/2,4/),resP)    

 ;lg Resources
 ;---------------------
 lgres                    = True
 lgres@vpWidthF           = 0.2           
 lgres@vpHeightF          = 0.12        
 lgres@lgLineColors       = color  
 lgres@lgPerimOn          = False             
 lgres@lgDashIndexes      = (/0,0,0,0/)      
 lgres@lgLineLabelStrings = (/"","","",""/)    
 lgres@lgLabelFontHeightF = 0.1              

 gsn_legend_ndc(wks,4,labels,0.8,0.999,lgres)
 frame(wks)
end
