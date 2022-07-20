module PrettyDoc
using MLStyle
import Base: +, *, >>, <<

export Doc, space, vsep, align, seg, indent, breakable

@data Doc begin
    Doc_Concat(left::Doc, right::Doc)
    Doc_VSep(elements::Vector{Doc})
    Doc_Align(document::Doc)
    Doc_Indent(delta::Int, document::Doc)
    Doc_Segment(segment::String)
    Doc_Breakable(document::Doc)
    Doc_Empty
end

"""
Combinatorial documentation objects, which has the following constructors:
- `Doc_Concat(left::Doc, right::Doc)`
    Concatenates two documents,and the line is not broken.
- `Doc_VSep(elements::Vector{Doc})`
    Concatenates a vector of documents with the line separator `"\n"`.
- `Doc_Align(document::Doc)`
    Aligns the document using the current indentation.
- `Doc_Indent(delta::Int, document::Doc)`
    Locally indents the document by `delta` spaces.
- `Doc_Segment(segment::String)`
    A segment of text.
- Doc_Breakable(document::Doc)
    Inidicating the end of the document is breakable.
- Doc_Empty
    Do nothing.
"""
Doc

"""
Rendering options
"""
struct RenderOptions
    preferredLineWidth :: Int
end

"""
A default set of rendering options.
"""
const defaultRenderOptions = RenderOptions(42)

"""
A document object representing a single whitespace.
"""
const space = Doc_Segment(" ")

(left::Doc) * (right::Doc) = Doc_Concat(left, right)
(left::Doc) + (right::Doc) = left * space * right
(doc::Doc) >> (delta::Int) = Doc_Indent(delta, doc)
(doc::Doc) << (delta::Int) = Doc_Indent(-delta, doc)

function Base.show(io::IO, @nospecialize(doc::Doc))
    render!(defaultRenderOptions, compileToPrims(doc)) do s::String
        print(io, s)
    end
end

@data ProceduralDoc begin
    PDoc_PopIndent
    PDoc_PushCurrentIndent
    PDoc_PushIndent(delta::Int)
    PDoc_Segment(segment::String)
    PDoc_Breakable
end

const PDoc = ProceduralDoc

function concat(self::Vector{T}, xs :: Vector{T}...) where T
    result = self
    for x in xs
        result = vcat(result, x)
    end
    return result
end

function compileToPrims(doc::Doc)
    @nospecialize doc

    @match doc begin
        Doc_Segment(segment) => [PDoc[PDoc_Segment(segment)]]
        Doc_Breakable(doc) =>
          let result = compileToPrims(doc)  
                if isempty(result) || length(result) == 1 && isempty(result[1])
                    [PDoc[PDoc_Breakable]]
                else
                    result[1] = concat(PDoc[PDoc_Breakable], result[1])
                    result
                end
          end
        Doc_Concat(left, right) =>
            let left_primes = compileToPrims(left),
                right_primes = compileToPrims(right)
                if isempty(left_primes)
                    right_primes
                elseif isempty(right_primes)
                    left_primes
                else
                    concat(
                        left_primes[1:end-1],
                        [concat(left_primes[end], right_primes[1])],
                        right_primes[2:end]
                    )
                end
            end
        Doc_Align(doc) =>
            let result = compileToPrims(doc)
                if isempty(result)
                    result
                else
                    result[1] = concat(PDoc[PDoc_PushCurrentIndent], result[1])
                    result[end] = concat(result[end], PDoc[PDoc_PopIndent])
                    result
                end
            end
        Doc_Indent(delta, doc) =>
            let result = compileToPrims(doc)
                if isempty(result)
                    result
                else
                    result[1] = concat(PDoc[PDoc_PushIndent(delta)], result[1])
                    result[end] = concat(result[end], PDoc[PDoc_PopIndent])
                    result
                end
            end
        Doc_VSep(elements) =>
            Vector{PDoc}[ v for elt in elements for v in compileToPrims(elt) ]
        
        Doc_Empty => Vector{PDoc}[]
    end
end


mutable struct Level
    level :: Int
    breaked :: Bool  # use for future?
end

function render!(fwrite::Function, opts::RenderOptions, sentences::Vector{Vector{PDoc}})
    levels = [Level(0, false)]
    if isempty(sentences)
        return
    end

    for segments in sentences
        col = 0
        initialized = false

        function line_init()
            if !initialized
                col = levels[end].level
                fwrite(repeat(" ", col))
                initialized = true
            end
        end

        for seg in segments
            @switch seg begin
                @case PDoc_Breakable
                    if col > opts.preferredLineWidth
                        initialized = false
                        levels[end].breaked = true
                        fwrite("\n")
                        col = 0
                    end
                @case PDoc_Segment(segment)
                    line_init()
                    fwrite(segment)
                    col += length(segment)
                @case PDoc_PushCurrentIndent
                    push!(levels, Level(col, false))
                @case PDoc_PushIndent(delta)
                    push!(levels, Level(max(0, levels[end].level + delta), false))
                @case PDoc_PopIndent
                    pop!(levels)
            end # end switch
        end # end for segments
        
        if !levels[end].breaked
            fwrite("\n")
        end
    end # end for sentences
end

"""
Using `repr(o)` to create a document from an object.
"""
function pretty(o)
    Doc_Segment(repr(o))
end

"""
Making a document from a string.
Note that including line ending characters can cause ugly pretty printing.
"""
function seg(s::AbstractString)
    Doc_Segment(convert(String, s))
end

function vsep(sections::Doc...)
    vsep(collect(Doc, sections))
end

function vsep(sections::AbstractVector)
    vsep(collect(Doc, sections))
end

function vsep(sections::Vector{Doc})
    Doc_VSep(sections)
end

"""
Concatenates a vector of documents with the line separator `"\n"`.
"""
vsep

"""
Align the document using the current indentation.
"""
align(inner::Doc) = Doc_Align(inner)

"""
Indent a document by `delta` spaces. Negative `delta`s are allowed.

P.S: You might use `doc >> 2` or `doc << 2` to indent document objects.
"""
indent(delta::Int, inner::Doc) = Doc_Indent(i, inner)

"""
A empty document.
"""
const empty = Doc_Empty

"""
Wrap a document with left and right parentheses.
"""
parens(a::Doc) = seg("(") * a * seg(")")

"""
Wrap a document with left and right brackets.
"""
bracket(a::Doc) = seg("[") * a * seg("]")

"""
Wrap a document with left and right braces.
"""
brace(a::Doc) = seg("{") * a * seg("}")

"""
Wrap a document with left and right angle brackets.
"""
angle(a::Doc) = seg("<") * a * seg(">")

"""
A document representing a single comma.
"""
const comma = seg(",")

listof(elements::AbstractVector) = listof(collect(Doc, elements))
listof(elements::Doc...) = listof(collect(Doc, elements))

function listof(elements::Vector{Doc})
    if isempty(elements)
        return empty
    end
    let head = elements[1],
        tail = @view elements[2:end]
        
        result = head
        for each in tail
            result *= each
        end
        return result
    end
end

"""
Create a document that represents a list of elements. No separator.
"""
listof

seplistof(sep::Doc, elements::AbstractVector) =
    seplistof(sep, collect(Doc, elements))


function seplistof(sep::Doc, elements::Vector{Doc})
    if isempty(elements)
        return empty
    end
    let head = elements[1],
        tail = @view elements[2:end]
        
        result = head
        for each in tail
            result *= sep * each
        end
        return result
    end
end

"""
    seplistof(separator, elements)

Create a document that represents a list of elements, separated by the given separator.

"""
seplistof

"""
Make the document breakable at its beginning.
"""
breakable(x::Doc) = Doc_Breakable(x)

end
