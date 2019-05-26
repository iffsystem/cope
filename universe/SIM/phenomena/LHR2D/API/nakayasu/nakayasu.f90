module mod_nakayasu
    implicit none
    
    integer,parameter :: ON=1
    integer,parameter :: OFF=0
	
	
    
    
    ! definition of variables
    real*8,allocatable :: uflux(:)     ! 
    real*8,allocatable :: responce(:,:)     ! 
    real*8,allocatable :: hyeto(:)     ! 
    real*8,allocatable :: hydro(:)     !
    
    
    
    !--- parameter for draw figure
    real*8,parameter :: dt  = 60.0d0         ! time step to draw position in figure [sec]
    
    
contains

subroutine open_resultfiles(iflen_out,outpath,outfname)
    integer,intent(in) :: iflen_out(1)
    character(len=300),intent(in) :: outpath(1),outfname(1)
    
    integer err
    
    character(len=iflen_out(1)):: fname1
    
    
    !------- output unit graph
    fname1=trim(adjustl(outpath(1)))//trim(adjustl(outfname(1)))
    open(10,file=fname1,action='write',iostat=err)
    
    if(err/=0) then
		write(*,*) 'cannot open file ',fname1
		stop
	end if
    
    
end subroutine

subroutine open_inputfiles(iflen_in,inpath,infname)
    integer,intent(in) :: iflen_in(1)
    character(len=300),intent(in) :: inpath(1),infname(1)
    
    integer err
    
    character(len=iflen_in(1)):: fname1
    
    
    !------- input hyetograph
    fname1=trim(adjustl(inpath(1)))//trim(adjustl(infname(1)))
    open(100,file=fname1,action='read',iostat=err)
    
    if(err/=0) then
		write(*,*) 'cannot open file ',fname1
		stop
	end if
    
end subroutine

subroutine set_unitgraph(time,itmax,it,ap,uflux,utime1,utime03)
    integer,intent(in) :: it,itmax
    real*8,intent(in) :: time,ap,utime1,utime03
    real*8,intent(out) :: uflux(itmax)
    
    integer i
    real*8 xx
    
    if ( time <= utime1 ) then
        
        xx = ap * (time/utime1)**2.4
    
    else if ( time <= utime1 + utime03 ) then
        
        xx = (time - utime1)/utime03
        xx = 0.3d0**xx
        xx = ap * xx
        
    else if ( time <= utime1 + 2.5d0*utime03 ) then
        
        xx = (time - utime1 + 0.5d0*utime03)/1.5d0/utime03
        xx = 0.3d0**xx
        xx = ap * xx
        
    else
        
        xx = (time - utime1 + 1.5d0*utime03)/2.0d0/utime03
        xx = 0.3d0**xx
        xx = ap * xx
        
    end if
    
    uflux(it) = xx
    
    
end subroutine

end module mod_nakayasu




!-- main body of program
program main
    
    use mod_nakayasu
    
    real*8 time,ap,xx,maxtime,peakrate,x1,x2
    real*8 duration,area,runoffrate,utime1,utime03
    integer i,j,it,chk,lnum,itmax
    integer iflen_in(1),iflen_out(1)
    character(len=100) :: dummy
    character(len=300) :: inpath(1)
    character(len=300) :: infname(1)
    character(len=300) :: outpath(1)
    character(len=300) :: outfname(1)
    
    inpath(1) = "./"
    infname(1) = "hyeto.d"
    outpath(1) = "./"
    outfname(1) = "hydro.out"
    
    iflen_in(1) = len_trim(trim(adjustl(inpath(1)))//trim(adjustl(infname(1))))
    iflen_out(1) = len_trim(trim(adjustl(outpath(1)))//trim(adjustl(outfname(1))))
    
    
    
       
    !--- check number of lines of hyeto file
    call open_inputfiles(iflen_in,inpath,infname)
    
    read(100,*) duration,area,runoffrate ! duration of hyetograph [min], Area of drainage [km2]
    read(100,*) utime1      ! time at peak of unit graph [hour]
    read(100,*) utime03     ! time at utime1 + 0.3 of unit graph [hour]
    read(100,*) dummy
    
    maxtime = duration * 20.0d0 
    
    !- time interval of hyetograph (mm/h) must be set as 60 sec
    lnum = 0
    do
        read(100,*,iostat=chk) dummy
        if(chk/=0) exit
        lnum = lnum + 1
    end do
    close(100)
    
    itmax  = int(maxtime * 60.0 / dt )     ! iterration number [-] 
    
    write(*,*) lnum,itmax
    
    !--- set arrays according to number of rain data
    allocate (hyeto(itmax),hydro(itmax),responce(itmax,itmax))
    allocate (uflux(itmax))
    
    hyeto = 0.0d0
    
    !--- read hyeto
    call open_inputfiles(iflen_in,inpath,infname)
    do i = 1,4
        read(100,*) dummy
    end do
    
    x1=0.0d0
    do i = 1,lnum
        read(100,*) hyeto(i)
        x1=x1+hyeto(i)*dt/3600.0d0
    
    end do
    
    ! check volume
    x1=x1*0.001d0*area*1000.0*1000.0 ! m3
    
    
    write(*,*)duration, area
    write(*,*)x1
    close(100)
    
    
    
    !--- setting initial condition
    time = 0.0d0
    
    ap = 1.0d0 / (0.3d0*utime1 + utime03)
    
    write(*,'(" ap =",1pe12.3)') ap
    write(*,'(" T1 =",1pe12.3)') utime1
    write(*,'(" T0.3 =",1pe12.3)') utime03
    write(*,'(" itmax =",i7)') itmax
    write(*,*)
    
    
            
    !--- set unit graph
    do it=1,itmax
        
        call set_unitgraph(time,itmax,it,ap,uflux,utime1,utime03)
        
        !--- update time
        time = time + dt/3600.0d0
        
    end do
    
    
    !--- get specific discharge
    responce = 0.0d0
    do j = 1,lnum
        do i = 1,itmax
            if (i+j-1 > itmax) exit
            responce(i+j-1,j) = uflux(i) * hyeto(j)
        end do
    end do
    
    !--- get hydrograph
    x2=0.0d0
    time = 0.0d0
    do i = 1,itmax
        xx = 0.0d0
        do j = 1,lnum
            xx = xx + responce(i,j) * dt/3600.0d0
        end do
        
        hydro(i) = runoffrate * xx * area / 3.6d0
        
        if (i==2) then
            write(*,'(" [",i6,"]  time =",1pe12.3," [hr],  Hydro(t) =",1pe12.3," [m3/sec]", &
            &" Hyeto(t) =",1pe12.3," [mm/hr]",1pe12.3)')&
                & i,time,hydro(i),hyeto(i),xx
        else if ( i > 1 .and. mod(i-1,5)==0 ) then
            write(*,'(" [",i6,"]  time =",1pe12.3," [hr],  Hydro(t) =",1pe12.3," [m3/sec]", &
            &" Hyeto(t) =",1pe12.3," [mm/hr]",1pe12.3)')&
                & i,time,hydro(i),hyeto(i),xx
        end if
        
        x2=x2+hydro(i)*dt
        !--- update time
        time = time + dt/3600.0d0
    end do
    
    write(*,*)x1
    write(*,*)x2
    
    !--- check peak flow rate
    peakrate = 0.0d0
    do i = 1,itmax
        if (hydro(i) > peakrate) peakrate = hydro(i)
    end do
    
    write(*,'(" Drainage area =",1pe12.3," [km2]")') area
    write(*,'(" Peak rate =",1pe12.3," [m3/sec]")') peakrate
    
    !--- output hydrograph (if flow rate below peakrate/200 = 0.5%, it would suppose end)
    call open_resultfiles(iflen_out,outpath,outfname)
    
    write(10,*) peakrate
    time = 0.0d0
    do i = 1,itmax
        
        write(10,'(3(1pe15.6))')time/60.0d0,hydro(i),hyeto(i)
        
        time = time + dt
        
        if (i > lnum .and. hydro(i) < peakrate/200.0d0) exit
    end do
    
    close(10)
    
    
    write(*,'(" [done]")')
    
    deallocate(hyeto,hydro,responce,uflux)
    
end program main

