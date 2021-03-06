#=
    Helper functions to store constraint mappings
=#
cmap(model::LinQuadOptimizer) = model.constraint_mapping
# dummy method for isvalid
constrdict(::LinQuadOptimizer, ::CI{F, S}) where {F, S} = Dict{CI{F, S}, Any}()

function Base.getindex(model::LinQuadOptimizer, index::CI)
    return constrdict(model, index)[index]
end

# Internal function: delete the constraint name.
function delete_constraint_name(model::LinQuadOptimizer, index::CI)
    model.name_to_constraint = nothing
    delete!(model.constraint_to_name, index)
    return
end

"""
    has_integer(model::LinQuadOptimizer)::Bool

A helper function to determine if `model` has any integer components (i.e.
binary, integer, special ordered sets, semicontinuous, or semi-integer
variables).
"""
function has_integer(model::LinQuadOptimizer)
    constraint_map = cmap(model)
    return length(constraint_map.integer) > 0 ||
        length(constraint_map.binary) > 0 ||
        length(constraint_map.sos1) > 0 ||
        length(constraint_map.sos2) > 0 ||
        length(constraint_map.semicontinuous) > 0 ||
        length(constraint_map.semiinteger) > 0
end

#=
    MOI.is_valid
=#

function MOI.is_valid(model::LinQuadOptimizer, index::CI{F,S}) where F where S
    dict = constrdict(model, index)
    return haskey(dict, index)
end

"""
    __assert_valid__(model::LinQuadOptimizer, index::MOI.Index)

Throw an MOI.InvalidIndex error if `MOI.is_valid(model, index) == false`.
"""
function __assert_valid__(model::LinQuadOptimizer, index::MOI.Index)
    if !MOI.is_valid(model, index)
        throw(MOI.InvalidIndex(index))
    end
end

"""
    __assert_supported_constraint__(model::LinQuadOptimizer, ::Type{F}, ::Type{S})

Throw an `UnsupportedConstraint{F, S}` error if the model cannot add constraints
of type `F`-in-`S`.
"""
function __assert_supported_constraint__(model::LinQuadOptimizer, ::Type{F}, ::Type{S}) where {F<:MOI.AbstractFunction, S<:MOI.AbstractSet}
    if !((F,S) in supported_constraints(model))
        throw(MOI.UnsupportedConstraint{F, S}())
    end
end

#=
    Get number of constraints
=#

function MOI.get(model::LinQuadOptimizer, attribute::MOI.NumberOfConstraints{F, S}) where F where S
    __assert_supported_constraint__(model, F, S)
    return length(constrdict(model, CI{F,S}(UInt(0))))
end

#=
    Get list of constraint references
=#

function MOI.get(model::LinQuadOptimizer, attribute::MOI.ListOfConstraintIndices{F, S}) where F where S
    __assert_supported_constraint__(model, F, S)
    dict = constrdict(model, CI{F,S}(UInt(0)))
    indices = collect(keys(dict))
    return sort(indices, by=x->x.value)
end

#=
    Get list of constraint types in model
=#

function MOI.get(model::LinQuadOptimizer, ::MOI.ListOfConstraints)
    return [(F, S) for (F, S) in supported_constraints(model) if
        MOI.get(model, MOI.NumberOfConstraints{F,S}()) > 0]
end

#=
    Get constraint names
=#

function MOI.get(model::LinQuadOptimizer, ::MOI.ConstraintName, index::CI)
    return get(model.constraint_to_name, index, "")
end

function MOI.supports(
        ::LinQuadOptimizer, ::MOI.ConstraintName, ::Type{<:MOI.ConstraintIndex})
    return true
end

function MOI.set(model::LinQuadOptimizer, ::MOI.ConstraintName,
                  index::MOI.ConstraintIndex, name::String)
    if name != ""
        model.constraint_to_name[index] = name
    else
        delete!(model.constraint_to_name, index)
    end
    model.name_to_constraint = nothing
    return
end

#=
    Get constraint by name. Rebuild the lazy reverse-lookup if required.
=#
            
function _rebuild_name_to_constraint(model::LinQuadOptimizer)
    model.name_to_constraint = Dict{String, MOI.ConstraintIndex}()
    for (constr, c_name) in model.constraint_to_name
        c_name == "" && continue
        if haskey(model.name_to_constraint, c_name)
            duuplicate_con = model.name_to_constraint[c_name]
            model.name_to_constraint = nothing
            error("Constraints $(constr) and $(duuplicate_con) have the ",
                  "same name: ", c_name)
        else
            model.name_to_constraint[c_name] = constr
        end
    end
    return                
end

function MOI.get(
        model::LinQuadOptimizer, ::Type{<:MOI.ConstraintIndex}, name::String)
    if model.name_to_constraint === nothing
        _rebuild_name_to_constraint(model)
    end
    return get(model.name_to_constraint, name, nothing)
end

# this covers the type-stable get(m, ConstraintIndex{F,S}, name)::CI{F,S} case
function MOI.get(model::LinQuadOptimizer, ::Type{MOI.ConstraintIndex{F,S}},
                 name::String) where {F, S}
    index = MOI.get(model, MOI.ConstraintIndex, name)
    if isa(index, MOI.ConstraintIndex{F, S})
        return index::MOI.ConstraintIndex{F, S}
    end
    return nothing
end


"""
    CSRMatrix{T}

Type alias for `Transpose{T,SparseMatrixCSC{T,Int}} where T`, which allows for the
    efficient storage of compressed sparse row (CSR) sparse matrix

Please use the following interface to access this data in case model is changed in future
 - `row_pointers(mat)` returns that sparse row_pointer vector see description
    which has a length of rows+1
 - `colvals` this is the column version of `rowvals(SparseMatrixCSC)`
 - `row_nonzeros` this is the equivilent to `nonzeros(SparseMatrixCSC)`
"""

const CSRMatrix{T} = Transpose{T,SparseMatrixCSC{T,Int}} where T

function CSRMatrix{T}(row_pointers, columns, coefficients) where T
    @assert length(columns) == length(coefficients)
    @assert length(columns) + 1 == row_pointers[end]
    transpose(SparseMatrixCSC{T,Int}(maximum(columns), length(row_pointers)-1, row_pointers, columns, coefficients))
end

#   Move access to an interface so that if we want to change type definition we can.
colvals(mat::CSRMatrix) = rowvals(transpose(mat))
row_pointers(mat::CSRMatrix) = transpose(mat).colptr  # This is the only way to get at colptrs without recreating it
row_nonzeros(mat::CSRMatrix) = nonzeros(transpose(mat))

#=
    Below we add constraints.
=#

include("constraints/singlevariable.jl")
include("constraints/vectorofvariables.jl")
include("constraints/scalaraffine.jl")
include("constraints/vectoraffine.jl")
include("constraints/scalarquadratic.jl")
