;======================================================
; Read synthetic model out or perfect model run
; Read COSMO grib files
; Read CLM netcdf files
; Read PARFLOW binary files
; The external folder contains Fortran wrapper codes for
; reading Parflow Binary Files
; A debug file is also created as an example at the end of
; the code. Make sure the file paths have history outputs only.
; 26.03.2012 Created 
; 20.04.2012 Added Flags readcos, readclm, readpfl
;======================================================
; Prabhakar Shrestha
; Transregional Collaborative Research Centre 32 (TR32)
; Z4: Model Development and Maintenance Services
; Meteorological Institute
; University of Bonn
; Auf dem Hügel 20
; D-53121 Bonn
; E-mail: pshrestha@uni-bonn.de
;=======================================================

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

; tps available from https://git.meteo.uni-bonn.de
external EXT1 "$HOME/tps/external/pfread_dim.so"
external EXT2 "$HOME/tps/external/pfread_var.so"

begin
;---------------------------------------------------------------------------
; User Settings
;---------------------------------------------------------------------------
; ouput-storage structure
; /tsmpdir/cosout/       --- cosmo grib files, lfff0000000c included in /ivr/
;         /clmout/       --- clmoas nc files
;         /pflout/press/ --- pressure files only
;                /satur/ --- saturation files only
;
;---------------------------------------------------------------------------

 tsmppath  = "..//PM_run/"
 nrestart  = 14           ;Number of Restarts
 griboup   = False        ;True for grib cosmo outputs
 readcos   = True         ;read cosmo outputs
 readclm   = True         ;read clm outputs
 readpfl   = True         ;read parflow outputs
 pfl_step  = 1.0          ;history output frequency for ParFlow (Hours)
 dtype     = "float"      ;data type for cosmo output

;---------------------------------------------------------------------------
; User Settings End 
;---------------------------------------------------------------------------

 do cycle = 1, nrestart                              ;rdir Loop

   outputdir = "perfectModel" + sprinti("%0.2i",cycle)
   ;
   tsmpdir   = tsmppath+"/"+outputdir+"/"
   diri_cos  = tsmpdir+"/cosout/"         ;grib files
   diri_clm  = tsmpdir+"/clmout/"         ;netcdf files
   diri_pfl  = tsmpdir+"/pflout/satur/"   ;Undistributed pfb files

   ;---------------------------------------------------------------------
   ;  Read grib, netcdf and pfb files into NCL space                    
   ;---------------------------------------------------------------------

   ;----------------------
   ;Load COSMO files
   ;----------------------
   if (readcos) then
     fils_cos  = systemfunc("ls " + diri_cos + "lf*")

     ; create timestamp for COSMO
     nf_cos   = dimsizes(fils_cos)
     nd_cos   = dimsizes(stringtochar(diri_cos))-1
     tim_cos  = new(nf_cos,"float")                     ;create Time array

     if (griboup) then
     do fn = 0, nf_cos-1
       temp        = stringtochar(fils_cos(fn))
       grbdate     = temp(nd_cos:nd_cos+11)
       days        = stringtofloat(charactertostring(grbdate(4:5)))
       hours       = stringtofloat(charactertostring(grbdate(6:7)))
       minutes     = stringtofloat(charactertostring(grbdate(8:9)))
       seconds     = stringtofloat(charactertostring(grbdate(10:11)))
       tim_cos(fn) = days*24.0 + hours + minutes/60.0 + seconds/3600.0
     end do
     end if  ;griboup 
   end if    ;readcos

   ;----------------------
   ;Load CLM files
   ;----------------------
   if (readclm) then
     fils_clm  = systemfunc("ls " + diri_clm + "clmoas*")
     ; cat CLM output
     print("....Reading all clm netcdf files together.......")          ;takes couple of seconds
     ncdf_clm   = addfiles(fils_clm,"r")
     ListSetType (ncdf_clm, "cat")

     ; create timestamp for CLM
     tim_clm    = ncdf_clm[:]->time*24.0    ;Convert days into hours

   end if    ;readclm

   ;----------------------
   ;Read ParFlow Variables
   ;----------------------

   if (readpfl) then
     fils_pfl  = systemfunc("ls " + diri_pfl )

     ; cat ParFlow output
     print("....Reading all parflow pfb files together.......")
     nf_pfl  = dimsizes(fils_pfl)
     do fn = 0, nf_pfl-1
       fname = diri_pfl+fils_pfl(fn)
       if (fn .eq.  0) then
         nx=new(1,integer)
         ny=new(1,integer)
         nz=new(1,integer)
         dx=new(1,double)
         dy=new(1,double)
         dz=new(1,double)
         EXT1::pfread_dim(fname,nx,ny,nz,dx,dy,dz)
         pfb_pfl = new((/nf_pfl,nz,ny,nx/),double)
       end if

       pfvar = new((/nz,ny,nx/),double)
       EXT2::pfread_var(fname,nx,ny,nz,pfvar)
       pfb_pfl(fn,:,:,:) = pfvar
       delete(pfvar)
     end do

     ; create timestamp for ParFlow
     tim_pfl    = ispan(0,nf_pfl-1,1)*pfl_step
   end if  ;readpfl

   ;---------------------------------------------------------------------------
   ;Read COSMO and CLM variables
   ;---------------------------------------------------------------------------

   if (readcos) then
     print("....Reading cosmo grib files .......")

     file_ivr = systemfunc("ls " + diri_cos + "/ivr/lf*")
     if (griboup) then
       grib_ivr = addfile(file_ivr + ".grb","r")
       Z_HYBL   = grib_ivr->GEOMET_H_GDS10_HYBL(::-1,:,:)
     else
       grib_ivr = addfile(file_ivr ,"r")
       Z_HYBL   = grib_ivr->HHL(0,::-1,:,:)
     end if
     nbdl     = 3 ;Computataional Boundaries
     nl       = nbdl+1
     ndim     = dimsizes(Z_HYBL)
     nx       = ndim(2)
     ny       = ndim(1)
     nz       = ndim(0)-1
     zxx_cos  = 0.5*(Z_HYBL(0:nz-1,nbdl:ny-nl,nbdl:nx-nl) + Z_HYBL(1:nz,nbdl:ny-nl,nbdl:nx-nl))

     nxc = nx - 2*nbdl
     nyc = ny - 2*nbdl
     ;Generate new array to store atmospheric variables

     txx_cos = new((/nf_cos,nz,nyc,nxc/),dtype)
     pxx_cos = new((/nf_cos,nz,nyc,nxc/),dtype)
     qvx_cos = new((/nf_cos,nz,nyc,nxc/),dtype)
     wxx_cos = new((/nf_cos,nz,nyc,nxc/),dtype)
     uxx_cos = new((/nf_cos,nz,nyc,nxc/),dtype)
     vxx_cos = new((/nf_cos,nz,nyc,nxc/),dtype)
     pbl_cos = new((/nf_cos,nyc,nxc/),dtype)
     qrn_cos = new((/nf_cos,nyc,nxc/),dtype)
;;
     do nf = 0, nf_cos-1
       if (griboup) then
         grib_cos = addfile(fils_cos(nf)+".grb","r")
         txx_cos(nf,:,:,:)   = grib_cos->T_GDS10_HYBY(::-1,nbdl:ny-nl,nbdl:nx-nl)
         pxx_cos(nf,:,:,:)   = grib_cos->PS_GDS10_HYBY(::-1,nbdl:ny-nl,nbdl:nx-nl)
         qvx_cos(nf,:,:,:)   = grib_cos->QV_GDS10_HYBY(::-1,nbdl:ny-nl,nbdl:nx-nl)
         temp_wxx            = grib_cos->VERT_VEL_GDS10_HYBL(::-1,nbdl:ny-nl,nbdl:nx-nl)
         wxx_cos(nf,:,:,:)   = 0.5*(temp_wxx(0:nz-1,:,:) + temp_wxx(1:nz,:,:))
         uxx_cos(nf,:,:,:)   = grib_cos->U_GDS10_HYBY(::-1,nbdl:ny-nl,nbdl:nx-nl)
         vxx_cos(nf,:,:,:)   = grib_cos->V_GDS10_HYBY(::-1,nbdl:ny-nl,nbdl:nx-nl)
         pbl_cos(nf,:,:)     = grib_cos->VAR_156_GDS10_SFC(nbdl:ny-nl,nbdl:nx-nl)
       else
         grib_cos = addfile(fils_cos(nf),"r")
         txx_cos(nf,:,:,:)   = grib_cos->T(0,::-1,nbdl:ny-nl,nbdl:nx-nl)
         pxx_cos(nf,:,:,:)   = grib_cos->P(0,::-1,nbdl:ny-nl,nbdl:nx-nl)
         qvx_cos(nf,:,:,:)   = grib_cos->QV(0,::-1,nbdl:ny-nl,nbdl:nx-nl)
         temp_wxx            = grib_cos->W(0,::-1,nbdl:ny-nl,nbdl:nx-nl)
         wxx_cos(nf,:,:,:)   = 0.5*(temp_wxx(0:nz-1,:,:) + temp_wxx(1:nz,:,:))
         uxx_cos(nf,:,:,:)   = grib_cos->U(0,::-1,nbdl:ny-nl,nbdl:nx-nl)
         vxx_cos(nf,:,:,:)   = grib_cos->V(0,::-1,nbdl:ny-nl,nbdl:nx-nl)
         pbl_cos(nf,:,:)     = grib_cos->HPBL(0,nbdl:ny-nl,nbdl:nx-nl)
         qrn_cos(nf,:,:)     = grib_cos->TOT_PREC(0,nbdl:ny-nl,nbdl:nx-nl)
       end if
    
     end do
   end if

   if (readclm) then
     thb_clm   = ncdf_clm[:]->FIRA
     sob_clm   = ncdf_clm[:]->FSA
     tau_clm   = ncdf_clm[:]->TAUX
     tav_clm   = ncdf_clm[:]->TAUY
     shf_clm   = (ncdf_clm[:]->FSH_G)+(ncdf_clm[:]->FSH_V)
     lhf_clm   = (ncdf_clm[:]->FCTR)+(ncdf_clm[:]->FGEV)+(ncdf_clm[:]->FCEV)
     tvg_clm   = ncdf_clm[:]->TV
     tso_clm   = ncdf_clm[:]->TSOI
     t2m_clm   = ncdf_clm[:]->TSA
     q2m_clm   = ncdf_clm[:]->Q2M
   end if


   ;--------------------------------------
   ; Now write the output files
   ;--------------------------------------
  
   fname             = outputdir+".nc"
   system("rm " + fname)
   fout              = addfile(fname,"c")

   if (readcos) then
     fout->tim_cos     = (/tim_cos/)
     fout->zxx_cos     = (/zxx_cos/)
     fout->txx_cos     = (/txx_cos/)
     fout->qvx_cos     = (/qvx_cos/)
     fout->wxx_cos     = (/wxx_cos/)
     fout->uxx_cos     = (/uxx_cos/)
     fout->pxx_cos     = (/pxx_cos/)
     fout->vxx_cos     = (/vxx_cos/)
     fout->pbl_cos     = (/pbl_cos/)
     fout->qrn_cos     = (/qrn_cos/)
   end if

   if (readclm) then
     fout->tim_clm     = (/tim_clm/)
     fout->tvg_clm     = (/tvg_clm/)
     fout->tso_clm     = (/tso_clm/)
     fout->sob_clm     = (/sob_clm/)
     fout->thb_clm     = (/thb_clm/)
     fout->tau_clm     = (/tau_clm/)
     fout->tav_clm     = (/tav_clm/)
     fout->shf_clm     = (/shf_clm/)
     fout->lhf_clm     = (/lhf_clm/)
     fout->t2m_clm     = (/t2m_clm/)
     fout->q2m_clm     = (/q2m_clm/)
   end if

   if (readpfl) then
     fout->tim_pfl     = (/tim_pfl/)
     fout->swx_pfl     = (/pfb_pfl(:,::-1,:,:)/)
   end if

 end do                         ;rdir Loop

end
