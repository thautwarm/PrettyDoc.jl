# PrettyDoc

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://thautwarm.github.io/PrettyDoc.jl/stable/) -->
[![API](https://img.shields.io/badge/docs-APIs-blue.svg)](https://thautwarm.github.io/PrettyDoc.jl/dev/)
[![Build Status](https://github.com/thautwarm/PrettyDoc.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/thautwarm/PrettyDoc.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/thautwarm/PrettyDoc.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/thautwarm/PrettyDoc.jl)


> The idea is to combine a Document out of many small components, then using a layouter to convert it to an easily renderable SimpleDocStream

This is an easy-to-use and lightweight text layout combinator library.

```julia
import PrettyDoc as PD
const squote = "\""
struct Block
    name::String
    contents::Union{String, Vector{Block}}
end

function render_block(self::Block)
    if self.contents isa Vector
        return PD.vsep(
            PD.seg(self.name) + PD.seg("{"),
            PD.vsep(map(render_block, self.contents)) >> 4,
            PD.seg("}")
        )
    end
    return PD.seg(self.name) + PD.seg(squote * escape_string(self.contents) * squote)
end

block = Block(
    "A",
    [
        Block("C", "ccc"),
        Block("B",
            [
                Block("C", "ccc"),
            ]
        ),
        Block("C", "ccc"),
        Block("C", "ccc"),
    ]
)

string(render_block(block))
```

=>

```
A {
    C "ccc"
    B {
        C "ccc"
    }
    C "ccc"
    C "ccc"
}
```


See [the API documentation](https://thautwarm.github.io/PrettyDoc.jl/dev/) for the available combinator functions.
