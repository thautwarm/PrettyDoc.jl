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

    @testset "breakable" begin

        s = repeat("1", 100)
        preferredLineWidth = 20
        opts = PD.RenderOptions(preferredLineWidth)
        new_io = IOBuffer()
        
        PD.render!(opts, PD.compileToPrims(
            PD.seg(s) * PD.breakable(PD.seg("next line"))
        )) do s
            write(new_io, s)
        end
        
        @test equal_s(String(take!(new_io)), raw"""
1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
next line
""")
    end

    @testset "align" begin
        mk_eq(x, y) = PD.seg(x) + PD.seg("=") + PD.seg(y)
        doc_o = PD.seg("begin") + PD.align(
            PD.vsep(
                mk_eq("x", "1"),
                mk_eq("y", "2"),
                mk_eq("z", "3"),
            )
        )
        @test equal_s(string(doc_o), raw"""
begin x = 1
      y = 2
      z = 3
""")
    
    end

    @testset "corner cases" begin 
        @test PD.compileToPrims(PD.align(PD.empty)) == PD.compileToPrims(PD.empty)
        @test PD.compileToPrims(PD.empty >> 2) == PD.compileToPrims(PD.empty << 2)
    end

    @testset "common" begin 
        let (==) = equal_s
            @test string(PD.parens(PD.pretty(1))) == "(1)"
            @test string(PD.brace(PD.pretty(1))) == "{1}"
            @test string(PD.angle(PD.pretty(1))) == "<1>"
            @test string(PD.bracket(PD.pretty(1))) == "[1]"
            @test string(PD.listof(PD.pretty(1), PD.pretty(2))) == "12"
            @test string(PD.seplistof(PD.comma, [PD.pretty(1), PD.pretty(2)])) == "1,2"
        end
    end

end
