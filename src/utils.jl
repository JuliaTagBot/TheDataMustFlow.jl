
# this function works for anything with a schema field
colidx(f, cols::AbstractVector{Symbol}) = Int[f.schema[string(n)] for n ∈ cols]


#=========================================================================================
    <BatchIterator>
=========================================================================================#
function _N_batches(idx::AbstractVector{<:Integer}, ℓ::Integer)
    (l, m) = divrem(length(idx), ℓ)
    l + Int(m > 0)
end


# TODO consider implementing entire AbstractVector interface
# TODO handle truncations
struct BatchIterator{T<:Integer,K<:AbstractVector{T}}
    idx::K
    ℓ::Int  # batch length

    N::Int  # number of batches

    function (BatchIterator{T,K}(idx::AbstractVector{T}, ℓ::Integer)
              where {T<:Integer,K<:AbstractVector{T}})
        new(convert(K, idx), ℓ, _N_batches(idx, ℓ))
    end
end

function BatchIterator{T<:Integer,K<:AbstractVector{T}}(idx::K, ℓ::Integer)
    BatchIterator{T,K}(idx, ℓ)
end


Base.start(iter::BatchIterator) = 1

function Base.next{T,K<:AbstractUnitRange{T}}(iter::BatchIterator{T,K}, state::Int)
    a = iter.idx[1] + iter.ℓ*(state-1)
    b = min(iter.idx[end], iter.idx[1] + iter.ℓ*state - 1)
    (a:b, state+1)
end

function Base.next{T,K<:AbstractVector{T}}(iter::BatchIterator{T,K}, state::Int)
    a = iter.ℓ*(state-1) + 1
    b = min(length(iter.idx), iter.ℓ*state)
    (iter.idx[a:b], state+1)
end

Base.done(iter::BatchIterator, state::Integer) = state > iter.N


function batchiter(idx::AbstractVector{<:Integer}, batch_size::Integer)
    BatchIterator(idx, batch_size)
end
#=========================================================================================
    </BatchIterator>
=========================================================================================#


