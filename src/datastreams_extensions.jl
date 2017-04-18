
vectortype{T}(::Type{T}) = Vector{T}
vectortype{T}(::Type{Nullable{T}}) = NullableVector{T}

coltype(sch::Data.Schema, i::Integer) = vectortype(Data.types(sch)[i])
function coltypes(sch::Data.Schema, cols::AbstractVector{<:Integer})
    DataType[coltype(sch, c) for c ∈ cols]
end
coltypes(sch::Data.Schema) = coltypes(sch, 1:length(Data.header(sch)))

# this will hopefully get implemented in DataStreams some day
function streamfrom{T}(src, ::Type{Data.Column}, ::Type{Vector{T}},
                       rows::AbstractVector{<:Integer}, col::Integer)
    [Data.streamfrom(src, Data.Field, T, i, col) for i ∈ rows]::Vector{T}
end
function streamfrom{T}(src, ::Type{Data.Column}, ::Type{NullableVector{T}},
                       rows::AbstractVector{<:Integer}, col::Integer)
    # TODO wow, this is bad
    # can't fix without updating DataStreams standard
    o = [Data.streamfrom(src, Data.Field, Nullable{T}, i, col) for i ∈ rows]
    convert(NullableArray, o)::NullableVector{T}
end


# TODO user needs to have option about whether to use this
_apply_nolift(f::Function, v::AbstractVector) = f.(v)
function _apply_nolift(f::Function, v::NullableVector)
    o = Vector{Bool}(length(v))
    for i ∈ 1:length(v)
        o[i] = v.isnull[i] ? false : f(v.values[i])
    end
    o
end

function sift{T}(src, f::Function, ::Type{T}, i::Integer, ab::AbstractVector{<:Integer})
    _apply_nolift(f, streamfrom(src, Data.Column, T, ab, i))::AbstractVector{Bool}
end


