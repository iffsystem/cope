      program debri
!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------
      
      integer itime,itt,itime_h
      integer itime_min,itime_sec
      
      end_flag=0
      
      call setfopen_list
      call input_mesh_header
      call set_init
      call input_param
      call input_hydrograph
      call input_inflow_point
      call input_base_dem
      
      end_flag=1
 
      dt0 = 0.0
      artime_max0 = dt0

      write(*,*)
      write(*,'(" >> calculation start <<")')
      write(*,*)

      k = 0
      iconvcount = 0
      do 4000
            k = k + 1

            dt2 = dlt / 2.0

            dt1 = dt1 + dlt + dt0

            call debin(dt1)

            ! monitor the calculation status every 100 step
            if (mod(k,100)==0) then
            itime = int(dt1 + dt1/86400.0)
            itime_h = itime / 3600
            itt = itime - itime_h * 3600
            itime_min = itt / 60
            itime_sec = itt - itime_min * 60

            write(*,100)k,itime_h,itime_min,itime_sec,discharge_max

            end if  
        
      
      call   mncal(dt1,dt2)
      call   cmncal()
      call   corct1(dt2)
      call   hzcal(dt1,dt2)
      if(imax.le.0)  call  maxcal(dt1) 
      call  delete
      

      ! output snaps
      if(ioutFlag == 1) then

        wbl=0.
        vbl=0.
        do 1110 j=2,jm0
          do 1100 i=2,im0
            if(ipp(i,j).gt.0)  go to 1100
            if(zi(i,j).gt.0.0) then
              vbl = vbl + (zl3(i,j) - zi(i,j))*dlx*dly*cst
              vbl = vbl + hh3(i,j)*cd3(i,j)*dlx*dly
              wbl = wbl + hh3(i,j)*(1.0 - cd3(i,j))*dlx*dly
              wbl = wbl + (zl3(i,j) - zi(i,j))*(1.0 - cst)*dlx*dly
            end if

 1100   continue
 1110   continue


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
      do 5500  i9=2,im0
       hh01(i9,j9) = hh1(i9,j9)
       hh1(i9,j9) = hh3(i9,j9)
       zl1(i9,j9) = zl3(i9,j9)
       qm02(i9,j9)= qm0(i9,j9)
       qn02(i9,j9)= qn0(i9,j9)
       qm0(i9,j9) = qm2(i9,j9)
       qn0(i9,j9) = qn2(i9,j9)
       cd1(i9,j9) = cd3(i9,j9)
 5500 continue
 5600 continue

      artime_max  = maxval(artime(:,:))
      if (artime_max - artime_max0 < 1.d-8) then
              iconvcount = iconvcount + 1
      else
              iconvcount = 0
      end if
      if (iconvcount == 1) convflag = dt1
      if (hydDuration < dt1    .and. 
     $    dt1 - convflag > 300 .and. 
     $    artime_max - artime_max0 < 1.d-8) then
              write(*, *) "Flow status converged."
              exit
      end if
      artime_max0 = artime_max


 4000 continue
      if(end_flag == 1) go to 9000
 9000 continue

      call set_result_output_max()
      
      write(*,'("")')
      write(*,'(" Calculation END ")')
      write(*,'("")')

 100  format(2x, 'k = ', i7,
     *      ' time = ', i3, ' h', i3, ' m', i3, ' s Q = ',
     *      1pe11.3, ' m3/s')

      stop
      end

!**********************************************
      subroutine  set_init
!**********************************************

!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------

      exo = 10000.0
      exu = -exo
      exm = 0.0000001
      icheck = 0
      do j=1,jmy
            do i=1,imx
                  ipp(i,j) = 0
                  hh1(i,j) = 0.0
                  hh3(i,j) = 0.0
                  hh01(i,j) = 0.0
                  qm0(i,j) = 0.0
                  qn0(i,j) = 0.0
                  qm02(i,j) = 0.0
                  qn02(i,j) = 0.0
                  qm2(i,j) = 0.0
                  qn2(i,j) = 0.0
                  cd1(i,j) = 0.0
                  cd3(i,j) = 0.0
                  zl1(i,j) = 0.0
                  zl3(i,j) = 0.0
                  zmax(i,j) = 0.0
                  hmax(i,j) = 0.0
                  qmt(i,j) = 0.0
                  qnt(i,j) = 0.0
                  qmbt(i,j) = 0.0
                  qnbt(i,j) = 0.0
                  qmax(i,j) = 0.0
                  vmax(i,j) = 0.0
                  qxm(i,j) = 0.0
                  qym(i,j) = 0.0
                  vxm(i,j) = 0.0
                  vym(i,j) = 0.0
                  fmax(i,j) = 0.0
                  pdyn(i,j) = 0.0d0
                  psta(i,j) = 0.0d0
                  tau0(i,j) = 0.0d0
                  pmax2(i,j)  = 0.0
                  artime(i,j) = 0.0
                  uvmax(i,j)  = 0.0
                  hh3max(i,j) = 0.0
                  zi(i,j) = -1.0
                  zi0(i,j) = -1.0
                  zdl(i,j) = -1.0
                  ibz(i,j) = -1
                  adz(i,j) = 0.0
                  ikabe(i,j) = 0
            end do
      end do

      return
      end

!**********************************************
      subroutine  set_result_output(dt1)
!**********************************************

!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------

      integer i,j,itime
      real(8) tmpx(in, jn), tmpy(in, jn)
      real(8) state(in, jn)
      character(len=400)  :: fname1
      character(len=400)  :: fname2
      character(len=400)  :: fname3
      character(len=400)  :: fname4
      character(len=400)  :: fname5
      character(len=400)  :: fname6
      character(len=400)  :: fname7
      character(len=400)  :: fname8
      character(len=400)  :: fname9
      character(len=400)  :: fname10
      character(len=400)  :: fname11
      character(len=400)  :: fname12
      character(len=400)  :: fname13
      character(len=400)  :: fname14
      character(len=256):: fname
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
          if(abs(hh3(i, j)) > hcr) then
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
      include'pcf2b-sp.inc' 
!----------------------------------------------

      real(8) state(in, jn)
      character(len=400):: fname15
      character(len=400):: fname16
      character(len=400):: fname17
      character(len=400):: fname18
      character(len=400):: fname19
      character(len=400):: fname20
      character(len=400):: fname21
      character(len=400):: fname22
      character(len=400):: fname23
      character(len=400):: fname24
      character(len=400):: fname25
      character(len=400):: fname26
      character(len=400):: fname27
      character(len=400):: fname28
      character(len=400):: fname29
      character(len=400):: fname30
      character(len=400):: fname31
      character(len=400):: fname32
      character(len=400):: fname33
      character(len=400):: fname34
      character(len=400):: fname35
      character(len=400):: fname36
      character(len=400):: fname37
      character(len=400):: fname38
      character(len=400):: fname39
      character(len=400):: fname40
      character(len=256):: fname
      
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
      call ascout(fname, vmax)
      fname = trim(adjustl(fname28))//'.out'
      call ascout(fname, uvmaxtime)

      ! flow power in x-direction
      fname = trim(adjustl(fname29))//'.out'
      call ascout(fname, fmaxx)

      ! flow power in y-direction
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
      state(:, :) = artime(:, :) / 3600.d0
      call ascout(fname, artime)

      ! accumulated elevation
      fname = trim(adjustl(fname40))//'.out'
      state(:, :) = zl3(:, :) + hh3(:, :) * cd3(:, :) / cst
      call ascout(fname, state)

      return
      end

      subroutine ascout(fname, xx)
!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------
      character(256) :: fname
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

!**********************************************
      subroutine  setfopen_list
!**********************************************

!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------

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
          read(100, *) outfname(i)
          read(100, *) outfpath(i)
        end do
        
        
        ! set character length excepted any space
        do i=1,6
              iflen_in(i)=len_trim(trim(adjustl(infpath(i)))
     *                  //trim(adjustl(infname(i))))
        end do
        do i=1,40
              iflen_out(i)=len_trim(trim(adjustl(outfpath(i)))
     *                  //trim(adjustl(outfname(i))))
      !      write(*,*)i,iflen_out(i)
        end do
        
      
      close(100)
    
      return
      end

!**********************************************
      subroutine  input_mesh_header
!**********************************************

!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------

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

!**********************************************
      subroutine  input_param
!**********************************************

!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------

      integer err
      real(8) err0
      character(len=iflen_in(2)) fparam
      character(len=200) dummy

      fparam=trim(adjustl(infpath(2)))//trim(adjustl(infname(2)))
      open(102,file=fparam,action='read',iostat=err)
        if(err/=0) then
                write(*,*) 'cannot open file 102 fparam'
                call calerrout
                stop
        end if
        
        read(102,*) thu,dummy,dummy
        read(102,*) fai,dummy,dummy
        read(102,*) te,dummy,dummy
        read(102,*) crd,dummy,dummy
        read(102,*) sig,dummy,dummy
        read(102,*) cst,dummy,dummy
        read(102,*) dm,dummy,dummy
        read(102,*) bex,dummy,dummy
        read(102,*) bey,dummy,dummy
        read(102,*) hcr,dummy,dummy
        read(102,*) ccr,dummy,dummy
        read(102,*) qagx,dummy,dummy
        read(102,*) qagy,dummy,dummy
        read(102,*) iwr,dummy,dummy
        read(102,*) ickb,dummy,dummy
        read(102,*) ierg,dummy,dummy
        read(102,*) imax,dummy,dummy
        
        
        close(102)
        
        
        err0 = qagx + qagy - 1.0
      if(err0 .gt. exm) then
            write(*,'(3(1pe16.8))') err0,exm,exm-err0
            call errnum('in20')
      end if
      
        write(*,'(4(f10.3))')thu,fai,te,crd
        write(*,'(4(f10.3))')sig,cst,dm,bex
        write(*,'(5(f10.3))')bey,hcr,ccr,qagx,qagy
        write(*,'(4(i3))')iwr,ickb,ierg,imax
        
        if(crd.le.0.0)   crd = 1.0
        
      if(thu.le.0.0.or.thu.gt.90.0)  call  errnum('in09')
      if(fai.le.0.0.or.fai.gt.90.0)  call  errnum('in10')

       pai = 3.14159 / 180.0
       thu = thu * pai
       fai = fai * pai
       dm = dm / 100.0

       if(hcr.le.0.0)   hcr = 0.001
       if(bex.le.1.0)   bex = 1.0
       if(bey.le.1.0)   bey = 1.0

       if(sig.lt.0.5.or.sig.gt.5.0)  call  errnum('in13')
       if(cst.le.0.0.or.cst.gt.1.0)  call  errnum('in14')
       if( dm.le.0.0.or. dm.gt.100.0)call  errnum('in15')
       
       thu = sin(thu) / cos(thu)
       fai = sin(fai) / cos(fai)
 
        
        write(*,*)
        write(*,'(4(f10.3))')thu,fai,te,crd
        write(*,'(4(f10.3))')sig,cst,dm,bex
        write(*,'(5(f10.3))')bey,hcr,ccr,qagx,qagy
        write(*,'(4(i3))')iwr,ickb,ierg,imax
        
        
      
      return
      end

!**********************************************
      subroutine  input_hydrograph
!**********************************************

!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------

      integer err
      character(len=iflen_in(3)) fhyd
      character(len=200) dummy

      ! Set output interval time
      loutInterval = 60           ! every 60 seconds
      ioutTime     = loutInterval ! next output time
      ioutFlag     = 0            ! set output flag off

      fhyd=trim(adjustl(infpath(3)))//trim(adjustl(infname(3)))
      open(103,file=fhyd,action='read',iostat=err)
      if(err/=0) then
        write(*,*) 'cannot open file 103 fhyd'
        call calerrout
        stop
      end if

        read(103,*) ihydType, alpha
        read(103,*) dummy
        read(103,*) dummy
        
        write(*,*) ihydType, alpha

        select case (ihydType)

          case (HydtypeTriangular)
            read(103,*) hydDuration, hydVolume
            read(103,*) hydPeaktime
            read(103,*) huuPeak, cduPeak

            hydPeakrate = 2.0 * hydVolume / hydDuration

            write(*, *)
            write(*, *) hydDuration, hydVolume, hydPeakrate
            write(*, *) hydPeaktime
            write(*, *) huuPeak, cduPeak
            if(HydPeaktime < 0.d0 .or. 1.d0 < HydPeaktime) then
              write(*, *) 'Peaktime ration out of range.'
              write(*, *) 'HydPeak between 0 and 1.'
              call calerrout
              stop
            end if

          case (HydtypeRectangular)
            read(103,*) hydDuration, hydVolume
            read(103,*) huuPeak, cduPeak

            hydPeakrate = hydVolume / hydDuration

            write(*, *)
            write(*, *) hydDuration, hydVolume, hydPeakrate
            write(*, *) huuPeak, cduPeak

          case default
            write(*, '("Unknown hydrograph type: ", i5)') ihydType
            call calerrout
            stop
        end select


        close(103)
      return
      end

!**********************************************
      subroutine  input_inflow_point
!**********************************************

!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------

      integer err,i,j,num,px,py,pcol,prow
      character(len=iflen_in(4)) finf_p

      integer(4) :: uniqueCol(2, nh)
      integer(4) :: uniqueRow(2, nh)
      integer(4) :: nUniqueCol, nUniqueRow
      integer(4) :: maxPnt, minPnt, maxIdx, minIdx
      
      finf_p=trim(adjustl(infpath(4)))//trim(adjustl(infname(4)))
      open(104,file=finf_p,action='read',iostat=err)
        if(err/=0) then
                write(*,*) 'cannot open file 104 finf_p'
                call calerrout
                stop
        end if
        
        read(104,*) num, ifp_dir
        nqbc = num
        
        do i=1,num
              read(104,*) ifp_col(i), ifp_row(i)
        end do
        
        write(*, '(" Num. of in pnts.: ", i5)') num
        write(*, '(" Inflow dir.:      ", i5)') ifp_dir
        do i=1,num
              write(*,'(2(i5))')ifp_col(i),ifp_row(i)
        end do
        
      
      pcol=ifp_col(1)
      prow=ifp_row(1)
      
      write(*,*)
      
      
      i=0
      do while ( i == 0 )
        if (ifp_dir >= 0 .and. ifp_dir < 360 ) then
            i=1
        else if (ifp_dir < 0) then
            ifp_dir = ifp_dir + 360
        else if (ifp_dir >= 360 ) then
            ifp_dir = ifp_dir - 360
        end if
      end do
      
      if (ifp_dir ==   0) ipp_dir = 1
      if (ifp_dir ==  90) ipp_dir = 4
      if (ifp_dir == 180) ipp_dir = 3
      if (ifp_dir == 270) ipp_dir = 2
      if (  0 < ifp_dir .and. ifp_dir <  90) ipp_dir = 8
      if ( 90 < ifp_dir .and. ifp_dir < 180) ipp_dir = 7
      if (180 < ifp_dir .and. ifp_dir < 270) ipp_dir = 6
      if (270 < ifp_dir .and. ifp_dir < 360) ipp_dir = 5
      

      write(*, *) 'inflow points in computational alignment'
      do i=1,num
            px = ifp_col(i)+1
            py = jmy-1-ifp_row(i)
            ifp_col(i) = px
            ifp_row(i) = py
            iqbc(1, i) = px
            iqbc(2, i) = py
            ipp(px,py) = ipp_dir
            write(*,*)px,py,ipp_dir
      end do

      qqx =   hydPeakrate * cos(dble(ifp_dir) * pi180) / dble(num) / dly
      qqy = - hydPeakrate * sin(dble(ifp_dir) * pi180) / dble(num) / dlx
      
      
      write(*, '("  divided discharge: ", 2f10.5)') qqx, qqy

      ! Superposition of discharge
      fqxbc(:) = 0.d0; fqybc(:) = 0.d0
      ! X-direction
      call countUnique(num, ifp_row, uniqueRow, nUniqueRow)
      do i = 1, nUniqueRow
        maxPnt = 0
        minPnt = 99999
        do j = 1, num
          if (ifp_row(j) == uniqueRow(1, i)) then
                  if (ifp_col(j) > maxPnt) then
                          maxPnt = ifp_col(j)
                          maxIdx = j
                  end if
                  if (ifp_col(j) < minPnt) then
                          minPnt = ifp_col(j)
                          minIdx = j
                  end if
          end if
        end do

        if (qqx > 0.d0) then
                fqxbc(maxIdx) = abs(qqx * uniqueRow(2, i))
        else
                fqxbc(minIdx) = abs(qqx * uniqueRow(2, i))
        end if
      end do

      ! Y-direction
      call countUnique(num, ifp_col, uniqueCol, nUniqueCol)
      do i = 1, nUniqueCol
        maxPnt = 0
        minPnt = 99999
        do j = 1, num
          if (ifp_col(j) == uniqueCol(1, i)) then
                  if (ifp_row(j) > maxPnt) then
                          maxPnt = ifp_row(j)
                          maxIdx = j
                  end if
                  if (ifp_row(j) < minPnt) then
                          minPnt = ifp_row(j)
                          minIdx = j
                  end if
          end if
        end do
        if (qqy > 0.d0) then
                fqybc(maxIdx) = abs(qqy * uniqueCol(2, i))
        else
                fqybc(minIdx) = abs(qqy * uniqueCol(2, i))
        end if
      end do

      write(*, *) "fqxbc, fqybc (absolute val.)"
      do i = 1, num
        write(*, *) fqxbc(i), fqybc(i)
      end do
      
        close(104)
        
        ! +--------------+
        ! incremental time
        ! +--------------+

        qq = max(maxval(fqxbc(:)), maxval(fqybc(:))) ! assume max unit width discharge
        write(*, '("  max unit discharge: ", f10.5, " [m3/m/sec]")') qq

        if(qq.le.0.0)  then
          write(*, *) 'ZERO or negative peak discharge.'
          call calerrout
          stop
        end if
 
        if(cduPeak.gt.0.0)  go to  1000
         ce = (1.05409255 * thu / fai)**3
         if(ce.gt.0.9*cst)  ce = 0.9 * cst
        go to  2000
 1000   continue
        ce = cduPeak
 2000   continue
        cd = ce

        if(huuPeak.gt.0.0)  go to 5000
 
        a1 = 0.02 * te * dm * dm / grav
        a2 = 1.0 - ( cd / cst )**(1.0/3.0)
        a3 = sqrt( a1 / a2 ) 
        hu = ( 2.5 * a3 * abs(qq) / cd )**0.4
        uu = 0.4 / a3 * hu ** 1.5

        if(abs(qq).gt.0.0.and.uu.le.0.0)   call  errnum('db02')
        huuPeak = hu
        go to 6000

 5000   continue
        hu = huuPeak
        uu = qq / hu
 6000   continue

        !------------------------------!
        dlt = alpha * min(dlx, dly) / uu
        dlt_org = dlt
        !------------------------------!
        write(*, *)
        write(*, '("  Incremental time: ", f15.12, " [sec]")') dlt
        write(*, *)

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

!**********************************************
      subroutine  input_base_dem
!**********************************************

!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------

      integer err,i,j,rows,cols
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
              write(*,*)imx,imy,cols,rows
              write(*,'("STOP")')
              write(*,*)
              call calerrout
              stop
        end if
        
        
        do j=rows+1,2,-1
              read(106,*) (zi(i,j),i=2,cols+1)
        end do
        
        close(106)
        
        ! copy initial elevation        
        do j=1,jmy
              do i=1,imx
                    zl1(i,j) = zi(i,j)
                  zl3(i,j) = zi(i,j)
            end do
        end do
        
        ! set boundary flag
        do j=2,jm0

            ibc(1,j) = 2
            ibc(2,j) = im0

            do i=2,im0
                  if(zi(i+1,j) < 0.0.and.zi(i,j) >= 0.0) exit
                  
                  if(zi(i-1,j) < 0.0.and.zi(i,j) >= 0.0) then
                        ibc(1,j) = i
                        exit
                  end if
            end do

            do i=im0,2,-1
                  if(zi(i-1,j) < 0.0.and.zi(i,j) >= 0.0) exit
                  
                  if(zi(i+1,j) < 0.0.and.zi(i,j) >= 0.0) then
                      ibc(2,j) = i
                      exit
                  end if
            end do
      end do
        

      do j=2,jm0
            do i=2,im0
                  if(zi(i,j) < 0.0) cycle
                  zdl(i,j)=zi(i,j)-adz(i,j)
                  ibz(i,j) = 1
            end do
      end do

      ! set trainning dyke to control the direction of flow
      if(ickb == 1)then

      else
            do j=2,jm0
                  do i=2,im0
                        ikabe(i,j)=0
                  end do
            end do
      end if

      if(iwr <= 0)  return
        
        
        
      return
      end


!**********************************************
      subroutine  debin(dt1)
!**********************************************

!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------

      discharge_max = 0.d0
      do ib = 1, nqbc

        ixbc = iqbc(1, ib)
        iybc = iqbc(2, ib)
        fqx  = fqxbc(ib)
        fqy  = fqybc(ib)


        qqx = 0.0
        qqy = 0.0
        select case (ihydType)

          case (HydtypeTriangular)
                  Peaktime = hydDuration * hydPeaktime
                  if (0.d0 <= dt1 .and. dt1 < Peaktime) then
                          tt1 = dt1 / Peaktime
                          qqx = fqx     * tt1
                          qqy = fqy     * tt1
                          cdu = cduPeak * tt1
                          huu = huuPeak * tt1

                  else if (Peaktime <= dt1 .and. dt1 < hydDuration) then
                          tt1 = (hydDuration - dt1) 
     $                        / (hydDuration - Peaktime)
                          qqx = fqx     * tt1
                          qqy = fqy     * tt1
                          cdu = cduPeak * tt1
                          huu = huuPeak * tt1

                  else
                          cdu = 0.d0
                          huu = 0.d0
                  end if

          case (HydtypeRectangular)
                  if (0.d0 <= dt1 .and. dt1 < hydDuration) then
                          qqx = fqx
                          qqy = fqy
                          cdu = cduPeak
                          huu = huuPeak
                  else
                          cdu = 0.d0
                          huu = 0.d0
                  end if

          case default
                  write(*, '("Unknown hydrograph type: ", i5)') ihydType
                  call calerrout
                  stop
        end select


        qq = sqrt( qqx*qqx + qqy*qqy )
        if (qq > discharge_max) discharge_max = qq
        if(qq.le.0.0)  then
          hu = 0.0
          uu = 0.0
          cd = 0.0
          go to 7000
        end if
 
        if(cdu.gt.0.0)  go to  1000
         ce = (1.05409255 * thu / fai)**3
         if(ce.gt.0.9*cst)  ce = 0.9 * cst
        go to  2000
 1000   continue
        ce = cdu
 2000   continue
        cd = ce

        if(huu.gt.0.0)  go to 5000
 
        a1 = 0.02 * te * dm * dm / grav
        a2 = 1.0 - ( cd / cst )**(1.0/3.0)
        a3 = sqrt( a1 / a2 ) 
        hu = ( 2.5 * a3 * qq / cd )**0.4
        uu = 0.4 / a3 * hu ** 1.5

        if(qq.gt.0.0.and.uu.le.0.0)   call  errnum('db02')
        huu = hu
        go to 6000

 5000   continue
        hu = huu
        uu = qq / huu
 6000   continue

        qq = qq / cd
        qqx = qqx / cd
        qqy = qqy / cd

 7000   continue


          if(ipp(ixbc,iybc).eq.1.or.ipp(ixbc,iybc).eq.5
     $                          .or.ipp(ixbc,iybc).eq.8)  then
             qm2(ixbc+1,  iybc)  = qqx
             qm0(ixbc+1,  iybc)  = qqx
             qm02(ixbc+1, iybc)  = qqx
          end if

          if(ipp(ixbc,iybc).eq.2.or.ipp(ixbc,iybc).eq.5
     $                          .or.ipp(ixbc,iybc).eq.6)  then
             qn2(ixbc,  iybc+1)  = qqy
             qn0(ixbc,  iybc+1)  = qqy
             qn02(ixbc, iybc+1)  = qqy
          end if

          if(ipp(ixbc,iybc).eq.3.or.ipp(ixbc,iybc).eq.6
     $                          .or.ipp(ixbc,iybc).eq.7)  then
             qm2(ixbc,  iybc)  = -qqx
             qm0(ixbc,  iybc)  = -qqx
             qm02(ixbc, iybc)  = -qqx
          end if

          if(ipp(ixbc,iybc).eq.4.or.ipp(ixbc,iybc).eq.7
     $                          .or.ipp(ixbc,iybc).eq.8)  then
             qn2(ixbc,  iybc)  = -qqy
             qn0(ixbc,  iybc)  = -qqy
             qn02(ixbc, iybc)  = -qqy
          end if

           hh3(ixbc, iybc) = hu
           hh1(ixbc, iybc) = hu
           cd1(ixbc, iybc) = cd
           cd3(ixbc, iybc) = cd
           ibz(ixbc, iybc) = 0

      end do

      return


      end
!**********************************************
      subroutine  mncal(dt1,dt)
!**********************************************
!     solve M=uh & N=vh by momentum eq. 
!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------

      dt2 = 1.0 / (2.0*dt)
      alfa1 = 1.0
      alfa2 = 1.0

      do 1000 j=2,jm0
      do 2000 i=ibc(1,j),ibc(2,j)

!============================================================= boundary
        if(zi(i,j).lt.0.0)  go to 2000
        if(ipp(i-1,j).eq.1.or.ipp(i-1,j).eq.5.or.ipp(i-1,j).eq.8.or.
     @     ipp(i  ,j).eq.3.or.ipp(i  ,j).eq.6.or.ipp(i  ,j).eq.7)
     @                                                  go to 3000
!======================================================================

!======================================================== x - direction

        if((zi(i-1,j).ge.0.0).and.
     @    (ikabe(i-1,j).ne.1).and.(ikabe(i-1,j).ne.3))  go to 4000
       qm2(i,j) = 0.0
       go to 3000
 4000 continue
       qm2(i,j) = 0.0

      if(ibz(i,j).le.0.or.ibz(i-1,j).le.0)  go to 3000

      ccd =  ( cd1(i,j) + cd1(i-1,j) ) / 2.0

      h0 = hh1(i,j) + hh1(i-1,j)

      a6 = 0.0
      a7 = 0.0
      a8 = 0.0

!.................................................................. xdx
      a1 = 0.0
      a2 = 0.0
      h1 = hh1(i+1,j) + hh1(i  ,j) + hh01(i+1,j) + hh01(i  ,j)
      h2 = hh1(i  ,j) + hh1(i-1,j) + hh01(i,  j) + hh01(i-1,j)
      
      if(h1.ge.hcr)  a1 = ( qm0(i+1,j) + qm02(i+1,j) ) / h1
      if(h2.ge.hcr)  a2 = ( qm0(i  ,j) + qm02(i  ,j) ) / h2

!============================================================= boundary
      if(qq.gt.0.0.and.
     *        (ipp(i+1,j).eq.3.or.ipp(i+1,j).eq.6.or.ipp(i+1,j).eq.7))
     *                                a1 = uu * qm0(i+1,j) / qq
!======================================================================

      u1 = a1 + a2

      a1 = 0.0
      a2 = 0.0
      h1 = hh1(i,  j) + hh1(i-1,j) + hh01(i  ,j) + hh01(i-1,j)
      h2 = hh1(i-1,j) + hh1(i-2,j) + hh01(i-1,j) + hh01(i-2,j)
      if(h1.ge.hcr)  a1 = ( qm0(i  ,j) + qm02(i  ,j) ) / h1
      if(h2.ge.hcr)  a2 = ( qm0(i-1,j) + qm02(i-1,j) ) / h2

!============================================================= boundary
      if(qq.gt.0.0.and.
     *        (ipp(i-2,j).eq.1.or.ipp(i-2,j).eq.5.or.ipp(i-2,j).eq.8))
     *                                a2 = uu * qm0(i-1,j) / qq
!======================================================================

      u0 = a1 + a2

      qq2 = ( qm0(i+1,j) + qm02(i+1,j) ) / 2.0
      qq1 = ( qm0(i  ,j) + qm02(i  ,j) ) / 2.0
      qq0 = ( qm0(i-1,j) + qm02(i-1,j) ) / 2.0

      xdx =  u1 * ( qq1 + qq2 ) + alfa1 * abs( u1 ) * ( qq1 - qq2 )
     *     - u0 * ( qq0 + qq1 ) - alfa1 * abs( u0 ) * ( qq0 - qq1 )
      xdx = xdx / dlx / 4.0

!................................................................. xdy

      qq0 = ( qm0(i,j-1) + qm02(i,j-1) ) / 2.0
      qq1 = ( qm0(i,j  ) + qm02(i,j  ) ) / 2.0
      qq2 = ( qm0(i,j+1) + qm02(i,j+1) ) / 2.0


      v1= 0.0
      a1 = 2.0 * ( qn0(i-1,j) + qn02(i-1,j) )
      h1 = hh1(i-1,j) + hh1(i-1,j-1) + hh01(i-1,j) + hh01(i-1,j-1)
      if(h1.ge.hcr)  v1 = a1 / h1

      v2 = 0.0
      a2 = 2.0 * ( qn0(i-1,j+1) + qn02(i-1,j+1) )
      h2 = hh1(i-1,j+1) + hh1(i-1,j) + hh01(i-1,j+1) + hh01(i-1,j)
      if(h2.ge.hcr)  v2 = a2 / h2

      v3 = 0.0
      a3 = 2.0 * ( qn0(i,j) + qn02(i,j) )
      h3 = hh1(i,j) + hh1(i,j-1) + hh01(i,j) + hh01(i,j-1)
      if(h3.ge.hcr)  v3 = a3 / h3

      v4 = 0.0
      a4 = 2.0 * ( qn0(i,j+1) + qn02(i,j+1) )
      h4 = hh1(i,j+1) + hh1(i,j) + hh01(i,j+1) + hh01(i,j)
      if(h4.ge.hcr)  v4 = a4 / h4

!============================================================= boundary
      if(qq.gt.0.0.and.(ipp(i-1,j  ).eq.4.or.ipp(i-1,j  ).eq.7.or.
     *  ipp(i-1,j-1).eq.2.or.ipp(i-1,j-1).eq.5.or.ipp(i-1,j-1).eq.6))
     *            v1 = uu * qn0(i-1,j) / qq

      if(qq.gt.0.0.and.(ipp(i-1,j  ).eq.2.or.ipp(i-1,j  ).eq.6.or.
     *  ipp(i-1,j+1).eq.4.or.ipp(i-1,j+1).eq.7.or.ipp(i-1,j+1).eq.8))
     *            v2 = uu * qn0(i-1,j+1) / qq

      if(qq.gt.0.0.and.(ipp(i,j  ).eq.4.or.ipp(i,j  ).eq.8.or.
     *  ipp(i,j-1).eq.2.or.ipp(i,j-1).eq.5.or.ipp(i,j-1).eq.6))
     *            v3 = uu * qn0(i,j) / qq

      if(qq.gt.0.0.and.(ipp(i,j  ).eq.2.or.ipp(i,j  ).eq.5.or.
     *  ipp(i,j+1).eq.4.or.ipp(i,j+1).eq.7.or.ipp(i,j+1).eq.8))
     *            v4 = uu * qn0(i,j+1) / qq
!======================================================================

      xdy = (v2 + v4) * (qq1 + qq2) + alfa2 * abs(v2 + v4) * (qq1 - qq2)
     *    - (v1 + v3) * (qq0 + qq1) - alfa2 * abs(v1 + v3) * (qq0 - qq1)
      xdy = xdy / dly / 4.0 

      a5 = bex * xdx + bex * xdy

      if(h0.lt.hcr)  go to 2250

      hh = h0 / 2.0
      a6 = -4.9 * h0 * (  ( zl1(i,j  ) + hh1(i,j  ) )
     *               -  ( zl1(i-1,j) + hh1(i-1,j) ) ) / dlx

      u0 = 0.0
      h9 = hh01(i,j) + hh01(i-1,j) + hh1(i,j) + hh1(i-1,j)
      if(h9.ge.hcr)  u0 = 2.0 * ( qm0(i,j) + qm02(i,j) ) / h9

      call v0cal(i,j,v1,v2,v3,v4,v0)

      uv = sqrt(u0*u0 + v0*v0)
      if(uv.le.0.0)  go to 2250

      a8 = 0.1185854 * ccd**(1.0/3.0) / 
     *                    ( 1.0 - ( ccd / cst )**(1.0/3.0) )
      a8 = - a8 * fai * te * ( dm / hh )**2 *  uv / h0

 2250 continue
      a9 = a6 - a5 + qm0(i,j)*(dt2 + a8 + a7)
      a0 = dt2 - a8 - a7
      qm2(i,j) = a9 / a0

      if(qm2(i,j).gt.exo)  call  calerr(dt1,dt,'+qm2')
      if(qm2(i,j).lt.exu)  call  calerr(dt1,dt,'-qm2')

      if(hh1(i  ,j).lt.hcr.and.qm2(i,j).lt.0.0)   qm2(i,j) = 0.0
      if(hh1(i-1,j).lt.hcr.and.qm2(i,j).gt.0.0)   qm2(i,j) = 0.0
      if(abs(qm2(i,j)).lt. exm)  qm2(i,j) = 0.0

!======================================================== y - direction

 3000 continue
        if(ipp(i,j-1).eq.2.or.ipp(i,j-1).eq.5.or.ipp(i,j-1).eq.6.or.
     @     ipp(i,j  ).eq.4.or.ipp(i,j  ).eq.7.or.ipp(i,j  ).eq.8)
     @                                                   go to 2000

      if((zi(i,j-1).gt.0.0).and.(ikabe(i,j-1).lt.2))  go to 5000
       qn2(i,j) = 0.0
       go to 2000
 5000 continue
       qn2(i,j) = 0.0

      if(ibz(i,j).le.0.or.ibz(i,j-1).le.0)  go to 2000

       ccd = ( cd1(i,j) + cd1(i,j-1) ) / 2.0

      h0 = hh1(i,j) + hh1(i,j-1)

      a6 = 0.0
      a7 = 0.0
      a8 = 0.0

!.................................................................. ydy
      a1 = 0.0
      a2 = 0.0
      h1 = hh1(i,j+1) + hh1(i,j  ) + hh01(i,j+1) + hh01(i,j  )
      h2 = hh1(i,j  ) + hh1(i,j-1) + hh01(i,j  ) + hh01(i,j-1)
      if(h1.ge.hcr)  a1 = ( qn0(i,j+1) + qn02(i,j+1) ) / h1
      if(h2.ge.hcr)  a2 = ( qn0(i  ,j) + qn02(i  ,j) ) / h2

!============================================================= boundary
      if(qq.gt.0.0.and.
     *        (ipp(i,j+1).eq.4.or.ipp(i,j+1).eq.7.or.ipp(i,j+1).eq.8))
     *                                a1 = uu * qn0(i,j+1) / qq
!======================================================================

      v1 = a1 + a2

      a1 = 0.0
      a2 = 0.0
      h1 = hh1(i,  j) + hh1(i,j-1) + hh01(i  ,j) + hh01(i,j-1)
      h2 = hh1(i,j-1) + hh1(i,j-2) + hh01(i,j-1) + hh01(i,j-2)
      if(h1.ge.hcr)  a1 = ( qn0(i  ,j) + qn02(i  ,j) ) / h1
      if(h2.ge.hcr)  a2 = ( qn0(i,j-1) + qn02(i,j-1) ) / h2

!============================================================= boundary
      if(qq.gt.0.0.and.
     *        (ipp(i,j-2).eq.2.or.ipp(i,j-2).eq.5.or.ipp(i,j-2).eq.6))
     *                                a2 = uu * qn0(i,j-1) / qq
!======================================================================

      v0 = a1 + a2

      qq0 = ( qn0(i,j-1) + qn02(i,j-1) ) / 2.0
      qq1 = ( qn0(i  ,j) + qn02(i  ,j) ) / 2.0
      qq2 = ( qn0(i,j+1) + qn02(i,j+1) ) / 2.0

      ydy =  v1 * ( qq1 + qq2 ) + alfa1 * abs( v1 ) * ( qq1 - qq2 )
     *     - v0 * ( qq0 + qq1 ) - alfa1 * abs( v0 ) * ( qq0 - qq1 )
      ydy = ydy / dly / 4.0

!.................................................................. ydx

      u1= 0.0
      a1 = 2.0 * ( qm0(i,j-1) +  qm02(i,j-1) )
      h1 = hh1(i,j-1) + hh1(i-1,j-1) + hh01(i,j-1) + hh01(i-1,j-1)
      if(h1.ge.hcr)  u1 = a1 / h1

      u2 = 0.0
      a2 = 2.0 * ( qm0(i+1,j-1) + qm02(i+1,j-1) )
      h2 = hh1(i+1,j-1) + hh1(i,j-1) + hh01(i+1,j-1) + hh01(i,j-1)
      if(h2.ge.hcr)  u2 = a2 / h2

      u3 = 0.0
      a3 = 2.0 * ( qm0(i,j) + qm02(i,j) )
      h3 = hh1(i,j) + hh1(i-1,j) + hh01(i,j) + hh01(i-1,j)
      if(h3.ge.hcr)  u3 = a3 / h3

      u4 = 0.0
      a4 = 2.0 * ( qm0(i+1,j) + qm02(i+1,j) )
      h4 = hh1(i+1,j) + hh1(i,j) + hh01(i+1,j) + hh01(i,j)
      if(h4.ge.hcr)  u4 = a4 / h4

!============================================================= boundary
      if(qq.gt.0.0.and.(ipp(i,j-1).eq.3.or.ipp(i,j-1).eq.7.or.
     *  ipp(i-1,j-1).eq.1.or.ipp(i-1,j-1).eq.5.or.ipp(i-1,j-1).eq.8))
     *            u1 = uu * qm0(i,j-1) / qq

      if(qq.gt.0.0.and.(ipp(i,j-1).eq.1.or.ipp(i,j-1).eq.8.or.
     *  ipp(i+1,j-1).eq.3.or.ipp(i+1,j-1).eq.6.or.ipp(i+1,j-1).eq.7))
     *            u2 = uu * qm0(i+1,j-1) / qq

      if(qq.gt.0.0.and.(ipp(i,j  ).eq.3.or.ipp(i,j  ).eq.6.or.
     *  ipp(i-1,j).eq.1.or.ipp(i-1,j).eq.5.or.ipp(i-1,j).eq.8))
     *            u3 = uu * qm0(i,j) / qq

      if(qq.gt.0.0.and.(ipp(i,j  ).eq.1.or.ipp(i,j  ).eq.5.or.
     *   ipp(i+1,j).eq.3.or.ipp(i+1,j).eq.6.or.ipp(i+1,j).eq.7))
     *            u4 = uu * qm0(i+1,j) / qq
!======================================================================

      qq0 = ( qn0(i-1,j) + qn02(i-1,j) ) / 2.0
      qq1 = ( qn0(i  ,j) + qn02(i  ,j) ) / 2.0
      qq2 = ( qn0(i+1,j) + qn02(i+1,j) ) / 2.0

      ydx = (u2 + u4) * (qq1 + qq2) + alfa2 * abs(u2 + u4) * (qq1 - qq2)
     *    - (u1 + u3) * (qq0 + qq1) - alfa2 * abs(u1 + u3) * (qq0 - qq1)
      ydx = ydx / dlx / 4.0 

      a5 = bey * ydy + bey * ydx

      if(h0.lt.hcr)  go to 2400

      hh = h0 / 2.0
      a6 = -4.9 * h0 * (  ( zl1(i,j  ) + hh1(i,j  ) )
     *               -  ( zl1(i,j-1) + hh1(i,j-1) ) ) / dly

      call u0cal(i,j,u1,u2,u3,u4,u0)
     
      v0 = 0.0
      h9 = hh01(i,j) + hh01(i,j-1) + hh1(i,j) + hh1(i,j-1)
      if(h9.ge.hcr)  v0 = 2.0 * ( qn0(i,j) + qn02(i,j) ) / h9

      uv = sqrt(u0*u0+v0*v0)
      if(uv.le.0.0)  go to 2400

      a8 = 0.1185854 * ccd**(1.0/3.0) /
     *                    ( 1.0 - ( ccd / cst )**(1.0/3.0) )
      a8 = - a8 * fai * te * ( dm / hh )**2 * uv / h0

 2400 continue
      a9 = a6 - a5 + qn0(i,j)*(dt2 + a8 + a7)
      a0 = dt2 - a8 - a7
      qn2(i,j) = a9 / a0

      if(qn2(i,j).gt.exo)  call calerr(dt1,dt,'+qn2')
      if(qn2(i,j).lt.exu)  call calerr(dt1,dt,'-qn2')

      if(hh1(i,j  ).lt.hcr.and.qn2(i,j).lt.0.0)   qn2(i,j) = 0.0
      if(hh1(i,j-1).lt.hcr.and.qn2(i,j).gt.0.0)   qn2(i,j) = 0.0
      if(abs(qn2(i,j)).lt. exm)  qn2(i,j) = 0.0

 2000 continue
 1000 continue

      return
      end
!**********************************************
      subroutine  v0cal(i,j,v1,v2,v3,v4,v0)
!**********************************************

!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------

      v0 = ( v1 + v2 + v3 + v4 ) / 4.0

      if((ibz(i  ,j-1).lt.  0.or.ikabe(i  ,j-1).ge.2).and.
     @   (ibz(i-1,j+1).lt.  0.or.ikabe(i-1,j  ).ge.2).and.
     @   (ibz(i  ,j+1).lt.  0.or.ikabe(i  ,j  ).ge.2))     go to 2500
      if((ibz(i-1,j-1).lt.  0.or.ikabe(i-1,j-1).ge.2).and.
     @   (ibz(i  ,j-1).lt.  0.or.ikabe(i  ,j-1).ge.2).and.
     @   (ibz(i  ,j+1).lt.  0.or.ikabe(i  ,j  ).ge.2))     go to 2510
      if((ibz(i-1,j-1).lt.  0.or.ikabe(i-1,j-1).ge.2).and.
     @   (ibz(i-1,j+1).lt.  0.or.ikabe(i-1,j  ).ge.2).and.
     @   (ibz(i  ,j+1).lt.  0.or.ikabe(i  ,j  ).ge.2))     go to 2520
      if((ibz(i-1,j-1).lt.  0.or.ikabe(i-1,j-1).ge.2).and.
     @   (ibz(i  ,j-1).lt.  0.or.ikabe(i  ,j-1).ge.2).and.
     @   (ibz(i-1,j+1).lt.  0.or.ikabe(i-1,j  ).ge.2))     go to 2530

      if((ibz(i-1,j-1).lt.  0.or.ikabe(i-1,j-1).ge.2).and.
     @   (ibz(i  ,j+1).lt.  0.or.ikabe(i  ,j  ).ge.2))     go to 2540
      if((ibz(i  ,j-1).lt.  0.or.ikabe(i  ,j-1).ge.2).and.
     @   (ibz(i-1,j+1).lt.  0.or.ikabe(i-1,j  ).ge.2))     go to 2550
      if((ibz(i-1,j-1).lt.  0.or.ikabe(i-1,j-1).ge.2).and.
     @   (ibz(i-1,j+1).lt.  0.or.ikabe(i  ,j-1).ge.2))     go to 2560
      if((ibz(i-1,j-1).lt.  0.or.ikabe(i-1,j-1).ge.2).and.
     @   (ibz(i  ,j-1).lt.  0.or.ikabe(i  ,j-1).ge.2))     go to 2570
      if((ibz(i-1,j+1).lt.  0.or.ikabe(i-1,j  ).ge.2).and.
     @   (ibz(i  ,j+1).lt.  0.or.ikabe(i  ,j  ).ge.2))     go to 2580
      if((ibz(i  ,j-1).lt.  0.or.ikabe(i  ,j-1).ge.2).and.
     @   (ibz(i  ,j+1).lt.  0.or.ikabe(i  ,j  ).ge.2))     go to 2590

      if(ibz(i-1,j-1).lt.  0.or.ikabe(i-1,j-1).ge.2)
     @           v0 = ( v2 + v3 + v4 ) / 3.0
      if(ibz(i-1,j+1).lt.  0.or.ikabe(i-1,j  ).ge.2)
     @           v0 = ( v1 + v3 + v4 ) / 3.0
      if(ibz(i  ,j-1).lt.  0.or.ikabe(i  ,j-1).ge.2)
     @           v0 = ( v1 + v2 + v4 ) / 3.0
      if(ibz(i  ,j+1).lt.  0.or.ikabe(i  ,j  ).ge.2)
     @           v0 = ( v1 + v2 + v3 ) / 3.0
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
!**********************************************
      subroutine  u0cal(i,j,u1,u2,u3,u4,u0)
!**********************************************

!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------

      u0 = ( u1 + u2 + u3 + u4 ) / 4.0

      if((ibz(i+1,j-1).lt.  0.or.ikabe(i  ,j-1).eq.1).and.
     @   (ibz(i-1,j  ).lt.  0.or.ikabe(i-1,j  ).eq.1
     @                       .or.ikabe(i-1,j  ).eq.3).and.
     @   (ibz(i+1,j  ).lt.  0.or.ikabe(i  ,j  ).eq.1
     @                       .or.ikabe(i  ,j  ).eq.3))     go to 3500
      if((ibz(i-1,j-1).lt.  0.or.ikabe(i-1,j-1).eq.1
     @                       .or.ikabe(i-1,j-1).eq.3).and.
     @   (ibz(i-1,j  ).lt.  0.or.ikabe(i-1,j  ).eq.1
     @                       .or.ikabe(i-1,j  ).eq.3).and.
     @   (ibz(i+1,j  ).lt.  0.or.ikabe(i  ,j  ).eq.1
     @                       .or.ikabe(i  ,j  ).eq.3))     go to 3510
      if((ibz(i-1,j-1).lt.  0.or.ikabe(i-1,j-1).eq.1
     @                       .or.ikabe(i-1,j-1).eq.3).and.
     @   (ibz(i+1,j-1).lt.  0.or.ikabe(i  ,j-1).eq.1).and.
     @   (ibz(i+1,j  ).lt.  0.or.ikabe(i  ,j  ).eq.1
     @                       .or.ikabe(i  ,j  ).eq.3))     go to 3520
      if((ibz(i-1,j-1).lt.  0.or.ikabe(i-1,j-1).eq.1
     @                       .or.ikabe(i-1,j-1).eq.3).and.
     @   (ibz(i+1,j-1).lt.  0.or.ikabe(i  ,j-1).eq.1).and.
     @   (ibz(i-1,j  ).lt.  0.or.ikabe(i-1,j  ).eq.1
     @                       .or.ikabe(i-1,j  ).eq.3))     go to 3530
 
      if((ibz(i-1,j  ).lt.  0.or.ikabe(i-1,j  ).eq.1
     @                       .or.ikabe(i-1,j  ).eq.3).and.
     @   (ibz(i+1,j  ).lt.  0.or.ikabe(i  ,j  ).eq.1
     @                       .or.ikabe(i  ,j  ).eq.3))     go to 3540
      if((ibz(i-1,j-1).lt.  0.or.ikabe(i-1,j-1).eq.1
     @                       .or.ikabe(i-1,j-1).eq.3).and.
     @   (ibz(i+1,j-1).lt.  0.or.ikabe(i  ,j-1).eq.1))     go to 3550
      if((ibz(i-1,j-1).lt.  0.or.ikabe(i-1,j-1).eq.1
     @                       .or.ikabe(i-1,j-1).eq.3).and.
     @   (ibz(i+1,j  ).lt.  0.or.ikabe(i  ,j  ).eq.1
     @                       .or.ikabe(i  ,j  ).eq.3))     go to 3560
      if((ibz(i+1,j-1).lt.  0.or.ikabe(i  ,j-1).eq.1).and.
     @   (ibz(i-1,j  ).lt.  0.or.ikabe(i-1,j  ).eq.1
     @                       .or.ikabe(i-1,j  ).eq.3))     go to 3570
      if((ibz(i-1,j-1).lt.  0.or.ikabe(i-1,j-1).eq.1
     @                       .or.ikabe(i-1,j-1).eq.3).and.
     @   (ibz(i-1,j  ).lt.  0.or.ikabe(i-1,j  ).eq.1
     @                       .or.ikabe(i-1,j  ).eq.3))     go to 3580
      if((ibz(i+1,j-1).lt.  0.or.ikabe(i  ,j-1).eq.1).and.
     @   (ibz(i+1,j  ).lt.  0.or.ikabe(i  ,j  ).eq.1
     @                       .or.ikabe(i  ,j  ).eq.3))     go to 3590

      if(ibz(i-1,j-1).lt.  0.or.ikabe(i-1,j-1).eq.1
     @                      .or.ikabe(i-1,j-1).eq.3)
     @           u0 = ( u2 + u3 + u4 ) / 3.0
      if(ibz(i-1,j  ).lt.  0.or.ikabe(i-1,j  ).eq.1
     @                      .or.ikabe(i-1,j  ).eq.3)
     @           u0 = ( u1 + u2 + u4 ) / 3.0
      if(ibz(i+1,j-1).lt.  0.or.ikabe(i  ,j-1).eq.1)
     @           u0 = ( u1 + u3 + u4 ) / 3.0
      if(ibz(i+1,j  ).lt.  0.or.ikabe(i  ,j  ).eq.1
     @                      .or.ikabe(i  ,j  ).eq.3)
     @           u0 = ( u1 + u2 + u3 ) / 3.0
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
!**********************************************
      subroutine  cmncal()
!**********************************************

!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------

      do 1000 j=2,jm0
      do 2000 i=ibc(1,j),ibc(2,j)

       if(ibz(i,j).le.0)  go to 2000

        cd3(i,j) = 0.0
        hl = hh1(i,j)
        if(hl.lt.hcr)  go to 2000

        ifx1 = 1
        ifx2 = 1
        ify1 = 1
        ify2 = 1


        slx1 = ( zl1(i,j) - zl1(i-1,j) ) / dlx
        if(ibz(i-1,j).lt.0.or.ikabe(i-1,j).eq.1
     @                    .or.ikabe(i-1,j).eq.3)  then
          slx1 = 0.0
          ifx1 = 0
        end if

        sly1 = ( zl1(i,j) - zl1(i,j-1) ) / dly
        if(ibz(i,j-1).lt.0.or.ikabe(i,j-1).ge.2)  then
          sly1 = 0.0
          ify1 = 0
        end if


        sly2 =  ( zl1(i,j+1) - zl1(i,j) ) / dly
        if(ibz(i,j+1).lt.0.or.ikabe(i,j).ge.2)  then
          sly2 = 0.0
          ify2 = 0
        end if


        slx2 = ( zl1(i+1,j) -  zl1(i,j) ) / dlx
        if(ibz(i+1,j).lt.0.or.ikabe(i,j).eq.1
     @                    .or.ikabe(i,j).eq.3)  then
          slx2 = 0.0
          ifx2 = 0
        end if

        sl1 = sqrt( slx1*slx1 + sly1*sly1 )
        sl2 = sqrt( slx1*slx1 + sly2*sly2 )
        sl3 = sqrt( slx2*slx2 + sly2*sly2 )
        sl4 = sqrt( slx2*slx2 + sly1*sly1 )

        sl = ( sl1 + sl2 + sl3 + sl4 ) / 4.0
        if(ifx1.eq.0.and.ify1.eq.1.and.ifx2.eq.1.and.ify2.eq.1)
     @   sl = ( sl3 + sl4 ) / 2.0
        if(ifx1.eq.1.and.ify1.eq.0.and.ifx2.eq.1.and.ify2.eq.1)
     @   sl = ( sl2 + sl3 ) / 2.0
        if(ifx1.eq.1.and.ify1.eq.1.and.ifx2.eq.0.and.ify2.eq.1)
     @   sl = ( sl1 + sl2 ) / 2.0
        if(ifx1.eq.1.and.ify1.eq.1.and.ifx2.eq.1.and.ify2.eq.0)
     @   sl = ( sl1 + sl4 ) / 2.0
        if(ifx1.eq.1.and.ify1.eq.1.and.ifx2.eq.0.and.ify2.eq.0)
     @   sl = sl3
        if(ifx1.eq.0.and.ify1.eq.1.and.ifx2.eq.1.and.ify2.eq.0)
     @   sl = sl2
        if(ifx1.eq.0.and.ify1.eq.0.and.ifx2.eq.1.and.ify2.eq.1)
     @   sl = sl1
        if(ifx1.eq.1.and.ify1.eq.1.and.ifx2.eq.0.and.ify2.eq.1)
     @   sl = sl4
        if(ifx1.eq.1.and.ify1.eq.0.and.ifx2.eq.1.and.ify2.eq.0)
     @   sl = ( abs(sly1) + abs(sly2) ) / 2.0
        if(ifx1.eq.0.and.ify1.eq.1.and.ifx2.eq.0.and.ify2.eq.1)
     @   sl = ( abs(slx1) + abs(slx2) ) / 2.0
        if(ifx1.eq.1.and.ify1.eq.0.and.ifx2.eq.0.and.ify2.eq.0)
     @   sl = slx1
        if(ifx1.eq.0.and.ify1.eq.1.and.ifx2.eq.0.and.ify2.eq.0)
     @   sl = sly1
        if(ifx1.eq.0.and.ify1.eq.0.and.ifx2.eq.1.and.ify2.eq.0)
     @   sl = slx2
        if(ifx1.eq.0.and.ify1.eq.0.and.ifx2.eq.0.and.ify2.eq.1)
     @   sl = sly2


       cc = (1.05409255 * sl / fai)**3
       if(cc.gt.0.9*cst)  cc = 0.9 * cst
       cd3(i,j) = ( cc + cd1(i,j) ) / 2.0
       if(cd3(i,j).lt.exm)  cd3(i,j) = 0.0

 2000 continue
 1000 continue



      return
      end
!**********************************************
      subroutine  corct1(dt)
!**********************************************

!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------

      dt2 = dt * 2.0

      do 1000 j = 2 , jm0
      do 2000 i=ibc(1,j),ibc(2,j)

      if(ibz(i,j).le.0)  go to 2000

       if(cd1(i,j).lt.ccr)  then
         if(qm2(i  ,j  ).lt.0.0)  qm2(i  ,j  ) = 0.0
         if(qm2(i+1,j  ).gt.0.0)  qm2(i+1,j  ) = 0.0
         if(qn2(i  ,j  ).lt.0.0)  qn2(i  ,j  ) = 0.0
         if(qn2(i  ,j+1).gt.0.0)  qn2(i  ,j+1) = 0.0

         if(hh1(i,j).lt.hcr)  go to 2100
         qx = ( qm2(i,j) + qm2(i+1,j) ) / 2.0
         qy = ( qn2(i,j) + qn2(i,j+1) ) / 2.0
         vx = qx / hh1(i,j)
         vy = qy / hh1(i,j)
         vv = sqrt( vx*vx + vy*vy )

             if(vv.lt.0.01)  then
               hh3(i,j) = 0.0
               cd3(i,j) = 0.0
               go to 2000
             end if
 2100 continue
         go to 2000
       end if


      wx1 = 0.0
      wx2 = 0.0
      wy1 = 0.0
      wy2 = 0.0

      if(qm2(i  ,j  ).lt.0.0) wx1 = qm2(i  ,j  )
      if(qm2(i+1,j  ).gt.0.0) wx2 = qm2(i+1,j  )
      if(qn2(i  ,j  ).lt.0.0) wy1 = qn2(i  ,j  )
      if(qn2(i  ,j+1).gt.0.0) wy2 = qn2(i  ,j+1)


      a1 =  hh1(i,j) * dlx * dly
      a2 = ( wx2 - wx1 ) * dlx + ( wy2 - wy1 ) * dly
      a2 = a2 * dt2
      if(a2.lt.exm)  go to 2000

      if(a2.gt.a1)  then
        aa =  a1 / a2
        if(qm2(i  ,j  ).lt.0.0) qm2(i  ,j  ) = qm2(i  ,j  ) * aa
        if(qm2(i+1,j  ).gt.0.0) qm2(i+1,j  ) = qm2(i+1,j  ) * aa
        if(qn2(i  ,j  ).lt.0.0) qn2(i  ,j  ) = qn2(i  ,j  ) * aa
        if(qn2(i  ,j+1).gt.0.0) qn2(i  ,j+1) = qn2(i  ,j+1) * aa
      end if

 2000 continue
 1000 continue

      do 3000 j = 2 , jm0
      do 4000 i=ibc(1,j),ibc(2,j)

      if(ibz(i,j).le.0)  go to 4000

      sx1 = 0.0
      sx2 = 0.0
      sy1 = 0.0
      sy2 = 0.0

      if(qm2(i  ,j  ).lt.0.0) sx1 = qm2(i  ,j  ) * cd3(i  ,j  )
      if(qm2(i+1,j  ).gt.0.0) sx2 = qm2(i+1,j  ) * cd3(i  ,j  )
      if(qn2(i  ,j  ).lt.0.0) sy1 = qn2(i  ,j  ) * cd3(i  ,j  )
      if(qn2(i  ,j+1).gt.0.0) sy2 = qn2(i  ,j+1) * cd3(i  ,j  )

      a1 = cd1(i,j)  * hh1(i,j) - ( zdl(i,j) - zl1(i,j) ) * cst
      a2 = ( sx2 - sx1 ) / dlx + ( sy2 - sy1 ) / dly
      a2 = a2 * dt2

      if(a2.lt.exm)  go to 4000
      if(a2.gt.a1)  then
        aa =  a1 / a2
        if(qm2(i  ,j  ).lt.0.0) qm2(i  ,j  ) = qm2(i  ,j  ) * aa
        if(qm2(i+1,j  ).gt.0.0) qm2(i+1,j  ) = qm2(i+1,j  ) * aa
        if(qn2(i  ,j  ).lt.0.0) qn2(i  ,j  ) = qn2(i  ,j  ) * aa
        if(qn2(i  ,j+1).gt.0.0) qn2(i  ,j+1) = qn2(i  ,j+1) * aa
      end if

 4000 continue
 3000 continue

      return
      end
!**********************************************
      subroutine  hzcal(dt1,dt)
!**********************************************

!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------

      
      ! calc Eq. of fluid volume conservation (equation of continuity)
      
      dt2 = 2.0 * dt

      do 3000 j = 2 , jm0
      do 4000 i=ibc(1,j),ibc(2,j)

      if(ibz(i,j).le.0)  go to 4000

      ! 1st order Euler forward difference
      wx1 = qm2(i  ,j  )
      wx2 = qm2(i+1,j  )
      wy1 = qn2(i  ,j  )
      wy2 = qn2(i  ,j+1)

      a2 = ( wx2 - wx1 ) / dlx + ( wy2 - wy1 ) / dly
      a2 = a2 * dt2
      hh3(i,j) = hh1(i,j) - a2
      if(hh3(i,j).lt.exm)  hh3(i,j) = 0.0

 4000 continue
 3000 continue


      
      ! calc Eq. of solid volume conservation (equation of continuity)
      
      do 1000 j = 2 , jm0
      do 2000 i=ibc(1,j),ibc(2,j)

      if(ibz(i,j).le.0)  go to 2000

      sx1 = 0.0
      sx2 = 0.0
      sy1 = 0.0
      sy2 = 0.0

      if(qm2(i  ,j  ).lt.0.0) sx1 = qm2(i  ,j  ) * cd3(i  ,j  )
      if(qm2(i  ,j  ).gt.0.0) sx1 = qm2(i  ,j  ) * cd3(i-1,j  )
      if(qm2(i+1,j  ).lt.0.0) sx2 = qm2(i+1,j  ) * cd3(i+1,j  )
      if(qm2(i+1,j  ).gt.0.0) sx2 = qm2(i+1,j  ) * cd3(i  ,j  )
      if(qn2(i  ,j  ).lt.0.0) sy1 = qn2(i  ,j  ) * cd3(i  ,j  )
      if(qn2(i  ,j  ).gt.0.0) sy1 = qn2(i  ,j  ) * cd3(i  ,j-1)
      if(qn2(i  ,j+1).lt.0.0) sy2 = qn2(i  ,j+1) * cd3(i  ,j+1)
      if(qn2(i  ,j+1).gt.0.0) sy2 = qn2(i  ,j+1) * cd3(i  ,j  )


      a1 =  cd3(i,j) * hh3(i,j) - cd1(i,j) * hh1(i,j)
      a2 = ( sx2 - sx1 ) / dlx + ( sy2 - sy1 ) / dly

      dz = - ( a1 + a2 * dt2 ) / cst
      if(dz.lt.0.0.and.dz.ge.-exm)  dz = 0.0
      zl3(i,j) = zl1(i,j) + dz

      znl = zdl(i,j) - zl1(i,j)
      if(dz.ge.znl)  go to 5000

      c1 = hh1(i,j) * cd1(i,j) - znl * cst - dt2 * a2
      if(cd3(i,j).lt.exm)  call calerr(dt1,dt,'hzc2')
      hh3(i,j) = c1 / cd3(i,j)
      if(hh3(i,j).lt.-exm)  call calerr(dt1,dt,'hzc3')
      if(hh3(i,j).lt. exm)  hh3(i,j) = 0.0

      zl3(i,j) = zdl(i,j)

 5000 continue

      qmt(i,j) = qmt(i,j) + wx1 * dly * dt2
      qnt(i,j) = qnt(i,j) + wy1 * dlx * dt2
      qmbt(i,j) = qmbt(i,j) + sx1 * dly * dt2
      qnbt(i,j) = qnbt(i,j) + sy1 * dlx * dt2

 2000 continue
 1000 continue

      return
      end
!**********************************************
      subroutine  maxcal(dt1)
!**********************************************

!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------

      do 1000 j = 2 ,jm0
      do 2000 i=ibc(1,j),ibc(2,j)

      if(zi(i,j).lt.0.0)  go to 2000

      hel = hh3(i,j) + zl3(i,j)  - zi(i,j)
      if(hel.gt.hmax(i,j))  hmax(i,j) = hel
      dzz = zl3(i,j) - zi(i,j)
      dzznow = dzz + hh3(i,j) * cd3(i,j) / cst

      if(hh3(i,j).lt.exm)  go to 2000

      qx = ( qm2(i,j) + qm2(i+1,j) ) / 2.0
      qy = ( qn2(i,j) + qn2(i,j+1) ) / 2.0

      vx = qx / hh3(i,j)
      vy = qy / hh3(i,j)

      qv = sqrt( qx*qx + qy*qy )    
      vv = sqrt( vx*vx + vy*vy )

      ff = hh3(i,j) * cd3(i,j) * sig * vv * vv / grav
      if(ff.gt.fmax(i,j))   fmax(i,j) = ff

      if(qv.gt.qmax(i,j))   then
         qmax(i,j) = qv
         qxm(i,j) = qx
         qym(i,j) = qy
         qmaxtime(i, j) = dt1
      end if

      if(vv.gt.vmax(i,j))   then
         vmax(i,j) = vv
         vxm(i,j) = vx
         vym(i,j) = vy
      end if

      hh = hh3(i,j)
      hhm = ( hh3(i-1,j) + hh3(i,j) ) / 2.0
      hhn = ( hh3(i,j-1) + hh3(i,j) ) / 2.0
      vvx = qm2(i,j) / hhm
      vvy = qn2(i,j) / hhn
      vvxy = sqrt( vvx*vvx + vvy*vvy )
      if(artime(i,j).eq.0.and.hh.gt.0.0) then
        artime(i,j) = dt1
      endif

      call maxset(vvxy, uvmax(i, j), dt1, uvmaxtime(i, j))
      call maxset(hh, hh3max(i, j), dt1, hh3maxtime(i, j))
      call maxset(dzznow, zmax(i, j), dt1, zmaxtime(i, j))
      call maxset(cd3(i, j), cd3max(i, j), dt1, cd3maxtime(i, j))
      
      
      pdyn(i,j) = 0.5d0 * cd3(i,j) * sig * (vvx*vvx + vvy*vvy)
      
      if(pdyn(i,j) > pdynmax(i,j)) then
            pdynmax(i, j) = pdyn(i,j) 
            pdynmaxtime(i,j) = dt1
            
            if(xpdyn >= 1.0E+06) then
                  write(*,'("xpdyn=",1pe10.3," vvx=",
     *             1pe10.3," vvy=",1pe10.3," qm2=",1pe10.3,
     *            " qn2=",1pe10.3," hhm=",1pe10.3," hhn=",1pe10.3)')
     *             xpdyn,vvx,vvy,qm2(i,j),qn2(i,j),hhm,hhn
            end if
      end if
      
      !--- maximum Static Flow Pressure [kPa] 
      psta(i,j) = cd3(i,j) * sig * grav * sqrt(hhm*hhm + hhn*hhn)
      if(psta(i,j) > pstamax(i,j)) then
            pstamax(i, j) = psta(i,j) 
            pstamaxtime(i,j) = dt1
      end if
      
      !--- maximum bottom share stress [kPa]
      ! weisbach firiction coefficient
      xx= 3.0d0 / 32.0d0 / sqrt(10.0d0) * cd3(i,j)**(1.0/3.0) /
     *                    ( 1.0 - ( cd3(i,j) / cst )**(1.0/3.0) )
      wfc = xx * fai * te * dm * dm / (hh3(i,j)*hh3(i,j))
      tau0(i,j) = cd3(i,j) * sig * wfc * (vvx*vvx + vvy*vvy)
      if(tau0(i,j) > tau0max(i,j)) then
            tau0(i,j) = xtau0
            tau0maxtime(i,j) = dt1
            
            if(xtau0 >= 1.0E+09) then
                  write(*,'("xtau0=",1pe10.3," vvx=",
     *             1pe10.3," vvy=",1pe10.3," wfc=",1pe10.3,
     *            " xx=",1pe10.3," h=",1pe10.3)')
     *             xtau0,vvx,vvy,wfc,xx,(hh1(i,j)*hh1(i,j))
                   
            end if
      end if
      
      !--- maximum flow pressure (dynamic + static) [kPa]
      pp(i,j) = psta(i,j) + pdyn(i,j)
      if(pp(i,j) > pmax2(i,j)) then
            pmax2(i,j) = xx
            pmax2time(i,j) = dt1
      endif

      !--- flow power
      fm_pst(i,j) = cd3(i,j)*sig*qv*qv/hh3(i,j)/grav
      if(fm_pst(i,j) > fmax(i,j)) then
            fmax(i,j) = fm_pst(i,j)
            fmaxtime(i,j) = dt1
            if(vv > exm) then
              fmaxx(i,j) = fm_pst(i,j) * vx / vv
              fmaxy(i,j) = fm_pst(i,j) * vy / vv
            else
              fmaxx(i,j) = 0.0
              fmaxy(i,j) = 0.0
            end if
      endif
            
    !---------------------------
 2000 continue
 1000 continue

      return
      end
      subroutine maxset(val, valmax, tnow, valmaxtime)
      include 'pcf2b-sp.inc'

        if(val > valmax) then
                valmax = val
                valmaxtime = tnow
        end if

        return

      end subroutine maxset

!**********************************************
      subroutine  delete
!**********************************************

!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------

      do 9990 j=2,jm0
      do 9980 i=ibc(1,j),ibc(2,j)

      if(ibz(i,j).le.0)  go to 9980

      if(zi(i-1,j).lt.0.0.or.zi(i,j-1).lt.0.0.or.zi(i+1,j).lt.0.0.or.
     *   zi(i,j+1).lt.0.0)  then
      hh3(i,j)=0.
      zl3(i,j)=zi(i,j)
      end if

 9980 continue
 9990 continue

      return
      end


!**********************************************
      subroutine  errnum(i)
!**********************************************

      implicit real*8 (a-h,o-z)
      character i*4

      call calerrout
      
      write(6,100) i
  100 format(10x,' ***  error  no. ',a4,' ***')
      stop

      end
!**********************************************
      subroutine  calerr(dt1,dt2,i)
!**********************************************

!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------

      character i*4

      call calerrout
      
      icheck = 1
      call  print1(dt1,dt2)
      call  print2(dt1,dt2)
      write(6,100)  i
  100 format(10x,' ***  error  no. ',a4,' ***')

      stop
      end

!**********************************************
      subroutine  calerrout
!**********************************************

      open(99999,file='../.calc.err', action='write')
      write(99999,'("err")')
      close(99999)
      
      end

!**********************************************
      subroutine  print1(dt1,dt2)
!**********************************************

!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------

      integer*4  itimex
      dimension  nob(12),dz(12)

      dt = dt2 * 2.0

      i0 = imx
      k1 = (i0 - 1) / 12 + 1
      k2 = mod(i0,12)

      do 1000 k=1,k1
      k3 = 12
      if(k.eq.k1.and.k2.ne.0)  k3 = k2

      i1 = (k-1)*12 + 1
      i2 = k*12
      if(k.eq.k1.and.k2.ne.0)  i2 = i1 - 1 + k2

      j = jmy + 1
 9000 continue
      j = j - 1
      m1 = j
      m2 = j - 4
      if(m2.lt.1)  m2 = 1
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
      write(6,100)
      itimex = int(dt1 + dt1/86400.0)
      itime1 = itimex / 3600
      itimey = itimex - itime1 * 3600
      itime2 = itimey / 60
      itime3 = itimey - itime2 * 60
      write(6,200) itime1,itime2,itime3
      write(6,210) dt1,dt
  200 format(5x,' jikan : ',i3,'h ',i2,'m ',i2,'s ')
  210 format(    85x,'  time : ',f10.3,'(s)  dt: ',f7.4,' (s)')

      do 2300 l=1,k3
      nob(l) = l-2+i1
 2300 continue

      write(6,300)  (nob(l),l=1,k3)
      m = m1 + 1
      do 2100 n=m2,m1
      m = m -1
      mj = m - 1
      write(6,400)  mj
      write(6,500)  (hh1(i,m),i=i1,i2)
      write(6,510)  (qm0(i,m),i=i1,i2)
      write(6,520)  (qn0(i,m),i=i1,i2)
      write(6,530)  (zl1(i,m),i=i1,i2)
      write(6,540)  (hh3(i,m),i=i1,i2)
      write(6,550)  (qm2(i,m),i=i1,i2)
      write(6,560)  (qn2(i,m),i=i1,i2)
      write(6,570)  (zl3(i,m),i=i1,i2)

      k9 = 0
      do 2400 l=i1,i2
      k9 = k9 + 1
      dz(k9) = 0.0
      if(zi(l,m).lt.0.0)  go to 2400
      dz(k9) = zl3(l,m) - zi(l,m)
 2400 continue

      write(6,580)  (dz(i),i=1,k9)
 2100 continue

 2000 continue
       j = m2
       if(j.gt.1)  go to 9000
 1000 continue
       if(icheck.eq.1)  return
      write(6,110)  vbl
      write(6,120)  wbl

      return

  100 format(1h1)
  110 format('   sediment volume =   ',e18.9,'   (m3)')
  120 format('   water    volume =   ',e18.9,'   (m3)')
  300 format(10x,12(1x,' x =',i4,1x))
  400 format(2x,' y =',i4)
  500 format(' depth-1  ',12f10.5)
  510 format(' x-flux-0 ',12f10.5)
  520 format(' y-flux-0 ',12f10.5)
  530 format(' bed-e.l-1',12f10.3)
  540 format(' depth-3  ',12f10.5)
  550 format(' x-flux-2 ',12f10.5)
  560 format(' y-flux-2 ',12f10.5)
  570 format(' bed-e.l-3',12f10.3)
  580 format(' bed-var  ',12f10.5)

      end


!**********************************************
      subroutine  print2(dt1,dt2)
!**********************************************

!----------------------------------------------
      include'pcf2b-sp.inc' 
!----------------------------------------------

      integer*4  itimex
      dimension  nob(12),dz(12),hel(12)

      dt = dt2 * 2.0

      i0 = imx
      k1 = (i0 - 1) / 12 + 1
      k2 = mod(i0,12)

      do 1000 k=1,k1
      k3 = 12
      if(k.eq.k1.and.k2.ne.0)  k3 = k2

      i1 = (k-1)*12 + 1
      i2 = k*12
      if(k.eq.k1.and.k2.ne.0)  i2 = i1 - 1 + k2

      j = jmy + 1
 9000 continue
      j = j - 1
      m1 = j
      m2 = j - 4
      if(m2.lt.1)  m2 = 1
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
      write(6,100)
      itimex = int(dt1 + dt1/86400.0)
      itime1 = itimex / 3600
      itimey = itimex - itime1 * 3600
      itime2 = itimey / 60
      itime3 = itimey - itime2 * 60
      write(6,200) itime1,itime2,itime3
      write(6,210) dt1,dt
  200 format(5x,' jikan : ',i3,'h ',i2,'m ',i2,'s ')
  210 format(    85x,'  time : ',f10.3,'(s)  dt: ',f7.4,' (s)')

      do 2300 l=1,k3
      nob(l) = l-2+i1
 2300 continue

      write(6,300)  (nob(l),l=1,k3)
      m = m1 + 1
      do 2100 n=m2,m1
      m = m -1
      mj = m - 1
      write(6,400)  mj
      write(6,500)  (cd1(i,m),i=i1,i2)
      write(6,510)  (cd3(i,m),i=i1,i2)
      write(6,540)  (zdl(i,m),i=i1,i2)
      write(6,560)  (hh01(i,m),i=i1,i2)
      write(6,570)  (zl3(i,m),i=i1,i2)

      k9 = 0
      do 2400 l=i1,i2
      k9 = k9 + 1
      dz(k9) = 0.0
      hel(k9) = 0.0
      if(zi(l,m).lt.0.0)  go to 2400
      dz(k9) = zl3(l,m) - zi(l,m)
      hel(k9) = zl3(l,m)+hh3(l,m)
 2400 continue

      write(6,550)  (hel(i),i=1,k9)
      write(6,580)  (dz(i),i=1,k9)
 2100 continue

 2000 continue
       j = m2
       if(j.gt.1)  go to 9000
 1000 continue
      if(icheck.eq.1)  return
      write(6,110)  vbl
      write(6,120)  wbl

      return

  100 format(1h1)
  110 format('   sediment volume =   ',e18.9,'   (m3)')
  120 format('   water    volume =   ',e18.9,'   (m3)')
  300 format(10x,12(1x,' x =',i4,1x))
  400 format(2x,' y =',i4)
  500 format(' cd1      ',12f10.5)
  510 format(' cd3      ',12f10.5)
  540 format(' zdl      ',12f10.5)
  550 format(' h-el.-3  ',12f10.3)
  560 format(' hh01     ',12f10.5)
  570 format(' bed-el.-3',12f10.3)
  580 format(' bed-var  ',12f10.5)

      end

