      implicit real*8 (a-h,o-z)
      parameter( in =  200 , jn = 200 , nh = 200 )
c
      common /mesa/  dlx,dly,wbl,vbl
c
      common /mesb/  im0,jm0,imx,jmy,imax
c
      common /mes1/  zi(in,jn),zdl(in,jn),adz(in,jn),zi0(in,jn)
      common /mes2/  ibz(in,jn),ikabe(in,jn),ipp(in,jn)
      common /mes3/  zl1(in,jn),zl3(in,jn)
      common /mes4/  hh01(in,jn),hh1(in,jn),hh3(in,jn)
      common /mes5/  qm02(in,jn),qm0(in,jn),qm2(in,jn)
      common /mes6/  qn02(in,jn),qn0(in,jn),qn2(in,jn)
      common /mes7/  cd1(in,jn),cd3(in,jn),pdyn(in,jn)
      common /mes8/  psta(in,jn),pp(in,jn),tau0(in,jn)
      common /mes9/  fm_pst(in,jn)
      common /mud0/  thu,roh,ron,sig,fai,te,cst,dm,bex,bey,hcr,ccr,crd
      common /mud1/  cd,qq,uu,hu
      common /mud2/  ierg, ickb, iwr
      common /fopen/ infname(nh),outfname(nh),infpath(nh),outfpath(nh),
     *               headcom(nh),headnum(nh),iflen_in(nh),iflen_out(nh)
c
      common /hydr/  q0,tt,dlt,dlt_org, quu,huu,
     *               cdu,qagx,qagy,lmq,inn,jnn,
     *               ifp_row(nh),ifp_col(nh),ifp_dir
      common /hydr2/ ihydType
      common /hydr3/ hydVolume, hydPeakrate, hydDuration,
     *               cduPeak, huuPeak, hydPeaktime, alpha,
     *               discharge_max

      common /output/ loutInterval, ioutTime, ioutFlag
c
      common /bc1/    nqbc, iqbc(2, nh)
      common /bc2/    fqxbc(nh), fqybc(nh)
c
      common /calc/  exo,exu,exm,icheck
      common /bund/  ibc(2,jn)
      common /tytl/  itit
c
      common /dnam/  dfname(nh),tmpfil
c
      common /odt1/  qmt(in,jn),qnt(in,jn),hmax(in,jn)
      common /odt2/  qxm(in,jn),qym(in,jn),vxm(in,jn),vym(in,jn)
      common /odt3/  qmax(in,jn),vmax(in,jn),fmax(in,jn)
      common /odt4/  qmbt(in,jn),qnbt(in,jn),zmax(in,jn)
      
      common /max1/ artime(in,jn),uvmax(in,jn)
      common /max2/ hh3max(in,jn),pmax2(in,jn)
      
      common /max3/ pdynmax(in,jn),pstamax(in,jn),tau0max(in,jn) 
      common /max4/ cd3max(in,jn),fmaxx(in,jn),fmaxy(in,jn)

      common /maxtime1/ hh3maxtime(in,jn)
      common /maxtime2/ zmaxtime(in,jn)
      common /maxtime3/ uvmaxtime(in,jn)
      common /maxtime4/ qmaxtime(in,jn), cd3maxtime(in,jn)
      common /maxtime5/ pdynmaxtime(in,jn), pstamaxtime(in,jn)
      common /maxtime6/ pmax2time(in,jn), tau0maxtime(in,jn)
      common /maxtime7/ fmaxtime(in,jn)
      
      character   itit*80,dfname*16,tmpfil*16,headcom*10
      character   infname*100, outfname*100, infpath*300, outfpath*300


      integer(4), parameter :: HydtypeArbitrary   = 0 
      integer(4), parameter :: HydtypeTriangular  = 1
      integer(4), parameter :: HydtypeRectangular = 2 

      real(8), parameter :: grav = 9.80665d0
      real(8), parameter :: pi = acos(-1.d0)
      real(8), parameter :: pi180 = pi / 180.d0
