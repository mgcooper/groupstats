# Group Stats Toolbox

## Getting Started

`groupstats` is a MATLAB&reg; toolbox for grouped statistics. Thanks for checking it out. If you're just getting started, here's what we recommend:

* First, open the live script `gettingStarted.mlx` for instructions on installing the toolbox.
* Next, work through the tutorials, beginning with `toolbox/examples/usingGroupStats.mlx`.

To get more help:

* `groupstats.help()`

To contribute:

* Open an issue:

To run the test suite:

* Tests are located in `tests/`
* From a matlab command window, type `runtests('tests')` and press enter.

* The toolbox installation file is in `release/`

## Toolbox Features

Grouped statistics for MATLAB tables:

* Group-wise summary statistics (`groupstats.groupsummary`)
* Group-wise frequencies and percentages, including groupsets (`groupstats.grouppercent`)
* Group-wise conditional (Bayesian) probabilities (`groupstats.groupbayes`)
* Group difference estimation, including permutation tests (`groupstats.groupdifference`)
* Row selection by group membership (`groupstats.groupselect`)
* Apply a function to each group in a table and recombine the results (`groupmap`)

Charts for categorical (grouped) table data:

* Bar and box charts grouped along the x-axis and colored within groups (`barchartcats`, `boxchartcats`)
* Grouped scatter charts and histograms (`groupstats.scatter`, `groupstats.histogram`)

## Contributing

## License

The license is available in the license.txt file in this GitHub repository.
