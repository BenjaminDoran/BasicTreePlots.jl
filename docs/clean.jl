#!/usr/bin/env julia

# Removes all files (likely) generated by invoking docs/make.jl

const DIR = @__DIR__
const ARTIFACTS = String[]

append!(
    ARTIFACTS,
    # Untracked files in build directory
    eachline(`git ls-files --other --directory $(joinpath(DIR, "build"))`),
    # Untracked files in examples/tutorials/howto/gallery generated by Literate.jl
    let literate_output =
            joinpath.(DIR, "src", ["examples", "tutorials", "howto", "gallery"])
        eachline(`git ls-files --other --directory $(literate_output)`)
    end,
)

for artifact in ARTIFACTS
    @info "Removing $artifact"
    rm(artifact; recursive = true, force = true)
end
