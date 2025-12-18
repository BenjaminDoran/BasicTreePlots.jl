# Make sure docs environment is active and instantiated
using Pkg: Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

cd(@__DIR__)

using TimerOutputs
using ArgMacros
using LiveServer: LiveServer

if "--liveserver" ∈ ARGS
    using Revise
    Revise.revise()
end

using CairoMakie, BasicTreePlots, Literate
using Documenter: Documenter
using Documenter.MarkdownAST
using Documenter.MarkdownAST: @ast
using Markdown

dto = TimerOutput()
reset_timer!(dto)

const ORG_NAME = "BenjaminDoran"
const PACKAGE_NAME = "BasicTreePlots.jl"
const repo_root = dirname(@__DIR__)
const is_ci = haskey(ENV, "GITHUB_ACTIONS")
const TUTORIALS_IN = joinpath(@__DIR__, "src", "literate-tutorials")
const TUTORIALS_OUT = joinpath(@__DIR__, "src", "tutorials")
const GALLERY_IN = joinpath(@__DIR__, "src", "literate-gallery")
const GALLERY_OUT = joinpath(@__DIR__, "src", "gallery")
const changelogfile = joinpath(repo_root, "CHANGELOG.md")


function parse_args(ARGS)
    args = @tuplearguments begin
        @argumentflag liveserver "--liveserver"
        @argumentflag excludetutorials "--exclude-tutorials"
        @argumentflag verbose "-v" "--verbose"
    end
    return args
end

include("helpers/helpers.jl")
include("helpers/figure_block.jl")
include("helpers/attrdocs_block.jl")
include("helpers/shortdocs_block.jl")

function nested_filter(x, regex)
    _match(x::String) = match(regex, x) !== nothing
    _match(x::Pair) = x[2] isa String ? match(regex, x[2]) !== nothing : true
    fn(el::Pair) = el[2] isa Vector ? el[1] => nested_filter(el[2], regex) : el
    fn(el) = el
    return filter(_match, map(fn, x))
end

unnest(vec::Vector) = collect(Iterators.flatten([unnest(el) for el in vec]))
unnest(p::Pair) = p[2] isa String ? [p[2]] : unnest(p[2])
unnest(s::String) = [s]

function main(ARGS)
    args = parse_args(ARGS)

    Documenter.DocMeta.setdocmeta!(
        BasicTreePlots,
        :DocTestSetup,
        :(using BasicTreePlots);
        recursive = true,
    )

    # Generate change log
    _create_documenter_changelog(@__DIR__)

    # Generate tutorials by default
    if !args.excludetutorials
        ## Generate tutorials..
        mkpath(TUTORIALS_OUT)
        _generate_literate_docs(TUTORIALS_IN, TUTORIALS_OUT, args.liveserver)
        _generate_literate_docs(GALLERY_IN, GALLERY_OUT, args.liveserver)
        tutorials_in_menu = true
    else
        @warn """
        You are excluding the tutorials from the Menu,
        which might be done if you can not render them locally.

        Remember that this should never be done on CI for the full documentation.
        """
        tutorials_in_menu = false
    end

    ## Setup tutorials menu
    tutorials_menu =
        "Tutorials" => [
            joinpath("tutorials", file) for
            file in readdir(TUTORIALS_OUT) if last(splitext(file)) == ".md"
        ]
    gallery_menu =
        "Gallery" => [
            joinpath("gallery", file) for
            file in readdir(GALLERY_OUT) if last(splitext(file)) == ".md"
        ]

    numbered_pages = [
        file for file in readdir(joinpath(@__DIR__, "src")) if
        startswith(file, r"^\d\d-") && last(splitext(file)) == ".md"
    ]

    reference_pages =
        "Reference" => [
            joinpath("reference", file) for
            file in readdir(joinpath(@__DIR__, "src", "reference")) if
            last(splitext(file)) == ".md"
        ]

    pages = [
        "Home" => "index.md",
        (tutorials_in_menu ? [tutorials_menu] : [])...,
        (tutorials_in_menu ? [gallery_menu] : [])...,
        reference_pages,
        numbered_pages...,
        "Change Log" => "changelog.md",
    ]

    empty!(MakieDocsHelpers.FIGURES)
    Documenter.makedocs(;
        # modules = [BasicTreePlots],
        authors = "Benjamin Doran and collaborators",
        repo = "https://github.com/$ORG_NAME/$PACKAGE_NAME/blob/{commit}{path}#{line}",
        sitename = PACKAGE_NAME,
        format = Documenter.HTML(;
            prettyurls = get(ENV, "CI", "false") == "true",
            canonical = "https://$ORG_NAME.github.io/$PACKAGE_NAME",
            assets = String[],
            repolink = "https://github.com/$ORG_NAME/$PACKAGE_NAME",
            collapselevel = 1,
        ),
        pages = pages,
        expandfirst = unnest(
            nested_filter(pages, r"src/(gallery|tutorials|reference)/(?!overview)"),
        ),
        pagesonly = true,
    )

    if !args.liveserver
        deploydocs(; repo = "github.com/$ORG_NAME/$PACKAGE_NAME")
    end
end

main(ARGS)
