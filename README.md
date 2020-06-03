# Bayesian_analysis_GUI
GUIs for the bayesian analysis code

## Simulation GUI
This GUI helps the user with the setup of the simulation.

- the user needs to specify various parameters, which all have default values.
    - number of clusters
    - number of molecules per cluster
    - model (so far there is only a Gaussian model)
    - standard deviation for the Gaussian model
    - background relative to the clustered data
    - background distribution: # TODO
        - 1,1 completely spacial random distribution
    - size of the region of interest (ROI) in [nm, nm]
        - separately for x and y
        - best option: x and y identical
    - number of simulations
    - gamma parameters: # TODO
    - multimerisation: # TODO
        - molecules
        - proportion
    - storage directory/folder name
    
- so far no backend support
    - need to understand numpy and pandas
    - idea: 
        - hand data to R in a string numpy array because right now every variable is a string
        - R then handles the rest
- rply2: pipe to R # TODO
    - possible to run R script from python, 
    but not yet with the GUI's input parameters. 

It is very easy to make some words **bold** and other words *italic* with Markdown. You can even [link to Google!](http://google.com)

# This is an <h1> tag
## this in an <h2> tag
###### This is an <h6> tag

*This text will be italic*
_This will also be italic_

**This text will be bold**
__This will also be bold__

_You **can** combine them_

# Lists
## Unordered
* Item 1
* item 2
    * Item 2a
    * Item 2b

## Ordered
1. Item 1
1. Item 2
1. Item 3
    1. Item 3a
    1. Item 3b
    
# Images
![GitHub Logo](/images/logo.png)
Format: ![Alt Text](url)

#Links
http://github.com - automatic!
[GitHub](http://github.com)

# Blockquotes
As Kanye West said:
> We're living the future so
>the present is our past.

# Inline code
I think you should use an `<addr>` element here instead.

# Syntax highlighting
```javascript
function fancyAlert(arg) {
    if(arg) {
        $.facebox({div:'#foo'})
}}
```

# Task Lists
- [x] @mentions, #refs, [links](), **formatting**, and <del>tags</del> supported
- [x] list syntax required (any unordered or ordered list supported)
- [x] this is a complete item
- [ ] this is an incomplete item

# Tables
First Header | Second Header
-------------|--------------
Content from cell 1 | Content from cell 2
Content in the first column | Content in the second column

~~this~~

:smiley:
