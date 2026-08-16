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
%   groupstats.groupdifference                     - Estimate group differences
%   groupstats.groupmap                            - Apply a function to groups within a table and recombine results
%   groupstats.grouppercent                        - Compute group-wise frequencies (percents) including groupsets
%   groupstats.groupselect                         - Select rows of table by variable name and group members
%   groupstats.groupsummary                        - Compute group-wise statistics
%   groupstats.help                                - Open toolbox html help document in the MATLAB Help browser
%   groupstats.histogram                           - Histogram grouped data
%   groupstats.prepareTableGroups                  - Select rows and prepare group variables in a table
%   groupstats.scatter                             - Scatter chart categorical table data
%   groupstats.testnamespace                       - Test namespace access
%
%   +GROUPSTATS/+INTERNAL
%   groupstats.internal.buildpath                  - Build full path to toolbox folder or file
%   groupstats.internal.checkdependencies          - Report functions groupstats needs but does not ship
%   groupstats.internal.docpath                    - Return the path to a toolbox help page
%   groupstats.internal.installRequiredFiles       - Install required files from Github
%   groupstats.internal.makecontents               - Make contents.m for each folder including package folders
%   groupstats.internal.privatefunction            - Return handle(s) to private functions in toolbox
%   groupstats.internal.releaseoptions             - Build the packaging options a release uses
%   groupstats.internal.replacePackagePrefix       - Replace namespace package prefix in function files
%   groupstats.internal.runtests                   - Run all tests in the test suite
%   groupstats.internal.version                    - Read version.txt in the toolbox root directory
%
%   +GROUPSTATS/+INTERNAL/PRIVATE
%   groupstats.internal/private.backupfile         - Create a backup file name or folder name and (optionally) a copy
%   groupstats.internal/private.cellmap            - Apply function to cell-array
%   groupstats.internal/private.convertlivescripts - Convert live script to m-files
%   groupstats.internal/private.getcontents        - Get the contents of a specified directory
%   groupstats.internal/private.getRequiredFiles   - Retrieve requirements for MATLAB functions or toolboxes
%   groupstats.internal/private.installpath        - Return toolbox installation path from user preferences group
%   groupstats.internal/private.isoctave           - Return true if the environment is Octave
%   groupstats.internal/private.listfiles          - List all files in folder and (optionally) subfolders
%   groupstats.internal/private.listfolders        - Return a list of folders under a top-level directory
%   groupstats.internal/private.mpackagefolders    - List all package and sub-package folders in folder
%   groupstats.internal/private.mpackagename       - Return the package namespace name
%   groupstats.internal/private.projectpath        - Return the full path to the top-level project directory
%   groupstats.internal/private.rmdotfolders       - Remove dot folders from directory list
%   groupstats.internal/private.toolboxpath        - Return toolbox basepath
%   groupstats.internal/private.updatecontents     - Create a Contents.m file including subdirectories
%   groupstats.internal/private.withcd             - Temporarily cd to a directory
%
%   +GROUPSTATS/+NAMELISTS
%   groupstats.namelists.centralstatistic          - Valid values for a method option that summarizes a group
%   groupstats.namelists.legendorientation         - Valid values for a LegendOrientation option
%   groupstats.namelists.legendvisibility          - Valid values for a Legend option
%   groupstats.namelists.mustBeMemberOf            - Validate a value against a named list in this package
%   groupstats.namelists.populationoption          - Valid values for the groupbayes Population option
%   groupstats.namelists.sortdatavar               - Data arguments a sort order can read
%   groupstats.namelists.sortdirection             - Valid sort directions
%   groupstats.namelists.sortgroupvar              - Grouping arguments a sort order can follow
%   groupstats.namelists.sortorder                 - Valid values for a SortBy option that can also skip sorting
%   groupstats.namelists.testtail                  - Valid values for the tail of a rank test
%
%   +GROUPSTATS/+TEST
%   groupstats.test.generateTestData               - Generate data for unit tests, demos, and scripts
%
%   +GROUPSTATS/+TEST/+FIXTURES
%   groupstats.test.fixtures.InvisibleFigure       - Open an invisible figure for the duration of a test
%
%   +GROUPSTATS/PERMUTEST
%   license.txt
%   groupstats/permutest.permutest                 - Permutation test for dependent or independent measures of 1-D or 2-D data
%
%   +GROUPSTATS/PRIVATE
%   groupstats/private.groupmembers                - Return unique members of a table column (variable)
%   groupstats/private.isvariable                  - Determine if VARNAME is a variable in table TBL
%   groupstats/private.reordergroupmembers         - Index a member list by a caller's partial order
%   groupstats/private.settablevarnames            - Set table variable names
%   groupstats/private.validatemember              - Confirm every group member is an exact valid member
%   groupstats/private.withwarnoff                 - Temporarily disable warnings
%
%   This file was generated by updatecontents.m on 16 Aug 2026 at 15:17:18.
