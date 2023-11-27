# ninja-sprite-dma
 Example of DMA'ing sprites with NBP

All code (c) em00k - do not use without persmission. 

Please NOTE the assets ARE NOT TO BE USED!! You cannot reuse any assets 
that are included and only here for example purposes. 

This will only build with NextBuildPro which is not yet released (the beta version will not support the code)

Files :

- Sample.bas
    This is the main master file which acts as the orchestrator, loads in 
    any common includes and also assets, this will produce the Sample.NEX

- Module5.bas
    In the example we only use module5 - 1 to 4 were small progressions. The module is loaded from Sample.BAS on line 94 SetLoadModule(ModuleSample5,0,0)

- inc-common.bas
    This contains all the variables used in the master and modules and should be included in each module. The varables are alwasy store in the same location in memory startig at $4000

    There are also common routines used between modules store in here. 

There is also a nextlib_ints_ctc2.bas which is not included for this example which handles all the interrupts for music and sample audio. 

To run this example copy the files from release to your Next and run Sample.NEX

Example video : https://www.youtube.com/watch?v=2SisC9-zurk

