      program bedload
      include 'lahar2d.inc'
      integer itime,itt,itime_h
      integer itime_min,itime_sec
      integer itime_hEnd,itime_minEnd,itime_secEnd

      end_flag=0
      
      call setfopen_list
      call input_mesh_header
      call input_param
      call set_init
      call input_hydrograph
      call input_inflow_point
      call input_base_dem
      
      end_flag=1
      jj=0

      OPEN(UNIT=2,FILE='log_condition.txt',STATUS='UNKNOWN',
     *     ACCESS='SEQUENTIAL',FORM='FORMATTED')


      write(*,*) 'calculation start!'

      ! Set output interval time
      loutInterval = 300          ! every 300 seconds
      ioutTime     = loutInterval ! next output time
      ioutFlag     = 0            ! set output flag off

! ==========================================================

      itime = int(simDuration + simDuration/86400.0)
      itime_hEnd = itime / 3600
      itt = itime - itime_hEnd * 3600
      itime_minEnd = itt / 60
      itime_secEnd = itt - itime_minEnd * 60
      
      
      
      dt0 = 0.d0
      dt1 = dt0
      
      k = 0
      lhyd(:) = 1

      do 5000
        k = k + 1
        
        dt2 = dlt * 0.5d0
        dt1 = dt1 + dlt + dt0
        
        
        if (dt1 > simDuration) go to 9000
        do l = 1, lhd
          if (nhydCount(l) == 0) cycle
          if (dt1 > tt(lhyd(l), l)) lhyd(l) = lhyd(l) + 1
        end do

        call debin(dt1)
        
        ! monitor the calculation status every 10 step
        if (mod(k,100)==0) then
                  itime = int(dt1 + dt1/86400.0)
                  itime_h = itime / 3600
                  itt = itime - itime_h * 3600
                  itime_min = itt / 60
                  itime_sec = itt - itime_min * 60
            
     
            write(*,'(" it=",i7," time=",i3," h",i3," m",i3,
     *      " sec (",i3,"h",i2,"m",i2,
     *      "sec) dt=",1pe9.2," cfl=",1pe8.1,
     *       " Q=",1pe9.2," U=",1pe9.2," H=",1pe9.2,
     *       1pe9.2)')
     *       k,itime_h,itime_min,itime_sec,
     *       itime_hEnd,itime_minEnd,itime_secEnd,
     *       dlt,alpha,qi0(1),uu(1),hu(1),maxval(hh3max)
            
            
        end if

      call mncal(dt2)
      call dmcal
      call cmncal
      call qbscal
      call depcal(dt2)
      call crect2(dt2)
      call bedcal(dt2)
      call maxcal(dt1)
      call delete




       if (ioutFlag == 1 ) then
         wbl=0.
         vbl=0.
         do 1110 j=2,jm0
         do 1100 i=2,im0
         if(ipp(i,j).gt.0)  go to 1100
         if(zi(i,j).ge.0.) wbl=wbl+hh3(i,j)*dlx*dly
         if(zi(i,j).ge.0.) vbl=vbl+(zl3(i,j)-zi(i,j))*dlx*dly*cst
 1100    continue
 1110    continue
         
         
         call set_result_output(dt1)

         ioutFlag = 0
         ioutTime = ioutTime + loutInterval
         dlt = dlt_org
       end if
       
      ! Check output timing
      if (dt1 + dlt > ioutTime) then
              dlt = ioutTime - dt1
              ioutFlag = 1
      end if

      do 5600  j9=2,jm0
      do 5500  i9=ibc(1,j9),ibc(2,j9)
       hh01(i9,j9) = hh1(i9,j9)
       hh1(i9,j9)  = hh3(i9,j9)
       zl1(i9,j9)  = zl3(i9,j9)
       qm02(i9,j9) = qm0(i9,j9)
       qn02(i9,j9) = qn0(i9,j9)
       qm0(i9,j9)  = qm2(i9,j9)
       qn0(i9,j9)  = qn2(i9,j9)
 5500 continue
 5600 continue

 5000 continue


      if(end_flag == 1) go to 9000

 9000 continue

      call set_result_output_max()

      itimex = int(dt1 + dt1/86400.0)
      itime1 = itimex / 3600
      itimey = itimex - itime1 * 3600
      itime2 = itimey / 60
      itime3 = itimey - itime2 * 60
      write(6,1200) itime1,itime2,itime3
 1200 format(1h ,'time : ',i3,'h ',i2,'m ',i2,'s  end')

 
      close(2)
      
      write(6,'(1h ,''nomal end'')')
      
      write(*,'("")')
      write(*,'(" Calculation END ")')
      write(*,'("")')


  100 format(2x,' l= ',i3,'/',i3,' k= ',i5,
     *'/',i5,
     *' time=',i3,' h',i3,' m',i3,' s Q=',
     *1pe11.3,' m3/s')
      
      stop
      end


      
c**********************************************
      subroutine  set_result_output(dt1)
c**********************************************

c----------------------------------------------
      include 'lahar2d.inc' 
c----------------------------------------------


      integer i,j,itime
      real(8) :: tmpx(in, jn), tmpy(in, jn)
      real(8) :: state(in, jn)
      character(len=200):: fname1
      character(len=200):: fname2
      character(len=200):: fname3
      character(len=200):: fname4
      character(len=200):: fname5
      character(len=200):: fname6
      character(len=200):: fname7
      character(len=200):: fname8
      character(len=200):: fname9
      character(len=200):: fname10
      character(len=200):: fname11
      character(len=200):: fname12
      character(len=200):: fname13
      character(len=200):: fname14
      character(len=200):: fname
      character(len=3):: hh
      character(len=2):: mm
      character(len=2):: ss
 
      itime = int(dt1 + dt1/86400.0)
      itime_h = itime / 3600
      itt = itime - itime_h * 3600
      itime_min = itt / 60
      itime_sec = itt - itime_min * 60
      
      write(hh,'(i3.3)') itime_h
      write(mm,'(i2.2)') itime_min
      write(ss,'(i2.2)') itime_sec

      fname1=trim(adjustl(outfpath(1)))//trim(adjustl(outfname(1)))
      fname2=trim(adjustl(outfpath(2)))//trim(adjustl(outfname(2)))
      fname3=trim(adjustl(outfpath(3)))//trim(adjustl(outfname(3)))
      fname4=trim(adjustl(outfpath(4)))//trim(adjustl(outfname(4)))
      fname5=trim(adjustl(outfpath(5)))//trim(adjustl(outfname(5)))
      fname6=trim(adjustl(outfpath(6)))//trim(adjustl(outfname(6)))
      fname7=trim(adjustl(outfpath(7)))//trim(adjustl(outfname(7)))
      fname8=trim(adjustl(outfpath(8)))//trim(adjustl(outfname(8)))
      fname9=trim(adjustl(outfpath(9)))//trim(adjustl(outfname(9)))
      fname10=trim(adjustl(outfpath(10)))//trim(adjustl(outfname(10)))
      fname11=trim(adjustl(outfpath(11)))//trim(adjustl(outfname(11)))
      fname12=trim(adjustl(outfpath(12)))//trim(adjustl(outfname(12)))
      fname13=trim(adjustl(outfpath(13)))//trim(adjustl(outfname(13)))
      fname14=trim(adjustl(outfpath(14)))//trim(adjustl(outfname(14)))

      ! flow depth
      fname = trim(adjustl(fname1)) // '_'
     &        //hh//'h'//mm//'m'//ss//'s.out'
      state(:, :) = hh3(:, :)
      call ascout(fname, state)

      ! deposition
      fname = trim(adjustl(fname2)) // '_'
     &        //hh//'h'//mm//'m'//ss//'s.out'
      state(:, :) = zl3(:, :) - zi(:, :)
      call ascout(fname, state)

      ! deposition from initial bed elevation
      fname = trim(adjustl(fname3)) // '_'
     &        //hh//'h'//mm//'m'//ss//'s.out'
      state(:, :) = zl3(:, :) - zi0(:, :)
      call ascout(fname, state)

      ! deposition + flow depth
      fname = trim(adjustl(fname4)) // '_'
     &        //hh//'h'//mm//'m'//ss//'s.out'
      state(:, :) = zl3(:, :) - zi(:, :) + hh3(:, :)
      call ascout(fname, state)

      do j = 1, jm0
        do i = 1, im0
          tmpx(i, j) = ( qm2(i,j) + qm2(i+1,j) ) * 0.5
          tmpy(i, j) = ( qn2(i,j) + qn2(i+1,j) ) * 0.5
        end do
      end do

      ! discharge in x-direction
      fname = trim(adjustl(fname5)) // '_'
     &        //hh//'h'//mm//'m'//ss//'s.out'
      call ascout(fname, tmpx)

      ! discharge in y-direction
      fname = trim(adjustl(fname6)) // '_'
     &        //hh//'h'//mm//'m'//ss//'s.out'
      call ascout(fname, tmpy)

      ! discharge (absolute value)
      fname = trim(adjustl(fname7)) // '_'
     &        //hh//'h'//mm//'m'//ss//'s.out'
      state(:, :) = sqrt(tmpx(:,:)*tmpx(:,:) + tmpy(:,:)*tmpy(:,:))
      call ascout(fname, state)

      ! cd
      fname = trim(adjustl(fname8)) // '_'
     &        //hh//'h'//mm//'m'//ss//'s.out'
      call ascout(fname, cd3)

      do j = 1, jm0
        do i = 1, im0
          if(abs(hh3(i, j)) > exm) then
            tmpx(i, j) = tmpx(i, j) / hh3(i, j)
            tmpy(i, j) = tmpy(i, j) / hh3(i, j)
          else
            tmpx(i, j) = 0.0
            tmpy(i, j) = 0.0
          end if
        end do
      end do

      ! flow speed in x-direction
      fname = trim(adjustl(fname9)) // '_'
     &        //hh//'h'//mm//'m'//ss//'s.out'
      call ascout(fname, tmpx)

      ! flow speed in y-direction
      fname = trim(adjustl(fname10)) // '_'
     &        //hh//'h'//mm//'m'//ss//'s.out'
      call ascout(fname, tmpy)

      ! flow speed (absolute value)
      fname = trim(adjustl(fname11)) // '_'
     &        //hh//'h'//mm//'m'//ss//'s.out'
      state(:, :) = sqrt(tmpx(:,:)*tmpx(:,:) + tmpy(:,:)*tmpy(:,:))
      call ascout(fname, state)

      do j = 1, jm0
        do i = 1, im0
          if(abs(state(i, j)) > exm) then
            tmpx(i, j) = fm_pst(i,j) * tmpx(i,j) / state(i,j)
            tmpy(i, j) = fm_pst(i,j) * tmpy(i,j) / state(i,j)
          else
            tmpx(i, j) = 0.0
            tmpy(i, j) = 0.0
          end if
        end do
      end do

      ! flow power in x-direction
      fname = trim(adjustl(fname12)) // '_'
     &        //hh//'h'//mm//'m'//ss//'s.out'
      call ascout(fname, tmpx)

      ! flow power in y-direction
      fname = trim(adjustl(fname13)) // '_'
     &        //hh//'h'//mm//'m'//ss//'s.out'
      call ascout(fname, tmpy)

      ! flow power (absolute value)
      fname = trim(adjustl(fname14)) // '_'
     &        //hh//'h'//mm//'m'//ss//'s.out'
      state(:, :) = sqrt(tmpx(:,:)*tmpx(:,:) + tmpy(:,:)*tmpy(:,:))
      call ascout(fname, state)


      
      
      
      return
      end


!**********************************************
      subroutine  set_result_output_max()
!**********************************************

!----------------------------------------------
      include'lahar2d.inc' 
!----------------------------------------------

      real(8) state(in, jn)
      character(len=200):: fname15
      character(len=200):: fname16
      character(len=200):: fname17
      character(len=200):: fname18
      character(len=200):: fname19
      character(len=200):: fname20
      character(len=200):: fname21
      character(len=200):: fname22
      character(len=200):: fname23
      character(len=200):: fname24
      character(len=200):: fname25
      character(len=200):: fname26
      character(len=200):: fname27
      character(len=200):: fname28
      character(len=200):: fname29
      character(len=200):: fname30
      character(len=200):: fname31
      character(len=200):: fname32
      character(len=200):: fname33
      character(len=200):: fname34
      character(len=200):: fname35
      character(len=200):: fname36
      character(len=200):: fname37
      character(len=200):: fname38
      character(len=200):: fname39
      character(len=200):: fname40
      character(len=256):: fname
      
      irows=int(headnum(5))
      icols=int(headnum(6))
      
      fname15=trim(adjustl(outfpath(15)))//trim(adjustl(outfname(15)))
      fname16=trim(adjustl(outfpath(16)))//trim(adjustl(outfname(16)))
      fname17=trim(adjustl(outfpath(17)))//trim(adjustl(outfname(17)))
      fname18=trim(adjustl(outfpath(18)))//trim(adjustl(outfname(18)))
      fname19=trim(adjustl(outfpath(19)))//trim(adjustl(outfname(19)))
      fname20=trim(adjustl(outfpath(20)))//trim(adjustl(outfname(20)))
      fname21=trim(adjustl(outfpath(21)))//trim(adjustl(outfname(21)))
      fname22=trim(adjustl(outfpath(22)))//trim(adjustl(outfname(22)))
      fname23=trim(adjustl(outfpath(23)))//trim(adjustl(outfname(23)))
      fname24=trim(adjustl(outfpath(24)))//trim(adjustl(outfname(24)))
      fname25=trim(adjustl(outfpath(25)))//trim(adjustl(outfname(25)))
      fname26=trim(adjustl(outfpath(26)))//trim(adjustl(outfname(26)))
      fname27=trim(adjustl(outfpath(27)))//trim(adjustl(outfname(27)))
      fname28=trim(adjustl(outfpath(28)))//trim(adjustl(outfname(28)))
      fname29=trim(adjustl(outfpath(29)))//trim(adjustl(outfname(29)))
      fname30=trim(adjustl(outfpath(30)))//trim(adjustl(outfname(30)))
      fname31=trim(adjustl(outfpath(31)))//trim(adjustl(outfname(31)))
      fname32=trim(adjustl(outfpath(32)))//trim(adjustl(outfname(32)))
      fname33=trim(adjustl(outfpath(33)))//trim(adjustl(outfname(33)))
      fname34=trim(adjustl(outfpath(34)))//trim(adjustl(outfname(34)))
      fname35=trim(adjustl(outfpath(35)))//trim(adjustl(outfname(35)))
      fname36=trim(adjustl(outfpath(36)))//trim(adjustl(outfname(36)))
      fname37=trim(adjustl(outfpath(37)))//trim(adjustl(outfname(37)))
      fname38=trim(adjustl(outfpath(38)))//trim(adjustl(outfname(38)))
      fname39=trim(adjustl(outfpath(39)))//trim(adjustl(outfname(39)))
      fname40=trim(adjustl(outfpath(40)))//trim(adjustl(outfname(40)))

      ! flow depth
      fname = trim(adjustl(fname15))//'.out'
      call ascout(fname, hh3max)
      fname = trim(adjustl(fname16))//'.out'
      call ascout(fname, hh3maxtime)

      ! deposition
      fname = trim(adjustl(fname17))//'.out'
      call ascout(fname, zmax)
      fname = trim(adjustl(fname18))//'.out'
      call ascout(fname, zmaxtime)

      ! discharge in x-direction
      fname = trim(adjustl(fname19))//'.out'
      call ascout(fname, qxm)

      ! discharge in y-direction
      fname = trim(adjustl(fname20))//'.out'
      call ascout(fname, qym)

      ! discharge (absolute value)
      fname = trim(adjustl(fname21))//'.out'
      call ascout(fname, qmax)
      fname = trim(adjustl(fname22))//'.out'
      call ascout(fname, qmaxtime)

      ! cd
      fname = trim(adjustl(fname23))//'.out'
      call ascout(fname, cd3max)
      fname = trim(adjustl(fname24))//'.out'
      call ascout(fname, cd3maxtime)

      ! flow speed in x-direction
      fname = trim(adjustl(fname25))//'.out'
      call ascout(fname, vxm)

      ! flow speed in y-direction
      fname = trim(adjustl(fname26))//'.out'
      call ascout(fname, vym)

      ! flow speed (absolute value)
      fname = trim(adjustl(fname27))//'.out'
      call ascout(fname, uvmax)
      fname = trim(adjustl(fname28))//'.out'
      call ascout(fname, uvmaxtime)

      ! flow power in x-direction
      fname = trim(adjustl(fname29))//'.out'
      call ascout(fname, fmaxx)

      ! flow power in x-direction
      fname = trim(adjustl(fname30))//'.out'
      call ascout(fname, fmaxy)

      ! flow power (absolute value)
      fname = trim(adjustl(fname31))//'.out'
      call ascout(fname, fmax)
      fname = trim(adjustl(fname32))//'.out'
      call ascout(fname, fmaxtime)
      
      ! flow pressure (static)
      fname = trim(adjustl(fname33))//'.out'
      call ascout(fname, pstamax)

      ! flow pressure (dynamic)
      fname = trim(adjustl(fname34))//'.out'
      call ascout(fname, pdynmax)

      ! flow pressure (static + dynamic)
      fname = trim(adjustl(fname35))//'.out'
      call ascout(fname, pmax2)
      fname = trim(adjustl(fname36))//'.out'
      call ascout(fname, pmax2time)

      ! bottom shear stress
      fname = trim(adjustl(fname37))//'.out'
      call ascout(fname, tau0max)
      fname = trim(adjustl(fname38))//'.out'
      call ascout(fname, tau0maxtime)

      ! arrival time
      fname = trim(adjustl(fname39))//'.out'
      call ascout(fname, artime)

      ! accumulated elevation
      fname = trim(adjustl(fname40))//'.out'
      state(:, :) = zl3(:, :)
      call ascout(fname, state)

      return
      end

      subroutine ascout(fname, xx)
!----------------------------------------------
      include 'lahar2d.inc' 
!----------------------------------------------
      character(200) :: fname
      integer(4) :: err
      real(8) :: xx(in, jn)

      open(10,file=fname, action='write',iostat=err)
      if(err/=0) then
                write(*,*) 'cannot open file ',fname
                call calerrout
                stop
      end if
      
      write(10,*) headcom(1),headnum(1)
        write(10,*) headcom(2),headnum(2)
        write(10,*) headcom(3),headnum(3)
        write(10,*) headcom(4),headnum(4)
        write(10,*) headcom(5),headnum(5)
        write(10,*) headcom(6),headnum(6)
      do j=jmy-1,2,-1
            do i=2,imx-1
                  if(i == imx-1) then
                        write(10,'(1pe15.6)')xx(i, j)
                  else
                        write(10,'(1pe15.6,$)')xx(i, j)
                  end if
            end do
      end do
      
      close(10)

      return
      end subroutine ascout




c**********************************************
      subroutine  setfopen_list
c**********************************************

c----------------------------------------------
      include 'lahar2d.inc' 
c----------------------------------------------


      integer err,i
      character(len=200)dummy
     
      open(100,file='flist.dat',action='read',iostat=err)
      if(err/=0) then
            write(*,*) 'cannot open file 100 flist.dat'
            call calerrout
            stop
      end if

      read(100,*) infname(1)
      read(100,*) infpath(1)
      read(100,*) infname(2)
      read(100,*) infpath(2)
      read(100,*) infname(3)
      read(100,*) infpath(3)
      read(100,*) infname(4)
      read(100,*) infpath(4)
      read(100,*) infname(5)
      read(100,*) infpath(5)
      read(100,*) infname(6)
      read(100,*) infpath(6)
      read(100,*) dummy
      do i = 1, 40
        read(100,*) outfname(i)
        read(100,*) outfpath(i)
      end do
      
      ! set character length excepted any space
      do i=1,6
            iflen_in(i)=len_trim(trim(adjustl(infpath(i)))
     *                  //trim(adjustl(infname(i))))
      end do
      do i=1,40
            iflen_out(i)=len_trim(trim(adjustl(outfpath(i)))
     *                  //trim(adjustl(outfname(i))))
      end do
      
      close(100)

      return
      end

c**********************************************
      subroutine  input_mesh_header
c**********************************************

c----------------------------------------------
      include 'lahar2d.inc' 
c----------------------------------------------

      integer err,rows,cols
      real(8) lnorth,lsouth,least,lwest
      character(len=iflen_in(1)) fmesh_h
      character(len=200) dummy
      
      fmesh_h=trim(adjustl(infpath(1)))//trim(adjustl(infname(1)))
      open(101,file=fmesh_h,action='read',iostat=err)
      if(err/=0) then
            write(*,*) 'cannot open file 101 fmesh_h'
            call calerrout
            stop
      end if
      
      read(101,*) headcom(1),headnum(1)
      read(101,*) headcom(2),headnum(2)
      read(101,*) headcom(3),headnum(3)
      read(101,*) headcom(4),headnum(4)
      read(101,*) headcom(5),headnum(5)
      read(101,*) headcom(6),headnum(6)
      read(101,*) dummy,dlx
      read(101,*) dummy,dly
      
      close(101)
      
      dlx=abs(dlx)
      dly=abs(dly)
      
      cols=int(headnum(6))
      rows=int(headnum(5))
      
      lnorth=int(headnum(1))
      lsouth=int(headnum(2))
      least =int(headnum(3))
      lwest =int(headnum(4))
      
      imx = cols + 2
      jmy = rows + 2
      im0 = imx - 1
      jm0 = jmy - 1
      
      write(*,'(4i5,2f8.3)')rows,cols,imx,jmy,dlx,dly
            
      return
      end


c**********************************************
      subroutine  input_param
c**********************************************

c----------------------------------------------
      include 'lahar2d.inc' 
c----------------------------------------------


      integer err,l,k
      real(8) err0,pai,a1,dm0,f0,fd
      character(len=iflen_in(2)) fparam
      character(len=200) dummy
      
      dimension cksum(5),ddm(5)
      
      fparam=trim(adjustl(infpath(2)))//trim(adjustl(infname(2)))
      open(102,file=fparam,action='read',iostat=err)
      if(err/=0) then
            write(*,*) 'cannot open file 102 fparam'
            call calerrout
            stop
      end if
      
      !---- input physical constant & coefficient
      read(102,*) roh,dummy,dummy
      read(102,*) sig,dummy,dummy
      read(102,*) cst,dummy,dummy
      read(102,*) bex,dummy,dummy
      read(102,*) bey,dummy,dummy
      read(102,*) eps,dummy,dummy
      read(102,*) cmpm,dummy,dummy
      read(102,*) sodo,dummy,dummy
      read(102,*) alph,dummy,dummy
      read(102,*) tastcm,dummy,dummy
      read(102,*) sta1,dummy,dummy
      read(102,*) fai,dummy,dummy
      read(102,*) ild,dummy,dummy
      read(102,*) iwr,dummy,dummy
      read(102,*) ickb,dummy,dummy
      read(102,*) iel,dummy,dummy
      read(102,*) imax,dummy,dummy
      
      if(tastcm.le.0.0) tastcm=0.05
      
      write(*,'(5(1pe12.3))')roh,sig,cst,bex,bey
      write(*,'(5(1pe12.3))')eps,cmpm,sodo,alph,tastcm
      write(*,'(3(1pe12.3))')sta1,fai
      
      write(*,'(5(i5))')ild,iwr,ickb,iel,imax
      
      if(roh < 0.9 .or. roh > 2.9)  call  errnum('roh ')
      if(sig < roh .or. sig > 5.0)  call  errnum('sig ')
      if(cst <= 0.0 .or. cst > 1.0)  call  errnum('cst ')
      if(bex <= 0.0 .or. bex > 2.0)  call  errnum('bex ')
      if(bey <= 0.0 .or. bey > 2.0)  call  errnum('bey ')
      if(sodo <= 0.0 .or. sodo > 1.0)call  errnum('sodo')
      if(eps <= 0.0)                call  errnum('eps ')
      if(alph <= 0.0 .or. alph > 10.0)call  errnum('alph')
      if(sta1 <= 0.0 .or. sta1 > 90.0)  call  errnum('sta1')
      if(fai <= 0.0 .or. fai > 90.0)  call  errnum('fai ')

      pai = 3.14159265 / 180.0
      
      fai = tan(fai*pai)
      ss1 = sig / roh - 1.0
      sta1 = sta1 * pai
      sin1 = sin( sta1 )
      cos1 = cos( sta1 )
      tan1 = tan( sta1 )
      
      
      !---- input grain info
      read(102,*) dummy
      read(102,*) idnum,dummy,dummy
      read(102,*) indst,dummy,dummy
      read(102,*) dmix0,dummy,dummy
      read(102,*) dcng,dummy,dummy
      
      write(*,'(2(i4),2(1pe12.3))')idnum,indst,dmix0,dcng
      
      if(dmix0 < dcng)  call errnum('dcng')
          
      read(102,*) dummy
      do l=1,idnum
            read(102,*) gsd(l),dsinp(l),(dist(l,k),k=1,indst)
            write(*,'(i4,2(1pe12.3))')l,gsd(l),dsinp(l)
            write(*,*) (dist(l,k),k=1,indst)
      end do
      
      
      
      close(102)
      
      !-----
      do k = 1,indst
            cksum(k) = 0.0
            ddm(k) = 0.0
      end do

      a1 = 0.0
      dm0 = 0.0
      
      do l = 1, idnum
            f0 = 36.0 * 0.01**2 / ss1 / 980.0 / gsd(l)**3
            fd =   sqrt( 2.0 / 3.0 + f0 ) - sqrt( f0 )
            w0(l) = sqrt( ss1 * 980.0 * gsd(l) ) * fd
            w0(l) = w0(l) / 100.0
            gsd(l) = gsd(l) / 100.0
     
            do k = 1, indst
                  write(*,*) '%d',k,dist(l,k)
                  cksum(k) = cksum(k) + dist(l,k)
                  ddm(k) = ddm(k) + gsd(l) * dist(l,k)
            end do
      
            a1  = a1 + dsinp(l)
            dm0 = dm0 + gsd(l) * dsinp(l)
      end do

      write(*,'("dm0=",1pe12.3)') dm0

      write(*,*) 'going error check 3'

      err0 = abs( 1.0 - a1 )
      
      write(*,'("a1=",f8.2," err0=",f8.2," dsinp=",f8.2)')
     * a1,err0,dsinp(l)

      if(err0 > 0.001)   call errnum('dsin')

      do k = 1 , indst
            err0 = abs( 1.0 - cksum(k) )
            write(*,'("cksum(k)=",f8.2," err0=",f8.2)')cksum(k),err0

            if(err0 > 0.001)  call errnum('dist')
      end do
            
      return
      end

c**********************************************
      subroutine  input_hydrograph
c**********************************************

c----------------------------------------------
      include 'lahar2d.inc' 
c----------------------------------------------


      integer err,i,l,k
      character(len=iflen_in(3)) fhyd
      character(len=200) dummy
      
      fhyd=trim(adjustl(infpath(3)))//trim(adjustl(infname(3)))
      open(103,file=fhyd,action='read',iostat=err)
      if(err/=0) then
            write(*,*) 'cannot open file 103 fhyd'
            call calerrout
            stop
      end if
      
      !---- input number of flow point, hydro bars and zero-clearing flag
      read(103, *) lhd, alpha, dummy, dummy
      read(103, *) dummy
      read(103, *) dummy

      hydPeaktime(:) = 0.d0
      nhydCount(:) = 0
      do l = 1, lhd
        read(103, *) ihydType(l), dummy
        select case (ihydType(l))

          case (HydtypeTriangular)
            read(103,*) hydDuration(l), hydVolume(l)
            read(103,*) hydPeaktime(l)
            read(103,*) huuPeak(l), (cduPeak(k, l), k = 1, idnum)

            hydPeakrate(l) = 2.d0 * hydVolume(l) / hydDuration(l)

            write(*, *)
            write(*, '("Hydro No: ", i5)') l
            write(*, *) hydDuration(l), hydVolume(l), hydPeakrate(l)
            write(*, *) hydPeaktime(l)
            write(*, *) huuPeak(l), (cduPeak(k, l), k = 1, idnum)
            if(HydPeaktime(l) < 0.d0 .or. 1.d0 < HydPeaktime(l)) then
              write(*, *) 'Peaktime ratio out of range.'
              write(*, *) 'Please set HydPeak between 0 and 1.'
              call calerrout
              stop
            end if

          case (HydtypeRectangular)
            read(103,*) hydDuration(l), hydVolume(l)
            read(103,*) huuPeak(l), (cduPeak(k, l), k = 1, idnum)

            hydPeakrate(l) = hydVolume(l) / hydDuration(l)

            write(*, *)
            write(*, '("Hydro No: ", i5)') l
            write(*, *) hydDuration(l), hydVolume(l), hydPeakrate(l)
            write(*, *) huuPeak(l), (cduPeak(k, l), k = 1, idnum)

          case (HydtypeArbitrary)
                  read(103,*) hydPeakrate(l)
                  write(*,'("Peak rate =",1pe12.3)') hydPeakrate(l)
                  i = 1
                  do
                    read(103,*,iostat=err) tt(i, l), qia(i, l)
                    if (err /= 0) exit
                    write(*,*) i,tt(i, l), qia(i, l)
                    
                    i = i + 1
                    
                  end do
                  tt(:, l) = 60.d0 * tt(:, l)
                  hydDuration(l) = tt(i-1, l)
                  nhydCount(l) = i-1

          case default
            write(*, '("Unknown hydrograph type: ", i5)') ihydType
            call calerrout
            stop
        end select

      end do

      ! Assuming max river length = diagonal length of DEM and flow vel. = 1.0 m/s
      simDuration = maxval(hydDuration) 
     $            + sqrt(imx * dlx * imx * dlx
     $            +      jmy * dly * jmy * dly) / 1.d0

      write(*,'("duration of hydro = ",1pe12.3," [sec]")') 
     * maxval(hydDuration)
      write(*,'("simDuration = ",1pe12.3," [sec]")') 
     * simDuration
      

      close(103)

      return
      end

c**********************************************
      subroutine  input_inflow_point
c**********************************************

c----------------------------------------------
      include 'lahar2d.inc' 
c----------------------------------------------


      integer err,px,py
      character(len=iflen_in(4)) finf_p

      real(8) :: tmp(nlhd)
      real(8) :: qqx, qqy, qqmax

      integer(4) :: uniqueCol(2, nh)
      integer(4) :: uniqueRow(2, nh)
      integer(4) :: nUniqueCol, nUniqueRow
      integer(4) :: ipp_dir(nlhd)
      integer(4) :: maxPnt, minPnt, maxIdx, minIdx
      
    
      tmp = 1.0e+12
      
      finf_p=trim(adjustl(infpath(4)))//trim(adjustl(infname(4)))
      open(104,file=finf_p,action='read',iostat=err)
      if(err/=0) then
            write(*,*) 'cannot open file 104 finf_p'
            call calerrout
            stop
      end if
      

      do llq = 1, lhd
        read(104, *) num(llq),ifp_dir(llq),bi0(llq),slu(llq)
        do i = 1, num(llq)
          read(104, *) ifp_col(i, llq), ifp_row(i, llq)
        end do

        write(*, '(" Num. of in pnts.: ", i5)') num(llq)
        write(*, '(" Inflow azimuth:      ", i5)') ifp_dir(llq)
        do i = 1, num(llq)
              write(*,'(2(i5))')ifp_col(i, llq),ifp_row(i, llq)
        end do
      end do

      bc_rate(:, :, :) = 0.d0
      qqmax = 0.d0
      do llq = 1, lhd
        
        
        i=0
        do while ( i == 0 )
            if (ifp_dir(llq) >= 0 .and. ifp_dir(llq) < 360 ) then
                i=1
            else if (ifp_dir(llq) < 0) then
                ifp_dir(llq) = ifp_dir(llq) + 360
            else if (ifp_dir(llq) >= 360 ) then
                ifp_dir(llq) = ifp_dir(llq) - 360
            end if
        end do
        
        if (ifp_dir(llq) ==   0) ipp_dir(llq) = 1
        if (ifp_dir(llq) ==  90) ipp_dir(llq) = 4
        if (ifp_dir(llq) == 180) ipp_dir(llq) = 3
        if (ifp_dir(llq) == 270) ipp_dir(llq) = 2
        if (  0 < ifp_dir(llq).and.ifp_dir(llq) <  90) ipp_dir(llq) = 8
        if ( 90 < ifp_dir(llq).and.ifp_dir(llq) < 180) ipp_dir(llq) = 7
        if (180 < ifp_dir(llq).and.ifp_dir(llq) < 270) ipp_dir(llq) = 6
        if (270 < ifp_dir(llq).and.ifp_dir(llq) < 360) ipp_dir(llq) = 5
        
      
        do i = 1, num(llq)
          px = ifp_col(i, llq) + 1
          py = jmy - 1 - ifp_row(i, llq)
          ifp_col(i, llq) = px
          ifp_row(i, llq) = py
          iqbc(1, i, llq) = px
          iqbc(2, i, llq) = py
          ipp(px, py) = ipp_dir(llq)
        end do

        qqx =   cos(dble(ifp_dir(llq)) * pi180) / dble(num(llq)) / dly
        qqy = - sin(dble(ifp_dir(llq)) * pi180) / dble(num(llq)) / dlx
        
       
      write(*, '("  divide rate : ", 2(1pe12.3))') 
     *  qqx, qqy
      write(*, '("  peakrate : ", 2(1pe12.3))') 
     *  maxval(hydPeakrate)
      write(*, '("  direction in calculation : ", i3)') 
     *  ifp_dir(llq)
      
        
        ! Superposition of discharge
        ! X direction
        call countUnique(num(llq), ifp_row(:, llq),
     $                   uniqueRow, nUniqueRow)
        do i = 1, nUniqueRow
          maxPnt = 0
          minPnt = 99999
          do j = 1, num(llq)
            if (ifp_row(j, llq) == uniqueRow(1, i)) then
                    if (ifp_col(j, llq) > maxPnt) then
                            maxPnt = ifp_col(j, llq)
                            maxIdx = j
                    end if
                    if (ifp_col(j, llq) < minPnt) then
                            minPnt = ifp_col(j, llq)
                            minIdx = j
                    end if
            end if
          end do

          if (qqx > 0.d0) then
                  bc_rate(1,maxIdx,llq) = abs(qqx*dble(uniqueRow(2,i)))
          else
                  bc_rate(1,minIdx,llq) = abs(qqx*dble(uniqueRow(2,i)))
          end if
        end do
        ! Y direction
        call countUnique(num(llq), ifp_col(:, llq),
     $                   uniqueCol, nUniqueCol)
        do i = 1, nUniqueCol
          maxPnt = 0
          minPnt = 99999
          do j = 1, num(llq)
            if (ifp_col(j, llq) == uniqueCol(1, i)) then
                    if (ifp_col(j, llq) > maxPnt) then
                            maxPnt = ifp_row(j, llq)
                            maxIdx = j
                    end if
                    if (ifp_col(j, llq) < minPnt) then
                            minPnt = ifp_row(j, llq)
                            minIdx = j
                    end if
            end if
          end do

          if (qqy > 0.d0) then
                  bc_rate(2,maxIdx,llq) = abs(qqy*dble(uniqueCol(2,i)))
          else
                  bc_rate(2,minIdx,llq) = abs(qqy*dble(uniqueCol(2,i)))
          end if
        end do

        ! Max discharge
        do j = 1, num(llq)
          qq_j = sqrt((hydPeakrate(llq)*bc_rate(1,j,llq))**2
     $         +      (hydPeakrate(llq)*bc_rate(2,j,llq))**2)
          if (qq_j > qqmax) qqmax = qq_j
        end do

        if(qqmax.le.0.0)  then
          write(*, *) 'ZERO or negative peak discharge.'
          call calerrout
          stop
        end if
        if(huuPeak(llq) <= 0.d0) then
                huuPeak(llq) = (qqmax*sodo/sqrt(slu(llq)))**0.6d0
                uu(llq) = 0.d0
                if(huuPeak(llq) > eps) then
                        uu(llq) = qqmax / huuPeak(llq)
                end if
        end if
        tmp(llq) = alpha * min(dlx, dly) / uu(llq)

        write(*,'("llq =",i7," tmp =",1pe12.3)') llq,tmp(llq)
        ! Make inflow discharge time series for Nakayasu

      end do

            
      !------------------------------!
      dlt = minval(tmp)
      dlt_org = dlt
      !------------------------------!
      write(*,'("dlt =",1pe12.3," tmp =",1pe12.3)') dlt,minval(tmp)
      
      close(104)
      
      return
      end

      subroutine countUnique(nn, a, aUnique, nUnique)
          implicit none
          integer(4) :: a(nn), aUnique(2, nn), aTmp(nn)
          integer(4) :: nn, i, ii, iUnique, nUnique
      
          call sort(nn, a, aTmp)
      
          i = 1
          nUnique = 1
          do while (i <= nn)
              iunique = 0
              do ii = i , nn
                  if (aTmp(i) == aTmp(ii)) then
                      iUnique = iUnique + 1
                      if (ii == nn) then
                          aUnique(1, nUnique) = aTmp(i)
                          aUnique(2, nUnique) = iUnique
                          i = nn + 1
                          exit
                      end if
                  else
                      aUnique(1, nUnique) = aTmp(i)
                      aUnique(2, nUnique) = iUnique
                      nUnique = nUnique + 1
                      i = ii
                      exit
                  end if
              end do
          end do
      
      
      end subroutine countUnique
      
      subroutine sort(n, a, b)
          implicit none
          integer(4) :: n, i, j
          integer(4) :: a(n), b(n), tmp
      
          b(:) = a(:)
          do i = 1, n - 1
              do j = i + 1, n
                  if (b(i) > b(j)) then
                      tmp = b(i)
                      b(i) = b(j)
                      b(j) = tmp
                  end if
              end do
          end do
      
          return
      end subroutine sort



c**********************************************
      subroutine  input_base_dem
c**********************************************

c----------------------------------------------
      include 'lahar2d.inc' 
c----------------------------------------------


      integer err,i,j,k,l,rows,cols
      character(len=iflen_in(5)) fbasedem
      character(len=iflen_in(6)) fcurrdem
      character(len=200) dummy
      
      fbasedem=trim(adjustl(infpath(5)))//trim(adjustl(infname(5)))
      open(105,file=fbasedem,action='read',iostat=err)
      if(err/=0) then
            write(*,*) 'cannot open file 105 fbasedem'
            call calerrout
            stop
      end if
      
      read(105,*) dummy,dummy
      read(105,*) dummy,dummy
      read(105,*) dummy,dummy
      read(105,*) dummy,dummy
      read(105,*) dummy,rows
      read(105,*) dummy,cols
      
      if(imx/=cols+2 .or. jmy/=rows+2) then
            write(*,*)
            write(*,'("error in input_base_dem")')
            write(*,*)imx,imy,cols,rows
            write(*,'("STOP")')
            write(*,*)
            call calerrout
            stop
      end if
      
      
      do j=rows+1,2,-1
            read(105,*) (zi0(i,j),i=2,cols+1)
      end do
      
      close(105)
      
      fcurrdem=trim(adjustl(infpath(6)))//trim(adjustl(infname(6)))
      open(106,file=fcurrdem,action='read',iostat=err)
      if(err/=0) then
            write(*,*) 'cannot open file 106 fcurrdem'
            call calerrout
            stop
      end if
      
      read(106,*) dummy,dummy
      read(106,*) dummy,dummy
      read(106,*) dummy,dummy
      read(106,*) dummy,dummy
      read(106,*) dummy,rows
      read(106,*) dummy,cols
      
      if(imx/=cols+2 .or. jmy/=rows+2) then
            write(*,*)
            write(*,'("error in input_current_dem")')
            write(*,'("STOP")')
            write(*,*)
            call calerrout
            stop
      end if
      
      
      do j=rows+1,2,-1
            read(106,*) (zi(i,j),i=2,cols+1)
      end do
      
      ! copy initial elevation      
      do j=1,jmy
            do i=1,imx
                  zl1(i,j) = zi(i,j)
                  zl3(i,j) = zi(i,j)
                  
                  if(zl1(i,j)/=zl1(i,j) .or. zl3(i,j)/=zl3(i,j)) then
                        write(*,*)
                        write(*,'("error in input_current_dem:NaN")')
                        write(*,'("STOP")')
                        write(*,*)
                        call calerrout
                        stop
                  end if
            end do
      end do
      
      do j=1,jmy
            ibc(1,j) = 2
            ibc(2,j) = 2
            do i=1,imx
                  adz(i,j) = 0.0
                  ibz(i,j) = 0
                  kabe(i,j)= 0
            end do
      end do
      
      ! set boundary flag
      do j=2,jm0
            do i=2,im0
                  if(zi(i-1,j).lt.0.0.and.zi(i,j).ge.0.0) then
                        ibc(1,j) = i
                        exit
                  end if
            end do

             do i=im0,2,-1
                  if(zi(i+1,j).lt.0.0.and.zi(i,j).ge.0.0) then
                        ibc(2,j) = i
                        exit
                  end if
            end do
      end do
      
      ! set initial river bed erosion
      if(iel == 1) then
            do j=rows+1,2,-1
                  read(106,*) (adz(i,j),i=2,cols+1)
            end do
      end if
      
      do j=1,jmy
            do i=1,imx
                  if(zi(i,j) < 0.0) ibz(i,j) = -1
                  zdl(i,j) = zi(i,j) - adz(i,j)
            end do
      end do

      if(ickb == 1) then
            do j=rows+1,2,-1
                  read(106,*) (kabe(i,j),i=2,cols+1)
            end do
      end if
      
      if(indst > 1)  then
            do j=rows+1,2,-1
                  read(106,*) (idist(i,j),i=2,cols+1)
            end do
      end if
      
      close(106)
      
      do j=1,jmy
            do i=1,imx
                  if(zi(i,j) >= 0.0) then                        
                        if(adz(i,j) > 0.0) then
                              dmix(i,j) = dmix0
                              ddz2(i,j) = adz(i,j) - dmix0
                              
                              if(adz(i,j) < dmix0)  then
                                    dmix(i,j) = adz(i,j)
                                    ddz2(i,j) = 0.0
                              end if
                        
                        else
                             dmix(i,j) = 0.0
                             ddz2(i,j) = 0.0
                        end if
                  end if
      
                  k = idist(i,j)
                  do l = 1 , idnum
      
                        qmb(l,i,j) = 0.0
                        qnb(l,i,j) = 0.0
                        dzd1(l,i,j) = 0.0
                        dzd2(l,i,j) = 0.0
                        qmbdt(l,i,j) = 0.0
                        qnbdt(l,i,j) = 0.0
                        qmbs1(l,i,j) = 0.0
                        qmbs2(l,i,j) = 0.0
                        qnbs1(l,i,j) = 0.0
                        qnbs2(l,i,j) = 0.0
                  
                        if(zi(i,j) < 0.0)  cycle
                  
                        dzd1(l,i,j) = dmix(i,j) *  dist(l,k)
                        dzd2(l,i,j) = ddz2(i,j) *  dist(l,k)
                  end do
            end do
      end do
      
      return
      end

c -------------------------

      subroutine  set_init

c ------------------------
      include 'lahar2d.inc'

      exo = 10000.0
      exu = -exo
      exm = 0.00000001
      wbl = 0.0
      vbl = 0.0
      icheck = 0

      ddxy = dlx * dly
      ddxyc = dlx * dly * cst
      
      if(ddxy == 0.0 .or. ddxyc == 0.0) then
            write(*,*)
            write(*,'("error in set_init:seed of NaN")')
            write(*,'("ddxy=",f8.2," ddxyc=",f8.2)')ddxy,ddxyc
            write(*,'("dlx=",f8.2," dly=",f8.2," cst=",f8.2)')
     *      dlx,dly,cst
            write(*,'("STOP")')
            write(*,*)
            call calerrout
            stop
      end if

      do j=1,jmy
            do i=1,imx
                  hh01(i,j) = 0.0
                  hh1(i,j) = 0.0
                  hh3(i,j) = 0.0
                  qm02(i,j) = 0.0
                  qn02(i,j) = 0.0
                  qm0(i,j) = 0.0
                  qn0(i,j) = 0.0
                  qm2(i,j) = 0.0
                  qn2(i,j) = 0.0
                  qmbtt(i,j) = 0.0
                  qnbtt(i,j) = 0.0
                  vx(i,j) = 0.0
                  uvx(i,j) = 0.0
                  egx(i,j) = 0.0
                  uy(i,j) = 0.0
                  uvy(i,j) = 0.0
                  egy(i,j) = 0.0
                  zi(i,j) = -1.0
                  zi0(i,j) = -1.0
                  zl1(i,j) = -1.0
                  zl3(i,j) = -1.0
                  ipp(i,j) = 0
                  idist(i,j) = 1

                  qmt(i,j) = 0.0
                  qnt(i,j) = 0.0
                  hmax(i,j) = 0.0
                  qmax(i,j) = 0.0
                  fmax(i,j) = 0.0
                  qxm(i,j) = 0.0
                  qym(i,j) = 0.0
                  vxm(i,j) = 0.0
                  vym(i,j) = 0.0
                  cmax(i,j) = 0.0
                  cd3(i,j) = 0.0

                  artime(i,j) = 0.0
                  uvmax(i,j) = 0.0
                  hh3max(i,j) = 0.0
                  qmax2(i,j) = 0.0
      
                  dm(i,j)   = 0.0
                  dmix(i,j) = 0.0
                  ddz2(i,j) = 0.0
             end do     
      end do

      ! Accumulation of input discharge
      qitt    = 0.d0
      qbtt    = 0.d0
      qbit(:) = 0.d0
      

      return
      end

C ----------------------

      subroutine  setcd(llq, qql)

C -----------------------
      include 'lahar2d.inc'

      dimension  qbb0(200),qbb1(200),ccd(200)

      real*8 p
      p=0.0d0

      isw = 0

       h0  = 0.0
       bb0 = 0.0
        if(qql.le.0.0)  go to 3800
        bb0 = alph * sqrt( qql )
        if(bb0.gt.bi0(llq))  bb0 = bi0(llq)

        h0 = ( qql * sodo / bb0 / sqrt(slu(llq)) )**.6


 3800 continue
        hin = h0

        do 3000 l=1,idnum
         if(cdu(l,llq).lt.0.0)  isw = 1
         qbb0(l) = qql * cdu(l,llq) * dlt * 2.d0
         qbt0 = qbt0 + qbb0(l)
         if(isw.eq.1.and.qql.gt.0.0) qbb0(l) = -1.d0
 3000   continue

       if(cdu(1,llq).lt.0.0)  qbt0 = -1.0
       if(isw.eq.1)  qbtt = -1.0

      qbt1 = 0.0
      ust = sqrt( hin * slu(llq) * 9.8 )


      do 4000 l = 1 , idnum

      qbb1(l) = 0.0
      ccd(l)  = 0.0

      tast0 = hin * slu(llq) / ss1 / gsd(l)
      aa = gsd(l) / dm0
      if(aa.lt.0.4)  tastc = 0.85 * tastcm / aa
      if(aa.ge.0.4)  then
         a1 = 1.27875360095  / dlog10( 19.0 * aa )
         tastc = a1 * a1 * tastcm
      end if


      if(tast0.lt.tastc)  go to  4000

      a1 = fbed(tast0,tastc)

      a2 = a1 * sqrt( ss1 * 9.8 * gsd(l)**3 )
      df = dsinp(l)

      qbb = a2 * df

      qbs = 0.0


      if(ild.eq.0) go to 6000

      if(qql.le.0.0)  go to 6000


      df = df * 100.0
      uust = qql / hin / bb0 / ust
      wust = w0(l) / ust
      if(wust/=wust .or. wust==0.0d0) then
            write(*,'("ERROR in setcb 1")')
            call calerrout
            stop
      end if

      dst = 0.5 / wust * exp( - wust * wust )
      cb = 5.55 * df * dst**1.61


      p=0.0d0

!-----------
      call pcal(wust,uust,p)
!----------

      qbs = qql * cb * p / bb0 * 1.0e-6

 6000 continue

      qb = qbb + qbs

      qbb1(l) = qb * bb0 * dlt * 2.d0
      ccd(l) = 0.0
      if(qql.gt.0.0)   ccd(l) = qb * bb0 / qql
      qbt1 = qbt1 + qbb1(l)

 4000 continue

         qbt1 = 0.0
         isw = 0

         if(cdu(1,llq).lt.0.0)  isw = 1
        do 3020 l = 1,idnum
          if(cdu(l,llq).gt.ccd(l))  cdu(l,llq) = ccd(l)
          if(isw.eq.1)   cdu(l,llq) = ccd(l)
          qbb1(l) = cdu(l,llq) * qql * dlt * 2.d0
          qbt1 = qbt1 + qbb1(l)
 3020 continue

       qitt = qitt + qql * dlt * 2.d0
       qbtt = qbtt + qbt1

      do 2032  l = 1, idnum
        qbit(l) = qbit(l) + qbb1(l)
 2032 continue


      return

      end

C -----------------------

      subroutine  debin(dt1)

C ----------------------
      include 'lahar2d.inc'

      dimension  qqb(200,200),qbin(200),qcd(200)
      real(8) :: q0, q1, t0, t1
      write(2,200)

!!--- Definition of qi0(llq), huu(llq), cdu(k, llq)
      do llq = 1, lhd
        ! make information for inflow point (at LLQ)
        !  - Water depth
        !  - sediment concentrations

        select case (ihydType(llq))

          case (HydtypeTriangular)
              Peaktime = hydDuration(llq) * hydPeaktime(llq)
              if (0.d0 <= dt1 .and. dt1 < Peaktime) then
                      tt1 = dt1 / Peaktime
                      huu(llq) = huuPeak(llq) * tt1
                      qi0(llq) = hydPeakrate(llq) * tt1
                      if (minval(cduPeak(:, llq)) > 0.d0) then
                        do k = 1, idnum
                          cdu(k, llq) = cduPeak(k, llq) * tt1
                        end do
                      end if
                      call setcd(llq, qi0(llq))

              else if (Peaktime <= dt1 
     $           .and. dt1 < hydDuration(llq)) then
                      tt1 = (hydDuration(llq) - dt1) 
     $                    / (hydDuration(llq) - Peaktime)
                      huu(llq) = huuPeak(llq) * tt1
                      qi0(llq) = hydPeakrate(llq) * tt1
                      if (minval(cduPeak(:, llq)) > 0.d0) then
                        do k = 1, idnum
                          cdu(k, llq) = cduPeak(k, llq) * tt1
                        end do
                      end if
                      call setcd(llq, qi0(llq))

              else
                      huu(llq)    = 0.d0
                      qi0(llq) = 0.d0
                      do k = 1, idnum
                        cdu(k, llq) = 0.d0
                      end do
              end if

          case (HydtypeRectangular)
                  if (0.d0 <= dt1 .and. dt1 < hydDuration(llq)) then
                      huu(llq)    = huuPeak(llq)
                      qi0(llq) = hydPeakrate(llq)
                      if (minval(cduPeak(:, llq)) > 0.d0) then
                        do k = 1, idnum
                          cdu(k, llq) = cduPeak(k, llq)
                        end do
                      end if
                      call setcd(llq, qi0(llq))
                  else
                      qi0(llq) = 0.d0
                      do k = 1, idnum
                        cdu(k, llq) = 0.d0
                      end do
                      huu(llq)    = 0.d0
                  end if
                  
          case(HydtypeArbitrary)
                  if (lhyd(llq)+1 < nhydCount(llq)) then
                          if ( lhyd(llq) == 1) then
                            t0 = 0.d0
                            t1  = tt(lhyd(llq), llq)
                          else
                            t0  = tt(lhyd(llq)-1,   llq)
                            t1  = tt(lhyd(llq), llq)
                          end if
                          
                          q0  = qia(lhyd(llq),   llq)
                          q1  = qia(lhyd(llq)+1, llq)
                          
                          qi0(llq) = q0  + (q1  - q0)/(t1 - t0)
     $                                  *  (dt1 - t0)
                          
                          if (qi0(llq) < 0.0d0) qi0(llq) = -qi0(llq)
                          
                          do k = 1, idnum
                            cdu(k, llq) = -1.d0
                          end do
                          
                          call setcd(llq, qi0(llq))
                  else
                          do k = 1, idnum
                            cdu(k, llq) = 0.d0
                          end do
                          huu(llq) = 0.d0
                          qi0(llq) = 0.d0
                  end if
                  
          case default
                  write(*, '("Unknown hydrograph type: ", i5)') 
     $              ihydType(llq)
                  call calerrout
                  stop
        end select
      end do


        do 9000 llq = 1 , lhd

        q1 = qi0(llq)
        
        if(q1.le.eps)  then
            qq(llq) = 0.0
            hu(llq) = 0.0
            uu(llq) = 0.0
            go to  7000
        end if
        
        bb0 = alph * sqrt(q1)
        if(bb0.gt.bi0(llq))  bb0 = bi0(llq)

        q1 = q1 / bb0

        
        if(q1.le.eps .and. huu(llq) .le. eps)  then
            
          qq(llq) = 0.0
          hu(llq) = 0.0
          uu(llq) = 0.0
          go to  7000
        end if
        
         do 4100 k = 1,idnum
          if(q1.le.0.0)  cd(k,llq) = 0.0
          cd(k,llq) = cdu(k,llq)
          qqb(k,llq) = qi0(llq) * cdu(k,llq)
 4100   continue
        
     
         qq(llq) = q1
         
        if(huu(llq).gt.0.0)  go to 5000
         hu(llq) = ( q1 * sodo / sqrt(slu(llq)) )**.6
         uu(llq) = 0.0
         if(hu(llq).gt.eps)  uu(llq) = qq(llq) / hu(llq)
        go to 6000

 5000   continue
        
        
        hu(llq) = huu(llq)
        uu(llq) = qq(llq) / huu(llq)
 6000   continue


 7000   continue
        write(2,201)  llq
        write(2,202)  l
        write(2,205)
        cdt = 0.0
        qbtin = 0.0

        do 4200 l0 = 1 ,idnum
         qcd(l0)  =  cd(l0,llq)
         qbin(l0) =  qi0(llq) * cdu(l0,llq) * dlt * 2.d0
         qbtin = qbtin + qbin(l0)
         write(2,210)  gsd(l0),cd(l0,llq),qcd(l0),qbin(l0)
 4200   continue
        if(qi0(llq).gt.0.0)  cdt = qbtin /  (qi0(llq) * dlt * 2.d0)

        write(2,220)
        write(2,230)  qbtin
        write(2,100)  qq(llq),uu(llq),hu(llq)
        write(2,110)  cdt,cmpm
        
        
        
        if(qq(llq)/=qq(llq).or.hu(llq)/=hu(llq)
     *   .or.uu(llq)/=uu(llq)) then
            write(*,'(" !!! Error in (debin): result is NaN !!!")')
            
            write(*,'(6(1pe12.3))') 
     *       dt1,qi0(llq),qq(llq),uu(llq),hu(llq),eps
            write(*,'(6(1pe12.3))') q1,sodo,slu(llq),bb0,dlt
            do i = 1, idnum
                write(*,'(6(1pe12.3))') cdu(i,llq)
            end do
            write(*,'(" !!! Stop !!!")')
            write(*,*)
            call calerrout
            stop
      end if
      
        
 9000   continue
c==============================================================

      do llq = 1, lhd
        do ib = 1, num(llq)
          ix = iqbc(1, ib, llq)
          jy = iqbc(2, ib, llq)

           hh01(ix,jy) = hu(llq)
           hh1(ix,jy) = hu(llq)
           hh3(ix,jy) = hu(llq)
           ibz(ix,jy) = 0

          !*East
          if(ipp(ix,jy).eq.1.or.ipp(ix,jy).eq.5
     $                      .or.ipp(ix,jy).eq.8)  then
              qm2(ix+1,jy)  = qi0(llq) * bc_rate(1,ib,llq)
              qm0(ix+1,jy)  = qi0(llq) * bc_rate(1,ib,llq)
              qm02(ix+1,jy) = qi0(llq) * bc_rate(1,ib,llq)
              uvx(ix+1,jy)  = uu(llq) * bc_rate(1,ib,llq)
              do k = 1,idnum
                qmb(k,ix+1,jy) = qqb(k,llq) * bc_rate(1,ib,llq)
              end do
          end if

          !*West
          if(ipp(ix,jy).eq.3.or.ipp(ix,jy).eq.6
     $                      .or.ipp(ix,jy).eq.7)  then
              qm2(ix,jy)  = -qi0(llq) * bc_rate(1,ib,llq)
              qm0(ix,jy)  = -qi0(llq) * bc_rate(1,ib,llq)
              qm02(ix,jy) = -qi0(llq) * bc_rate(1,ib,llq)
              uvx(ix,jy)  = uu(llq) * bc_rate(1,ib,llq)
              do k = 1,idnum
                qmb(k,ix,jy)  = -qqb(k,llq) * bc_rate(1,ib,llq)
              end do
          end if

          !*North
          if(ipp(ix,jy).eq.2.or.ipp(ix,jy).eq.5
     $                      .or.ipp(ix,jy).eq.6)  then
              qn2(ix,jy+1)  = qi0(llq) * bc_rate(2,ib,llq)
              qn0(ix,jy+1)  = qi0(llq) * bc_rate(2,ib,llq)
              qn02(ix,jy+1) = qi0(llq) * bc_rate(2,ib,llq)
              uvy(ix,jy+1)  = uu(llq) * bc_rate(2,ib,llq)
              do k = 1,idnum
                qnb(k,ix,jy+1) = qqb(k,llq) * bc_rate(2,ib,llq)
              end do
          end if

          !*South
          if(ipp(ix,jy).eq.4.or.ipp(ix,jy).eq.7
     $                      .or.ipp(ix,jy).eq.8)  then
             qn2(ix,jy)   = -qi0(llq) * bc_rate(2,ib,llq)
             qn0(ix,jy)   = -qi0(llq) * bc_rate(2,ib,llq)
             qn02(ix,jy)  = -qi0(llq) * bc_rate(2,ib,llq)
             uvy(ix,jy)   = uu(llq) * bc_rate(2,ib,llq)
             do k = 1,idnum
               qnb(k,ix,jy)  = -qqb(k,llq) * bc_rate(2,ib,llq)
             end do
          end if

        end do
      end do
      
      return

  100 format( 5x,' qq = ',f10.6,5x,' uu = ',f10.6,5x,' hu = ',f10.6)
  110 format( 5x,' cd = ',f10.6,5x,'cmpm= ',f10.6)
  200 format(1h1//1x,'  *** calculation condition ***  '//)
  201 format(1h //,'.......... hydrograph no.',i3)
  202 format(1h //,'.......... hydrograph step.',i3)
  205 format( 5x,' grain size       cdu  bedload/1mesh     bedload')
  210 format( 5x,f12.4,f12.8,2f12.4)
  220 format( 5x,'-------------------------------------------------')
  230 format( 5x,'                       total bedload',f12.4/)

      end
C -----------------------------

      subroutine  mncal(dt)

C ----------------------------
      include 'lahar2d.inc'

      dt2 = 1.0 / (2.0*dt)

      do 2000 j=2,jm0
      do 1000 i=ibc(1,j),ibc(2,j)

c============================================================= boundary
        if(zi(i,j).lt.0.0)  go to 1000
        if(ipp(i-1,j).gt.0.or.ipp(i,j).gt.0)  go to 3000
c======================================================================

        if((zi(i-1,j).ge.0.0).and.
     *    (kabe(i-1,j).ne.1).and.(kabe(i-1,j).ne.3))  go to 4000
       qm2(i,j) = 0.0
       go to 3000
 4000 continue
       qm2(i,j) = 0.0

      h0 = hh1(i,j) + hh1(i-1,j)

      a6 = 0.0
      a7 = 0.0
      a8 = 0.0

c.................................................................. xdx
      a1 = 0.0
      a2 = 0.0
      h1 = hh1(i+1,j) + hh1(i  ,j) + hh01(i+1,j) + hh01(i  ,j)
      h2 = hh1(i  ,j) + hh1(i-1,j) + hh01(i,  j) + hh01(i-1,j)

      if(h1.ge.eps)  a1 = 2.0 * ( qm0(i+1,j) + qm02(i+1,j) ) / h1
      if(h2.ge.eps)  a2 = 2.0 * ( qm0(i  ,j) + qm02(i  ,j) ) / h2

c============================================================= boundary
      if(ipp(i+1,j).gt.0)  then
         id = ipp(i+1,j)
         if(ipf(id).eq.2)   a1 = -uu(id)
      end if
c======================================================================

      u1 = a1 + a2

      a1 = 0.0
      a2 = 0.0
      h1 = hh1(i,  j) + hh1(i-1,j) + hh01(i  ,j) + hh01(i-1,j)
      h2 = hh1(i-1,j) + hh1(i-2,j) + hh01(i-1,j) + hh01(i-2,j)
      if(h1.ge.eps)  a1 = 2.0 * ( qm0(i  ,j) + qm02(i  ,j) ) / h1
      if(h2.ge.eps)  a2 = 2.0 * ( qm0(i-1,j) + qm02(i-1,j) ) / h2

c============================================================= boundary
      if(ipp(i-2,j).gt.0)  then
        id = ipp(i-2,j)
        if(ipf(id).eq.1)   a2 = uu(id)
      end if
c======================================================================

      u0 = a1 + a2

      q3 = ( qm0(i+1,j) + qm02(i+1,j) ) / 2.0
      q2 = ( qm0(i  ,j) + qm02(i  ,j) ) / 2.0
      q1 = ( qm0(i-1,j) + qm02(i-1,j) ) / 2.0

      xdx =  u1 * ( q2 + q3 ) + abs( u1 ) * ( q2 - q3 )
     *     - u0 * ( q1 + q2 ) - abs( u0 ) * ( q1 - q2 )
      xdx = xdx / dlx / 4.0


c................................................................. xdy

      q1 = ( qm0(i,j-1) + qm02(i,j-1) ) / 2.0
      q2 = ( qm0(i,j  ) + qm02(i,j  ) ) / 2.0
      q3 = ( qm0(i,j+1) + qm02(i,j+1) ) / 2.0

      v1= 0.0
      a1 = 2.0 * ( qn0(i-1,j) + qn02(i-1,j) )
      h1 = hh1(i-1,j) + hh1(i-1,j-1) + hh01(i-1,j) + hh01(i-1,j-1)
      if(h1.ge.eps)  v1 = a1 / h1

      v2 = 0.0
      a2 = 2.0 * ( qn0(i-1,j+1) + qn02(i-1,j+1) )
      h2 = hh1(i-1,j+1) + hh1(i-1,j) + hh01(i-1,j+1) + hh01(i-1,j)
      if(h2.ge.eps)  v2 = a2 / h2

      v3 = 0.0
      a3 = 2.0 * ( qn0(i,j) + qn02(i,j) )
      h3 = hh1(i,j) + hh1(i,j-1) + hh01(i,j) + hh01(i,j-1)
      if(h3.ge.eps)  v3 = a3 / h3

      v4 = 0.0
      a4 = 2.0 * ( qn0(i,j+1) + qn02(i,j+1) )
      h4 = hh1(i,j+1) + hh1(i,j) + hh01(i,j+1) + hh01(i,j)
      if(h4.ge.eps)  v4 = a4 / h4

      xdy =  (v2 + v4) * (q2 + q3) + abs(v2 + v4) * (q2 - q3)
     *     - (v1 + v3) * (q1 + q2) - abs(v1 + v3) * (q1 - q2)
      xdy = xdy / dly / 4.0

      a5 = bex * xdx + bex * xdy

      if(h0.lt.eps)  go to 2250

      a6 = -9.8 * h0 / (2.0 * dlx)
      a6 = a6 * (hh1(i,j) + zl1(i,j) - hh1(i-1,j) - zl1(i-1,j))

      u0 = 0.0
      h9 = hh01(i,j) + hh01(i-1,j) + hh1(i,j) + hh1(i-1,j)
      if(h9.ge.eps)  u0 = 2.0 * ( qm0(i,j) + qm02(i,j) ) / h9

      call v0cal(i,j,v1,v2,v3,v4,v0)

      a8 = -9.8 * sodo * sodo * sqrt( u0*u0 + v0*v0 )
      a8 = a8 / h0 / ( h0/2.0 )**(1.0/3.0)

 2250 continue
      a9 = a6 + a7 - a5 + qm0(i,j) * ( dt2 + a8)
      a0 = dt2 - a8
      qm2(i,j) = a9 / a0

      if(qm2(i,j).lt.-exo)  call calerr(dt1,dt,'qm--')
      if(qm2(i,j).gt. exo)  call calerr(dt1,dt,'qm++')

      
      if(qm2(i,j) /= qm2(i,j)) then
            write(*,'(" !!! Error in (mncal): result is NaN !!!")')
            
            write(*,'("i=",i5," j=",i5)')i,j
            write(*,'(" qm2=",f8.2," qn2=",f8.2)')
     *       qm2(i,j),qn2(i,j)
            write(*,'(6(1pe12.3))') a0,a5,a6,a8,dt2,dt
            write(*,'(6(1pe12.3))') bey,ydy,bey,ydx,dlx
            write(*,'(6(1pe12.3))') a1,a2,a3,a4
            write(*,'(6(1pe12.3))') u1,u2,u3,u4
            write(*,'(6(1pe12.3))') q1,q2,q3,q4
            write(*,'(6(1pe12.3))') dt1,qi0(1),hu(1),uu(1)
            write(*,'(4(1pe12.3))') zi(i,j),zl1(i,j),zl3(i,j)     
            write(*,'(" !!! Stop !!!")')
            write(*,*)
            call calerrout
            stop
      end if
      
 3000 continue
c============================================================= boundary
      if(ipp(i,j).gt.0.or.ipp(i,j-1).gt.0)  go to 1000
c======================================================================
      if((zi(i,j-1).ge.0.0).and.
     *  (kabe(i,j-1).ne.2).and.(kabe(i,j-1).ne.3))   go to 5000
       qn2(i,j) = 0.0
       go to 1000
 5000 continue
       qn2(i,j) = 0.0

      h0 = hh1(i,j) + hh1(i,j-1)

      a6 = 0.0
      a7 = 0.0
      a8 = 0.0

c.................................................................. ydy
      a1 = 0.0
      a2 = 0.0
      h1 = hh1(i,j+1) + hh1(i,j  ) + hh01(i,j+1) + hh01(i,j  )
      h2 = hh1(i,j  ) + hh1(i,j-1) + hh01(i,j  ) + hh01(i,j-1)
      if(h1.ge.eps)  a1 = 2.0 * ( qn0(i,j+1) + qn02(i,j+1) ) / h1
      if(h2.ge.eps)  a2 = 2.0 * ( qn0(i  ,j) + qn02(i  ,j) ) / h2

c============================================================= boundary
      if(ipp(i,j+1).gt.0)  then
         id = ipp(i,j+1)
         if(ipf(id).eq.4)   a1 = -uu(id)
      end if
c======================================================================

      v1 = a1 + a2

      a1 = 0.0
      a2 = 0.0
      h1 = hh1(i,  j) + hh1(i,j-1) + hh01(i  ,j) + hh01(i,j-1)
      h2 = hh1(i,j-1) + hh1(i,j-2) + hh01(i,j-1) + hh01(i,j-2)
      if(h1.ge.eps)  a1 = 2.0 * ( qn0(i  ,j) + qn02(i  ,j) ) / h1
      if(h2.ge.eps)  a2 = 2.0 * ( qn0(i,j-1) + qn02(i,j-1) ) / h2

c============================================================= boundary
      if(ipp(i,j-2).gt.0)  then
        id = ipp(i,j-2)
        if(ipf(id).eq.3)   a2 = uu(id)
      end if
c======================================================================

      v0 = a1 + a2

      q1 = ( qn0(i,j-1) + qn02(i,j-1) ) / 2.0
      q2 = ( qn0(i  ,j) + qn02(i  ,j) ) / 2.0
      q3 = ( qn0(i,j+1) + qn02(i,j+1) ) / 2.0

      ydy =  v1 * ( q2 + q3 ) +  abs( v1 ) * ( q2 - q3 )
     *     - v0 * ( q1 + q2 ) -  abs( v0 ) * ( q1 - q2 )
      ydy = ydy / dly / 4.0

c.................................................................. ydx

      u1= 0.0
      a1 = 2.0 * ( qm0(i,j-1) +  qm02(i,j-1) )
      h1 = hh1(i,j-1) + hh1(i-1,j-1) + hh01(i,j-1) + hh01(i-1,j-1)
      if(h1.ge.eps)  u1 = a1 / h1

      u2 = 0.0
      a2 = 2.0 * ( qm0(i+1,j-1) + qm02(i+1,j-1) )
      h2 = hh1(i+1,j-1) + hh1(i,j-1) + hh01(i+1,j-1) + hh01(i,j-1)
      if(h2.ge.eps)  u2 = a2 / h2

      u3 = 0.0
      a3 = 2.0 * ( qm0(i,j) + qm02(i,j) )
      h3 = hh1(i,j) + hh1(i-1,j) + hh01(i,j) + hh01(i-1,j)
      if(h3.ge.eps)  u3 = a3 / h3

      u4 = 0.0
      a4 = 2.0 * ( qm0(i+1,j) + qm02(i+1,j) )
      h4 = hh1(i+1,j) + hh1(i,j) + hh01(i+1,j) + hh01(i,j)
      if(h4.ge.eps)  u4 = a4 / h4

      q1 = ( qn0(i-1,j) + qn02(i-1,j) ) / 2.0
      q2 = ( qn0(i  ,j) + qn02(i  ,j) ) / 2.0
      q3 = ( qn0(i+1,j) + qn02(i+1,j) ) / 2.0

      ydx =  (u2 + u4) * (q2 + q3) +  abs(u2 + u4) * (q2 - q3)
     *     - (u1 + u3) * (q1 + q2) -  abs(u1 + u3) * (q1 - q2)
      ydx = ydx / dlx / 4.0

      a5 = bey * ydy + bey * ydx

      if(h0.lt.eps)  go to 2400

      a6 = -9.8 * h0 / (2.0 * dly)
      a6 = a6 * (hh1(i,j) + zl1(i,j) - hh1(i,j-1) - zl1(i,j-1))

      call u0cal(i,j,u1,u2,u3,u4,u0)

      v0 = 0.0
      h9 = hh01(i,j) + hh01(i,j-1) + hh1(i,j) + hh1(i,j-1)
      if(h9.ge.eps)  v0 = 2.0 * ( qn0(i,j) + qn02(i,j) ) / h9

      a8 = -9.8 * sodo * sodo * sqrt( u0*u0 + v0*v0 )
      a8 = a8 / h0 / ( h0/2.0 )**(1.0/3.0)
 2400 continue
      a9 = a6 + a7 - a5 + qn0(i,j)*(dt2 + a8)
      a0 = dt2 - a8
      qn2(i,j) = a9 / a0

      if(qn2(i,j).lt.-exo)  call calerr(dt1,dt,'qm--')
      if(qn2(i,j).gt. exo)  call calerr(dt1,dt,'qm++')


      if(qn2(i,j) /= qn2(i,j)) then
            write(*,'(" !!! Error in (mncal): result is NaN !!!")')
            
            write(*,'("i=",i5," j=",i5)')i,j
            write(*,'(" qm2=",f8.2," qn2=",f8.2)')
     *       qm2(i,j),qn2(i,j)
            write(*,'(6(1pe12.3))') a0,a5,a6,a8,dt2,dt
            write(*,'(6(1pe12.3))') bey,ydy,bey,ydx,dlx
            write(*,'(6(1pe12.3))') a1,a2,a3,a4
            write(*,'(6(1pe12.3))') u1,u2,u3,u4
            write(*,'(6(1pe12.3))') q1,q2,q3,q4
            write(*,'(6(1pe12.3))') dt1,qi0(1),hu(1),uu(1)
            write(*,'(4(1pe12.3))') zi(i,j),zl1(i,j),zl3(i,j)     
            write(*,'(" !!! Stop !!!")')
            write(*,*)
            call calerrout
            stop
      end if

 1000 continue
 2000 continue

      
      return
      end
C --------------------------

      subroutine v0cal(i,j,v1,v2,v3,v4,v0)

C --------------------------
      include 'lahar2d.inc'

      v0 = ( v1 + v2 + v3 + v4 ) / 4.0

      if((ibz(i  ,j-1).lt.  0.or.kabe(i  ,j-1).ge.2).and.
     *   (ibz(i-1,j+1).lt.  0.or.kabe(i-1,j  ).ge.2).and.
     *   (ibz(i  ,j+1).lt.  0.or.kabe(i  ,j  ).ge.2))     go to 2500
      if((ibz(i-1,j-1).lt.  0.or.kabe(i-1,j-1).ge.2).and.
     *   (ibz(i  ,j-1).lt.  0.or.kabe(i  ,j-1).ge.2).and.
     *   (ibz(i  ,j+1).lt.  0.or.kabe(i  ,j  ).ge.2))     go to 2510
      if((ibz(i-1,j-1).lt.  0.or.kabe(i-1,j-1).ge.2).and.
     *   (ibz(i-1,j+1).lt.  0.or.kabe(i-1,j  ).ge.2).and.
     *   (ibz(i  ,j+1).lt.  0.or.kabe(i  ,j  ).ge.2))     go to 2520
      if((ibz(i-1,j-1).lt.  0.or.kabe(i-1,j-1).ge.2).and.
     *   (ibz(i  ,j-1).lt.  0.or.kabe(i  ,j-1).ge.2).and.
     *   (ibz(i-1,j+1).lt.  0.or.kabe(i-1,j  ).ge.2))     go to 2530

      if((ibz(i-1,j-1).lt.  0.or.kabe(i-1,j-1).ge.2).and.
     *   (ibz(i  ,j+1).lt.  0.or.kabe(i  ,j  ).ge.2))     go to 2540
      if((ibz(i  ,j-1).lt.  0.or.kabe(i  ,j-1).ge.2).and.
     *   (ibz(i-1,j+1).lt.  0.or.kabe(i-1,j  ).ge.2))     go to 2550
      if((ibz(i-1,j-1).lt.  0.or.kabe(i-1,j-1).ge.2).and.
     *   (ibz(i-1,j+1).lt.  0.or.kabe(i  ,j-1).ge.2))     go to 2560
      if((ibz(i-1,j-1).lt.  0.or.kabe(i-1,j-1).ge.2).and.
     *   (ibz(i  ,j-1).lt.  0.or.kabe(i  ,j-1).ge.2))     go to 2570
      if((ibz(i-1,j+1).lt.  0.or.kabe(i-1,j  ).ge.2).and.
     *   (ibz(i  ,j+1).lt.  0.or.kabe(i  ,j  ).ge.2))     go to 2580
      if((ibz(i  ,j-1).lt.  0.or.kabe(i  ,j-1).ge.2).and.
     *   (ibz(i  ,j+1).lt.  0.or.kabe(i  ,j  ).ge.2))     go to 2590

      if(ibz(i-1,j-1).lt.  0.or.kabe(i-1,j-1).ge.2)
     *                                    v0 = ( v2 + v3 + v4 ) / 3.0
      if(ibz(i-1,j+1).lt.  0.or.kabe(i-1,j  ).ge.2)
     *                                    v0 = ( v1 + v3 + v4 ) / 3.0
      if(ibz(i  ,j-1).lt.  0.or.kabe(i  ,j-1).ge.2)
     *                                    v0 = ( v1 + v2 + v4 ) / 3.0
      if(ibz(i  ,j+1).lt.  0.or.kabe(i  ,j  ).ge.2)
     *                                    v0 = ( v1 + v2 + v3 ) / 3.0
      go to 2800

 2500 continue
      v0 = v1
      go to 2800
 2510 continue
      v0 = v2
      go to 2800
 2520 continue
      v0 = v3
      go to 2800
 2530 continue
      v0 = v4
      go to 2800
 2540 continue
      v0 = ( v2 + v3 ) / 2.0
      go to 2800
 2550 continue
      v0 = ( v1 + v4 ) / 2.0
      go to 2800
 2560 continue
      v0 = ( v3 + v4 ) / 2.0
      go to 2800
 2570 continue
      v0 = ( v2 + v4 ) / 2.0
      go to 2800
 2580 continue
      v0 = ( v1 + v3 ) / 2.0
      go to 2800
 2590 continue
      v0 = ( v1 + v2 ) / 2.0

 2800 continue

      return
      end
C --------------------------

      subroutine u0cal(i,j,u1,u2,u3,u4,u0)

C ---------------------------
      include 'lahar2d.inc'

      u0 = ( u1 + u2 + u3 + u4 ) / 4.0

      if((ibz(i+1,j-1).lt.  0.or.kabe(i  ,j-1).eq.1).and.
     *   (ibz(i-1,j  ).lt.  0.or.kabe(i-1,j  ).eq.1
     *                       .or.kabe(i-1,j  ).eq.3).and.
     *   (ibz(i+1,j  ).lt.  0.or.kabe(i  ,j  ).eq.1
     *                       .or.kabe(i  ,j  ).eq.3))     go to 3500
      if((ibz(i-1,j-1).lt.  0.or.kabe(i-1,j-1).eq.1
     *                       .or.kabe(i-1,j-1).eq.3).and.
     *   (ibz(i-1,j  ).lt.  0.or.kabe(i-1,j  ).eq.1
     *                       .or.kabe(i-1,j  ).eq.3).and.
     *   (ibz(i+1,j  ).lt.  0.or.kabe(i  ,j  ).eq.1
     *                       .or.kabe(i  ,j  ).eq.3))     go to 3510
      if((ibz(i-1,j-1).lt.  0.or.kabe(i-1,j-1).eq.1
     *                       .or.kabe(i-1,j-1).eq.3).and.
     *   (ibz(i+1,j-1).lt.  0.or.kabe(i  ,j-1).eq.1).and.
     *   (ibz(i+1,j  ).lt.  0.or.kabe(i  ,j  ).eq.1
     *                       .or.kabe(i  ,j  ).eq.3))     go to 3520
      if((ibz(i-1,j-1).lt.  0.or.kabe(i-1,j-1).eq.1
     *                       .or.kabe(i-1,j-1).eq.3).and.
     *   (ibz(i+1,j-1).lt.  0.or.kabe(i  ,j-1).eq.1).and.
     *   (ibz(i-1,j  ).lt.  0.or.kabe(i-1,j  ).eq.1
     *                       .or.kabe(i-1,j  ).eq.3))     go to 3530

      if((ibz(i-1,j  ).lt.  0.or.kabe(i-1,j  ).eq.1
     *                       .or.kabe(i-1,j  ).eq.3).and.
     *   (ibz(i+1,j  ).lt.  0.or.kabe(i  ,j  ).eq.1
     *                       .or.kabe(i  ,j  ).eq.3))     go to 3540
      if((ibz(i-1,j-1).lt.  0.or.kabe(i-1,j-1).eq.1
     *                       .or.kabe(i-1,j-1).eq.3).and.
     *   (ibz(i+1,j-1).lt.  0.or.kabe(i  ,j-1).eq.1))     go to 3550
      if((ibz(i-1,j-1).lt.  0.or.kabe(i-1,j-1).eq.1
     *                       .or.kabe(i-1,j-1).eq.3).and.
     *   (ibz(i+1,j  ).lt.  0.or.kabe(i  ,j  ).eq.1
     *                       .or.kabe(i  ,j  ).eq.3))     go to 3560
      if((ibz(i+1,j-1).lt.  0.or.kabe(i  ,j-1).eq.1).and.
     *   (ibz(i-1,j  ).lt.  0.or.kabe(i-1,j  ).eq.1
     *                       .or.kabe(i-1,j  ).eq.3))     go to 3570
      if((ibz(i-1,j-1).lt.  0.or.kabe(i-1,j-1).eq.1
     *                       .or.kabe(i-1,j-1).eq.3).and.
     *   (ibz(i-1,j  ).lt.  0.or.kabe(i-1,j  ).eq.1
     *                       .or.kabe(i-1,j  ).eq.3))     go to 3580
      if((ibz(i+1,j-1).lt.  0.or.kabe(i  ,j-1).eq.1).and.
     *   (ibz(i+1,j  ).lt.  0.or.kabe(i  ,j  ).eq.1
     *                       .or.kabe(i  ,j  ).eq.3))     go to 3590

      if(ibz(i-1,j-1).lt.  0.or.kabe(i-1,j-1).eq.1
     *                      .or.kabe(i-1,j-1).eq.3)
     *                                    u0 = ( u2 + u3 + u4 ) / 3.0
      if(ibz(i-1,j  ).lt.  0.or.kabe(i-1,j  ).eq.1
     *                      .or.kabe(i-1,j  ).eq.3)
     *                                    u0 = ( u1 + u2 + u4 ) / 3.0
      if(ibz(i+1,j-1).lt.  0.or.kabe(i  ,j-1).eq.1)
     *                                    u0 = ( u1 + u3 + u4 ) / 3.0
      if(ibz(i+1,j  ).lt.  0.or.kabe(i  ,j  ).eq.1
     *                      .or.kabe(i  ,j  ).eq.3)
     *                                    u0 = ( u1 + u2 + u3 ) / 3.0
      go to 3800

 3500 continue
      u0 = u1
      go to 3800
 3510 continue
      u0 = u2
      go to 3800
 3520 continue
      u0 = u3
      go to 3800
 3530 continue
      u0 = u4
      go to 3800
 3540 continue
      u0 = ( u1 + u2 ) / 2.0
      go to 3800
 3550 continue
      u0 = ( u3 + u4 ) / 2.0
      go to 3800
 3560 continue
      u0 = ( u3 + u2 ) / 2.0
      go to 3800
 3570 continue
      u0 = ( u1 + u4 ) / 2.0
      go to 3800
 3580 continue
      u0 = ( u2 + u4 ) / 2.0
      go to 3800
 3590 continue
      u0 = ( u1 + u3 ) / 2.0

 3800 continue

      return
      end
C ---------------------------

      subroutine  dmcal

C --------------------------
      include 'lahar2d.inc'


      do 1000 j = 2 ,jm0
      do 2000 i=ibc(1,j),ibc(2,j)

        if(zi(i,j).lt.0.0)  go to 2000
        if(ipp(i,j).gt.0)  go to 2000

      aa = 0.0
      do 3000 l = 1 ,idnum
       if(dmix(i,j).le.0.0)  go to 3000
       aa = aa + gsd(l) * dzd1(l,i,j) / dmix(i,j)
 3000 continue

       dm(i,j) = aa

 2000 continue
 1000 continue

      
      return
      end
C ------------------------

      subroutine  cmncal

C ------------------------
      include 'lahar2d.inc'

      do 2000 j=2,jm0
      do 1000 i=ibc(1,j),ibc(2,j)

c============================================================= boundary
        if(zi(i,j).lt.0.0)  go to 1000
        if(ipp(i-1,j).gt.0.or.ipp(i,j).gt.0)  go to 3000
c======================================================================

       vx(i,j) = 0.0
       uvx(i,j) = 0.0
       egx(i,j) = 0.0
       do 1101  l = 1 ,idnum
        qmb(l,i,j) = 0.0
 1101  continue

      if(abs(qm2(i,j)).lt.exm)  go to 3000
      dz = zl3(i-1,j) - zl3(i,j)
      if(abs(dz).lt.exm)  dz = 0.0
      if(adz(i  ,j).lt.exm.and.dz.lt.0.0.and.qm2(i,j).gt.0.0) go to 3000
      if(adz(i-1,j).lt.exm.and.dz.gt.0.0.and.qm2(i,j).lt.0.0) go to 3000

      if(qm2(i,j).lt.0.0)  ii = i
      if(qm2(i,j).gt.0.0)  ii = i - 1
      

      if(dmix(ii,j).lt.exm)  go to 3000

      h0 =  ( hh3(i,j) + hh3(i-1,j) ) / 2.0
      if(h0.lt.eps)  go to 3000
      u0 = qm2(i,j) / h0

      h1 = hh3(i-1,j) + hh3(i-1,j-1)
      v1= 0.0
      if(h1.ge.eps)  v1 = 2.0 * qn2(i-1,j) / h1

      h2 = hh3(i-1,j+1) + hh3(i-1,j)
      v2 = 0.0
      if(h2.ge.eps)  v2 = 2.0 * qn2(i-1,j+1) / h2

      h3 = hh3(i,j) + hh3(i,j-1)
      v3 = 0.0
      if(h3.ge.eps)  v3 = 2.0 * qn2(i,j) / h3

      h4 = hh3(i,j+1) + hh3(i,j)
      v4 = 0.0
      if(h4.ge.eps)  v4 = 2.0 * qn2(i,j+1) / h4

      call v0cal(i,j,v1,v2,v3,v4,v0)
      uv =  u0 * u0 + v0 * v0
      vx(i,j) = v0
      uvx(i,j) = sqrt( uv )

      egx(i,j) =  uv * sodo * sodo / h0**(4./3.)
      uv2 = u0 / uvx(i,j)
      heg = egx(i,j) * h0 / ss1
      ust = sqrt( egx(i,j) * h0 * 9.8 )
      uust = uvx(i,j) / ust

      do 4000 l = 1 , idnum
      qmb(l,i,j) = 0.0
      tast0 = heg /  gsd(l)
      aa = gsd(l) / dm(ii,j)
      if(aa.lt.0.4)  tastc = 0.85 * tastcm / aa
      if(aa.ge.0.4)  then

         a1 = 1.27875360095  / dlog10( 19.0 * aa )
         tastc = a1 * a1 * tastcm
      end if

      if(tast0.lt.tastc)  go to  4000

      a1 = fbed(tast0,tastc)

      a2 = a1 * sqrt( ss1 * 9.8 * gsd(l)**3 )
      df = dzd1(l,ii,j) / dmix(ii,j)

      qbb = a2 * df

      qbs = 0.0
      if(ild.eq.0) go to 4010

      df = df * 100.0
      wust = w0(l) / ust

      dst = 0.5 / wust * exp( - wust * wust )
      cb = 5.55 * df * dst**1.61
      call pcal(wust,uust,p)
      qbs = qm2(i,j) * cb * p * 1.0e-6

 4010 continue
      qb = qbb + qbs/uv2

      qmb(l,i,j) = qb * uv2
 4000 continue


 3000 continue
       if(ipp(i,j-1).gt.0.or.ipp(i,j).gt.0)  go to 1000
       uy(i,j) = 0.0
       uvy(i,j) = 0.0
       egy(i,j) = 0.0
       do 3101  l = 1 ,idnum
        qnb(l,i,j) = 0.0
 3101  continue

      if(abs(qn2(i,j)).lt.exm)  go to 1000
      dz = zl3(i,j-1) - zl3(i,j)
      if(abs(dz).lt.exm)  dz = 0.0
      if(adz(i,j  ).lt.exm.and.dz.lt.0.0.and.qn2(i,j).gt.0.0) go to 1000
      if(adz(i,j-1).lt.exm.and.dz.gt.0.0.and.qn2(i,j).lt.0.0) go to 1000

      if(qn2(i,j).lt.0.0)  jj = j
      if(qn2(i,j).gt.0.0)  jj = j - 1

      if(dmix(i,jj).lt.exm)  go to 1000

      h0 = ( hh3(i,j) + hh3(i,j-1) ) / 2.0
      if(h0.lt.eps)  go to 1000
      v0 =  qn2(i,j) / h0

      h1 = hh3(i,j-1) + hh3(i-1,j-1)
      u1= 0.0
      if(h1.ge.eps)  u1 = 2.0 * qm2(i,j-1) / h1

      h2 = hh3(i+1,j-1) + hh3(i,j-1)
      u2 = 0.0
      if(h2.ge.eps)  u2 = 2.0 * qm2(i+1,j-1) / h2

      h3 = hh3(i,j) + hh3(i-1,j)
      u3 = 0.0
      if(h3.ge.eps)  u3 = 2.0 * qm2(i,j) / h3

      h4 = hh3(i+1,j) + hh3(i,j)
      u4 = 0.0
      if(h4.ge.eps)  u4 = 2.0 * qm2(i+1,j) / h4

      call u0cal(i,j,u1,u2,u3,u4,u0)
      uv =  u0 * u0 + v0 * v0
      uy(i,j) = u0
      uvy(i,j) = sqrt( uv )

      egy(i,j) =  uv * sodo * sodo /  h0**(4./3.)
      uv2 = v0 / sqrt( uv )
      heg = egy(i,j) * h0 / ss1
      ust = sqrt( egy(i,j) * h0 * 9.8 )
      uust = uvy(i,j) / ust

      do 6000 l = 1 , idnum
      qnb(l,i,j) = 0.0
      tast0 = heg / gsd(l)
      aa = gsd(l) / dm(i,jj)
      if(aa.lt.0.4)  tastc = 0.85 * tastcm / aa
      if(aa.ge.0.4)  then
        
         a1 = 1.27875360095  / dlog10( 19.0 * aa )
         tastc = a1 * a1 * tastcm
      end if

      if(tast0.lt.tastc)  go to  6000

      a1 = fbed(tast0,tastc)

      a2 = a1 * sqrt( ss1 * 9.8 * gsd(l)**3 )
      df = dzd1(l,i,jj) / dmix(i,jj)

      qbb = a2 * df

      qbs = 0.0
      if(ild.eq.0) go to 6010

      df = df * 100.0
      wust = w0(l) / ust

      dst = 0.5 / wust * exp( - wust * wust )
      cb = 5.55 * df * dst**1.61
      call pcal(wust,uust,p)
      qbs = qn2(i,j) * cb * p * 1.0e-6

 6010 continue
      qb = qbb + qbs/uv2

      qnb(l,i,j) = qb * uv2
 6000 continue


 1000 continue
 2000 continue

      return
      end
c-------------------------------

      function  fbed(tast0,tastc)

c--------------------------------

      include 'lahar2d.inc'

      fbed = cmpm * ( tast0 - tastc )**1.5

      return
      end
C -------------------

      subroutine  pcal(wust,uust,p)

c -------------------
      implicit real*8 (a-h,o-z)

      pst(x) =  ( 1.0 + ( 1.0 + dlog( x ) ) / 0.4 / uust )
     *         * dexp( - 6.0 * wust * x / 0.4 )

      n2 = 10
      h = 0.1

      ds1 = 0.0
      ds2 = 0.0

      do 1000 m = 1 , n2-1

      isw = mod(m,2)

      x = h * float( m )
      if(isw.eq.0)  then
        ds2 = ds2 + pst( x )
       else
        ds1 = ds1 + pst( x )
      end if
 1000 continue

      c1 = 0.01
      c2 = 1.0

      p = h * ( pst( c1) + 4.0 * ds1 + 2.0 * ds2 + pst( c2) ) / 3.0

      return
      end
c ----------------------

      subroutine  qbscal

C ---------------------
      include 'lahar2d.inc'
c-----------------------
      do 2000 j = 2 , jm0
      do 1000 i = ibc(1,j) , ibc(2,j)

      if(zi(i,j).lt.0.0)  go to 1000

      do 1010 l = 1 ,idnum
       qmbs1(l,i,j) = 0.0
       qmbs2(l,i,j) = 0.0
       qnbs1(l,i,j) = 0.0
       qnbs2(l,i,j) = 0.0
 1010 continue

      if(ipp(i,j).gt.0.or.ipp(i-1,j).gt.0)  go to 3000

      if(abs(qm2(i,j)).lt.exm)  go to 3000
      if(kabe(i-1,j).eq.-1.or.kabe(i-1,j).eq.-3)  go to 3000

      h0 = ( hh3(i-1,j) + hh3(i,j) ) / 2.0
      if(h0.lt.eps)  go to 3000

      dz = zl3(i-1,j) - zl3(i,j)
      dz0 = abs( dz )
      if(dz0.lt.eps)  go to 3000

      if(dz.gt.0.0) then

          i2 = i -1
        else

          i2 = i
      end if

      if(dmix(i2,j).lt.exm)  go to 3000

      ddz0 = dz0 - dmix(i2,j)
      if(ddz0.gt.ddz2(i2,j))  ddz0 = ddz2(i2,j)
      if(ddz0.lt.eps)  ddz0 = 0.0
      ddz1 = ddz0 + dmix(i2,j)

      if(ddz0.ge.eps)  then
       dz2 =  ddz0 / ddz2(i2,j)
       dmm = 0.0
       do 1020 l = 1, idnum
        dmm = dmm+(dzd2(l,i2,j)*dz2+dzd1(l,i2,j))/ddz1 * gsd(l)
 1020 continue

      else
       dmm = dm(i2,j)
      end if

      if(dmm.le.0.0)  go to 3000

      tastsc = tastcm * cos1 * sqrt(1.0 - ( tan1 / fai )**2 )

      usta2 =  9.8 * h0 * egx(i,j)
      tast  =  usta2 / ss1 / dmm / 9.8
      tasts  = 0.5 * tast
      if(tasts.lt.tastsc)  go to 3000

      a1 = 0.01 * sqrt( tast ) * ( 1.0 - tastsc / tasts ) ** 3
      qbss = a1 * sqrt( usta2 ) * dz / sin1
      qmbs = qbss * abs( vx(i,j) ) / uvx(i,j)

      if(ddz0.ge.eps)  then

      aa =  ddz0 / dz0
      do 1030 l = 1,idnum

       qmbs1(l,i,j) = qmbs * dzd1(l,i2,j) / dz0
       qmbs2(l,i,j) = qmbs * dzd2(l,i2,j) / ddz2(i2,j) * aa
 1030 continue

      else

      do 1040 l = 1,idnum
       qmbs1(l,i,j) = qmbs * dzd1(l,i2,j) / dmix(i2,j)

       qmbs2(l,i,j) = 0.0
 1040 continue
      end if

 3000 continue

      if(ipp(i,j).gt.0.or.ipp(i,j-1).gt.0)  go to 1000
      if(abs(qn2(i,j)).lt.exm)  go to 1000
      if(kabe(i,j-1).le.-2)  go to 1000

      h0 = ( hh3(i,j-1) + hh3(i,j) ) / 2.0
      if(h0.lt.eps)  go to 1000

      dz = zl3(i,j-1) - zl3(i,j)
      dz0 = abs( dz )
      if(dz0.lt.eps)  go to 1000

      if(dz.gt.0.0) then

          j2 = j -1
        else

          j2 = j
      end if

      if(dmix(i,j2).lt.exm)  go to 1000

      ddz0 = dz0 - dmix(i,j2)
      if(ddz0.gt.ddz2(i,j2))  ddz0 = ddz2(i,j2)
      if(ddz0.lt.eps)  ddz0 = 0.0
      ddz1 = ddz0 + dmix(i,j2)

      if(ddz0.ge.eps)  then
       dz2 = ddz0 / ddz2(i,j2)
       dmm = 0.0
       do 2020 l = 1, idnum
       dmm = dmm+(dzd2(l,i,j2)*dz2+dzd1(l,i,j2))/ddz1 * gsd(l)
 2020 continue

      else
       dmm = dm(i,j2)
      end if

      if(dmm.le.0.0)  go to 1000

      tastsc = tastcm * cos1 * sqrt(1.0 - ( tan1 / fai )**2 )

      usta2 =  9.8 * h0 * egy(i,j)
      tast  =  usta2 / ss1 / dmm / 9.8
      tasts  = 0.5 * tast
      if(tasts.lt.tastsc)  go to 1000
      a1 = 0.01 * sqrt( tast ) * ( 1.0 - tastsc / tasts ) ** 3
      qbss = a1 * sqrt( usta2 ) * dz / sin1
      qnbs = qbss * abs( uy(i,j) )  / uvy(i,j)

      if(ddz0.ge.eps)  then

      aa =  ddz0 / dz0
      do 2030 l = 1,idnum
       qnbs1(l,i,j) = qnbs * dzd1(l,i,j2) / dz0
       qnbs2(l,i,j) = qnbs * dzd2(l,i,j2) / ddz2(i,j2) * aa
 2030 continue

      else

      do 2040 l = 1,idnum
       qnbs1(l,i,j) = qnbs * dzd1(l,i,j2) / dmix(i,j2)
       qnbs2(l,i,j) = 0.0
 2040 continue
      end if

 1000 continue
 2000 continue

      
      return
      end

C -----------------------

      subroutine  depcal(dt)

C ----------------------
      include 'lahar2d.inc'


      dt2 = 2.0 * dt

      do 3000 j=2,jm0

      do 1000 i=ibc(1,j),ibc(2,j)

       if(zi(i,j).lt.0.0)  go to 1000
       if(ipp(i,j).gt.0)  go to 1000

       if(qm2(i,j).eq.0.0.and.qm2(i+1,j).eq.0.0.and.qn2(i,j).eq.0.0
     * .and.qn2(i,j+1).eq.0.0.and.hh1(i,j).le.0.0)  go to 1000

      if(hh1(i,j).lt.eps) then
       if(qm2(i,j)  .lt.0.0)  qm2(i,j)   = 0.0
       if(qm2(i+1,j).gt.0.0)  qm2(i+1,j) = 0.0
       if(qn2(i,j)  .lt.0.0)  qn2(i,j)   = 0.0
       if(qn2(i,j+1).gt.0.0)  qn2(i,j+1) = 0.0
       go to 1000
      end if

      a2=0.0
      if(qm2(i  ,j  ).lt.0.) a2=a2-qm2(i  ,j  )*dly
      if(qm2(i+1,j  ).gt.0.) a2=a2+qm2(i+1,j  )*dly
      if(qn2(i  ,j  ).lt.0.) a2=a2-qn2(i  ,j  )*dlx
      if(qn2(i  ,j+1).gt.0.) a2=a2+qn2(i  ,j+1)*dlx

      wvl=hh1(i,j)*ddxy

      qwout=a2*dt2

      if(qwout.le.0.0)goto 2500
      if(qwout.le.wvl)go to 2500
      aa=wvl/qwout
      if(qm2(i  ,j  ).lt.0.) qm2(i  ,j  )=qm2(i  ,j  )*aa
      if(qm2(i+1,j  ).gt.0.) qm2(i+1,j  )=qm2(i+1,j  )*aa
      if(qn2(i  ,j  ).lt.0.) qn2(i  ,j  )=qn2(i  ,j  )*aa
      if(qn2(i  ,j+1).gt.0.) qn2(i  ,j+1)=qn2(i  ,j+1)*aa
 2500 continue

 1000 continue
 3000 continue

      do 3010 j=2,jm0

      do 1010 i=ibc(1,j),ibc(2,j)

       if(zi(i,j).lt.0.0)  go to 1010
       if(ipp(i,j).gt.0)  go to 1010

       if(qm2(i,j).eq.0.0.and.qm2(i+1,j).eq.0.0.and.qn2(i,j).eq.0.0
     * .and.qn2(i,j+1).eq.0.0.and.hh1(i,j).le.0.0)  go to 1010

      dh = (( qm2(i,j) - qm2(i+1,j) ) * dly +
     *      ( qn2(i,j) - qn2(i,j+1) ) * dlx ) * dt2 / ddxy

      h0 = hh1(i,j) + dh
      if(h0.ge.exm)  go to 2000

      h0=0.0

 2000 continue
      hh3(i,j) = h0
 1010 continue
 3010 continue

      return
      end
C -------------------------

      subroutine  crect2(dt)

C -------------------------
      include 'lahar2d.inc'

      dt2 = dt * 2.0

      do 2010 j=2,jm0
      do 1010 i=ibc(1,j),ibc(2,j)
       if(zi(i,j).lt.0.0)  go to 1010
       if(ipp(i,j).gt.0.or.ipp(i,j-1).gt.0.or.ipp(i-1,j).gt.0)
     *                     go to 1010
       qmba = 0.0
       qnba = 0.0
       do 3030 l=1,idnum
       qmba = qmba + qmb(l,i,j)
       qnba = qnba + qnb(l,i,j)
 3030 continue

      if(abs(qm2(i,j)).gt.exm)  then
        cm = qmba /  qm2(i,j)
        if(cm.lt.0.45)  go to 5000
        aa = 0.45 / cm
      else
        aa = 0.0
      end if

      do 4400 l = 1 , idnum
       qmb(l,i,j) = qmb(l,i,j) * aa
 4400 continue

 5000 continue
      if(abs(qn2(i,j)).gt.exm)  then
        cn = qnba /  qn2(i,j)
        if(cn.lt.0.45)  go to 1010
        aa = 0.45 / cn
      else
        aa = 0.0
      end if

      do 6400 l = 1 , idnum
       qnb(l,i,j) = qnb(l,i,j) * aa
 6400 continue

 1010 continue
 2010 continue


      
      do 2000 j=2,jm0
      do 1000 i=ibc(1,j),ibc(2,j)

       if(zi(i,j).lt.0.0)  go to 1000
       if(ipp(i,j).gt.0) go to 1000
       if(qm2(i,j).eq.0.0.and.qm2(i+1,j).eq.0.0.and.qn2(i,j).eq.0.0
     * .and.qn2(i,j+1).eq.0.0.and.hh3(i,j).le.0.0)  go to 1000

      do 3000 l = 1 , idnum

       q1=qmb(l,i  ,j  )+qmbs1(l,i  ,j  )
       q2=qmb(l,i+1,j  )+qmbs1(l,i+1,j  )
       q3=qnb(l,i  ,j  )+qnbs1(l,i  ,j  )
       q4=qnb(l,i  ,j+1)+qnbs1(l,i  ,j+1)
       a2=0.
       if(q1.lt.0.)    a2=a2-q1*dly
       if(q2.gt.0.)    a2=a2+q2*dly
       if(q3.lt.0.)    a2=a2-q3*dlx
       if(q4.gt.0.)    a2=a2+q4*dlx

       qsout = a2 * dt2
       if(qsout.le.0.0) go to 3010
       aeqsv =  dzd1(l,i,j) * ddxyc
       if(qsout.le.aeqsv) go to 3010
       aa = aeqsv / qsout

       if(q1.lt.0.) then
          qmb(l,i  ,j  )=qmb(l,i  ,j  )*aa
          qmbs1(l,i  ,j  )=qmbs1(l,i  ,j  )*aa
       end if
       if(q2.gt.0.) then
          qmb(l,i+1,j  )=qmb(l,i+1,j  )*aa
          qmbs1(l,i+1,j  )=qmbs1(l,i+1,j  )*aa
       end if
       if(q3.lt.0.) then
          qnb(l,i  ,j  )=qnb(l,i  ,j  )*aa
          qnbs1(l,i  ,j  )=qnbs1(l,i  ,j  )*aa
       end if
       if(q4.gt.0.) then
          qnb(l,i  ,j+1)=qnb(l,i  ,j+1)*aa
          qnbs1(l,i  ,j+1)=qnbs1(l,i  ,j+1)*aa
       end if
 3010 continue

       b2=0.
       if(qmbs2(l,i  ,j  ).lt.0.) b2=b2-qmbs2(l,i  ,j  )*dly
       if(qmbs2(l,i+1,j  ).gt.0.) b2=b2+qmbs2(l,i+1,j  )*dly
       if(qnbs2(l,i  ,j  ).lt.0.) b2=b2-qnbs2(l,i  ,j  )*dlx
       if(qnbs2(l,i  ,j+1).gt.0.) b2=b2+qnbs2(l,i  ,j+1)*dlx

       qsout = b2 * dt2
       if(qsout.le.0.0) go to 3000
       aeqsv =  dzd2(l,i,j) * ddxyc
       if(qsout.le.aeqsv) go to 3000
       bb = aeqsv / qsout

       if(qmbs2(l,i  ,j  ).lt.0.) qmbs2(l,i  ,j  )=qmbs2(l,i  ,j  )*bb
       if(qmbs2(l,i+1,j  ).gt.0.) qmbs2(l,i+1,j  )=qmbs2(l,i+1,j  )*bb
       if(qnbs2(l,i  ,j  ).lt.0.) qnbs2(l,i  ,j  )=qnbs2(l,i  ,j  )*bb
       if(qnbs2(l,i  ,j+1).gt.0.) qnbs2(l,i  ,j+1)=qnbs2(l,i  ,j+1)*bb


 3000 continue

 1000 continue
 2000 continue

      return
      end
C ----------------------

      subroutine  bedcal(dt)

C-------------------------
      include 'lahar2d.inc'


      dimension  dz(200)

      dt2 = dt * 2.0
      dtdx = dlx * dt2
      dtdy = dly * dt2

      do 920 j=1,jmy
      do 910 i=1,imx
      qmbt(i,j) = 0.0
      qnbt(i,j) = 0.0
  910 continue
  920 continue

      do 2000 j=2,jm0
      do 1000 i=ibc(1,j),ibc(2,j)

       if(zi(i,j).lt.0.0)  go to 1000
       if(ipp(i,j).gt.0)  go to 1000

       if(qm2(i,j).eq.0.0.and.qm2(i+1,j).eq.0.0.and.qn2(i,j).eq.0.0
     * .and.qn2(i,j+1).eq.0.0.and.hh3(i,j).le.0.0)  go to 1000

      dzt = 0.0
      dzt2 = 0.0

      do 3000 l = 1 , idnum

       q1 = 0.0
       q2 = 0.0
       q3 = 0.0
       q4 = 0.0
       a3 = 0.0
       if(qm2(i  ,j  ).ne.0.)  then
          q1 = ( qmb(l,i  ,j  )+qmbs1(l,i  ,j  ) ) * dtdy
          if(qmbs2(l,i  ,j  ).gt.0.) q1=q1+qmbs2(l,i  ,j  )*dtdy
          if(qmbs2(l,i  ,j  ).lt.0.) a3=a3-qmbs2(l,i  ,j  )*dly
       end if
       if(qm2(i+1,j  ).ne.0.)  then
          q2 = ( qmb(l,i+1,j  )+qmbs1(l,i+1,j  ) ) * dtdy
          if(qmbs2(l,i+1,j  ).lt.0.) q2=q2+qmbs2(l,i+1,j  )*dtdy
          if(qmbs2(l,i+1,j  ).gt.0.) a3=a3+qmbs2(l,i+1,j  )*dly
       end if
       if(qn2(i  ,j  ).ne.0.)  then
          q3 = ( qnb(l,i  ,j  )+qnbs1(l,i  ,j  ) ) * dtdx
          if(qnbs2(l,i  ,j  ).gt.0.) q3=q3+qnbs2(l,i  ,j  )*dtdx
          if(qnbs2(l,i  ,j  ).lt.0.) a3=a3-qnbs2(l,i  ,j  )*dlx
       end if
       if(qn2(i  ,j+1).ne.0.)  then
          q4 = ( qnb(l,i  ,j+1)+qnbs1(l,i  ,j+1) ) * dtdx
          if(qnbs2(l,i  ,j+1).lt.0.) q4=q4+qnbs2(l,i  ,j+1)*dtdx
          if(qnbs2(l,i  ,j+1).gt.0.) a3=a3+qnbs2(l,i  ,j+1)*dlx
       end if

       dz(l) = ( q1 - q2 + q3 - q4 ) / ddxyc

       if(dz(l).lt.exm.and.dz(l).gt.-exm)  dz(l) = 0.0

       dzt = dzt + dz(l)
       dz2 = a3 * dt2 / ddxyc
       dzd2(l,i,j) = dzd2(l,i,j) - dz2
       dzt2 = dzt2 + dz2

      qmbt(i,j) = qmbt(i,j) + qmb(l,i,j)+qmbs1(l,i,j)+qmbs2(l,i,j)
      qnbt(i,j) = qnbt(i,j) + qnb(l,i,j)+qnbs1(l,i,j)+qnbs2(l,i,j)
      qmbdt(l,i,j) = qmbdt(l,i,j)
     *      +(qmb(l,i,j) + qmbs1(l,i,j) + qmbs2(l,i,j) )* dtdy
      qnbdt(l,i,j) = qnbdt(l,i,j)
     *      +(qnb(l,i,j) + qnbs1(l,i,j) + qnbs2(l,i,j) )* dtdx
 3000 continue

      
      ddz2(i,j) = ddz2(i,j) - dzt2

       if(dzt.gt. exm)  call  case1(i,j,dz,dzt)
       if(dzt.lt.-exm)  call  case2(i,j,dz,dzt)

       zl3(i,j) = zl1(i,j) + dzt - dzt2
       
       if(zl3(i,j)/=zl3(i,j)) then
            write(*,'(3(f10.2))')zl1(i,j),dzt,dzt2
            write(*,'(3(f10.2))')ddxyc
            call calerrout
            stop
       end if

       qmbtt(i,j) = qmbtt(i,j) + qmbt(i,j) * dtdy
       qnbtt(i,j) = qnbtt(i,j) + qnbt(i,j) * dtdx
       qmt(i,j) = qmt(i,j) + qm2(i,j) * dtdy
       qnt(i,j) = qnt(i,j) + qn2(i,j) * dtdx

 1000 continue
 2000 continue
     
      return
      end
C ------------------------

      subroutine  case1(i,j,dz,dzt)

C ------------------------
      include 'lahar2d.inc'


      dimension  dz(200)

      dz1 = dmix(i,j) + dzt
      dz2 = dz1 - dmix0
      if(dz1.lt.dmix0)  go to 2000
      if(ddz2(i,j).le.0.0.and.dz2.lt.dcng)   go to 2000

      dmix(i,j) = dmix0
      ddz2(i,j) = ddz2(i,j) + dz2
       a1 = dmix0 / dz1
      do 1000 l = 1 ,idnum
       a2 = dzd1(l,i,j) + dz(l)
       dzd1(l,i,j) = a1 * a2
       dzd2(l,i,j) = dzd2(l,i,j) + ( 1.0 - a1 ) * a2
 1000 continue
       go to 1100

 2000 continue
      dmix(i,j) = dmix(i,j) + dzt
      ddz2(i,j) = 0.0
      do 3000 l = 1 ,idnum
       dzd1(l,i,j) = dzd1(l,i,j) + dz(l)
       dzd2(l,i,j) = 0.0
 3000 continue

 1100 continue
      
      
      return
      end
C -----------------------

      subroutine  case2(i,j,dz,dzt)

C -----------------------
      include 'lahar2d.inc'


      dimension  dz(200)

      dz1 = dmix(i,j)
      dz2 = ddz2(i,j) + dzt
      if(dz1.lt.dmix0)  go to 2000
      if(dz2.lt.dcng)   go to 2000

      a1 = - dzt / ddz2(i,j)
      do 1000 l = 1 ,idnum
       dzd1(l,i,j) = dzd1(l,i,j) + dz(l) + dzd2(l,i,j) * a1
       dzd2(l,i,j) = dzd2(l,i,j) * ( 1.0 - a1 )
 1000 continue
       dmix(i,j) = dmix0
       ddz2(i,j) = ddz2(i,j) + dzt
       go to 1100

 2000 continue
      dz1 = 0.0
      do 3000 l = 1 ,idnum
       dzd1(l,i,j) = dzd1(l,i,j) + dz(l) + dzd2(l,i,j)
       if(dabs(dzd1(l,i,j)).lt.exm) dzd1(l,i,j)=0.d0
       dzd2(l,i,j) = 0.0
       dz1 = dz1 + dzd1(l,i,j)
 3000 continue

       dmix(i,j) = dz1
       ddz2(i,j) = 0.0

 1100 continue
      if(dmix(i,j).lt.0.0)  dmix(i,j) = 0.0
      
      
      return
      end


c ------------------------

      subroutine  maxcal(dt1)

c -------------------------
      include 'lahar2d.inc'
      

      do 1000 j = 2 ,jm0

      do 2000 i=ibc(1,j),ibc(2,j)

      if(zi(i,j).lt.0.0)  go to 2000

      hh = hh3(i,j) + zl3(i,j) - zi(i,j)
      if(hh.gt.hmax(i,j))  hmax(i,j) = hh

      dzz = zl3(i, j) - zi(i, j)

      qx = ( qmbt(i,j) + qmbt(i+1,j) ) / 2.0
      qy = ( qnbt(i,j) + qnbt(i,j+1) ) / 2.0
      qb = sqrt( qx*qx + qy*qy )
      if(qb.gt.cmax(i,j))  cmax(i,j) = qb


      if(hh3(i,j).lt.exm)  go to 2000

      qx = ( qm2(i,j) + qm2(i+1,j) ) / 2.0
      qy = ( qn2(i,j) + qn2(i,j+1) ) / 2.0

      vvx = qx / hh3(i,j)
      vvy = qy / hh3(i,j)

      qv = sqrt( qx * qx + qy * qy )
      
      vvv = sqrt( vvx * vvx + vvy * vvy )

      if(qv.gt.qmax(i,j))   then
         qmax(i,j) = qv
         qxm(i,j) = qx
         qym(i,j) = qy
      end if

      fm = roh * qv * qv / hh3(i,j) / 9.8
      if(fm.gt.fmax(i,j))  fmax(i,j) = fm

      vmax = sqrt( vxm(i,j) * vxm(i,j) + vym(i,j) * vym(i,j) )
      if(vvv.gt.vmax) then
         vxm(i,j) = vvx
         vym(i,j) = vvy
      end if

      hh = hh3(i,j)
      hhm = ( hh3(i-1,j) + hh3(i,j) ) / 2.0
      hhn = ( hh3(i,j-1) + hh3(i,j) ) / 2.0
      vvx2 = qm2(i,j) / hhm
      vvy2 = qn2(i,j) / hhn
      vvxy = sqrt( vvx2*vvx2 + vvy2*vvy2 )

      if(artime(i,j).eq.0.and.hh.gt.0.0) then
        artime(i,j) = dt1
      endif

      call maxset(vvxy, uvmax(i, j), dt1, uvmaxtime(i, j))

      call maxset(hh, hh3max(i, j), dt1, hh3maxtime(i, j))

      fmm = roh * qv * qv / 9.8 * 9.80665 / 1000.0
      if(fmm.gt.qmax2(i,j)) then
        qmax2(i,j)=fmm
      endif

      call maxset(dzz, zmax(i, j), dt1, zmaxtime(i, j))

      cd3max(i, j) = 0.d0; cd3maxtime(i, j) = 0.d0
      pdynmax(i, j) = 0.d0; pdynmaxtime(i, j) = 0.d0
      pstamax(i, j) = 0.d0; pstamaxtime(i, j) = 0.d0
      tau0max(i, j) = 0.d0; tau0maxtime(i, j) = 0.d0
      pmax2(i, j) = 0.d0; pmax2time(i, j) = 0.d0
      fmax(i, j) = 0.d0; fmaxtime(i, j) = 0.d0

 2000 continue
 1000 continue

      return
      end
      
      
      subroutine maxset(val, valmax, tnow, valmaxtime)

      include 'lahar2d.inc'

        if(val > valmax) then
                valmax = val
                valmaxtime = tnow
        end if

        return

      end subroutine maxset
      

C ---------------------------------

      subroutine  delete

C ---------------------------------
      include 'lahar2d.inc'


      do 9990 j=2,jm0
      do 9980 i=ibc(1,j),ibc(2,j)

      if(ipp(i,j).gt.0)  go to 9980


      if(zi(i-1,j).lt.0.0.or.zi(i,j-1).lt.0.0.or.zi(i+1,j).lt.0.0.or.
     *   zi(i,j+1).lt.0.0)  then
      if(hh3(i,j).gt.0.01)  hh3(i,j)=0.01
      zl3(i,j)=zi(i,j)

      if(adz(i,j).le.0)  go to 1000
       dmix(i,j) = dmix0
       ddz2(i,j) = adz(i,j) - dmix0
      go to 1100
 1000 continue
       dmix(i,j) = 0.0
       ddz2(i,j) = 0.0
 1100 continue

      k = idist(i,j)
      do 8000 l = 1 ,idnum
       dzd1(l,i,j) = dmix(i,j) * dist(l,k)
       dzd2(l,i,j) = ddz2(i,j) * dist(l,k)
 8000 continue
      end if

 9980 continue
 9990 continue

      return
      end
c ------------------------

      subroutine  errnum(i)

c -----------------------
      include 'lahar2d.inc'

      character i*4

      call calerrout
      
      write(2,100) i
  100 format(10x,' ***  error  no. ',a4,' ***')
      
      stop

      end
c -----------------------

      subroutine  calerr(dt1,dt2,i)

c -----------------------
      include 'lahar2d.inc'


      character i*4

      call calerrout

      call  print1(dt1,dt2)
      call  print2(dt1,dt2)
      write(2,100)  i
  100 format(10x,' ***  error  no. ',a4,' ***')

      stop
      end
      
            
c ---------------------

      subroutine  print1(dt1,dt2)

c ---------------------
      include 'lahar2d.inc'


      integer*4  itimex
      dimension  nob(12),dz(12)

      dt = dt2 * 2.0

      i0 = im0 - 1
      k1 = i0 / 12 + 1

      k2 = mod(i0,12)

      do 1000 k=1,k1
      k3 = 12
      if(k.eq.k1.and.k2.ne.0)  k3 = k2

      i1 = (k-1)*12 + 2
      i2 = k*12 + 1
      if(k.eq.k1.and.k2.ne.0)  i2 = i1 - 1 + k2

      j = jm0 + 1
 9000 continue
      m1 = j - 1
      m2 = j - 5
      if(m2.lt.2)  m2 = 2
      if(icheck.eq.1)  go to 6010
      do 5000 i=i1,i2
      do 6000 m=m2,m1
        if(hh1(i,m).gt.exm.or.hh3(i,m).gt.exm)  go to 5500
        if(abs(qm0(i,m)).gt.exm.or.abs(qm2(i,m)).gt.exm)  go to 5500
        if(abs(qn0(i,m)).gt.exm.or.abs(qn2(i,m)).gt.exm)  go to 5500
 6000 continue
 5000 continue
       go to 2000
 6010 continue
      do 5010 i=i1,i2
      do 6020 m=m2,m1
       if(hh3(i,m).lt.0.0)  go to 5500
       if(qm2(i,m).gt.exo.or.qm2(i,m).lt.exu)  go to 5500
       if(qn2(i,m).gt.exo.or.qn2(i,m).lt.exu)  go to 5500
 6020 continue
 5010 continue
       go to 2000

 5500 continue
      write(2,100)
      itimex = int(dt1 + dt1/86400.0)
      itime1 = itimex / 3600
      itimey = itimex - itime1 * 3600
      itime2 = itimey / 60
      itime3 = itimey - itime2 * 60
      write(2,200) itit,itime1,itime2,itime3
      write(2,210) dt1,dt
  200 format(5x,a80,' jikan : ',i3,'h ',i2,'m ',i2,'s ')
  210 format(    85x,'  time : ',f10.3,'(s)  dt: ',f7.4,' (s)')

      do 2300 l=1,k3
      nob(l) = l-2+i1
 2300 continue

      write(2,300)  (nob(l),l=1,k3)
      m = m1 + 1
      do 2100 n=m2,m1
      m = m -1
      write(2,400)  m-1
      write(2,500)  (hh1(i,m),i=i1,i2)
      write(2,510)  (qm0(i,m),i=i1,i2)
      write(2,520)  (qn0(i,m),i=i1,i2)
      write(2,530)  (zl1(i,m),i=i1,i2)
      write(2,540)  (hh3(i,m),i=i1,i2)
      write(2,520)  (qm2(i,m),i=i1,i2)
      write(2,560)  (qn2(i,m),i=i1,i2)
      write(2,570)  (zl3(i,m),i=i1,i2)

      k9 = 0
      do 2400 l=i1,i2
      k9 = k9 + 1
      dz(k9) = 0.0
      if(zi(l,m).lt.0.0)  go to 2400
      dz(k9) = zl3(l,m) + hh3(l,m)
 2400 continue

      write(2,580)  (dz(i),i=1,k9)
 2100 continue

 2000 continue
       j = m2
       if(j.gt.2)  go to 9000
 1000 continue
      write(2,110)  vbl
      write(2,120)  wbl

      return

  100 format(1h1)
  110 format('   sediment volume =   ',e15.7,'   (m3)')
  120 format('   water    volume =   ',e15.7,'   (m3)')
  300 format(10x,12(1x,' x =',i4,1x))
  400 format(2x,' y =',i4)
  500 format(' depth-1  ',12f10.5)
  510 format(' x-flux-0 ',12f10.5)
  520 format(' y-flux-0 ',12f10.5)
  530 format(' bed-e.l-1',12f10.5)
  540 format(' depth-3  ',12f10.5)
  560 format(' y-flux-2 ',12f10.5)
  570 format(' bed-e.l-3',12f10.5)
  580 format(' h-e.l.-3 ',12f10.5)

      end

c---------------------

      subroutine  print2(dt1,dt2)

c---------------------

      include 'lahar2d.inc'


      integer*4  itimex
      dimension  nob(12),d1(12),d2(12),d3(12),d4(12)

      dt = dt2 * 2.0

      i0 = im0 - 1
      k1 = i0 / 12 + 1
      k2 = mod(i0,12)

      do 1000 k=1,k1
      k3 = 12
      if(k.eq.k1.and.k2.ne.0)  k3 = k2

      i1 = (k-1)*12 + 2
      i2 = k*12 + 1
      if(k.eq.k1.and.k2.ne.0)  i2 = i1 - 1 + k2

      j = jm0 + 1
 9000 continue
      m1 = j - 1
      m2 = j - 5
      if(m2.lt.2)  m2 = 2
      if(icheck.eq.1)  go to 6010
      do 5000 i=i1,i2
      do 6000 m=m2,m1
        if(hh1(i,m).gt.exm.or.hh3(i,m).gt.exm)  go to 5500
        if(abs(qm0(i,m)).gt.exm.or.abs(qm2(i,m)).gt.exm)  go to 5500
        if(abs(qn0(i,m)).gt.exm.or.abs(qn2(i,m)).gt.exm)  go to 5500
 6000 continue
 5000 continue
       go to 2000
 6010 continue
      do 5010 i=i1,i2
      do 6020 m=m2,m1
       if(hh3(i,m).lt.0.0)  go to 5500
       if(qm2(i,m).gt.exo.or.qm2(i,m).lt.exu)  go to 5500
       if(qn2(i,m).gt.exo.or.qn2(i,m).lt.exu)  go to 5500
 6020 continue
 5010 continue
       go to 2000

 5500 continue
      write(2,100)
      itimex = int(dt1 + dt1/86400.0)
      itime1 = itimex / 3600
      itimey = itimex - itime1 * 3600
      itime2 = itimey / 60
      itime3 = itimey - itime2 * 60
      write(2,200) itit,itime1,itime2,itime3
      write(2,210) dt1,dt
  200 format(5x,a80,' jikan : ',i3,'h ',i2,'m ',i2,'s ')
  210 format(    85x,'  time : ',f10.3,'(s)  dt: ',f7.4,' (s)')

      do 2300 l=1,k3
      nob(l) = l-2+i1
 2300 continue

      write(2,300)  (nob(l),l=1,k3)
      m = m1 + 1
      do 2100 n=m2,m1
      m = m -1
      write(2,400)  m-1
      write(2,520)  (uvx(i,m),i=i1,i2)
      write(2,530)  (uvy(i,m),i=i1,i2)

      k9 = 0
      do 2410 l=i1,i2
      k9 = k9 + 1
      d3(k9) = 0.0
      d4(k9) = 0.0
      if(zi(l,m).lt.0.0)  go to 2410
      do 2420 ll = 1,idnum
      d3(k9) = d3(k9) + qmb(ll,l,m)
      d4(k9) = d4(k9) + qnb(ll,l,m)
 2420 continue
 2410 continue

      write(2,540)  (d3(i),i=1,k9)
      write(2,520)  (d4(i),i=1,k9)

      write(2,560)  (dm(i,m)  ,i=i1,i2)
      write(2,570)  (dmix(i,m),i=i1,i2)
      write(2,580)  (ddz2(i,m),i=i1,i2)

      k9 = 0
      do 2400 l=i1,i2
      k9 = k9 + 1
      d1(k9) = 0.0
      d2(k9) = 0.0
      if(zi(l,m).lt.0.0)  go to 2400
      d1(k9) = dmix(l,m) + ddz2(l,m)
      d2(k9) = zl3(l,m) - zi(l,m)
 2400 continue

      write(2,590)  (d1(i),i=1,k9)
      write(2,600)  (d2(i),i=1,k9)
 2100 continue

 2000 continue
       j = m2
       if(j.gt.2)  go to 9000
 1000 continue

      return

  100 format(1h1)
  300 format(10x,12(1x,' x =',i4,1x))
  400 format(2x,' y =',i4)
  520 format(' uvx      ',12f10.5)
  530 format(' uvy      ',12f10.5)
  540 format(' qmbt     ',12f10.5)
  560 format(' dm-mix-l ',12f10.5)
  570 format(' bed-dmix ',12f10.5)
  580 format(' bed-ddz2 ',12f10.5)
  590 format(' bed-depth',12f10.5)
  600 format(' bed-var  ',12f10.5)

      end

!**********************************************
      subroutine  calerrout
!**********************************************

      open(99999,file='../.calc.err', action='write')
      write(99999,'("err")')
      close(99999)
      
      end


