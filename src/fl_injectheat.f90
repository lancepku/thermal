!==============================================================================
!  Adding magma and latent heat in injection zone
!  G. Ito 8/11/06 
!==============================================================================
subroutine fl_injectheat    
use arrays                       
include 'precision.inc' ! vs BI(Behn and Ito 2008): the same
include 'params.inc'   ! vs BI: not the same
include 'arrays.inc'   ! vs BI: not the same
                          ! (J-1,I-1)------(J-1,I)----(J-1,I+1)
                          !     |            |            |
                          !     |   a11      |   a12      |
                          !     | (j-1,i-1)  | (j,i-1)    |
                          !     |            |            |
                          !  (J,I-1)-------(J,I)--------(J,I+1)
                          !     |            |            |
                          !     |   a21      |    a22     |
                          !     | (j-1,i)    |   (j,i)    |
                          !     |            |            |
                          ! (J+1,I-1)------(J+1,I)----(J+1,I+1)
 
dimension njTinj(nz)
!==============================================================================
! Compute M including effects axial depth
! if Zamc < Hc, M = 1
! if Zamc > Hc, M = Hc/(Hl+HG)                                                                           \
! Hl is Z600, Hg is the function of Hl and axial depth(See Liu and Buck 2017)
!==============================================================================
D_axial = 0.25*(cord(1,nx/2,2)+cord(2,nx/2,2)+cord(1,nx/2+1,2)+cord(2,nx/2+1,2))
!print *,'D',D_axial
!define the depth of AMC
Z1100 = 1
do j=1,nz
if (temp(j,nx/2).lt.1100.)then
Z1100=j+1
else if (temp(j,nx/2).ge.1100)then
Z1100 = Z1100
end if
end do
Zamc = abs(cord(int(Z1100),nx/2,2))+ D_axial
print *,'Zamc',Zamc
!define the lithospheric thickness
Z600 = 1
do j=1,nz
if (temp(j,nx/2).lt.600.)then
Z600=j+1
else if (temp(j,nx/2).ge.600)then
Z600 = Z600
end if
end do
HL=abs(cord(int(Z600),nx/2,2))+D_axial
orgh1 = 3000 ! density between magma and rock
orgh2 = 20000 ! density between water and rock
pd = 1.e7 ! driving pressure
D = -D_axial ! make sure axial depth for valley is positive
HG1 = -3.*(orgh1*HL+orgh2*D)
HG2 = sqrt(9*((orgh1*HL+orgh2*D)**2)+24*orgh1*pd*HL)
HG= (HG1+HG2)/(2.*orgh1) ! see Liu&Buck 2017 for detial
!HG=HL+2*D_axial  ! should redescribe the HG
Print *,'HL',HL,'HG',HG

if (Zamc.lt.6.e3) then
rate_inject_HG = Vp_
else if (Zamc.ge.6.e3)then
rate_inject_HG = Vp_*6.e3/(HL+0.5*HG)
endif
rate_inject= min(rate_inject_HG,Vp_)
!print *, 'rate_inject',rate_inject
print *,'rate_inject', rate_inject
!===========================

!************   find the depth of AMC, 1100 !LIU
jinj2 = 1
do j=1,nz
 if (temp(j,nx/2).lt.1100.)then
 jinj2=j+1
 else if (temp(j,nx/2).ge.1100)then
 jinj2 = jinj2
end if
end do
!*************
ninj=iinj2-iinj1+1   !new ninj(horizontal #nodes), iinj1(left bound of dike), iinj2(right bound)
!print *,jinj2
!fdum=xlatheat/( cp(1)*(Tliq-Tsol) )   !L/(Cp*(T_liq - T_sol))
iph = 2   ! phase of the dike
fdum=xlatheat/( cp(iph)*(tl(iph)-ts(iph)) )   !L/(Cp*(T_liq - T_sol))
ninjbot=jinj2     !new ninjbot, jinj2(bottom # of dike)
!print *, 'iinj2=', iinj2, 'ninj=',ninj,'xlatheat=',xlatheat,'fdum=',fdum,'ninjbot=',ninjbot !Tian debug
!----------------------------------------
!don't understand this block (begin)
!----------------------------------------
do 110 i=iinj1,iinj2+1
goto 222 !Tian Comment this block, it make ninjbot become weird
   jcnt=1
   njTinj(1) = ninjbot				!Start: same code as in fl_rheol
   do j = 1,nz-1
     dcord = cord(1,i,2) - cord(j+1,i,2)
     if(dcord.gt.Tcinj) then
       njTinj(jcnt) = j
       jcnt = jcnt+1
     endif
   end do
   ninjbot = min(ninjbot,njTinj(1))		!End: same code as in fl_rheol
222 continue
!----------------------------------------
!don't understand this block (end)
!----------------------------------------

   do 100 j=jinj1,ninjbot+1
!-------------------------------------------------------------------------------
! Compute areas to centers of adjacent cells
!-------------------------------------------------------------------------------
   i1=max0(i-1,1)
   j1=max0(j-1,1)
   i2=min0(i+1,nx)
   j2=min0(j+1,nz)
     
   dx11=0.5*(cord(j1,i ,1)-cord(j1,i1,1)+cord(j ,i ,1)-cord(j ,i1,1))
   dy11=0.5*(cord(j1,i1,2)-cord(j ,i1,2)+cord(j1,i ,2)-cord(j ,i ,2))
   
   dx12=0.5*(cord(j1,i2,1)-cord(j1,i ,1)+cord(j ,i2,1)-cord(j ,i ,1))
   dy12=0.5*(cord(j1,i ,2)-cord(j ,i ,2)+cord(j1,i2,2)-cord(j ,i2,2))
   
   dx21=0.5*(cord(j ,i ,1)-cord(j ,i1,1)+cord(j2,i ,1)-cord(j2,i1,1))
   dy21=0.5*(cord(j ,i1,2)-cord(j2,i1,2)+cord(j ,i ,2)-cord(j2,i  ,2))
   
   dx22=0.5*(cord(j ,i2,1)-cord(j ,i ,1)+cord(j2,i2,1)-cord(j2,i  ,1))
   dy22=0.5*(cord(j ,i ,2)-cord(j2,i ,2)+cord(j ,i2,2)-cord(j2,i2,2))

   a11=dabs(dx11*dy11)/4.  !no real need for 1/4 but it reminds us areas are to center of element
   a12=dabs(dx12*dy12)/4.
   a21=dabs(dx21*dy21)/4.
   a22=dabs(dx22*dy22)/4.
   atot=a11+a12+a21+a22
!-------------------------------------------------------------------------------
! Compute dT's
!-------------------------------------------------------------------------------




   rfac=ratfac*rate_inject*dt/(dx11*dble(ninj))   ! no need to have ratfac
   T0=0.25*(temp(j1,i1)+temp(j1,i)+temp(j,i1)+temp(j,i))
   dtemp=dtemp_inj(T0,tl(iph),ts(iph),rfac,fdum)
   dtemp=dmin1(dtemp,tl(iph)-T0)
   dtemp11=dmax1(dtemp,0.0)

   rfac=ratfac*rate_inject*dt/(dx12*dble(ninj))
   T0=0.25*(temp(j1,i)+temp(j1,i2)+temp(j,i)+temp(j,i2))
   dtemp=dtemp_inj(T0,tl(iph),ts(iph),rfac,fdum)
   dtemp=dmin1(dtemp,tl(iph)-T0)
   dtemp12=dmax1(dtemp,0.0)

   rfac=ratfac*rate_inject*dt/(dx21*dble(ninj))
   T0=0.25*(temp(j,i1)+temp(j,i)+temp(j2,i1)+temp(j2,i))
   dtemp=dtemp_inj(T0,tl(iph),ts(iph),rfac,fdum)
   dtemp=dmin1(dtemp,tl(iph)-T0)
   dtemp21=dmax1(dtemp,0.0)

   rfac=ratfac*rate_inject*dt/(dx22*dble(ninj))
   T0=0.25*(temp(j,i)+temp(j,i2)+temp(j2,i)+temp(j2,i2))
   dtemp=dtemp_inj(T0,tl(iph),ts(iph),rfac,fdum)
   dtemp=dmin1(dtemp,tl(iph)-T0)
   dtemp22=dmax1(dtemp,0.0)
!-------------------------------------------------------------------------------
! Eliminate contribution from elements outside diking zone
!-------------------------------------------------------------------------------
   f11=1.0		
   f12=1.0
   f21=1.0
   f22=1.0 
   if     (i.eq.iinj1) then
     f11=0.
     f21=0.
   elseif (i.eq.iinj2+1) then
     f12=0.
     f22=0.
   endif
   
   if (j.eq.jinj1) then  
     f11=0.                               
     f12=0. 
   elseif (j.eq.ninjbot+1) then
     f21=0.
     f22=0.
   endif
   
!-------------------------------------------------------------------------------
! Update Nodal temperatures
!-------------------------------------------------------------------------------
  dtemp_ave=(dtemp11*f11*a22+dtemp12*f12*a21+dtemp21*f21*a12+dtemp22*f22*a11)/atot

  temp(j,i)=temp(j,i)+dtemp_ave
!  end do 
!end do
!print *, 'j=',j,'i=',i,'dtemp_ave=',dtemp_ave
!------------------------------------------------------------------------------------
! There is/was a bug that make dtemp_ave=NAN, with iinj1=1,
! but it goes away with this if statement.  Keep and eye out!
!------------------------------------------------------------------------------------
  if (dabs(dtemp_ave).gt.10.*tl(iph)) then
    write(*,'(8ES11.3,3i4)') dtemp11, dtemp12, dtemp21, dtemp22, dtemp_ave, dble(ninj), &
    rfac, atot, i,j,nloop
    stop
  endif

100 continue
110 continue

! Boundary conditions (top)
!
if (jinj1.eq.1) then
  do i = iinj1,iinj2+1
    temp(1,i) = t_top
  end do
endif

! Boundary conditions: dt/dx =0 on left and right  
!$DIR PREFER_PARALLEL
if (iinj1.eq.1) then
  do j = jinj1,jinj2
    temp(j ,1)  = temp(j,2)
  end do
endif


return
end  

!+++++++++++++++++++++++++++++++++++++++++++++++++++
!compute the heat injection within magma lens !LIU 7/2017
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++
subroutine fl_magmaheat
use arrays
include 'precision.inc' ! vs BI(Behn and Ito 2008): the same
include 'params.inc'   ! vs BI: not the same
include 'arrays.inc'   ! vs BI: not the same

dimension njTinjm(nz)

!==============================================================================
! Compute M including effects axial depth
! if Zamc < Hc, M = 1
! if Zamc > Hc, M = Hc/(Hl+HG)                                                                           \
! Hl is Z600, Hg is the function of Hl and axial depth(See Liu and Buck 2017)
!==============================================================================
D_axial = 0.25*(cord(1,nx/2,2)+cord(2,nx/2,2)+cord(1,nx/2+1,2)+cord(2,nx/2+1,2))
!print *,'D',D_axial
!define the depth of AMC
Z1100 = 1
do j=1,nz
if (temp(j,nx/2).lt.1100.)then
Z1100=j+1
else if (temp(j,nx/2).ge.1100)then
Z1100 = Z1100
end if
end do
Zamc = abs(cord(int(Z1100),nx/2,2))+D_axial
print *,'Zamc',Zamc
!define the lithospheric thickness
Z600 = 1
do j=1,nz
if (temp(j,nx/2).lt.600.)then
Z600=j+1
else if (temp(j,nx/2).ge.600)then
Z600 = Z600
end if
end do
HL=abs(cord(int(Z600),nx/2,2))+D_axial
orgh1 = 3000 ! density between magma and rock
orgh2 = 20000 ! density between water and rock
pd = 1.e7 ! driving pressure
D = -D_axial ! make sure axial depth for valley is positive
HG1 = -3.*(orgh1*HL+orgh2*D)
HG2 = sqrt(9*((orgh1*HL+orgh2*D)**2)+24*orgh1*pd*HL)
HG= (HG1+HG2)/(2.*orgh1) ! see Liu&Buck 2017 for detial
!HG=HL+2*D_axial  ! should redescribe the HG
Print *,'HL',HL,'HG',HG

if (Zamc.lt.6.e3) then
rate_inject_HG = Vp_
else if (Zamc.ge.6.e3)then
rate_inject_HG = Vp_*6.e3/(HL+0.5*HG)
endif
rate_inject=min(rate_inject_HG,Vp_)
!print *, 'rate_inject',rate_inject
print *,'rate_inject', rate_inject
!===========================
ninjm=iinjm2-iinjm1+1   !new ninj(horizontal #nodes), iinj1(left bound of dike), iinj2(right bound)
iph = 2   ! phase of the dike                                                                          
fdum=xlatheat/( cp(iph)*(tl(iph)-ts(iph)) )   
!*********************************
!find the magma lens depth !LIU 07/2017
!********************************
jinjm1 = 1
do j=1,nz
 if (temp(j,nx/2).lt.1100.)then
 jinjm1=j+1
 else if (temp(j,nx/2).ge.1100)then
 jinjm1 = jinjm1
end if
end do
!jinjm2=max(jinjmc2)
jinjm2=jinjm1+2.
!print *,jinjm2,jinjm1,iinjm1,iinjm2
!**********************************
!find the injection rate within AMC
!
!Hc = 10e3
Zmax = int(abs(cord(jinjm2,nx/2,2))) !depth of 1100
Widthm= cord(jinjm2,iinjm2,1)-cord(jinjm2,iinjm1,1) !width of AMC
!Dams = Hc-250*abs(jinjm2)
rate_inject_m = rate_inject*(6.e3-Zmax)/Widthm
if (rate_inject_m.lt.0) then
rate_inject_m = 0
else if (rate_inject.ge.0)then
rate_injcet_m = rate_inject_m
end if
!print * ,rate_inject_m,Zmax,Widthm
!*****************************

ninjmbot=jinjm2     !new ninjbot, jinj2(bottom # of dike)
!print *, 'iinj2=', iinj2, 'ninj=',ninj,'xlatheat=',xlatheat,'fdum=',fdum,'ninjbot=',ninjbot !Tian debug
do 110 i=iinjm1,iinjm2+1
goto 222 !Tian Comment this block, it make ninjbot become weird
jcntm=1
njTinjm(1) = ninjmbot				!Start: same code as in fl_rheol
do j = 1,nz-1
dcord = cord(1,i,2) - cord(j+1,i,2)
if(dcord.gt.Tcinjm) then
njTinjm(jcntm) = j
jcntm = jcntm+1
endif
end do
ninjmbot = min(ninjmbot,njTinjm(1))		!End: same code as in fl_rheol
222 continue
do 100 j=jinjm1,ninjmbot+1
!-------------------------------------------------------------------------------
! Compute areas to centers of adjacent cells
!-------------------------------------------------------------------------------
i1=max0(i-1,1)
j1=max0(j-1,1)
i2=min0(i+1,nx)
j2=min0(j+1,nz)

dx11=0.5*(cord(j1,i ,1)-cord(j1,i1,1)+cord(j ,i ,1)-cord(j ,i1,1))
dy11=0.5*(cord(j1,i1,2)-cord(j ,i1,2)+cord(j1,i ,2)-cord(j ,i ,2))

dx12=0.5*(cord(j1,i2,1)-cord(j1,i ,1)+cord(j ,i2,1)-cord(j ,i ,1))
dy12=0.5*(cord(j1,i ,2)-cord(j ,i ,2)+cord(j1,i2,2)-cord(j ,i2,2))

dx21=0.5*(cord(j ,i ,1)-cord(j ,i1,1)+cord(j2,i ,1)-cord(j2,i1,1))
dy21=0.5*(cord(j ,i1,2)-cord(j2,i1,2)+cord(j ,i ,2)-cord(j2,i  ,2))

dx22=0.5*(cord(j ,i2,1)-cord(j ,i ,1)+cord(j2,i2,1)-cord(j2,i  ,1))
dy22=0.5*(cord(j ,i ,2)-cord(j2,i ,2)+cord(j ,i2,2)-cord(j2,i2,2))

a11=dabs(dx11*dy11)/4.  !no real need for 1/4 but it reminds us areas are to center of element
a12=dabs(dx12*dy12)/4.
a21=dabs(dx21*dy21)/4.
a22=dabs(dx22*dy22)/4.
atot=a11+a12+a21+a22
!-------------------------------------------------------------------------------
! Compute dT's
!-------------------------------------------------------------------------------


rfac=ratfac*rate_inject_m*dt/(dx11*dble(ninjm))   ! no need to have ratfac
T0=0.25*(temp(j1,i1)+temp(j1,i)+temp(j,i1)+temp(j,i))
dtemp=dtemp_inj(T0,tl(iph),ts(iph),rfac,fdum)
dtemp=dmin1(dtemp,tl(iph)-T0)
dtemp11=dmax1(dtemp,0.0)

rfac=ratfac*rate_inject_m*dt/(dx12*dble(ninjm))
T0=0.25*(temp(j1,i)+temp(j1,i2)+temp(j,i)+temp(j,i2))
dtemp=dtemp_inj(T0,tl(iph),ts(iph),rfac,fdum)
dtemp=dmin1(dtemp,tl(iph)-T0)
dtemp12=dmax1(dtemp,0.0)

rfac=ratfac*rate_inject_m*dt/(dx21*dble(ninjm))
T0=0.25*(temp(j,i1)+temp(j,i)+temp(j2,i1)+temp(j2,i))
dtemp=dtemp_inj(T0,tl(iph),ts(iph),rfac,fdum)
dtemp=dmin1(dtemp,tl(iph)-T0)
dtemp21=dmax1(dtemp,0.0)

rfac=ratfac*rate_inject_m*dt/(dx22*dble(ninjm))
T0=0.25*(temp(j,i)+temp(j,i2)+temp(j2,i)+temp(j2,i2))
dtemp=dtemp_inj(T0,tl(iph),ts(iph),rfac,fdum)
dtemp=dmin1(dtemp,tl(iph)-T0)
dtemp22=dmax1(dtemp,0.0)
!-------------------------------------------------------------------------------
! Eliminate contribution from elements outside diking zone
!-------------------------------------------------------------------------------
f11=1.0
f12=1.0
f21=1.0
f22=1.0
if     (i.eq.iinjm1) then
f11=0.
f21=0.
elseif (i.eq.iinjm2+1) then
f12=0.
f22=0.
endif

if (j.eq.jinjm1) then
f11=0.
f12=0.
elseif (j.eq.ninjmbot+1) then
f21=0.
f22=0.
endif

!-------------------------------------------------------------------------------
! Update Nodal temperatures
!-------------------------------------------------------------------------------
dtemp_ave=(dtemp11*f11*a22+dtemp12*f12*a21+dtemp21*f21*a12+dtemp22*f22*a11)/atot

temp(j,i)=temp(j,i)+dtemp_ave
!end do
!end do
!print *, 'j=',j,'i=',i,'dtemp_ave=',dtemp_ave
!------------------------------------------------------------------------------------
! There is/was a bug that make dtemp_ave=NAN, with iinj1=1,
! but it goes away with this if statement.  Keep and eye out!
!------------------------------------------------------------------------------------
if (dabs(dtemp_ave).gt.10.*tl(iph)) then
write(*,'(8ES11.3,3i4)') dtemp11, dtemp12, dtemp21, dtemp22, dtemp_ave, dble(ninjm), &
rfac, atot, i,j,nloop
stop
endif

100 continue
110 continue

! Boundary conditions (top)
!
if (jinjm1.eq.1) then
do i = iinjm1,iinjm2+1
temp(1,i) = t_top
end do
endif

! Boundary conditions: dt/dx =0 on left and right
!$DIR PREFER_PARALLEL
if (iinjm1.eq.1) then
do j = jinjm1,jinjm2
temp(j ,1)  = temp(j,2)
end do
endif


return
end


!==============================================================================
! Compute dT including effects of latent heat
!==============================================================================
function dtemp_inj(T0,Tliq,Tsol,rfac,fdum)

include 'precision.inc'

! Garrett's original implementation (Page 4 of his notes)
!Tdum=(T0*(1.-rfac) + Tliq*(1.+fdum)*rfac)/(1.0+fdum*rfac)

!if (Tdum .lt. Tsol) then
!  dtemp_inj=( (Tliq-T0) + fdum*(Tliq-Tsol) )*rfac   
!else
!  dtemp_inj=(Tliq-T0)*(1+fdum)*rfac/(1.0+fdum*rfac)
!endif

!Revised by M. Behn Nov 2007
Tdum=(T0 + Tliq*rfac)/(1+rfac)  !<?> What is Tdum, 

if (Tdum .lt. Tsol) then
   dtemp_inj=( (Tliq-T0) + fdum*(Tliq-Tsol) ) * (rfac/(1+rfac))
   !<?> why rfac/(1+rfac) isn't rfac is melt fraction in dike zone?
else
  dtemp_inj=(Tliq-T0) * (rfac/(1+rfac))
endif

return
end
