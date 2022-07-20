using Test
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


function equal_s(a::AbstractString, b::AbstractString)
    a = strip(a)
    b = strip(b)
    xs_a = split(a, "\n")
    xs_b = split(b, "\n")
    if length(xs_a) != length(xs_b)
        return false
    end
    for i in eachindex(xs_a)
        x_a = xs_a[i]
        x_b = xs_b[i]
        if rstrip(x_a) != rstrip(x_b)
            return false
        end
    end
    return true
end

@testset "PrettyDoc.jl" begin
    # Write your tests here.

    @testset "render" begin
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

        @test equal_s(string(render_block(block)), strip(raw"""
A {
    C "ccc"
    B {
        C "ccc"
    }
    C "ccc"
    C "ccc"
}
"""))
    end

end
