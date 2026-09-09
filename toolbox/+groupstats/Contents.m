% +GROUPSTATS
% 
%   Contents file for +GROUPSTATS and its subfolders.
%
%   +GROUPSTATS
%   groupstats.barchartcats                        - Bar chart by groups along x-axis and by color within groups
%   groupstats.boxchartcats                        - Box chart by groups along x-axis and by color within groups
%   groupstats.boxchartxdata                       - Retrieve x-axis data for boxcharts in handle H
%   groupstats.boxchartydata                       - Compute y coordinates of boxchart
%   groupstats.dropcats                            - Remove categories that are not present in a table variable
%   groupstats.groupbayes                          - Compute group-wise conditional (Bayesian) probabilities
%   groupstats.groupcompare                        - Compare each group member against a reference member
%   groupstats.groupmap                            - Apply a function to groups within a table and recombine results
%   groupstats.grouppercent                        - Compute group-wise frequencies (percents) including groupsets
%   groupstats.groupsamples                        - Collect the data of each group member, reference first
%   groupstats.groupselect                         - Select rows of table by variable name and group members
%   groupstats.groupsummary                        - Compute group-wise statistics
%   groupstats.help                                - Open toolbox html help document in the MATLAB Help browser
%   groupstats.histogram                           - Histogram grouped data
%   groupstats.prepareTableGroups                  - Select rows and prepare group variables in a table
%   groupstats.scatter                             - Scatter chart categorical table data
%
%   +GROUPSTATS/+INTERNAL
%   groupstats.internal.assertpackagedversion      - Error unless a packaged toolbox carries the version
%   groupstats.internal.buildpath                  - Build full path to toolbox folder or file
%   groupstats.internal.checkdependencies          - Report files groupstats needs but does not ship
%   groupstats.internal.demolist                   - The demo files makedocs publishes
%   groupstats.internal.docpath                    - Return the path to a toolbox help page
%   groupstats.internal.installRequiredFiles       - Install required files from GitHub or a local checkout
%   groupstats.internal.makecontents               - Make contents.m for each folder including package folders
%   groupstats.internal.makedocs                   - Publish the toolbox documentation as html files
%   groupstats.internal.privatefunction            - Return handle(s) to private functions in toolbox
%   groupstats.internal.releaseoptions             - Build the packaging options a release uses
%   groupstats.internal.replacePackagePrefix       - Replace namespace package prefix in function files
%   groupstats.internal.runtests                   - Run all tests in the test suite
%   groupstats.internal.tablecompletions           - Generate completions from table variables
%   groupstats.internal.vendordependencies         - Copy the files a toolbox calls from a local checkout
%   groupstats.internal.vendoredfiles              - Return the vendored copies listed in vendored.txt
%   groupstats.internal.version                    - Read version.txt in the toolbox root directory
%
%   +GROUPSTATS/+INTERNAL/PRIVATE
%   groupstats.internal/private.arraymap           - Apply a function to an array, returning a cell array of results
%   groupstats.internal/private.backupfile         - Create a backup file name or folder name and (optionally) a copy
%   groupstats.internal/private.cat2double         - Convert categorical data to double
%   groupstats.internal/private.cellmap            - Apply function to cell-array
%   groupstats.internal/private.convertlivescripts - Convert live script to m-files
%   groupstats.internal/private.getcontents        - Get the contents of a specified directory
%   groupstats.internal/private.getRequiredFiles   - Retrieve requirements for MATLAB functions or toolboxes
%   groupstats.internal/private.installpath        - Return toolbox installation path from user preferences group
%   groupstats.internal/private.islogicalscalar
%   groupstats.internal/private.isoctave           - Return true if the environment is Octave
%   groupstats.internal/private.isscalartext       - Return true if input is scalar text
%   groupstats.internal/private.listfiles          - List all files in folder and (optionally) subfolders
%   groupstats.internal/private.listfolders        - Return a list of folders under a top-level directory
%   groupstats.internal/private.mpackagefolders    - List all package and sub-package folders in folder
%   groupstats.internal/private.mpackagename       - Return the package namespace name
%   groupstats.internal/private.projectpath        - Return the full path to the top-level project directory
%   groupstats.internal/private.rmdotfolders       - Remove dot folders from directory list
%   groupstats.internal/private.tempfile           - Get a temporary file name, or full path to temporary file name
%   groupstats.internal/private.toolboxpath        - Return toolbox basepath
%   groupstats.internal/private.undersource        - True when FOLDER is ROOT or lies below it
%   groupstats.internal/private.updatecontents     - Create a Contents.m file including subdirectories
%   groupstats.internal/private.withcd             - Temporarily cd to a directory
%
%   +GROUPSTATS/+NAMELISTS
%   groupstats.namelists.centralstatistic          - Valid values for a method option that summarizes a group
%   groupstats.namelists.comparetest               - Tests groupcompare can run
%   groupstats.namelists.legendorientation         - Valid values for a LegendOrientation option
%   groupstats.namelists.legendvisibility          - Valid values for a Legend option
%   groupstats.namelists.mergemethod               - Valid values for barchartcats' MergeMethod option
%   groupstats.namelists.mustBeMemberOf            - Validate a value against a named list in this package
%   groupstats.namelists.populationoption          - Valid values for the groupbayes Population option
%   groupstats.namelists.sortdatavar               - Data arguments a sort order can read
%   groupstats.namelists.sortgroupvar              - Grouping arguments a sort order can follow
%   groupstats.namelists.sortorder                 - Valid values for the SortBy option on every chart
%   groupstats.namelists.testtail                  - Valid values for the tail of a rank test
%
%   +GROUPSTATS/+TEST
%   groupstats.test.copytoolbox                    - Copy the toolbox folder without its generated help pages
%   groupstats.test.generateTestData               - Generate data for unit tests, demos, and scripts
%
%   +GROUPSTATS/+TEST/+FIXTURES
%   groupstats.test.fixtures.InvisibleFigure       - Open an invisible figure for the duration of a test
%
%   +GROUPSTATS/PRIVATE
%   groupstats/private.allCustomProps              - Get shared and unique custom properties in a set of tables
%   groupstats/private.bootmediandiff              - Bootstrap the signed median difference against a reference
%   groupstats/private.cat2double                  - Convert categorical data to double
%   groupstats/private.colorspace                  - Convert a color image between color representations
%   colorspace_LICENSE.txt
%   groupstats/private.dealout                     - Deal comma separated list, struct, or cell to comma separated list
%   groupstats/private.defaultcolors               - GETDEFAULTCOLORS Returns the default color triplets
%   groupstats/private.defaultmarkers              - Symbols = {'*','+','.','<','>','^','v','x','diamond','o','pentagram', ..
%   groupstats/private.distinguishable_colors      - : pick colors that are maximally perceptually distinct
%   distinguishable_colors_LICENSE.txt
%   groupstats/private.getMissingValue             - Return default missing value for class
%   groupstats/private.groupmembers                - Return unique members of a table column (variable)
%   groupstats/private.isnumericscalar
%   groupstats/private.isoneof                     - Validate if x is one member of a menu
%   groupstats/private.isvariable                  - Determine if VARNAME is a variable in table TBL
%   groupstats/private.makevalidvarnames           - Make variable names valid
%   groupstats/private.mcallername                 - Get the name of the calling function on the stack
%   groupstats/private.mergeCustomProps            - Merge custom properties of tables
%   groupstats/private.mergegroupmembers           - Pool named members of a categorical group column
%   groupstats/private.naninterp1                  - 1-d interpolation over NaN values in vector V
%   groupstats/private.notempty                    - Determine whether array X contains any non-empty elements
%   groupstats/private.permutest                   - Permutation test for dependent or independent measures of 1-D or 2-D data
%   permutest_LICENSE.txt
%   groupstats/private.reordergroupmembers         - Index a member list by a caller's partial order
%   groupstats/private.settablevarnames            - Set table variable names
%   groupstats/private.stacktables                 - Vertically concatenate tables
%   groupstats/private.validategroupsets           - Reject a scalar "none" as a GroupSets value
%   groupstats/private.validatemember              - Confirm every group member is an exact valid member
%   groupstats/private.validaterowselect           - Require both halves of a row-selection request
%   groupstats/private.withwarnoff                 - Temporarily disable warnings
%
%   This file was generated by updatecontents.m on 05 Sep 2026 at 23:45:16.
