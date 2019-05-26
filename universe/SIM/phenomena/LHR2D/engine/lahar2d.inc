      implicit real*8 (a-h,o-z)
C      
      parameter( in = 1000 , jn = 1000 , nlmq = 500 ,
     &           nidnum = 5 , nlhd = 3 , nh = 200)
C
C
C***********************
C    Input Data    1 0
C***********************
C
      common /mesa/  im0,jm0,imx,jmy,inn,jnn,
     &               ild,ickb,iel,imax,ipp(in,jn)
      common /mesb/  dlx,dly,ddxy,ddxyc,wbl,vbl
      common /mes1/  zi0(in,jn),zi(in,jn),adz(in,jn),ibz(in,jn)
     &               ,kabe(in,jn)
      common /mes2/  zdl(in,jn),zl1(in,jn),zl3(in,jn)
      common /mes3/  hh01(in,jn),hh1(in,jn),hh3(in,jn)
      common /mes4/  qm02(in,jn),qm0(in,jn),qm2(in,jn),qmbt(in,jn)
      common /mes5/  qn02(in,jn),qn0(in,jn),qn2(in,jn),qnbt(in,jn)
      common /mes6/  qmb(nidnum,in,jn),qnb(nidnum,in,jn)
      common /mes7/  dmix(in,jn),dzd1(nidnum,in,jn)
      common /mes8/  ddz2(in,jn),dzd2(nidnum,in,jn)
      common /mes9/  psta(in,jn),pp(in,jn),tau0(in,jn)
      common /mes10/ fm_pst(in,jn)
C
C************************
C    Input Data 2 0
C************************
C
      common /mud0/  roh,sig,cst,bex,bey,alph,ss1,eps,cmpm,sodo,tastcm
C
C
C*************************
C     Input Data 3 0
C*************************
C
      common /mud1/  cd(nidnum,nlhd),qq(nlhd),uu(nlhd),hu(nlhd),
     &               slu(nlhd),bi0(nlhd)
C
C************************
C     Input Data 2 0
C************************
C
C
      common /mud2/  dmix0,dcng,dm0,idnum,indst
      common /mud3/  sta1,sin1,cos1,tan1,fai,dtau
      common /gsd0/  gsd(nidnum),dsinp(nidnum),w0(nidnum),
     &               dist(nidnum,nidnum)
      common /gsd1/  dm(in,jn),idist(in,jn)
      common /qbs1/  qmbs1(nidnum,in,jn),qmbs2(nidnum,in,jn)
      common /qbs2/  qnbs1(nidnum,in,jn),qnbs2(nidnum,in,jn)
      common /uvxy/  uy(in,jn),vx(in,jn),uvx(in,jn),uvy(in,jn)
      common /egxy/  egx(in,jn),egy(in,jn)
C
C************************
C     Input Data 4 0
C************************
C
      common /out1/  zl(30),wl(30),iprn(30),iplt,izl,iwl
C
C*************************
C    Input Data 3 0
C*************************
      common /hydr/  dlt, dlt_org,qi0(nlhd),huu(nlhd),qia(nlmq,nlhd),
     &               cdu(nidnum, nlhd), lmq1, lhd, lmq, ipf(nlhd),
     &               ijp(nlhd,3), ifp_row(nh,nlhd), ifp_col(nh,nlhd),
     &               ifp_dir(nlhd), num(nlhd)
      common /hydr2/ ihydType(nlhd)
      common /hydr3/ hydVolume(nlhd), hydPeakrate(nlhd),
     &               hydDuration(nlhd), cduPeak(nidnum, nlhd),
     &               huuPeak(nlhd), hydPeaktime(nlhd),
     &               discharge_max(nlhd), alpha
      common /hydr4/ tt(nlmq, nlhd), nhydCount(nlhd), lhyd(nlhd)
      common /hydr5/ simDuration   ! Defined by max hydDuration(:)
      common /calc/  exo,exu,exm,icheck
      common /qbt1/  qmbtt(in,jn),qnbtt(in,jn)
      common /qbt2/  qmbdt(nidnum,in,jn),qnbdt(nidnum,in,jn)
      common /tytl/  itit
      common /acc/   qitt, qbtt, qbit(nidnum)
C
C
C***************************
C    Input Data 5 0, 6 0
C***************************
      common /fnam/  dfname(nlmq),tmpfil
      common /bund/  ibc(2,jn)
      common /odt1/  qmt(in,jn),qnt(in,jn),hmax(in,jn),cd3(in,jn)
      common /odt2/  qxm(in,jn),qym(in,jn),vxm(in,jn),vym(in,jn)
      common /odt3/  qmax(in,jn),fmax(in,jn),cmax(in,jn)
      common /odt4/  zmax(in,jn)

      ! boundary conditions
      common /bc1/   nqbc(nlhd), iqbc(2, nh, nlhd)
      common /bc2/   bc_rate(2, nh, nlhd)
C
C***************************
C    File list & Output Data
C***************************
C
      common /fopen/ infname(100),outfname(100),
     &               infpath(100),outfpath(100),
     &               headcom(100),headnum(100),
     &               iflen_in(100),iflen_out(100)
C     
      common /max1/  artime(in,jn),uvmax(in,jn) !arriving_time,max_velocity
      common /max2/  hh3max(in,jn),qmax2(in,jn), pmax2(in,jn) !max_flow_depth,max_flow_force
      common /max3/  pdynmax(in,jn), pstamax(in,jn), tau0max(in,jn)
      common /max4/  fmaxx(in,jn), fmaxy(in,jn), cd3max(in,jn)

      common /maxtime1/ hh3maxtime(in,jn)
      common /maxtime2/ zmaxtime(in,jn)
      common /maxtime3/ uvmaxtime(in,jn)
      common /maxtime4/ qmaxtime(in,jn), pmax2time(in,jn)
      common /maxtime5/ pdynmaxtime(in,jn), pstamaxtime(in,jn)
      common /maxtime6/ qmax2time(in,jn), tau0maxtime(in,jn)
      common /maxtime7/ fmaxtime(in,jn), cd3maxtime(in,jn)
C
      integer     end_flag
      common /flag/ end_flag
      common /output/ loutInterval, ioutTime, ioutFlag

      character   itit*80,dfname*16,tmpfil*16,headcom*10
      character   infname*100,outfname*100,infpath*200,outfpath*200


      ! Hydrograph types
      integer(4), parameter :: HydtypeArbitrary   = 0
      integer(4), parameter :: HydtypeTriangular  = 1
      integer(4), parameter :: HydtypeRectangular = 2

      ! Parameters
      real(8), parameter :: grav = 9.80665d0
      real(8), parameter :: pi = acos(-1.d0)
      real(8), parameter :: pi180 = pi / 180.d0
      
