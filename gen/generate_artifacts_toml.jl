#! /usr/bin/env julia
using Pkg: Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using TOML, Downloads, SHA, Tar, CodecBzip2

ROOT_URL = "https://sourceforge.net/projects/geographiclib/files"

# gridded geoids
GEOID = (;
    directory="geoids-distrib",
    names=[
        "egm2008-1",
        "egm2008-2_5",
        "egm2008-5",
        "egm96-5",
        "egm96-15",
        "egm84-15",
        "egm84-30",
    ],
)

# gravity models
GRAVITY = (;
    directory="gravity-distrib", names=["grs80", "wgs84", "egm84", "egm96", "egm2008"]
)

# magnetic models
MAGNETIC = (;
    directory="magnetic-distrib",
    names=[
        "emm2010",
        "emm2015",
        "emm2017",
        "igrf11",
        "igrf12",
        "igrf13",
        "wmm2010",
        "wmm2015",
        "wmm2015v2",
        "wmm2020",
    ],
)

# compute dictionary equivalent of Artifacts.toml contents
artifacts = Dict()
for model_type in [GEOID, GRAVITY, MAGNETIC]
    url_dir = joinpath(ROOT_URL, model_type.directory)
    for name in model_type.names
        filename = name * ".tar.bz2"
        url = joinpath(url_dir, filename)

        # download the archive locally
        filepath = joinpath(@__DIR__, filename)
        isfile(filepath) || Downloads.download(url, filepath)

        # compute its sha256
        sha = bytes2hex(open(sha256, filepath))

        # compute the git-tree-sha1 of its contents
        git_tree_sha1 = Tar.tree_hash(Bzip2DecompressorStream(open(filepath)))

        artifacts[name] = Dict(
            "lazy" => true,
            "download" => [Dict("url" => url, "sha256" => sha)],
            "git-tree-sha1" => git_tree_sha1,
        )
    end
end

# write out Artifacts.toml
open(joinpath(@__DIR__, "..", "Artifacts.toml"), "w") do io
    TOML.print(io, artifacts; sorted=true)
end
