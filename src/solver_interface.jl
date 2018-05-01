#=
    This file contains all of the functions that a solver needs to implement
    in order to use LQOI.

       min/max: c'x + x'Qx
    subject to:
                # Variable bounds
                abᵢ <=  xᵢ              <= bbᵢ, i=1,2,...Nx
                # Linear Constraints
                llᵢ <= alᵢ'x             <= ulᵢ, i=1,2,...Nl
                # Quadratic Constraints
                lqᵢ <= aqᵢ' x + x'Qqᵢ' x <= uqᵢ, i=1,2,...Nq
                # SOS1, SOS2 constraints
                # Binary Constraints
                xᵢ ∈ {0, 1}
                # Integer Constraints
                xᵢ ∈ Z
=#

"""
    lqs_char(m, ::MOI.AbstractSet)::CChar

Return a Cchar specifiying the constraint set sense.

Interval constraints are sometimes called range constraints and have the form
`l <= a'x <= u`

Three are special cases:
 - `Val{:Continuous}`: Cchar for a continuous variable
 - `Val{:Upperbound}`: Cchar for the upper bound of a variable
 - `Val{:Lowerbound}`: Cchar for the lower bound of a variable

### Defaults

    MOI.GreaterThan  - 'G'
    MOI.LessThan     - 'L'
    MOI.EqualTo      - 'E'
    MOI.Interval     - 'R'

    MOI.Zeros        - 'E'
    MOI.Nonpositives - 'L'
    MOI.Nonnegatives - 'G'

    MOI.ZeroOne - 'B'
    MOI.Integer - 'I'

    MOI.SOS1 - :SOS1  # '1'
    MOI.SOS2 - :SOS2  # '2'

    Val{:Continuous} - 'C'
    Val{:Upperbound} - 'U'
    Val{:Lowerbound} - 'L'
"""
lqs_char(m::LinQuadOptimizer, ::MOI.GreaterThan{T}) where T = Cchar('G')
lqs_char(m::LinQuadOptimizer, ::MOI.LessThan{T}) where T    = Cchar('L')
lqs_char(m::LinQuadOptimizer, ::MOI.EqualTo{T}) where T     = Cchar('E')
lqs_char(m::LinQuadOptimizer, ::MOI.Interval{T}) where T    = Cchar('R')

lqs_char(m::LinQuadOptimizer, ::MOI.Zeros)        = Cchar('E')
lqs_char(m::LinQuadOptimizer, ::MOI.Nonpositives) = Cchar('L')
lqs_char(m::LinQuadOptimizer, ::MOI.Nonnegatives) = Cchar('G')

lqs_char(m::LinQuadOptimizer, ::MOI.ZeroOne) = Cchar('B')
lqs_char(m::LinQuadOptimizer, ::MOI.Integer) = Cchar('I')

lqs_char(m::LinQuadOptimizer, ::MOI.SOS1{T}) where T = :SOS1  # Cchar('1')
lqs_char(m::LinQuadOptimizer, ::MOI.SOS2{T}) where T = :SOS2  # Cchar('2')


lqs_char(m::LinQuadOptimizer, ::Val{:Continuous}) = Cchar('C')
lqs_char(m::LinQuadOptimizer, ::Val{:Upperbound}) = Cchar('U')
lqs_char(m::LinQuadOptimizer, ::Val{:Lowerbound}) = Cchar('L')

"""
    LinQuadModel(M::Type{<:LinQuadOptimizer}, env)

Initializes a model given a model type `M` and an `env` that might be a `nothing`
for some solvers.
"""
function LinQuadModel end
#
# """
#     lqs_setparam!(m, name, val)::Void
#
# Set the parameter `name` to `val` for the model `m`.
# """
# function lqs_setparam!(m::LinQuadOptimizer, name, val) end
#
# """
#     lqs_setlogfile!(m, path::String)::Void
#
# Set the log file to `path` for the model `m`.
# """
# function lqs_setlogfile!(m::LinQuadOptimizer, path) end
#
# # TODO(@joaquimg): what is this?
# function lqs_getprobtype(m::LinQuadOptimizer) end

"""
    lqs_supported_constraints(m)::Vector{
        Tuple{MOI.AbstractFunction, MOI.AbstractSet}
    }

Get a list of supported constraint types in the model `m`.

For example, `[(LQOI.Linear, LQOI.EQ)]`
"""
lqs_supported_constraints(m::LinQuadOptimizer) = []

"""
    lqs_supported_objectives(m)::Vector{MOI.AbstractScalarFunction}

Get a list of supported objective types in the model `m`.

For example, `[LQOI.Linear, LQOI.Quad]`
"""
lqs_supported_objectives(m::LinQuadOptimizer) = []

# Constraints

function lqs_chgbds!(m::LinQuadOptimizer, colvec, valvec, sensevec) end

"""
    get_variable_lowerbound(m, col::Int)::Float64

Get the lower bound of the variable in 1-indexed column `col` of the model `m`.
"""
function get_variable_lowerbound end
@deprecate lqs_getlb get_variable_lowerbound

"""
    get_variable_upperbound(m, col::Int)::Float64

Get the upper bound of the variable in 1-indexed column `col` of the model `m`.
"""
function get_variable_upperbound end
@deprecate lqs_getub get_variable_upperbound

"""
    get_number_linear_constraints(m)::Int

Get the number of linear constraints in the model `m`.
"""
function get_number_linear_constraints(m::LinQuadOptimizer) end
@deprecate lqs_getnumrows get_number_linear_constraints

"""
    add_linear_constraints!(m, rows::Vector{Int}, cols::Vector{Int},
        coefs::Vector{Float64},
        sense::Vector{Cchar}, rhs::Vector{Float64})::Void

Adds linear constraints of the form `Ax (sense) rhs` to the model `m`.

The A matrix is given in triplet form `A[rows[i], cols[i]] = coef[i]` for all
`i`, and `length(rows) == length(cols) == length(coefs)`.

The `sense` is given by `lqs_char(m, set)`.

Ranged constraints (`set=MOI.Interval`) require a call to `lqs_chgrngval!`.
"""
function add_linear_constraints!(m::LinQuadOptimizer, rows, cols, coefs, sense, rhs) end
@deprecate lqs_addrows! add_linear_constraints!

"""
    get_rhs(m, row::Int)::Float64

Get the right-hand side of the linear constraint in the 1-indexed row `row` in
the model `m`.
"""
function get_rhs(m::LinQuadOptimizer, row) end
@deprecate lqs_getrhs get_rhs

"""
    get_linear_constraint(m, row::Int)::Tuple{Vector{Int}, Vector{Float64}}

Get the linear component of the constraint in the 1-indexed row `row` in
the model `m`. Returns a tuple of `(cols, vals)`.
"""
function get_linear_constraint(m::LinQuadOptimizer, row) end
@deprecate lqs_getrows get_linear_constraint

"""
    lqs_getcoef(m, row::Int, col::Int)::Float64

Get the linear coefficient of the variable in column `col`, constraint `row`.
"""
function lqs_getcoef(m::LinQuadOptimizer, row, col) end

"""
    lqs_chgcoef(m, row::Int, col::Int, coef::Float64)::Void

Set the linear coefficient of the variable in column `col`, constraint `row` to
`coef`.
"""
function lqs_chgcoef!(m::LinQuadOptimizer, row, col, coef) end

"""
    lqs_delrows!(m, start_row::Int, end_row::Int)::Void

Delete the linear constraints `start_row`, `start_row+1`, ..., `end_row` from
the model `m`.
"""
function lqs_delrows!(m::LinQuadOptimizer, start_row, end_row) end

"""
    lqs_chgctype(m, cols::Vector{Int}, types::Vector{Symbol})::Void

Change the variable types. Variable type must be `:CONTINUOUS`, `:INTEGER`, or
`:BINARY`.
"""
function lqs_chgctype!(m::LinQuadOptimizer, cols, types) end

"""
    lqs_chgsense(m, rows::Vector{Int}, sense::Vector{Symbol})::Void

Change the sense of the linear constraints in `rows` to `sense`.

The `sense` is one of `:RANGE`, `:LOWER`, `:UPPER`, `:EQUALITY`.

Ranged constraints (sense=`:RANGE`) require a call to `lqs_chgrngval!`.
"""
function lqs_chgsense!(m::LinQuadOptimizer, rows, sense) end

"""
    lqs_make_problem_type_integer(m)::Void

If an explicit call is needed to change the problem type integer (e.g., CPLEX).
"""
function lqs_make_problem_type_integer(m::LinQuadOptimizer) end

"""
    lqs_make_problem_type_continuous(m)::Void

If an explicit call is needed to change the problem type continuous (e.g., CPLEX).
"""
function lqs_make_problem_type_continuous(m::LinQuadOptimizer) end

"""
    lqs_addsos!(m, cols::Vector{Int}, vals::Vector{Float64}, typ::Symbol)::Void

Add the SOS constraint to the model `m`. `typ` is either `:SOS1` or `:SOS2`.
"""
function lqs_addsos!(m::LinQuadOptimizer, cols, vals, typ) end

"""
    lqs_delrows!(m, start_idx::Int, end_idx::Int)::Void

Delete the SOS constraints `start_idx`, `start_idx+1`, ..., `end_idx` from
the model `m`.
"""
function lqs_delsos!(m::LinQuadOptimizer, start_idx, end_idx) end

"""
    lqs_getsos(m, idx::Int)::Tuple{Vector{Int}, Vector{Float64}, Symbol}

Get the SOS constraint `idx` from the model `m`. Returns the triplet
    `(cols, vals, typ)`.
"""
function lqs_getsos(m::LinQuadOptimizer, idx) end

"""
    lqs_getnumqconstrs(m)::Int

Get the number of quadratic constraints in the model `m`.
"""
function lqs_getnumqconstrs(m::LinQuadOptimizer) end

"""
    lqs_addqconstr!(m, cols::Vector{Int}, coefs::Vector{Float64}, rhs::Float64,
        sense::Symbol, I::Vector{Int}, J::Vector{Int}, V::Vector{Float64})::Void

Add a quadratic constraint `a'x + 0.5 x' Q x`.
See `add_linear_constraints!` for information of linear component.
Arguments `(I,J,V)` given in triplet form for the Q matrix in `0.5 x' Q x`.
"""
function lqs_addqconstr!(m::LinQuadOptimizer, cols, coefs, rhs, sense, I, J, V) end


"""
    lqs_chgrngval!(m, rows::Vector{Int}, vals::Vector{Float64})::Void

A range constraint `l <= a'x <= u` is added as the linear constraint
`a'x :RANGED l`, then this function is called to set `u - l`, the range value.

See `add_linear_constraints!` for more.
"""
function lqs_chgrngval!(m::LinQuadOptimizer, rows, vals) end# later

#Objective
"""
    lqs_chgobj!(m, I::Vector{Int}, J::Vector{Int}, V::Vector{Float64})::Void

Set the quadratic component of the objective. Arguments given in triplet form
for the Q matrix in `0.5 x' Q x`.
"""
function lqs_copyquad!(m::LinQuadOptimizer, I, J, V) end

"""
    lqs_chgobj!(m, cols::Vector{Int}, coefs::Vector{Float64})::Void

Set the linear component of the objective.
"""
function lqs_chgobj!(m::LinQuadOptimizer, cols, coefs) end

"""
    lqs_chgobjsen(m, sense::Symbol)::Void

Change the optimization sense of the model `m` to `sense`. `sense` must be
`:min` or `:max`.
"""
function lqs_chgobjsen!(m::LinQuadOptimizer, sense) end

#TODO(@joaquimg): why is this not in-place?
"""
    lqs_getobj(m)::Vector{Float64}

Change the linear coefficients of the objective.
"""
function lqs_getobj(m::LinQuadOptimizer) end

"""
    lqs_getobjsen(m)::MOI.OptimizationSense

Get the optimization sense of the model `m`.
"""
function lqs_getobjsen(m::LinQuadOptimizer) end

#Solve

"""
    lqs_mipopt!(m)::Void

Solve a mixed-integer model `m`.
"""
function lqs_mipopt!(m::LinQuadOptimizer) end

"""
    lqs_qpopt!(m)::Void

Solve a model `m` with quadratic components.
"""
function lqs_qpopt!(m::LinQuadOptimizer) end

"""
    lqs_lpopt!(m)::Void

Solve a linear program `m`.
"""
function lqs_lpopt!(m::LinQuadOptimizer) end

# TODO(@joaquim): what is this?
function lqs_getstat(m::LinQuadOptimizer) end

# TODO(@joaquim): what is this?
function lqs_solninfo(m::LinQuadOptimizer) end # complex

"""
    lqs_getx!(m, x::Vector{Float64})

Get the primal solution for the variables in the model `m`, and
store in `x`. `x`must have one element for each variable.
"""
function lqs_getx!(m::LinQuadOptimizer, x) end

"""
    lqs_getax!(m, x::Vector{Float64})

Given a set of linear constraints `l <= a'x <= b` in the model `m`, get the
constraint primal `a'x` for each constraint, and store in `x`.
`x` must have one element for each linear constraint.
"""
function lqs_getax!(m::LinQuadOptimizer, x) end

"""
    lqs_getqcax!(m, x::Vector{Float64})

Given a set of quadratic constraints `l <= a'x + x'Qx <= b` in the model `m`,
get the constraint primal `a'x + x'Qx` for each constraint, and store in `x`.
`x` must have one element for each quadratic constraint.
"""
function lqs_getqcax!(m::LinQuadOptimizer, x) end

"""
    lqs_getdj!(m, x::Vector{Float64})

Get the dual solution (reduced-costs) for the variables in the model `m`, and
store in `x`. `x`must have one element for each variable.
"""
function lqs_getdj!(m::LinQuadOptimizer, x) end

"""
    lqs_getpi!(m, x::Vector{Float64})

Get the dual solution for the linear constraints in the model `m`, and
store in `x`. `x`must have one element for each linear constraint.
"""
function lqs_getpi!(m::LinQuadOptimizer, x) end

"""
    lqs_getqcpi!(m, x::Vector{Float64})

Get the dual solution for the quadratic constraints in the model `m`, and
store in `x`. `x`must have one element for each quadratic constraint.
"""
function lqs_getqcpi!(m::LinQuadOptimizer, x) end

"""
    lqs_getobjval!(m)

Get the objective value of the solved model `m`.
"""
function lqs_getobjval(m::LinQuadOptimizer) end

# TODO(@joaquimg): what is this?
function lqs_getbestobjval(m::LinQuadOptimizer) end

"""
    lqs_getmiprelgap!(m)

Get the relative MIP gap of the solved model `m`.
"""
function lqs_getmiprelgap(m::LinQuadOptimizer) end

"""
    lqs_getitcnt!(m)

Get the number of simplex iterations performed during the most recent
optimization of the model `m`.
"""
function lqs_getitcnt(m::LinQuadOptimizer) end

"""
    lqs_getbaritcnt!(m)

Get the number of barrier iterations performed during the most recent
optimization of the model `m`.
"""
function lqs_getbaritcnt(m::LinQuadOptimizer) end

"""
    lqs_getnodecnt!(m)

Get the number of branch-and-cut nodes expolored during the most recent
optimization of the model `m`.
"""
function lqs_getnodecnt(m::LinQuadOptimizer) end

"""
    lqs_dualfarkas!(m, x::Vector{Float64})

Get the farkas dual (certificate of primal infeasiblility) for the linear constraints
in the model `m`, and store in `x`. `x`must have one element for each linear
constraint.
"""
function lqs_dualfarkas!(m::LinQuadOptimizer, x) end

"""
    lqs_getray!(m, x::Vector{Float64})

Get the unbounded ray (certificate of dual infeasiblility) for the linear constraints
in the model `m`, and store in `x`. `x`must have one element for each variable.
"""
function lqs_getray!(m::LinQuadOptimizer, x) end

"""
    lqs_terminationstatus(m)

Get the termination status of the model `m`.
"""
function lqs_terminationstatus(m::LinQuadOptimizer) end

"""
    lqs_primalstatus(m)

Get the primal status of the model `m`.
"""
function lqs_primalstatus(m::LinQuadOptimizer) end

"""
    lqs_dualstatus(m)

Get the dual status of the model `m`.
"""
function lqs_dualstatus(m::LinQuadOptimizer) end

# Variables
"""
    lqs_getnumcols(m)::Int

Get the number of variables in the model `m`.
"""
function lqs_getnumcols(m::LinQuadOptimizer) end

"""
    lqs_newcols!(m, n::Int)::Void

Add `n` new variables to the model `m`.
"""
function lqs_newcols!(m::LinQuadOptimizer, n) end

"""
    lqs_delcols!(m, start_col::Int, end_col::Int)::Void

Delete the columns `start_col`, `start_col+1`, ..., `end_col` from the model `m`.
"""
function lqs_delcols!(m::LinQuadOptimizer, start_col, end_col) end

"""
    lqs_addmipstarts!(m, cols::Vector{Int}, x::Vector{Float64})::Void

Add the MIP start `x` for the variables in the columns `cols` of the model `m`.
"""
function lqs_addmipstarts!(m::LinQuadOptimizer, cols, x) end