_whyohwhy1 = AbstractAlgebra.Generic.MPolyRing{padic}
@attributes _whyohwhy1

_whyohwhy2 = FmpqMPolyRing
@attributes _whyohwhy2

_whyohwhy3 = FlintRationalField
@attributes _whyohwhy3

using pAdicSolver # to compute tropicalizations of zero-dimensional ideals (through solve_macaulay)

include("numbers.jl")
include("valuation.jl")
include("poly.jl")
include("initial.jl")
include("groebner_basis.jl")
include("groebner_flip.jl")
include("groebner_polyhedron.jl")
include("points.jl")
include("link.jl")
include("multiplicity.jl")
include("traversal.jl")

# Temporarily we will turn tropical polynomials into strings. This will be
# removed once Polymake.jl wraps its tropical polynomials and tropical numbers
#
# Warning: This function ignores all boundary cases!
function tropical_polynomial_to_polymake(f)
    convention = fun(base_ring(f))
    fstr = ""
    if convention == min
        fstr *= "min("
    else
        fstr *= "max("
    end
    td = total_degree(f)
    for i in 1:length(f)
        fstr *= repr(coeff(f,i).data)
        e = exponent_vector(f,i)
        if td - sum(e) != 0
            fstr *= "+"
            fstr *= repr(td-sum(e))
            fstr *= "x_0"
        end
        if !iszero(e)
            for j in 1:length(e)
                if !iszero(e[j])
                    fstr *= "+"
                    fstr *= repr(e[j])
                    fstr *= "*x_"
                    fstr *= repr(j)
                end
            end
        end
        if i != length(f)
            fstr *= ","
        end
    end
    fstr *= ")"
    result = ["x_"*repr(i) for i in 0:nvars(parent(f))]
    prepend!(result, [fstr])
    return result
end


###
# Allow gcd of vectors of univariate rational polynomials
# to make their handling similar to that of integers
###
function gcd(F::Vector{fmpq_poly})
  F_gcd,F_latter = Iterators.peel(F)

  for f in F_latter
    F_gcd = gcd(F_gcd,f)
  end

  return F_gcd
end

###
# Allow Singular.satstd over coefficient rings
###
function Singular.satstd(I::Singular.sideal{Singular.spoly{T}}, J::Singular.sideal{Singular.spoly{T}}) where T
   Singular.check_parent(I, J)
   !Singular.isvar_generated(J) && error("Second ideal must be generated by variables")
   R = base_ring(I)
   ptr = GC.@preserve I J R Singular.libSingular.id_Satstd(I.ptr, J.ptr, R.ptr)
   Singular.libSingular.idSkipZeroes(ptr)
   return Singular.sideal{Singular.spoly{T}}(R, ptr, true)
end

###
# Allow dot product between Vector{fmpq} and Vector{Int64}
###
function dot(x::Vector{fmpq}, y::Vector{Int64})
  xy = 0
  for (xi,yi) in zip(x,y)
    xy += xi*yi
  end
  return xy
end

# # Workaround for turning a PolyhedralFan of polymake into a proper PolyhedralComplex
# function polyhedral_complex_workaround(pm::Polymake.BigObject)
#     pc = pm
#     typename = Polymake.type_name(pm)
#     if typename[1:13] == "PolyhedralFan"
#         pc = Polymake.fan.PolyhedralComplex(pm)
#     end
#     typename = Polymake.type_name(pc)
#     if typename[1:17] != "PolyhedralComplex"
#         error("Input object is not of type PolyhedralFan or PolyhedralComplex")
#     end
#     fv = Polymake.to_one_based_indexing(pc.FAR_VERTICES)
#     mc = pc.MAXIMAL_POLYTOPES
#     feasibles = [Polymake.to_zero_based_indexing(Polymake.row(mc, i)) for i in 1:Polymake.nrows(mc) if Polymake.incl(Polymake.row(mc, i), fv)>0]
#     return Polymake.fan.PolyhedralComplex(POINTS=pc.VERTICES, INPUT_LINEALITY=pc.LINEALITY_SPACE, INPUT_POLYTOPES=feasibles)
# end


include("variety_supertype.jl")
include("variety.jl")
include("hypersurface.jl")
include("curve.jl")
include("linear_space.jl")
