# ARules

[![Docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://bcbi.github.io/ARules.jl/latest) [![Build Status](https://travis-ci.org/bcbi/ARules.jl.svg?branch=master)](https://travis-ci.org/bcbi/ARules.jl) [![codecov.io](http://codecov.io/github/bcbi/ARules.jl/coverage.svg?branch=master)](http://codecov.io/github/bcbi/ARules.jl?branch=master) [![DOI](https://zenodo.org/badge/95671564.svg)](https://zenodo.org/badge/latestdoi/95671564)

## 1. Installation
```julia
julia> Pkg.add("https://github.com/bcbi/ARules.jl")
```

## 2. Frequent Itemset Generation
The `frequent()` function can be used to obtain frequent itemsets using the
_a priori_ algorithm. The second and third arguments allow us to control the
minimum support threshold (either as a count or proportion) and the maximum
size of itemset to consider, respectively.
```julia
julia> using ARules

julia> transactions = [["milk", "eggs", "bread"],
                       ["butter", "milk", "sugar", "flour", "eggs"],
                       ["bacon", "eggs", "milk", "beer"],
                       ["bread", "ham", "turkey"],
                       ["cheese", "ham", "bread", "ketchup"],
                       ["mustard", "hot dogs", "buns", "hamburger", "cheese", "beer"],
                       ["milk", "sugar", "eggs"],
                       ["hamburger", "ketchup", "milk", "beer"],
                       ["ham", "cheese", "bacon", "eggs"]]

julia> frequent(transactions, 2, 6)				# uses a-priori algorithm
```

## 3. Association Rule Generation
The `apriori()` function can be used to obtain association rules.
```julia
julia> using ARules

julia> transactions = [["milk", "eggs", "bread"],
                       ["butter", "milk", "sugar", "flour", "eggs"],
                       ["bacon", "eggs", "milk", "beer"],
                       ["bread", "ham", "turkey"],
                       ["cheese", "ham", "bread", "ketchup"],
                       ["mustard", "hot dogs", "buns", "hamburger", "cheese", "beer"],
                       ["milk", "sugar", "eggs"],
                       ["hamburger", "ketchup", "milk", "beer"],
                       ["ham", "cheese", "bacon", "eggs"]]


julia> rules = apriori(transactions, supp = 0.01, conf = 0.1, maxlen = 6)
```


## 4. Note
This package is under active development. And as such, there are still many performance and feature improvements to be made. In the case of performance, while the package will handle many applications quite well, once the number of "items" in "transactions" becomes large, there is a marked performance penalty.

## 5. To Do
- Implement additional frequent-itemset generation algorithms (e.g., eclat, fp-growth)
- Add functionality for requiring rules to contain a certain item (or items)
- Improve performance
