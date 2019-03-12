;======================================================
; Plot of vertical profile of  boundary layer and soil states 
; Uses input processesd by the statistical script
; compute_error_statistics.ncl
;
; Observation states are extracted from the OL run for the plots
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

 diri       = "../nc_stat_data/"

 fils       = (/"WCDA_cos_","WCDA_clm_","WCDA_pfl_","OL_"/)
 color      = (/"red","green","steel blue","magenta","black"/)  ;1+color for OBS 
 labels     = (/"WCDA_cos", "WCDA_clm","WCDA_pfl","OL","OBS"/)
 varname    = "ens"  ; Variable to extract from the files
 filsfxs    = (/"theta","qvx_cos","swx_pfl", "tso_clm"/)
 ;; var_id  = 0

 filsfx     = filsfxs(var_id)

 ;Default, unless specified 
 offset    = 0.;
 scale     = 1.
 
if (filsfx.eq."tso_clm") then
   xyString   = (/"[degrees C]", "HGT [m]"/)
   time       = (/3,  9, 15, 21/)
   tloc       = (/0,  2,  4, 6/)
   trX       = (/8.,25./)
   trY       = (/0., 2.5/)
   offset    = 273.15;
   scale     = 1.
   freverse  = True
 end if

 if (filsfx.eq."thetaV") then
   time =   (/3, 9, 15, 21/) 
   tloc =   (/1, 3,  5, 7/)
   xyString = (/"~F33~q~F21~~B~v~N~ [K]", "HGT [m]"/)
   trX       = (/310.,316./)
   trY       = (/0., 4000./)
   freverse  = False
 end if

 if (filsfx.eq."theta") then
   time =   (/3, 9, 15, 21/)
   tloc =   (/1, 3,  5, 7/)
   xyString = (/"~F33~q~F21~~N~ [K]", "HGT [m]"/)
   trX       = (/264.,273./)
   trY       = (/0., 3000./)
   freverse  = False
 end if

 if (filsfx.eq."qvx_cos") then
   time =   (/3, 9, 15, 21/)
   tloc =   (/1, 3,  5, 7/)
   xyString = (/"QV [g/kg]", "HGT [m]"/)
   trX       = (/2.0,5.0/)
   trY       = (/0., 3000./)
   freverse  = False
 end if

 if (filsfx.eq."swx_pfl") then
   time      = (/3,9, 15, 21/)
   tloc      = (/1, 3,  5, 7/)
   xyString  = (/"S~B~w~N~ [-]", "Depth [m]"/)
   trX       = (/0.1,0.31/)
   trY       = (/0, 2.5/)
   freverse  = True
 end if
;------------------------------------------------------------------------------
;USER SETTINGS END
;------------------------------------------------------------------------------

 ;Hard-wire for four files, five labels
 nc_fil1   = addfile(diri+fils(0)+filsfx+".nc","r")
 nc_fil2   = addfile(diri+fils(1)+filsfx+".nc","r")
 nc_fil3   = addfile(diri+fils(2)+filsfx+".nc","r")
 nc_fil4   = addfile(diri+fils(3)+filsfx+".nc","r")

 stat_01   = nc_fil1->$(varname)$
 stat_02   = nc_fil2->$(varname)$ 
 stat_03   = nc_fil3->$(varname)$
 stat_04   = nc_fil4->$(varname)$
 varname   = "obs"
 stat_05   = nc_fil4->$(varname)$     ;Extract Observation State here 

 hhl       = nc_fil1->hhl             ;Vertical Profile
 ;
 ndim      = dimsizes(stat_01)
 ndim_ic   = ndim(0)

 ;--------------------
 ;Average over time
 ;--------------------
 var_01       = dim_sum_n(stat_01,0)/ndim_ic
 var_02       = dim_sum_n(stat_02,0)/ndim_ic
 var_03       = dim_sum_n(stat_03,0)/ndim_ic
 var_04       = dim_sum_n(stat_04,0)/ndim_ic
 var_05       = dim_sum_n(stat_05,0)/ndim_ic

 ;--------------------
 ;Rescale variablee
 ;--------------------
 var_01       = var_01*scale - offset
 var_02       = var_02*scale - offset
 var_03       = var_03*scale - offset
 var_04       = var_04*scale - offset
 var_05       = var_05*scale - offset

 ;------------------------
 ;PLOT
 ;------------------------

 fncps      = "~F21~"
 fncps_no   = 21
 fncps_hgt  = 0.025
 pltyp      = "x11"

 wks   = gsn_open_wks(pltyp,"Figure_ens_states")

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
 res@tiYAxisString                       = "HGT [m]"

 ;vp Resources
 ;------------------------
 res@vpYF                                = 0.65
 res@vpWidthF                            = 0.4
 res@vpHeightF                           = 0.5

 ;tr  Resources
 ;------------------------
 res@trYMaxF     = trY(1)
 res@trYMinF     = trY(0)
 res@trYReverse  = freverse
 res@trXMaxF     = trX(1) 
 res@trXMinF     = trX(0) 


 ;xy  Resources
 ;------------------------
 res@xyLineColor                         = "black"
 res@xyLineThicknessF                    = 3.
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
   ;
   print(ip + " " +time(ip) + " " + tloc(ip))
   res@xyLineColor                         = color(0) 
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
   ;
   res@xyLineColor                         = color(4)  ;
   dum4          = gsn_csm_xy(wks,var_05(tloc(ip),:),hhl,res)
   overlay(plot(ip),dum4)

   delete(res@gsnLeftString)
 end do
 
 resP                       = True
 resP@txString              = filsfxs(var_id)
 resP@gsnFrame              = False  
 gsn_panel(wks,plot,(/2,2/),resP)    

 ; lg Resources
 ;------------------------
 lgres                    = True
 lgres@vpWidthF           = 0.2          
 lgres@vpHeightF          = 0.12        
 lgres@lgLineColors       = color  
 lgres@lgPerimOn          = False               
 lgres@lgDashIndexes      = (/0,0,0,0,0/)      
 lgres@lgLineLabelStrings = (/"","","","",""/)    
 lgres@lgLabelFontHeightF = 0.1                   

 gsn_legend_ndc(wks,5,labels,0.8,0.98,lgres)
 frame(wks)
end
