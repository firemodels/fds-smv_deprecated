
! ------------ module COMPLEX_GEOMETRY ---------------------------------

MODULE COMPLEX_GEOMETRY ! this module will be moved to FDS

USE PRECISION_PARAMETERS
USE COMP_FUNCTIONS, ONLY: CHECKREAD,SHUTDOWN
USE MEMORY_FUNCTIONS, ONLY: ChkMemErr
USE READ_INPUT, ONLY: GET_SURF_INDEX
USE GLOBAL_CONSTANTS
USE TYPES

IMPLICIT NONE
REAL(EB), PARAMETER :: DEG2RAD=4.0_EB*ATAN(1.0_EB)/180.0_EB

PRIVATE
PUBLIC :: READ_GEOM,WRITE_GEOM,ROTATE_VEC, SETUP_AZ_ELEV
 
CONTAINS

! ------------ SUBROUTINE GET_GEOM_ID ---------------------------------

SUBROUTINE GET_GEOM_ID(ID,GEOM_INDEX, N_LAST)

! return the index of the geometry array with label ID

CHARACTER(30), INTENT(IN) :: ID
INTEGER, INTENT(IN) :: N_LAST
INTEGER, INTENT(OUT) :: GEOM_INDEX
INTEGER :: N
TYPE(GEOMETRY_TYPE), POINTER :: G=>NULL()
   
GEOM_INDEX=0
DO N=1,N_LAST
   G=>GEOMETRY(N)
   IF (TRIM(G%ID)==TRIM(ID)) THEN
      GEOM_INDEX=N
      RETURN
   ENDIF
END DO
END SUBROUTINE GET_GEOM_ID

! ------------ SUBROUTINE READ_GEOM ---------------------------------

SUBROUTINE READ_GEOM

! input &GEOM lines

INTEGER, PARAMETER :: MAX_VERTS=10000000 ! at some point we may decide to use dynmaic memory allocation
INTEGER, PARAMETER :: MAX_FACES=MAX_VERTS
INTEGER, PARAMETER :: MAX_IDS=100000
CHARACTER(30) :: ID,SURF_ID, GEOM_IDS(MAX_IDS)
REAL(EB) :: DAZIM(MAX_IDS), DELEV(MAX_IDS), DSCALE(3,MAX_IDS), DXYZ0(3,MAX_IDS), DXYZ(3,MAX_IDS)
REAL(EB) :: AZIM, ELEV, SCALE(3), XYZ0(3), XYZ(3)
REAL(EB), PARAMETER :: MAX_COORD=1.0E20_EB
REAL(EB) :: VERTS(3*MAX_VERTS)
INTEGER :: FACES(3*MAX_FACES)
INTEGER :: N_VERTS, N_FACES
INTEGER :: SURF_INDEX
INTEGER :: IOS,IZERO,N, I, NSUB_GEOMS, GEOM_INDEX
LOGICAL COMPONENT_ONLY
LOGICAL, ALLOCATABLE, DIMENSION(:) :: DEFAULT_COMPONENT_ONLY
TYPE(GEOMETRY_TYPE), POINTER :: G=>NULL()
NAMELIST /GEOM/ AZIM, COMPONENT_ONLY, DAZIM, DELEV, DSCALE, DXYZ0, DXYZ, &
                ELEV, FACES, GEOM_IDS, ID, SCALE, SURF_ID, VERTS, XYZ0, XYZ

! count &GEOM lines

N_GEOMETRY=0
REWIND(LU_INPUT)
COUNT_GEOM_LOOP: DO
   CALL CHECKREAD('GEOM',LU_INPUT,IOS)
   IF (IOS==1) EXIT COUNT_GEOM_LOOP
   READ(LU_INPUT,NML=GEOM,END=11,ERR=12,IOSTAT=IOS)
   N_GEOMETRY=N_GEOMETRY+1
   12 IF (IOS>0) CALL SHUTDOWN('ERROR: problem with GEOM line')
ENDDO COUNT_GEOM_LOOP
11 REWIND(LU_INPUT)

IF (N_GEOMETRY==0) RETURN

! Allocate GEOMETRY array

ALLOCATE(GEOMETRY(N_GEOMETRY),STAT=IZERO)
CALL ChkMemErr('READ','GEOMETRY',IZERO)

ALLOCATE(DEFAULT_COMPONENT_ONLY(N_GEOMETRY),STAT=IZERO)
CALL ChkMemErr('READ','DEFAULT_COMPONENT_ONLY',IZERO)

! default for COMPONENT_ONLY:
!   if an object is in a GEOM_IDS list then COMPONENT_ONLY is .TRUE. by default
!     ie object that IS in a GEOM_IDS list WILL NOT BE drawn by default on its own
!   if an object is not in any GEOM_IDS list then then COMPONENT_ONLY is .FALSE. by default
!     ie an object that IS NOT in any GEOM_IDS list WILL BE drawn by default on its own
READ_GEOM_LOOP0: DO N=1,N_GEOMETRY
   G=>GEOMETRY(N)
   
   CALL CHECKREAD('GEOM',LU_INPUT,IOS)
   IF (IOS==1) EXIT READ_GEOM_LOOP0
   
   ! Set defaults
   
   GEOM_IDS = ''

   ! Read the GEOM line
   
   READ(LU_INPUT,GEOM,END=25)

   DEFAULT_COMPONENT_ONLY(N) = .FALSE.
   DO I = 1, MAX_IDS
      IF (GEOM_IDS(I)=='') EXIT
      IF (N.GT.1) THEN
         CALL GET_GEOM_ID(GEOM_IDS(I),GEOM_INDEX, N-1)
         IF (GEOM_INDEX.GE.1.AND.GEOM_INDEX.LE.N-1) THEN
            DEFAULT_COMPONENT_ONLY(GEOM_INDEX) = .TRUE.
         ENDIF
      ENDIF
   END DO
   
ENDDO READ_GEOM_LOOP0
25 REWIND(LU_INPUT)

! read GEOM data

READ_GEOM_LOOP: DO N=1,N_GEOMETRY
   G=>GEOMETRY(N)
   
   CALL CHECKREAD('GEOM',LU_INPUT,IOS)
   IF (IOS==1) EXIT READ_GEOM_LOOP
   
   ! Set defaults
   
   COMPONENT_ONLY=DEFAULT_COMPONENT_ONLY(N)
   ID = 'geom'
   SURF_ID = 'null'
   VERTS=1.001_EB*MAX_COORD
   FACES=0
   GEOM_IDS = ''
   
   AZIM = 0.0_EB
   ELEV = 0.0_EB
   SCALE = 1.0_EB
   XYZ0 = 0.0_EB
   XYZ = 0.0_EB
   
   DAZIM = 0.0_EB
   DELEV = 0.0_EB
   DSCALE = 1.0_EB
   DXYZ0 = 0.0_EB
   DXYZ = 0.0_EB

   ! Read the GEOM line
   
   READ(LU_INPUT,GEOM,END=35)
   
   N_VERTS=0
   DO I = 1, MAX_VERTS
      IF (VERTS(3*I-2).GE.MAX_COORD.OR.VERTS(3*I-1).GE.MAX_COORD.OR.VERTS(3*I).GE.MAX_COORD) EXIT
      N_VERTS=N_VERTS+1
   END DO
   
   N_FACES=0
   DO I = 1, MAX_FACES
      IF (FACES(3*I-2).EQ.0.OR.FACES(3*I-1).EQ.0.OR.FACES(3*I).EQ.0) EXIT
      N_FACES=N_FACES+1
   END DO

   G%COMPONENT_ONLY=COMPONENT_ONLY
   
   NSUB_GEOMS=0
   DO I = 1, MAX_IDS
      IF (GEOM_IDS(I)=='') EXIT
      NSUB_GEOMS=NSUB_GEOMS+1
   END DO
   IF (NSUB_GEOMS.GT.0) THEN
      ALLOCATE(G%SUB_GEOMS(NSUB_GEOMS),STAT=IZERO)
      CALL ChkMemErr('READ_GEOM','SUB_GEOMS',IZERO)
      
      ALLOCATE(G%DSCALE(3,NSUB_GEOMS),STAT=IZERO)
      CALL ChkMemErr('READ_GEOM','DSCALE',IZERO)
      
      ALLOCATE(G%DAZIM(NSUB_GEOMS),STAT=IZERO)
      CALL ChkMemErr('READ_GEOM','DAZIM',IZERO)
      
      ALLOCATE(G%DELEV(NSUB_GEOMS),STAT=IZERO)
      CALL ChkMemErr('READ_GEOM','DELEV',IZERO)
      
      ALLOCATE(G%DXYZ0(3,NSUB_GEOMS),STAT=IZERO)
      CALL ChkMemErr('READ_GEOM','DXYZ0',IZERO)
      
      ALLOCATE(G%DXYZ(3,NSUB_GEOMS),STAT=IZERO)
      CALL ChkMemErr('READ_GEOM','DXYZ',IZERO)

      N_FACES=0 ! ignore vertex and face entries if there are any GEOM_IDS
      N_VERTS=0
   ENDIF
   G%NSUB_GEOMS=NSUB_GEOMS
   
   G%ID = ID
   G%N_FACES = N_FACES
   G%N_VERTS = N_VERTS
   G%HAS_SURF = .TRUE.
   IF(SURF_ID.EQ.'null')THEN
      G%HAS_SURF = .FALSE.
      SURF_ID = 'INERT'
   ENDIF
   G%SURF_ID = SURF_ID

   IF (N_FACES.GT.0) THEN
      ALLOCATE(G%FACES(3*N_FACES),STAT=IZERO)
      CALL ChkMemErr('READ_GEOM','FACES',IZERO)
      G%FACES(1:3*N_FACES) = FACES(1:3*N_FACES)
   
      DO I = 1, 3*N_FACES
         IF (FACES(I).LT.1.OR.FACES(I).GT.N_VERTS) THEN
            CALL SHUTDOWN('ERROR: problem with GEOM, vertex index out of bounds')
         ENDIF
      END DO

      ALLOCATE(G%SURFS(N_FACES),STAT=IZERO)
      CALL ChkMemErr('READ_GEOM','SURFS',IZERO)
      SURF_INDEX = GET_SURF_INDEX(SURF_ID)
      G%SURFS(1:N_FACES) = SURF_INDEX
   ENDIF

   IF (N_VERTS.GT.0) THEN
      ALLOCATE(G%VERTS(3*N_VERTS),STAT=IZERO)
      CALL ChkMemErr('READ_GEOM','VERTS',IZERO)
      G%VERTS(1:3*N_VERTS) = VERTS(1:3*N_VERTS)
   ENDIF
   
   DO I = 1, NSUB_GEOMS
      CALL GET_GEOM_ID(GEOM_IDS(I),GEOM_INDEX, N-1)
      IF (GEOM_INDEX.GE.1.AND.GEOM_INDEX.LE.N-1) THEN
         G%SUB_GEOMS(I)=GEOM_INDEX
      ELSE
         CALL SHUTDOWN('ERROR: problem with GEOM '//TRIM(G%ID)//' line, '//TRIM(GEOM_IDS(I))//' not yet defined.')
      ENDIF
   END DO
   
   G%AZIM = AZIM
   G%ELEV = ELEV
   G%SCALE = SCALE
   G%XYZ0(1:3) = XYZ0(1:3)
   G%XYZ(1:3) = XYZ(1:3)

   IF (NSUB_GEOMS.GT.0) THEN   
      G%DSCALE(1:3,1:NSUB_GEOMS) = DSCALE(1:3,1:NSUB_GEOMS)
      G%DAZIM(1:NSUB_GEOMS) = DAZIM(1:NSUB_GEOMS)
      G%DELEV(1:NSUB_GEOMS) = DELEV(1:NSUB_GEOMS)
      G%DXYZ0(1:3,1:NSUB_GEOMS) = DXYZ0(1:3,1:NSUB_GEOMS)
       G%DXYZ(1:3,1:NSUB_GEOMS) =  DXYZ(1:3,1:NSUB_GEOMS)
   ENDIF
ENDDO READ_GEOM_LOOP
35 REWIND(LU_INPUT)

DEALLOCATE(DEFAULT_COMPONENT_ONLY,STAT=IZERO)
END SUBROUTINE READ_GEOM


! ------------ SUBROUTINE TRANSLATE_VEC ---------------------------------

SUBROUTINE TRANSLATE_VEC(XYZ,N,XIN,XOUT)

! translate a geometry by the vector XYZ

INTEGER, INTENT(IN) :: N
REAL(EB), INTENT(IN) :: XYZ(3), XIN(3*N)
REAL(EB), INTENT(OUT) :: XOUT(3*N)
REAL(EB) :: VEC(3)
INTEGER :: I

DO I = 1, N 
   VEC(1:3) = XYZ(1:3) + XIN(3*I-2:3*I) ! copy into a temp array so XIN and XOUT can point to same space
   XOUT(3*I-2:3*I) = VEC(1:3)
END DO
END SUBROUTINE TRANSLATE_VEC

! ------------ SUBROUTINE ROTATE_VEC ---------------------------------

SUBROUTINE ROTATE_VEC(M,N,XYZ0,XIN,XOUT)

! rotate the vector XIN about the origin XYZ0

INTEGER, INTENT(IN) :: N
REAL(EB), INTENT(IN) :: M(3,3), XIN(3*N), XYZ0(3)
REAL(EB), INTENT(OUT) :: XOUT(3*N)
REAL(EB) :: VEC(3)
INTEGER :: I

DO I = 1, N
   VEC(1:3) = MATMUL(M,XIN(3*I-2:3*I)-XYZ0(1:3))  ! copy into a temp array so XIN and XOUT can point to same space
   XOUT(3*I-2:3*I) = VEC(1:3) + XYZ0(1:3)
END DO
END SUBROUTINE ROTATE_VEC

! ------------ SUBROUTINE SETUP_AZ_ELEV ---------------------------------

SUBROUTINE SETUP_AZ_ELEV(SCALE,AZ,ELEV,M)

! construct a rotation matrix M that rotates a vector by
! AZ degrees around the Z axis then ELEV degrees around
! the (cos AZ, sin AZ, 0) axis

REAL(EB), INTENT(IN) :: SCALE(3), AZ, ELEV
REAL(EB), DIMENSION(3,3), INTENT(OUT) :: M

REAL(EB) :: AXIS1(3), AXIS2(3)
REAL(EB) :: COS_AZ, SIN_AZ
REAL(EB) :: M0(3,3), M1(3,3), M2(3,3), MTEMP(3,3)

M0 = RESHAPE ((/&
               SCALE(1),  0.0_EB, 0.0_EB,&
                 0.0_EB,SCALE(2), 0.0_EB,&
                 0.0_EB,  0.0_EB,SCALE(3) &
               /),(/3,3/))

AXIS1 = (/0.0_EB, 0.0_EB, 1.0_EB/)
CALL SETUP_ROTATE(AZ,AXIS1,M1)

COS_AZ = COS(DEG2RAD*AZ)
SIN_AZ = SIN(DEG2RAD*AZ)
AXIS2 = (/COS_AZ, SIN_AZ, 0.0_EB/)
CALL SETUP_ROTATE(ELEV,AXIS2,M2)

MTEMP = MATMUL(M1,M0)
M = MATMUL(M2,MTEMP)
END SUBROUTINE SETUP_AZ_ELEV

! ------------ SUBROUTINE SETUP_ROTATE ---------------------------------

SUBROUTINE SETUP_ROTATE(ALPHA,U,M)

! construct a rotation matrix M that rotates a vector by
! ALPHA degrees about an axis U

REAL(EB), INTENT(IN) :: ALPHA, U(3)
REAL(EB), INTENT(OUT) :: M(3,3)
REAL(EB) :: UP(3,1), S(3,3), UUT(3,3), IDENTITY(3,3)
REAL(EB) :: COS_ALPHA, SIN_ALPHA

UP = RESHAPE(U/SQRT(DOT_PRODUCT(U,U)),(/3,1/))
COS_ALPHA = COS(ALPHA*DEG2RAD)
SIN_ALPHA = SIN(ALPHA*DEG2RAD)
S =   RESHAPE( (/&
                   0.0_EB, -UP(3,1),  UP(2,1),&
                  UP(3,1),   0.0_EB, -UP(1,1),&
                 -UP(2,1),  UP(1,1),  0.0_EB  &
                 /),(/3,3/))
UUT = MATMUL(UP,TRANSPOSE(UP))
IDENTITY = RESHAPE ((/&
               1.0_EB,0.0_EB,0.0_EB,&
               0.0_EB,1.0_EB,0.0_EB,&
               0.0_EB,0.0_EB,1.0_EB &
               /),(/3,3/))
M = UUT + COS_ALPHA*(IDENTITY - UUT) + SIN_ALPHA*S
END SUBROUTINE SETUP_ROTATE

! ------------ SUBROUTINE PROCESS_GEOMS ---------------------------------

SUBROUTINE PROCESS_GEOM

! transform (scale, rotate and translate) vectors found on each &GEOM line

   INTEGER :: I
   TYPE(GEOMETRY_TYPE), POINTER :: G=>NULL()
   REAL(EB) :: M(3,3)

   DO I = 1, N_GEOMETRY
      G=>GEOMETRY(I)

      IF (G%N_VERTS.EQ.0) CYCLE
      CALL SETUP_AZ_ELEV(G%SCALE,G%AZIM,G%ELEV,M)
      CALL ROTATE_VEC(M,G%N_VERTS,G%XYZ0,G%VERTS,G%VERTS)
      CALL TRANSLATE_VEC(G%XYZ,G%N_VERTS,G%VERTS,G%VERTS)
   END DO
END SUBROUTINE PROCESS_GEOM

! ------------ SUBROUTINE MERGE_GEOMS ---------------------------------

SUBROUTINE MERGE_GEOMS(VERTS,N_VERTS,FACES,SURF_IDS,N_FACES)

! combine vectors and faces found on all &GEOM lines into one set of VECTOR and FACE arrays

INTEGER N_VERTS, N_FACES, I
INTEGER, DIMENSION(:) :: FACES(3*N_FACES), SURF_IDS(N_FACES)
REAL(EB), DIMENSION(:) :: VERTS(3*N_VERTS)
TYPE(GEOMETRY_TYPE), POINTER :: G=>NULL()
INTEGER :: IVERT, IFACE, ISURF, OFFSET
   
IVERT = 0
IFACE = 0
ISURF = 0
OFFSET = 0
DO I = 1, N_GEOMETRY
   G=>GEOMETRY(I)
   IF (G%COMPONENT_ONLY) CYCLE
    IF (G%N_VERTS>0) THEN
      VERTS(1+IVERT:3*G%N_VERTS+IVERT) = G%VERTS(1:3*G%N_VERTS)
      IVERT = IVERT + 3*G%N_VERTS
   ENDIF
   
   IF (G%N_FACES>0) THEN
      FACES(1+IFACE:3*G%N_FACES + IFACE) = G%FACES(1:3*G%N_FACES)+OFFSET
      IFACE = IFACE + 3*G%N_FACES

      SURF_IDS(1+ISURF:G%N_FACES+ISURF) = G%SURFS(1:G%N_FACES)
      ISURF = ISURF +   G%N_FACES
   ENDIF
   OFFSET = OFFSET + G%N_VERTS
END DO
END SUBROUTINE MERGE_GEOMS

! ------------ SUBROUTINE EXPAND_GROUPS ---------------------------------

SUBROUTINE EXPAND_GROUPS

! for each geometry specifed in a &GEOM line, merge geometries referened
! by GEOM_IDS after scaling, rotating and translating

INTEGER I, J
TYPE(GEOMETRY_TYPE), POINTER :: G=>NULL(), GSUB=>NULL()
INTEGER :: N_VERTS, N_FACES
INTEGER :: IZERO
REAL(EB) :: M(3,3)
INTEGER :: IVERT, IFACE
REAL(EB), POINTER, DIMENSION(:) :: XIN, XOUT
INTEGER, POINTER, DIMENSION(:) :: FIN,FOUT, SURFIN, SURFOUT
INTEGER :: NSUB_VERTS ,NSUB_FACES, SURF_INDEX
REAL(EB), DIMENSION(:), POINTER :: DSCALEPTR, DXYZ0PTR, DXYZPTR
   
DO I = 2, N_GEOMETRY ! first geometry will not have any sub-geometries (since all sub-geometries must have 
                     ! been defined in a previous &GEOM line)
   G=>GEOMETRY(I)
     
   IF (G%NSUB_GEOMS.EQ.0) CYCLE
      
   N_VERTS=0  ! add number of vertices and faces in geometries referenced in GEOM_IDS
   N_FACES=0
   DO J = 1, G%NSUB_GEOMS
      GSUB=>GEOMETRY(G%SUB_GEOMS(J))
        
      IF (GSUB%N_VERTS.EQ.0.OR.GSUB%N_FACES.EQ.0) CYCLE
      N_VERTS = N_VERTS + GSUB%N_VERTS
      N_FACES = N_FACES + GSUB%N_FACES
   END DO
      
   IF (N_VERTS.EQ.0.OR.N_FACES.EQ.0) THEN ! nothing to do if GEOM_IDS geometries are empty
      G%N_VERTS=0
      G%N_FACES=0
      CYCLE
   ENDIF
      
   G%N_VERTS=N_VERTS
   G%N_FACES=N_FACES
      
   ALLOCATE(G%FACES(3*N_FACES),STAT=IZERO)
   CALL ChkMemErr('READ_GEOM','FACES',IZERO)

   ALLOCATE(G%VERTS(3*N_VERTS),STAT=IZERO)
   CALL ChkMemErr('READ_GEOM','VERTS',IZERO)
      
   ALLOCATE(G%SURFS(N_FACES),STAT=IZERO)
   CALL ChkMemErr('READ_GEOM','SURFS',IZERO)

   IVERT = 0
   IFACE = 0
   DO J = 1, G%NSUB_GEOMS
      GSUB=>GEOMETRY(G%SUB_GEOMS(J))
      NSUB_VERTS = GSUB%N_VERTS
      NSUB_FACES = GSUB%N_FACES
        
      IF (NSUB_VERTS.EQ.0.OR.NSUB_FACES.EQ.0) CYCLE

      DSCALEPTR(1:3) => G%DSCALE(1:3,J)
      CALL SETUP_AZ_ELEV(DSCALEPTR,G%DAZIM(J),G%DELEV(J),M)
        
      XIN(1:3*NSUB_VERTS) => GSUB%VERTS(1:3*NSUB_VERTS)
      XOUT(1:3*NSUB_VERTS) => G%VERTS(1+3*IVERT:3*(IVERT+NSUB_VERTS))
        
      DXYZ0PTR(1:3) => G%DXYZ0(1:3,J)
      DXYZPTR(1:3) => G%DXYZ(1:3,J)
      CALL ROTATE_VEC(M,NSUB_VERTS,DXYZ0PTR,XIN,XOUT)
      CALL TRANSLATE_VEC(DXYZPTR,NSUB_VERTS,XOUT,XOUT)
        
      ! copy and offset face indices
        
      FIN(1:3*NSUB_FACES) => GSUB%FACES(1:3*NSUB_FACES)
      FOUT(1:3*NSUB_FACES) => G%FACES(1+3*IFACE:3*(IFACE+NSUB_FACES))
      FOUT = FIN + IVERT

      ! copy surface indices
        
      SURFIN(1:NSUB_FACES) => GSUB%SURFS(1:NSUB_FACES)
      SURFOUT(1:NSUB_FACES) => G%SURFS(1+IFACE:IFACE+NSUB_FACES)
      SURFOUT = SURFIN
        
      IVERT = IVERT + NSUB_VERTS
      IFACE = IFACE + NSUB_FACES
   END DO
   IF (G%HAS_SURF) THEN
      SURF_INDEX = GET_SURF_INDEX(G%SURF_ID)
      G%SURFS(1:N_FACES) = SURF_INDEX
   ENDIF
END DO
END SUBROUTINE EXPAND_GROUPS

! ------------ SUBROUTINE WRITE_GEOM ---------------------------------

SUBROUTINE WRITE_GEOM

! output geometries to a .ge file

INTEGER :: I
TYPE(GEOMETRY_TYPE), POINTER :: G=>NULL()
INTEGER :: N_VERTS, N_FACES
INTEGER, ALLOCATABLE, DIMENSION(:) :: FACES, SURF_IDS
REAL(EB), ALLOCATABLE, DIMENSION(:) :: VERTS
INTEGER :: IZERO
INTEGER :: ONE=1, ZERO=0, VERSION=0
REAL(FB) :: STIME=0.0_EB
INTEGER :: N_VERT_S_VALS, N_VERT_D_VALS
INTEGER :: N_FACE_S_VALS, N_FACE_D_VALS

IF (N_GEOMETRY.LE.0) RETURN

CALL PROCESS_GEOM  ! scale, rotate, translate GEOM vertices 
CALL EXPAND_GROUPS ! create vertex and face list from geometries specified in GEOM_IDS list

N_VERTS=0
N_FACES=0
DO I = 1, N_GEOMETRY ! count vertices and faces
   G=>GEOMETRY(I)
      
   IF (G%COMPONENT_ONLY) CYCLE   
   N_VERTS = N_VERTS + G%N_VERTS
   N_FACES = N_FACES + G%N_FACES
END DO
IF (N_VERTS.LE.0.OR.N_FACES.LE.0) RETURN

ALLOCATE(VERTS(3*N_VERTS),STAT=IZERO)   ! create arrays to contain all vertices and faces
CALL ChkMemErr('WRITE_GEOM_TO_SMV','VERTS',IZERO)
   
ALLOCATE(FACES(3*N_FACES),STAT=IZERO)
CALL ChkMemErr('WRITE_GEOM_TO_SMV','FACES',IZERO)

ALLOCATE(SURF_IDS(N_FACES),STAT=IZERO)
CALL ChkMemErr('WRITE_GEOM_TO_SMV','SURF_IDS',IZERO)

CALL MERGE_GEOMS(VERTS,N_VERTS,FACES,SURF_IDS,N_FACES)

OPEN(LU_GEOM(1),FILE=FN_GEOM(1),FORM='UNFORMATTED',STATUS='REPLACE')

N_VERT_S_VALS=N_VERTS
N_VERT_D_VALS=0
N_FACE_S_VALS = N_FACES
N_FACE_D_VALS=0

WRITE(LU_GEOM(1)) ONE
WRITE(LU_GEOM(1)) VERSION
WRITE(LU_GEOM(1)) ZERO ! floating point header
WRITE(LU_GEOM(1)) ZERO ! integer header
WRITE(LU_GEOM(1)) N_VERT_S_VALS,N_FACE_S_VALS
IF (N_VERT_S_VALS>0) WRITE(LU_GEOM(1)) (REAL(VERTS(I),FB), I=1,3*N_VERT_S_VALS)
IF (N_FACE_S_VALS>0) THEN
   WRITE(LU_GEOM(1)) (FACES(I), I=1,3*N_FACE_S_VALS)
   WRITE(LU_GEOM(1)) (SURF_IDS(I), I=1,N_FACE_S_VALS)
ENDIF
WRITE(LU_GEOM(1)) STIME,ZERO
WRITE(LU_GEOM(1)) ZERO,ZERO

CALL WRITE_GEOM_SUMMARY

END SUBROUTINE WRITE_GEOM

! ------------ SUBROUTINE WRITE_GEOM_SUMMARY ---------------------------------

SUBROUTINE WRITE_GEOM_SUMMARY

! debug output routine (not intended for FDS)

INTEGER :: I,J

TYPE(GEOMETRY_TYPE), POINTER :: G=>NULL()

DO I = 1, N_GEOMETRY
   G=>GEOMETRY(I)
   
   WRITE(6,*)" GEOM:",I,TRIM(G%ID)
   WRITE(6,10)G%N_VERTS,G%N_FACES,G%NSUB_GEOMS
   10 FORMAT("   NVERTS=",I3,' NFACES=',I3,' NGEOMS=',I3)
   WRITE(6,20)G%SCALE
   20 FORMAT('   SCALE=',3(E11.4,1X))
   WRITE(6,25)G%AZIM,G%ELEV
   25 FORMAT(' AZIM=',E11.4,' ELEV=',E11.4)
   WRITE(6,30)G%XYZ0
   30 FORMAT('   XYZ0=',3(E11.4,1X))
   WRITE(6,40)G%XYZ
   40 FORMAT(' XYZ=',3(E11.4,1X))
   IF (G%NSUB_GEOMS.GT.0) THEN
      DO J=1,G%NSUB_GEOMS
         WRITE(6,*)"   GEOMS:",J
         WRITE(6,50)G%DAZIM(J),G%DELEV(J)
         50 FORMAT("      DAZIM=",E11.4," DELEV=",E11.4)
         WRITE(6,60)G%DXYZ0(1:3,J)
         60 FORMAT("      DXYZ0=",3E11.4)
         WRITE(6,70)G%DXYZ(1:3,J)
         70 FORMAT("      DXYZ=",3E11.4)
         WRITE(6,80)G%DSCALE(1:3,J)
         80 FORMAT("    DSCALE=",3E11.4)
         
      END DO
   ENDIF
      
END DO

END SUBROUTINE WRITE_GEOM_SUMMARY


END MODULE COMPLEX_GEOMETRY
