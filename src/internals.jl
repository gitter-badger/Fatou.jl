#   This file is part of Fatou.jl. It is licensed under the MIT license
#   Copyright (C) 2017 Michael Reed

if !(VERSION < v"0.6.0")
    import Base: invokelatest
end

funk(r::String) = :((z,c)->$(parse(r))) # unleash the funK
funK(r::String) = :((z,n,p)->$(parse(r))) # double funky

#matU(mat::Tuple{UInt8,Complex{Float64}})::UInt8 = mat[1]
#matF(mat::Tuple{UInt8,Complex{Float64}})::Complex{Float64} = mat[2]

"""
    sym2fun(expr,type)

Generate typed function code by constructing its lambda expression.

# Examples
```Julia
julia> Fatou.sym2fun(
           ((z,c)->z^2+c)(SymPy.Sym(:a),SymPy.Sym(:b)),
           :(Complex{Float64}))
:(function ##001(a::Complex{Float64},b::Complex{Float64},zargs...)
        b + a ^ 2
    end)

```
"""
sym2fun(expr,typ) = Expr(:function, Expr(:call, gensym(),
        map(s->Expr(:(::),s,typ),sort!(Symbol.(free_symbols(expr))))..., Expr(:(...),:zargs)),
    SymPy.walk_expression(expr))

# we can substitute the expression into Newton's method and display it with LaTeX
function newton_raphson(f::Function,m)
    return (VERSION < v"0.6.0") ?
        sym2fun(Sym(:z)-m*f(Sym(:z),Sym(:c))/diff(f(Sym(:z),Sym(:c))),:Any) |> eval :
        sym2fun(Sym(:z)-m*invokelatest(f,Sym(:z),Sym(:c))/diff(invokelatest(f,Sym(:z),Sym(:c))),:Any) |> eval
end

# define recursive composition on functions
function recomp(f::Function,x::Number,j::Int)
    if VERSION < v"0.6.0" # backwards compatability
        return j > 1 ? f(recomp(f,x,j-1),0) : f(x,0)
    else
        return j > 1 ? invokelatest(f,recomp(f,x,j-1),0) : invokelatest(f,x,0)
    end
end
# we can convert the j-th function composition into a latex expresion
nL(f::Function,m,j) = recomp(newton_raphson(f,m),Sym(:z),j) |> SymPy.latex
jL(f::Function,j) = recomp(f,Sym(:z),j) |> SymPy.latex

# set of points that are within an ϵ neighborhood of the roots ri of the function f
ds = "\\displaystyle"
set0 = "D_0(\\epsilon) = \\left\\{ z\\in\\mathbb{C}: \\left|\\,z"
setj(j) = "$ds D_$j(\\epsilon) = \\left\\{z\\in\\mathbb{C}:\\left|\\,"
nsetstr = "- r_i\\,\\right|<\\epsilon,\\,\\forall r_i(\\,f(r_i)=0 )\\right\\}"
jsetstr = "\\,\\right|>\\epsilon\\right\\}"
nset0 = latexstring("$set0 $nsetstr")
jset0 = latexstring("$set0 $jsetstr")
nrset(f::Function,m,j) = latexstring(
    j == 0 ? "$set0 $nsetstr":"$(setj(j))$(nL(f,m,j)) $nsetstr")
jset(f::Function,j) = latexstring(
    j == 0 ? "$set0 $jsetstr":"$(setj(j))$(jL(f,j)) $jsetstr")
