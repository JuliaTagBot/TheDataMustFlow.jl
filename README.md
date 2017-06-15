
<a id='TheDataMustFlow-1'></a>

# TheDataMustFlow


[![Build Status](https://travis-ci.org/ExpandingMan/TheDataMustFlow.jl.svg?branch=master)](https://travis-ci.org/ExpandingMan/TheDataMustFlow.jl)


[![Coverage Status](https://coveralls.io/repos/ExpandingMan/TheDataMustFlow.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/ExpandingMan/TheDataMustFlow.jl?branch=master)


[![codecov.io](http://codecov.io/github/ExpandingMan/TheDataMustFlow.jl/coverage.svg?branch=master)](http://codecov.io/github/ExpandingMan/TheDataMustFlow.jl?branch=master)


> "Without the data the navigators will be blind, the Bene Gesserit will lose all power, civilization will end.  If I am not obeyed, the data will not flow." -Muad'Dib



`TheDataMustFlow` is a package for applying transformations to array-indexable tabular data and collecting said data into arrays.  By "array-indexable" we mean that the row and column of a datum can be specified by an integer pair.  It is assumed that the use of `TheDataMustFlow` will be preceded by some data manipulation which involves joins and or aggregations, but is otherwise fairly minimal.  `TheDataMustFlow` is designed to address the difficulty of transforming data into machine-readable arrays but also has general functionality for mapping between tabular formats.


<a id='API-Docs-1'></a>

## API Docs

<a id='TheDataMustFlow.Morphism' href='#TheDataMustFlow.Morphism'>#</a>
**`TheDataMustFlow.Morphism`** &mdash; *Type*.



**Type: `Morphism{T<:MapDirection}`**

This is a type for wrapping functions which transfer data to and from a tabular data format which implements the [DataStreams](https://github.com/JuliaData/DataStreams.jl) interface.  The primary functionality involves creating a function which takes an index as an argument and either feeds data to a data sink or extracts data from a source, while passing the data through a function.

**Constructors**

```julia
Morphism{T<:MapDirection}(s, sch::Data.Schema, cols::AbstractVector,
                          funcs::AbstractVector)`
Morphism{T<:MapDirection}(s, cols::AbstractVector, funcs::AbstractVector)`
Morphism{T<:MapDirection}(s, cols::AbstractVector, f::Function)`
```

**Arguments**

  * `T<:MapDirection`: This is either `Pull` or `Push`. A `Morphism{Pull}`   is for extracting data from a table, a `Morphism{Push}` is for injecting   data into a table.
  * `s`: The source (in the `Pull` case) or sink (in the `Push` case). This must   be a tabular data format implementing the `DataStreams` interface.
  * `sch`: A `Data.Schema` schema generated from `s`.  If this argument is omitted, a   schema will be generated within the `Morphism` constructor.
  * `cols`: A vector of tuples, each containing column designations.  These designations can   be either `Integer`, `Symbol` or `String`.  If only a single function is being passed   to the constructor, one can instead pass a vector of column designations.
  * `funcs`: Functions to be applied to the data passing into, or being taken out of `s`.   The `cols` argument should contain a tuple for each such function.
  * `f`: If only a single function is being used, one can pass a single function which is   not wrapped in a vector.  In this case, `cols` should contain column designations   rather than tuples.

**Notes**

`Morphism` is the base type on which other objects such as `Harvester` `Sower` and `StreamFilter` in `TheDataMustFlow` are based.  Abstractly, it represents any function applied to tabular data composed with a data transfer.  See the function constructor function `morphism` for more details.

***TODO:*** Macros are coming!

**Examples**

```julia
# this extracts columns 1,2,3 and does nothing to them
I = Morphism{Pull}(data, [1,2,3], identity)  # we have overriden identity to return
                                             # tuples for multiple arguments
i = morphism(I)  # this is the function for pulling data
k, = i(1:10)  # this returns rows 1 through 10. note that always returns a tuple
              # here k is itself a tuple

f(x,y) = x .+ y
g(x,y) = x .- y
M = Morphism{Pull}(src, [(1,2), (3,4)], [f, g])
m = morphism(M)  # again, this is the function for pulling data
α, β = m(8:12)  # here α is the sum of columns 1,2 rows 8 through 12
                # β is the difference of columns 3,4 rows 8 through 12

# this inserts exactly what you give it into columns 3, 4
I = Morphism{Push}(data, [3,4], identity)
i = morphism(M)  # this is the function for feeding data
i(1:3, ones(3,2))  # this inserts ones into columns 3,4 rows 1 through 3

h₁(x) = [x+1, x+2]
h₂(x) = [x+3, x+4]
m = morphism(Push, data, [(3,4), (5,6)], [h₁,h₂])  # you can bypass the Morphism constructor
m(4:6, ones(3), 2ones(3))  # this puts numbers into columns 3,4,5,6
```

Note that the functions passed to `Pull` `Morphism`s accept as many arguments as there are column specified for them and that `Push` `Morphism`s can take functions that return either matrices or vectors of vectors (or tuples).  See `morphism` for more information.

<a id='TheDataMustFlow.Harvester' href='#TheDataMustFlow.Harvester'>#</a>
**`TheDataMustFlow.Harvester`** &mdash; *Type*.



**Type: `Harvester <: AbstractMorphism{Pull}`**

This is a type for pulling data from a tabular data source that implements the `DataStreams` interface in a format amenable to machine learning input (a simple array).

**Constructors**

```julia
Harvester(s, ::Type{T}, sch::Data.Schema, matrix_cols::AbstractVector{Symbol}...;
          null_replacement=nothing)
Harvester(s, ::Type{T}, matrix_cols::AbstractVector{Symbol}...;
          null_replacement=nothing)
```

**Arguments**

  * `s`: The tabular data source to pull data from. Must implement the `DataStreams` interface.
  * `T`: The element type of the matrix returned by the harvester.  In most cases this will   be either `Float32` or `Float64`.
  * `sch`: A `Data.Schema` schema for `s`.  If this is not provided, it will be generated.
  * `matrix_cols`: A variable length argument. The function created by the `Harvester` will   return a matrix for each `matrx_cols` argument.
  * `null_replacement`: A function or value for replacing nulls. Can only provide a zero-   argument function which will be called for every null it replaces. Alternatively, a   value will replace all nulls.  If `nothing`, no null substitution will be attempted.

**Examples**

```julia
h = Harvester(src, Float32, [:A, :B], [:C, :D])
harvest = harvester(h)
X, y = harvest(1000:1200)  # X and y are matrices produced from rows 1000 through 1200

# can bypass constructor; replace nulls with random numbers in [0, 1]
harvest = harvester(src, Float32, [:A, :B], null_replacement=rand)
X, = harvest(1:10^6)  # note that these always return tuples
```

<a id='TheDataMustFlow.Sower' href='#TheDataMustFlow.Sower'>#</a>
**`TheDataMustFlow.Sower`** &mdash; *Type*.



**Type: `Sower <: AbstractMorphism{Push}`**

This is a type for injecting data into a tabular data sink that implements the `DataStreams` sink interface.

**Constructors**

```julia
Sower(s, sch::Data.Schema, cols::AbstractVector)
Sower(s, cols::AbstractVector)
```

**Arguments**

  * `s`: The tabular data sink to inject data into. Must implement the `DataStreams` sink   interface.
  * `sch`: A `Data.Schema` for `s`. If it is not provided, it will be generated.
  * `cols`: The columns the provided matrices will be injected into. If multiple matrices   are being provided, the elements of this should be tuples.

**Examples**

```julia
X = rand(100, 2)

sow = sower(sink, [:γ, :δ])  # can bypass Sower constructor
sow!(1:100, X)  # the first column of X goes to :γ, second column goes to :δ
```

<a id='TheDataMustFlow.StreamFilter' href='#TheDataMustFlow.StreamFilter'>#</a>
**`TheDataMustFlow.StreamFilter`** &mdash; *Type*.



**Type: `StreamFilter <: AbstractMorphism{Pull}`**

A `StreamFilter` is an implementation of an `AbstractMorphism{Pull}` which is designed for determining which rows of a data table satisfy certain criteria.  It is intended that one of these be used to determine which index arguments should be passed to other methods, for example the results of `Morphism`, `Harvester` or `Sower`.

**Constructors**

```julia
StreamFilter(s, cols::AbstractVector, filterfuncs::AbstractVector{Function};
             lift_nulls::Bool=true, logical_op::Function=(&))
StreamFilter(s; lift_nulls::Bool=true, logical_op::Function=(&);
             kwargs...)
```

**Arguments**

  * `s`: The source, which must be a tabular data format implementing the `DataStreams`   interface.
  * `cols`: The columns which are relevant to the filter.  This should be a vector of   integers or symbols.
  * `filterfuncs`: Functions which will be applied to each colum. These should act on a single   column element and return `Bool`.
  * `lift_nulls`: Whether the functions should be appied to `Nullable` or the elements they   contain.  If `lift_nulls` is true, rows with nulls present will not be included.
  * `logical_op`: The logical operator combining columns.  For example, if `(&)`, the results   of the filtering will return only rows for which *all* functions return true.
  * `kwargs...`: One can instead pass functions using the column they are to be associated   with as a keyword.  For example `Column1=f1, Column2=f2`.

**Notes**

The function which implements the `StreamFilter` can be obtained by doing `streamfilter`. Alternatively, one may wish to run the filter on an entire dataset by doing `filterall`.

**Examples**

```julia
sfilter = StreamFilter(src, Col1=(i -> i % 2 == 0), Col2=(i -> i % 3 == 0))
bfilt = streamfilter(sfilter, Bool)
bfilt(1:100)  # will return a Vector{Bool} which is only true where
              # Col1 is a multiple of 2 and Col2 is a multiple of 3 for rows 1 through 100

filt = streamfilter(sfilter)
filt(1:100)  # will return a Vector{Int} containing the numbers of rows where
             # Col1 is a multiple of 2 and Col2 is a multiple of 3 for rows 1 through 100
```

<a id='TheDataMustFlow.batchiter' href='#TheDataMustFlow.batchiter'>#</a>
**`TheDataMustFlow.batchiter`** &mdash; *Function*.



**`batchiter`**

```
batchiter([f::Function], idx::AbstractVector{<:Integer}, batch_size::Integer)
```

Returns an iterator over batches.  If a function is provided, this will apply the function to the batches created from the indices `idx` with batch size `batch_size`.

<a id='TheDataMustFlow.batchiter-Tuple{TheDataMustFlow.StreamFilter,AbstractArray{#s4,1} where #s4<:Integer}' href='#TheDataMustFlow.batchiter-Tuple{TheDataMustFlow.StreamFilter,AbstractArray{#s4,1} where #s4<:Integer}'>#</a>
**`TheDataMustFlow.batchiter`** &mdash; *Method*.



**`StreamFilter`**

```
batchiter(f::StreamFilter, idx::AbstractVector{<:Integer}; batch_size::Integer=DEFAULT)
```

Returns an iterator over batches returning the valid indices within each batch.

<a id='TheDataMustFlow.filterall-Union{Tuple{T}, Tuple{Union{Function, TheDataMustFlow.StreamFilter},AbstractArray{T,1}}} where T<:Integer' href='#TheDataMustFlow.filterall-Union{Tuple{T}, Tuple{Union{Function, TheDataMustFlow.StreamFilter},AbstractArray{T,1}}} where T<:Integer'>#</a>
**`TheDataMustFlow.filterall`** &mdash; *Method*.



```
filterall(f::StreamFilter, idx::AbstractVector{<:Integer}; batch_size::Integer=DEFAULT)
```

Determine the indices selected by the `StreamFilter`.  These indices will be members of `idx` for which the `StreamFilter` source satisfies the functions in was created with.

<a id='TheDataMustFlow.harvester-Tuple{TheDataMustFlow.Harvester}' href='#TheDataMustFlow.harvester-Tuple{TheDataMustFlow.Harvester}'>#</a>
**`TheDataMustFlow.harvester`** &mdash; *Method*.



```
harvester(h::Harvester)
```

Returns a function `harvest(idx)` which will return matrices generated from the rows specified by `idx`.

<a id='TheDataMustFlow.morphism-Union{Tuple{D}, Tuple{R}, Tuple{Type{D},Any,DataStreams.Data.Schema,AbstractArray{#s1,1} where #s1<:Tuple,AbstractArray{#s11,1} where #s11<:Function,Type{R}}, Tuple{Type{D},Any,DataStreams.Data.Schema,AbstractArray{#s3,1} where #s3<:Tuple,AbstractArray{#s2,1} where #s2<:Function}} where R where D<:TheDataMustFlow.MapDirection' href='#TheDataMustFlow.morphism-Union{Tuple{D}, Tuple{R}, Tuple{Type{D},Any,DataStreams.Data.Schema,AbstractArray{#s1,1} where #s1<:Tuple,AbstractArray{#s11,1} where #s11<:Function,Type{R}}, Tuple{Type{D},Any,DataStreams.Data.Schema,AbstractArray{#s3,1} where #s3<:Tuple,AbstractArray{#s2,1} where #s2<:Function}} where R where D<:TheDataMustFlow.MapDirection'>#</a>
**`TheDataMustFlow.morphism`** &mdash; *Method*.



```
morphism(M::AbstractMorphism)
```

This returns a function that executes the transformations specified by `M`.  Note that one can pass the arguments to the cunstructor of a `Morphism` to `morphism` directly, obviating the need to write the `Morphism` constructor separately.  The function returned by `morphism` accepts different arguments depending on whether `M` is `Push` or `Pull`

**`Pull`**

If the `AbstractMorphism` passed to `morphism` is of `Pull` type, then the function `m` returned by `morphism` will accept only a single argument.  That argument must be an `AbstractVector{<:Integer}` containing the rows of the table which are to be pulled from. The functions passed to `M` will be applied to the appropriate columns, only for the rows specified.  See `Morphism` for more detail.

**`Push`**

If the `AbstractMorphism` passed to `morphism` is of `Push` type, then the function `m` returned by `morphism` will accept an `AbstractVector{<:Integer}` index argument followed by one argument for each function `M` was constructed with.  See `Morphism` for more details.

<a id='TheDataMustFlow.sower-Tuple{TheDataMustFlow.Sower}' href='#TheDataMustFlow.sower-Tuple{TheDataMustFlow.Sower}'>#</a>
**`TheDataMustFlow.sower`** &mdash; *Method*.



```
sower(s::Sower)
```

Returns a function `sow(idx, X...)` which will accept matrices `X` and map them into the rows specified by `idx` and columns specified by the `Sower`.

<a id='TheDataMustFlow.streamfilter-Tuple{TheDataMustFlow.StreamFilter,Type{Bool}}' href='#TheDataMustFlow.streamfilter-Tuple{TheDataMustFlow.StreamFilter,Type{Bool}}'>#</a>
**`TheDataMustFlow.streamfilter`** &mdash; *Method*.



```
streamfilter(sf::StreamFilter[, ::Type{Bool}])
```

Returns a function that applies the functions provided by streamfilter to rows in a range. The function returned can be called like `filt(idx)` where `idx` is an `AbstractVector` of indices.  If `Bool` is passed, `filt` will return a `Vector{Bool}` with elements that are true only for rows which satisfy the requirements.  Otherwise, a vector of the row numbers will be returned.

Optionally, one can pass the arguments for the `StreamFilter` constructor directly to this function.

