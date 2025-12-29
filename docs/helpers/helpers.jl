
function parse_args(ARGS)
    args = @tuplearguments begin
        @argumentflag liveserver "--liveserver"
        @argumentflag excludetutorials "--exclude-tutorials"
        @argumentflag verbose "-v" "--verbose"
    end
    return args
end

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

function _create_documenter_changelog(DIR)
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
        last_sentence_before_content => last_sentence_before_content * "\n\n" * contents_block,
    )
    # Remove trailing lines
    content = strip(content) * "\n"
    # Write out the content
    write(joinpath(DIR, "src/changelog.md"), content)
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
    content =
        replace(content, r"<!-- GitHub pull request/issue links -->.*$"ms => String(take!(io)))
    write(changelogfile, content)
end
