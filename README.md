SRNatComm21
-----------------------------------------------------------

Code Accompanying Ramirez, A.D. & Aksay, E.A. **Ramp-to-Threshold Dynamics in a Hindbrain Population Controls the Timing of Spontaneous Saccades.** _Nat Comm_.(2021)

### Contents
- _plotAll.m_ : script used to produce the figures in the paper. cells are labelled by the figure panel they create.  
- _/tools/_ : all classes and functions required for analyses

### Installation
1. Make sure the necessary dependencies have been installed.
2. Open _rootDirectories.m_ and change the variable `dataDir` to point to the proper data location (see Data).


### Dependencies
The _plotAll.m_ file has been tested with the following packages and versions:

- _Mac OS Catalina_: Version 10.15.7
- _MATLAB_: Version: '9.5'
    - _Optimization Toolbox_: Version: '8.2', ProductNumber: 6
    - _Signal Processing Toolbox_: Version: '8.1', ProductNumber: 8
    - _Mapping Toolbox_: Version: '4.7', ProductNumber: 11
    - _Symbolic Math Toolbox_: Version: '8.2', ProductNumber: 15
    - _Image Processing Toolbox_: Version: '10.3', ProductNumber: 17
    - _Statistics and Machine Learning Toolbox_: Version: '11.4', ProductNumber: 19
    - _Financial Toolbox_: Version: '5.12', ProductNumber: 30

- _CVX_ (Required for CaImAn):
  - Software for Disciplined Convex Programming       (c)2014 CVX Research Version 2.1, Build 1127 (95903bf)                  Sat Dec 15 18:52:07 2018, http://cvxr.com/cvx/
- _CaImAn_: https://github.com/flatironinstitute/CaImAn-MATLAB

### Data
Data used in *Ramp-to-Threshold Dynamics in a Hindbrain Population Controls the Timing of Spontaneous Saccades.** are available on figShare with the title _Spontaneous-SR-Data_

Note that the paper makes use of the ZBrain (1.0) atlas (Randlett et. al. 2015). Specifically, the Reference Brain and and Mask Database must be downloaded (https://zebrafishexplorer.zib.de/download). The reference brain must be changed to a .tiff file with scale added to the metadata. Make sure that the variables `fileDirs.ZBrainMasks` and `fileDirs.ZBrain` in  _rootDirectories.m_ point to the appropriate locations.
