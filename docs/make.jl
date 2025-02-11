# Make sure docs environment is active and instantiated
import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

cd(@__DIR__)

using TimerOutputs
using ArgMacros
import LiveServer

if "--liveserver" ∈ ARGS
    using Revise
    Revise.revise()
end

using Literate, BasicTreePlots
using Documenter

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

function main(ARGS)
    args = parse_args(ARGS)

    DocMeta.setdocmeta!(
        BasicTreePlots,
        :DocTestSetup,
        :(using BasicTreePlots);
        recursive = true,
    )

    # Generate change log
    _create_documenter_changelog()

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

    makedocs(;
        modules = [BasicTreePlots],
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
        pages = [
            "Home" => "index.md",
            (tutorials_in_menu ? [tutorials_menu] : [])...,
            (tutorials_in_menu ? [gallery_menu] : [])...,
            numbered_pages...,
            "Change Log" => "changelog.md",
        ],
    )

    if !args.liveserver
        deploydocs(; repo = "github.com/$ORG_NAME/$PACKAGE_NAME")
    end
end


function _generate_literate_docs(dir_in, dir_out, liveserver)
    # Run Literate on all examples
    for (IN, OUT) in [(dir_in, dir_out)]
        for program in readdir(IN; join = true)
            name = basename(program)
            if endswith(program, ".jl")
                if !liveserver
                    script = @timeit dto "script()" @timeit dto name begin
                        Literate.script(program, OUT)
                    end
                    code = strip(read(script, String))
                else
                    code = "<< no script output when building as draft >>"
                end

                # remove "hidden" lines which are not shown in the markdown
                line_ending_symbol = occursin(code, "\r\n") ? "\r\n" : "\n"
                code_clean = join(
                    filter(x -> !endswith(x, "#hide"), split(code, r"\n|\r\n")),
                    line_ending_symbol,
                )
                code_clean = replace(code_clean, r"^# This file was generated .*$"m => "")
                code_clean = strip(code_clean)

                mdpost(str) = replace(str, "@__CODE__" => code_clean)
                function nbpre(str)
                    # \llbracket and \rr bracket not supported by MathJax (Jupyter/nbviewer)
                    str = replace(str, "\\llbracket" => "[\\![", "\\rrbracket" => "]\\!]")
                    return str
                end

                @timeit dto "markdown()" @timeit dto name begin
                    Literate.markdown(program, OUT, postprocess = mdpost)
                end
                if !liveserver
                    @timeit dto "notebook()" @timeit dto name begin
                        Literate.notebook(program, OUT, preprocess = nbpre, execute = is_ci) # Don't execute locally
                    end
                end
            elseif any(endswith.(program, [".png", ".jpg", ".gif"]))
                cp(program, joinpath(OUT, name); force = true)
            else
                @warn "ignoring $program"
            end
        end
    end
end

function _create_documenter_changelog()
    content = read(changelogfile, String)
    # Replace release headers
    content = replace(content, "## [Unreleased]" => "## Changes yet to be released")
    content = replace(content, r"## \[(\d+\.\d+\.\d+)\]" => s"## Version \1")
    # Replace [#XXX][github-XXX] with the proper links
    content = replace(
        content,
        r"(\[#(\d+)\])\[github-\d+\]" =>
            s"\1(https://github.com/BenjaminDoran/BasicTreePlots.jl/pull/\2)",
    )
    # Remove all links at the bottom
    content = replace(content, r"^<!-- Release links -->.*$"ms => "")
    # Change some GitHub in-readme links to documenter links
    content = replace(content, "(#upgrading-code-from-ferrite-03-to-10)" => "(@ref)")
    # Add a contents block
    last_sentence_before_content = "adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)."
    contents_block = """
    ```@contents
    Pages = ["changelog.md"]
    Depth = 2:2
    ```
    """
    content = replace(
        content,
        last_sentence_before_content =>
            last_sentence_before_content * "\n\n" * contents_block,
    )
    # Remove trailing lines
    content = strip(content) * "\n"
    # Write out the content
    write(joinpath(@__DIR__, "src/changelog.md"), content)
    return nothing
end

function _fix_links()
    content = read(changelogfile, String)
    text = split(content, "<!-- Release links -->")[1]
    # Look for links of the form: [#XXX][github-XXX]
    github_links = Dict{String,String}()
    r = r"\[#(\d+)\](\[github-(\d+)\])"
    for m in eachmatch(r, text)
        @assert m[1] == m[3]
        # Always use /pull/ since it will redirect to /issues/ if it is an issue
        url = "https://github.com/$ORG_NAME/$PACKAGE_NAME/pull/$(m[1])"
        github_links[m[2]] = url
    end
    io = IOBuffer()
    print(io, "<!-- GitHub pull request/issue links -->\n\n")
    for l in sort!(collect(github_links); by = first)
        println(io, l[1], ": ", l[2])
    end
    content = replace(
        content,
        r"<!-- GitHub pull request/issue links -->.*$"ms => String(take!(io)),
    )
    write(changelogfile, content)
end

main(ARGS)
