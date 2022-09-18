## Install
if (!require('RPostgreSQL')) install.packages('RPostgreSQL')
if (!require('xlsx')) install.packages('xlsx')
if (!require('shinyjs')) install.packages('shinyjs')
if (!require('radiant.data')) install.packages('radiant.data', repos = 'https://r-package-manager.honeur.org/prod-internal/latest')
if (!require('radiant.basics')) install.packages('radiant.basics', repos = 'https://r-package-manager.honeur.org/prod-internal/latest')
if (!require('radiant.model')) install.packages('radiant.model', repos = 'https://r-package-manager.honeur.org/prod-internal/latest')
if (!require('radiant.design')) install.packages('radiant.design', repos = 'https://r-package-manager.honeur.org/prod-internal/latest')
if (!require('radiant.multivariate')) install.packages('radiant.multivariate', repos = 'https://r-package-manager.honeur.org/prod-internal/latest')
if (!require('radiant')) install.packages('radiant', repos = 'https://r-package-manager.honeur.org/prod-internal/latest')

library(radiant)

## Regular execution
# radiant::radiant()

# Retrieve the underlying shinyapp in radiant
shiny::shinyAppDir(system.file("app", package = "radiant"))
