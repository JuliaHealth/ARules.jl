using Documenter
using ARules

# make assets dir if doesn't exist
assets_dir = joinpath(@__DIR__,"src","assets")
if !isdir(assets_dir)
    mkdir(assets_dir)
end

base_url = "https://raw.githubusercontent.com/bcbi/code_style_guide/master/assets/"

# get/replace favicon
favicon_url = base_url*"favicon.ico"
favicon_path = joinpath(assets_dir,"favicon.ico")
run(`curl -g -L -f -o $favicon_path $favicon_url`)

# get/replace css
css_url = base_url*"bcbi.css"
css_path = joinpath(assets_dir,"bcbi.css")
run(`curl -g -L -f -o $css_path $css_url`)

# get/replace logo
logo_url = base_url*"bcbi-white-v.png"
logo_path = joinpath(assets_dir,"logo.png")
run(`curl -g -L -f -o $logo_path $logo_url`)

makedocs(
    modules = [ ARules ],
    assets = [
        "assets/favicon.ico",
        "assets/bcbi.css",
        "assets/logo.png"
        ],
    sitename = "ARules.jl",
    debug = true,
    pages = [
        "Home" => "index.md",
        "Guide" => "usage.md",
        "API" => "documentation.md"
        ]
    )

deploydocs(
    repo = "github.com/bcbi/ARules.jl.git"
)
