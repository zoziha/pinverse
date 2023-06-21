module pinverse

   ! This module provides functions and subroutines
   ! for calculating the singular value decomposition (SVD) and pseudoinverse of a matrix.

   use :: kinds  ! Import the module 'kinds' for precision types

   implicit none
   
   private              ! Make all module variables and procedures private

   public :: svd, pinv  ! Make svd and pinv functions public

   !===============================================================================
   interface svd
      procedure :: svd_rel ! Interface for the svd_rel subroutine
   end interface
   !===============================================================================


   !===============================================================================
   interface pinv
      procedure :: pinverse_rel ! Interface for the pinverse_rel function
   end interface
   !===============================================================================

contains

   !===============================================================================
   !> author: Seyed Ali Ghasemi
   !> Calculates the singular value decomposition (SVD) of a matrix A.
   pure subroutine svd_rel(A, U,S,VT)

      ! Inputs:
      real(rk), dimension(:, :), contiguous,          intent(in)  :: A    ! Input matrix A  

      ! Outputs:
      real(rk), dimension(size(A,1), size(A,1)),      intent(out) :: U    ! Left singular vectors
      real(rk), dimension(size(A,2), size(A,2)),      intent(out) :: VT   ! Right singular vectors
      real(rk), dimension(min(size(A,1), size(A,2))), intent(out) :: S    ! Singular values

      ! Local variables
      real(rk)                                                    :: work1(1) ! memory allocation query
      real(rk), dimension(:), allocatable                         :: work     ! Work array
      integer                                                     :: m, n, lwork, info, i, j

      ! External subroutine for calculating the SVD
      interface dgesvd
         pure subroutine dgesvd(jobuf,jobvtf,mf,nf,af,ldaf,sf,uf,lduf,vtf,ldvtf,workf,lworkf,infof)
            use kinds
            character, intent(in)  :: jobuf, jobvtf
            integer,   intent(in)  :: mf, nf, ldaf, lduf, ldvtf, lworkf
            real(rk),  intent(in)  :: Af(ldaf, *)
            real(rk),  intent(out) :: Sf(min(mf, nf))
            real(rk),  intent(out) :: Uf(lduf, *), VTf(ldvtf, *)
            real(rk),  intent(out) :: workf(*)
            integer,   intent(out) :: infof
         end subroutine dgesvd
      end interface

      m = size(A, 1)
      n = size(A, 2)
      
      ! Calculate the optimal size of the work array
      call dgesvd('S', 'S', m, n, A, m, S, U, m, VT, n, work1, -1, info)
      lwork = nint(work1(1))
      allocate(work(lwork))

      call dgesvd('S', 'S', m, n, A, m, S, U, m, VT, n, work, lwork, info)

      deallocate(work)
   end subroutine svd_rel
   !===============================================================================


   !===============================================================================
   !> author: Seyed Ali Ghasemi
   !> Calculates the pseudoinverse of a matrix A using the SVD.
   pure function pinverse_rel(A) result(Apinv)

      ! Inputs:
      real(rk), dimension(:, :), contiguous, intent(in)  :: A     ! Input matrix A

      ! Outputs:
      real(rk), dimension(size(A,2), size(A,1))          :: Apinv ! Pseudoinverse of A
      
      ! Local variables
      real(rk), dimension(size(A,1), size(A,1))          :: U    ! Left singular vectors
      real(rk), dimension(size(A,2), size(A,2))          :: VT   ! Right singular vectors
      real(rk), dimension(min(size(A,1), size(A,2)))     :: S    ! Singular values
      integer                                            :: m, n, i, j, irank, rank

      m = size(A, 1)
      n = size(A, 2)

      call svd_rel(A, U,S,VT)

      rank = min(m,n)
      
      Apinv = 0.0_rk

      do concurrent (irank = 1:rank, j = 1:m, i = 1:n) shared(Apinv, VT, U, S, rank, m , n)
         Apinv(i, j) = Apinv(i, j) + VT(irank, i) * U(j, irank) / S(irank)
      end do

   end function pinverse_rel
   !===============================================================================

end module pinverse