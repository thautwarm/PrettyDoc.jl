using PrettyDoc
using Documenter

DocMeta.setdocmeta!(PrettyDoc, :DocTestSetup, :(using PrettyDoc); recursive=true)

makedocs(;
    modules=[PrettyDoc],
    authors="thautwarm <twshere@outlook.com> and contributors",
    repo="https://github.com/thautwarm/PrettyDoc.jl/blob/{commit}{path}#{line}",
    sitename="PrettyDoc.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://thautwarm.github.io/PrettyDoc.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/thautwarm/PrettyDoc.jl",
    devbranch="main",
)
