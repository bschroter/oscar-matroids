#####################################################
# 1. Resolve a model
#####################################################

@doc raw"""
    blow_up(m::AbstractFTheoryModel, ideal_gens::Vector{String}; coordinate_name::String = "e")

Resolve an F-theory model by blowing up a locus in the ambient space.

# Examples
```jldoctest
julia> B3 = projective_space(NormalToricVariety, 3)
Normal toric variety

julia> w = torusinvariant_prime_divisors(B3)[1]
Torus-invariant, prime divisor on a normal toric variety

julia> t = literature_model(arxiv_id = "1109.3454", equation = "3.1", base_space = B3, model_sections = Dict("w" => w), completeness_check = false)
Construction over concrete base may lead to singularity enhancement. Consider computing singular_loci. However, this may take time!

Global Tate model over a concrete base -- SU(5)xU(1) restricted Tate model based on arXiv paper 1109.3454 Eq. (3.1)

julia> blow_up(t, ["x", "y", "x1"]; coordinate_name = "e1")
Partially resolved global Tate model over a concrete base -- SU(5)xU(1) restricted Tate model based on arXiv paper 1109.3454 Eq. (3.1)
```
Here is an example for a Weierstrass model.

# Examples
```jldoctest
julia> B2 = projective_space(NormalToricVariety, 2)
Normal toric variety

julia> b = torusinvariant_prime_divisors(B2)[1]
Torus-invariant, prime divisor on a normal toric variety

julia> w = literature_model(arxiv_id = "1208.2695", equation = "B.19", base_space = B2, model_sections = Dict("b" => b), completeness_check = false)
Construction over concrete base may lead to singularity enhancement. Consider computing singular_loci. However, this may take time!

Weierstrass model over a concrete base -- U(1) Weierstrass model based on arXiv paper 1208.2695 Eq. (B.19)

julia> blow_up(w, ["x", "y", "x1"]; coordinate_name = "e1")
Partially resolved Weierstrass model over a concrete base -- U(1) Weierstrass model based on arXiv paper 1208.2695 Eq. (B.19)
```
"""
function blow_up(m::AbstractFTheoryModel, ideal_gens::Vector{String}; coordinate_name::String = "e")
  R = cox_ring(ambient_space(m))
  I = ideal([eval_poly(k, R) for k in ideal_gens])
  return blow_up(m, I; coordinate_name = coordinate_name)
end

function blow_up(m::AbstractFTheoryModel, I::MPolyIdeal; coordinate_name::String = "e")
  
  # Cannot (yet) blowup if this is not a Tate or Weierstrass model
  @req ((typeof(m) == GlobalTateModel) || (typeof(m) == WeierstrassModel)) "Blowups are currently only supported for Tate and Weierstrass models"

  # This method only works if the model is defined over a toric variety over toric scheme
  @req typeof(base_space(m)) <: NormalToricVariety "Blowups of Tate models are currently only supported for toric bases"
  @req typeof(ambient_space(m)) <: NormalToricVariety "Blowups of Tate models are currently only supported for toric ambient spaces"

  # Compute the new ambient_space
  bd = blow_up(ambient_space(m), I; coordinate_name = coordinate_name)
  new_ambient_space = domain(bd)

  # Compute the new base
  # FIXME: THIS WILL IN GENERAL BE WRONG! IN PRINCIPLE, THE ABOVE ALLOWS TO BLOW UP THE BASE AND THE BASE ONLY.
  # FIXME: We should save the projection \pi from the ambient space to the base space.
  # FIXME: This is also ties in with the model sections to be saved, see below. Should the base change, so do these sections...
  new_base = base_space(m)

  # Prepare ring map for the computation of the strict transform.
  # FIXME: This assume that I is generated by indeterminates! Very special!
  S = cox_ring(new_ambient_space)
  _e = eval_poly(coordinate_name, S)
  images = MPolyRingElem[]
  for v in gens(S)
    v == _e && continue
    if string(v) in [string(k) for k in gens(I)]
      push!(images, v * _e)
    else
      push!(images, v)
    end
  end
  ring_map = hom(base_ring(I), S, images)

  # Construct the new model
  if typeof(m) == GlobalTateModel
    total_transform = ring_map(ideal([tate_polynomial(m)]))
    exceptional_ideal = total_transform + ideal([_e])
    strict_transform, exceptional_factor = saturation_with_index(total_transform, exceptional_ideal)
    new_pt = gens(strict_transform)[1]
    ais = [tate_section_a1(m), tate_section_a2(m), tate_section_a3(m), tate_section_a4(m), tate_section_a6(m)]
    model = GlobalTateModel(ais[1], ais[2], ais[3], ais[4], ais[5], new_pt, base_space(m), new_ambient_space)
  else
    total_transform = ring_map(ideal([weierstrass_polynomial(m)]))
    exceptional_ideal = total_transform + ideal([_e])
    strict_transform, exceptional_factor = saturation_with_index(total_transform, exceptional_ideal)
    new_pw = gens(strict_transform)[1]
    f = weierstrass_section_f(m)
    g = weierstrass_section_g(m)
    model = WeierstrassModel(f, g, new_pw, base_space(m), new_ambient_space)
  end

  # Copy/overwrite known attributes from old model
  model_attributes = m.__attrs
  for (key, value) in model_attributes
    set_attribute!(model, key, value)
  end
  set_attribute!(model, :partially_resolved, true)

  # Return the model
  return model
end


#####################################################
# 2. Tune a model
#####################################################

@doc raw"""
    tune(m::AbstractFTheoryModel, p::MPolyRingElem; completeness_check::Bool = true)

Tune an F-theory model by replacing the hypersurface equation by a custom (polynomial)
equation. The latter can be any type of polynomial: a Tate polynomial, a Weierstrass
polynomial or a general polynomial. We do not conduct checks to tell which type the
provided polynomial is. Consequently, this tuning will always return a hypersurface model.

Note that there is less functionality for hypersurface models than for Weierstrass or Tate
models. For instance, `singular_loci` can (currently) not be computed for hypersurface models.

# Examples
```jldoctest
julia> B3 = projective_space(NormalToricVariety, 3)
Normal toric variety

julia> w = torusinvariant_prime_divisors(B3)[1]
Torus-invariant, prime divisor on a normal toric variety

julia> t = literature_model(arxiv_id = "1109.3454", equation = "3.1", base_space = B3, model_sections = Dict("w" => w), completeness_check = false)
Construction over concrete base may lead to singularity enhancement. Consider computing singular_loci. However, this may take time!

Global Tate model over a concrete base -- SU(5)xU(1) restricted Tate model based on arXiv paper 1109.3454 Eq. (3.1)

julia> x1, x2, x3, x4, x, y, z = gens(parent(tate_polynomial(t)))
7-element Vector{MPolyDecRingElem{QQFieldElem, QQMPolyRingElem}}:
 x1
 x2
 x3
 x4
 x
 y
 z

julia> new_tate_polynomial = x^3 - y^2 - x * y * z * x4^4
-x4^4*x*y*z + x^3 - y^2

julia> tuned_t = tune(t, new_tate_polynomial)
Hypersurface model over a concrete base

julia> hypersurface_equation(tuned_t) == new_tate_polynomial
true

julia> base_space(tuned_t) == base_space(t)
true
```
"""
function tune(m::AbstractFTheoryModel, p::MPolyRingElem; completeness_check::Bool = true)
  @req (typeof(m) == GlobalTateModel) || (typeof(m) == WeierstrassModel) || (typeof(m) == HypersurfaceModel) "Tuning currently supported only for Weierstrass, Tate and hypersurface models"
  @req !(typeof(base_space(m)) <: FamilyOfSpaces) "Currently, tuning is only possible for models over concrete toric bases"
  if typeof(m) == GlobalTateModel
    equation = tate_polynomial(m)
  elseif typeof(m) == WeierstrassModel
    equation = weierstrass_polynomial(m)
  else
    equation = hypersurface_equation(m)
  end
  @req parent(p) == parent(equation) "Parent mismatch between given and existing hypersurface polynomial"
  @req degree(p) == degree(equation) "Degree mismatch between given and existing hypersurface polynomial"
  p == equation && return m
  tuned_model = HypersurfaceModel(base_space(m), ambient_space(m), fiber_ambient_space(m), p)
  set_attribute!(tuned_model, :partially_resolved, false)
  return tuned_model
end
