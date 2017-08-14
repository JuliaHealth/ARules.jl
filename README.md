# ARules

[![Build Status](https://travis-ci.org/bcbi/ARules.jl.svg?branch=master)](https://travis-ci.org/bcbi/ARules.jl)

[![Coverage Status](https://coveralls.io/repos/bcbi/ARules.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/bcbi/ARules.jl?branch=master)

[![codecov.io](http://codecov.io/github/bcbi/ARules.jl/coverage.svg?branch=master)](http://codecov.io/github/bcbi/ARules.jl?branch=master)

## 1. Installation
```julia
julia> Pkg.clone("https://github.com/bcbi/ARules.jl")
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


julia> rules = apriori(transactions, 0.01, 6)
```







## 3. Association Rule Generation

## N. To Do
