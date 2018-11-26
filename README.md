# PulseRain Reindeer - RISCV RV32I[M] Soft CPU
----------------------------------------------
  * # Overview
PulseRain Reindeer is a soft CPU of Von Neumann architecture. It supports RISC-V RV32I[M] instruction set, and features a 2 x 2 pipeline. It strives to make a balance between speed and area, and offers a flexible choice for soft CPU across all FPGA platforms.

## Highlights - 2 x 2 Pipeline
Reindeer's pipeline is composed of 4 stages: 
  + Instruction Fetch (IF)
  + Instruction Decode (ID)
  + Instruction Execution (IE)
  + Register Write Back and Memory Access (MEM)

However, unlike traditional pipelines, Reindeer's pipeline stages are mapped to a 2 x 2 layout, as illustrated below:

![2 x 2 pipeline](https://github.com/PulseRain/Reindeer/raw/master/docs/pipeline_2x2.png "2 x 2 Pipeline")

In the 2 x 2 layout, each stage is active every other clock cycle. For the even cycle, only IF and IE stages are active, while for the odd cycle, only ID and MEM stages are active. In this way, the Instruction Fetch and Memory Access always happen on different clock cycles, thus to avoid the structural hazard caused by the single port memory. 

Thanks to using single port memory to store both code and data, the Reindeer soft CPU is quite portable and flexible across all FPGA platforms. Some FPGA platforms, like the Lattice iCE40 UltraPlus family, carry a large amount of SPRAM with very little EBR RAM. And those platforms will find themselves a good match with the PulseRain Reindeer when it comes to soft CPU.

## Highlights - Hold and Load

Bootstrapping a soft CPU tends to be a headache. The traditional approach is more or less like the following:
  1. Making a boot loader in software
  2. Store the boot loader in a ROM
  3. After power on reset, the boot loader is supposed to be executed first, for which it will move the rest of the code/data into RAM. And the PC will be set to the _start address of the new image afterwards.

The drawbacks of the above approach are:
  1. The bootloader will be more or less intrusive, as it takes memory spaces.
  2. The implementation of ROM is not consistent across all FPGA platforms. For some FPGAs, like Intel Cyclone or Xilinx Artix, the memory initial data can be stored in FPGA bitstream, but other platforms might choose to use external flash for the ROM data. The boot loader itself could be executed in place, or loaded with a small preloader implemented in FPGA fabric. And when it comes to SoC + FPGA, like the Microsemi Smartfusion2, a hardcore processor could also be involved in the boot-loading. In other words, the soft CPU might have to improvise a little bit to work on various platforms.

To break the status quo, the PulseRain Reindeer takes a different approach called "hold and load", which  brings a hardware based OCD (on-chip debugger) into the fore, as illustrated below:

![Hold and Load](https://github.com/PulseRain/Reindeer/raw/master/docs/hold_and_load.png "Hold and Load")

The soft CPU and the OCD can share the same UART port, as illustrated above. The RX signal goes to both the soft CPU and OCD, while the TX signal has to go through a mux. And that mux is controlled by the OCD. 

After reset, the soft CPU will be put into a hold state, and it will have access to the UART TX port by default. But a valid debug frame sending from the host PC can let OCD to reconfigure the mux and switch the UART TX to OCD side, for which the memory can be accessed, and the control frames can be exchanged. A new software image can be loaded into the memory during the CPU hold state, which gives rise to the name "hold-and-load". 

After the memory is loaded with the new image, the OCD can setup the start-address of the soft CPU, and send start pulse to make the soft CPU active. At that point, the OCD can switch the UART TX back to the CPU side for CPU's output.
 
As the hold-and-load gets software images from an external host, it does not need any ROM to begin with. This makes it more portable across all FPGA platforms. If Flash is used to store the software image, the OCD can be modified a little bit to read from the flash instead of the external host.

  * # Folder Structure of the Repository
  
  The folder structure of the [GitHub repository](https://github.com/PulseRain/Reindeer) is illustrated below:
  
![Folder Structure](https://github.com/PulseRain/Reindeer/raw/master/docs/folder_structure.png "Folder Structure")
  
**And here is a brief index of the key items in the repository:**
  * **The soft CPU's HDL code**
  
    The platform dependent top level verilog code can be found in https://github.com/PulseRain/Reindeer/tree/master/source. And the platform independent verilog code can be found in https://github.com/PulseRain/Reindeer/tree/master/submodules/PulseRain_MCU
  
  * **Constraint and other FPGA-related files necessary to produce a binary bitstream for the respective hardware**
  
    Synthesis related constraint files can be found in https://github.com/PulseRain/Reindeer/tree/master/build/synth/constraints, and PAR related constraint files can be found in https://github.com/PulseRain/Reindeer/tree/master/build/par/constraints.
  
    To build bitstream for [**Gnarly Grey UPDuinoV2 board**](http://www.latticesemi.com/en/Products/DevelopmentBoardsAndKits/GnarlyGreyUPDuinoBoard), use Lattice Radiant software to open https://github.com/PulseRain/Reindeer/blob/master/build/par/Lattice/UPDuinoV2/UPDuinoV2.rdf
  
    To build bistream for [**Future Electronics Creative board (SmartFusion2)**](https://www.futureelectronics.com/p/development-tools--development-tool-hardware/futurem2sf-evb-future-electronics-dev-tools-3091560), do the following:
  
    1. Use synplify_pro (part of  Microsemi Libero SOC V11.9) to open https://github.com/PulseRain/Reindeer/blob/master/build/synth/Microsemi/Reindeer.prj, and generate Reindeer.vm

    2. Close synplify_pro and use Libero SOC V11.9 to open https://github.com/PulseRain/Reindeer/blob/master/build/par/Microsemi/creative/creative.prjx, import the Reindeer.vm produced in the previous step, and start the build process to generate bitstream. (In the repository, the Reindeer.vm has already been imported and put in https://github.com/PulseRain/Reindeer/tree/master/build/par/Microsemi/creative/hdl.)
  
  * **Binary version of the bitstream** 
  
    *) The Lattice FPGA bitstream for [**Gnarly Grey UPDuinoV2 board**](http://www.latticesemi.com/en/Products/DevelopmentBoardsAndKits/GnarlyGreyUPDuinoBoard) can be found in https://github.com/PulseRain/Reindeer/raw/master/bitstream_and_binary/Lattice/UPDuinoV2/UPDuinoV2_Reindeer.bin

    *) The Microsemi FPGA bitstream for [**Future Electronics Creative board (SmartFusion2)**](https://www.futureelectronics.com/p/development-tools--development-tool-hardware/futurem2sf-evb-future-electronics-dev-tools-3091560) can be found in https://github.com/PulseRain/Reindeer/raw/master/bitstream_and_binary/Microsemi/creative/creative.stp
  
  * # Simulation with [Verilator](https://www.veripool.org/wiki/verilator)

The PulseRain Reindeer can be simulated with [Verialtor](https://www.veripool.org/wiki/verilator). To prepare the simulation, the following steps (tested on Ubuntu and Debian hosts) can be followed: 
  
  1. Install Verilator from https://www.veripool.org/wiki/verilator
  
  2. Install zephyr-SDK, (details can be found in https://docs.zephyrproject.org/latest/getting_started/installation_linux.html)
     
  3. Make sure **riscv32-zephyr-elf-**  tool chain is in $PATH and is accessible everywhere
    
     If default installation path is used for Zephyr SDK, the following can be appended to the .profile or .bash_profile
     
         export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
         
         export ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk
         
         export PATH="/opt/zephyr-sdk/sysroots/x86_64-pokysdk-linux/usr/bin/riscv32-zephyr-elf":$PATH
         
  4. **git clone https://github.com/PulseRain/Reindeer.git**
  
  5. **cd Reindeer/sim/verilator**
  
  6. Build the verilog code and C++ test bench: **make**
  
  7. Run the simulation for compliance test: **make test_all**

If everything goes smooth, the output may look like the following:
  
<a href="https://youtu.be/bs-CplrT9Mo" target="_blank"><img src="https://github.com/PulseRain/Reindeer/raw/master/docs/verilator.GIF" alt="Verilator" width="1008" height="756" border="10" /></a>

As mentioned early, the Reindeer soft CPU uses an OCD to load code/data. And for the [verilator]( https://www.veripool.org/wiki/verilator) simulation, a C++ testbench will replace the OCD. The testbench will invoke the toolchain (riscv32-zephyr-elf-) to extract code/data from sections of the .elf file. The testbench will mimic the OCD bus to load the code/data into CPU's memory.  Afterwards, the start-address of the .elf file ("_start" or "__start" symbol) will be passed onto the CPU, and turn the CPU into active state.

To form a foundation for verification, it is mandatory to pass [55 test cases]( https://github.com/riscv/riscv-compliance/tree/master/riscv-test-suite/rv32i) for RV32I instruction set. For compliance test, the test bench will automatically extract the address for begin_signature and end_signature symbol.
The compliance test will utilize the hold-and-load feature of the PulseRain Reindeer soft CPU, and do the following:
  1. Reset the CPU, put it into hold state
  2. Call upon toolchain to extract code/data from the .elf file for the test case
  3. Start the CPU, run for 2000 clock cycles
  4. Reset the CPU, put it into hold state for the second time
  5. Read the data out of the memory, and compare them against the reference signature

And the diagram below also illustrates the same idea:

  
![Verilator Simulation](https://github.com/PulseRain/Reindeer/raw/master/docs/sim_verilator.png "Verilator Simulation")
  
And for the sake of completeness, the [Makefile for Verilator](https://github.com/PulseRain/Reindeer/blob/master/sim/verilator/Makefile) supports the following targets:
  * **make build** : the default target to build the verilog uut and C++ testbench for Verilator
  * **make test_all** : run compliance test for all 55 cases
  * **make test compliance_case_name** : run compliance test for individual case. For example: make test I-ADD-01
  * **make run elf_file** : run sim on an .elf file for 2000 cycles. For example: make run ../../bitstream_and_binary/zephyr/hello_world.elf

  
  

  * # Running Software on the soft CPU
## Environment Setup for Windows

![Load with Python Script](https://github.com/PulseRain/Reindeer/raw/master/docs/python_load.png "Load with Python Script")
  
As illustrated above, a python script called [**reindeer_config.py**](https://github.com/PulseRain/Reindeer/blob/master/scripts/reindeer_config.py) is provided to load software (.elf file) into the soft CPU and execute. At this point, this script is only tested on Windows platform. Before using this script, the following should be done to setup the environment on Windows:

  1. Install a RISC-V tool chain on Windows
  
     It is recommended to use [**the RISC-V Embedded GCC**](https://gnu-mcu-eclipse.github.io/toolchain/riscv/). And its [**v7.2.0-1-20171109 release**](https://github.com/gnu-mcu-eclipse/riscv-none-gcc/releases/download/v7.2.0-1-20171109/gnu-mcu-eclipse-riscv-none-gcc-7.2.0-1-20171109-1926-win64-setup.exe) can be downloaded from [**here**](https://github.com/gnu-mcu-eclipse/riscv-none-gcc/releases/download/v7.2.0-1-20171109/gnu-mcu-eclipse-riscv-none-gcc-7.2.0-1-20171109-1926-win64-setup.exe)

  2. After installation, add the RISC-V toolchain to system's $PATH
  
     If default installation path is used, most likely the following paths need to be added to system's $PATH:
     
     C:\Program Files\GNU MCU Eclipse\RISC-V Embedded GCC\7.2.0-1-20171109-1926\bin
 
  3. Install python3 on Windows
  
     The latest python for Windows can be downloaded from https://www.python.org/downloads/windows/

  4. After installation, add python binary and pip3 binary into system's $PATH
  
     For example, if python 3.7.1 is installed by user XYZ on Windows 10 in the default path, the following two folders might be added to $PATH:

         C:\Users\XYZ\AppData\Local\Programs\Python\Python37
        
         C:\Users\XYZ\AppData\Local\Programs\Python\Python37\Scripts


  5. open a command prompt (You might need to Run as Administrator), and install the pyserial package for python:
  
     **pip3 install pyserial**

  6. clone the GitHub repository for Reindeer soft CPU
     
     **git clone https://github.com/PulseRain/Reindeer.git**

  7. cd Reindeer/scripts , and type in "python reindeer_config.py -h" for help. The valid command line options are
  
    -r, --reset          : reset the CPU
    -P, --port=          : the name of the COM port, such as COM7
    -d, --baud=          : the baud rate, default to be 115200
    -t, --toolchain=     : setup the toolchain. By default,  riscv-none-embed-  is used
    -e, --elf=           : path and name to the elf image file
    -d, --dump_addr      : start address for memory dumping
    -l, --dump_length    : length of the memory dump
    -c, --console_enable : switch to observe the CPU UART after image is loaded.

  8. Connect the hardware board to the host PC. 

     At this point only two boards are officially supported:

     i.  [**Gnarly Grey UPDuinoV2 board (Lattice UP5K)**](http://www.latticesemi.com/en/Products/DevelopmentBoardsAndKits/GnarlyGreyUPDuinoBoard)
        
     ii. [**Future Electronics Creative board (Microsemi SmartFusion2 M2S025)**](https://www.futureelectronics.com/p/development-tools--development-tool-hardware/futurem2sf-evb-future-electronics-dev-tools-3091560)

     The FPGA bitstreams for the above boards can be found in [**here**](https://github.com/PulseRain/Reindeer/raw/master/bitstream_and_binary/Lattice/UPDuinoV2/UPDuinoV2_Reindeer.bin) and [**here**](https://github.com/PulseRain/Reindeer/raw/master/bitstream_and_binary/Microsemi/creative/creative.stp) respectively.
    
     And the programmer setting for [UPDuinoV2 board](http://www.latticesemi.com/en/Products/DevelopmentBoardsAndKits/GnarlyGreyUPDuinoBoard) can be found in [**here**](https://github.com/PulseRain/Reindeer/raw/master/build/par/Lattice/UPDuinoV2/source/Reindeer.xcf)

  9. Before using the python script, please make sure the boards are programmed with the correct bitstream. 

     If the board is programmed with the bitstream for the first time, unplug and plug the USB cable to make sure the board is properly re-initialized.
     
  10. After the hardware is properly connected to the host PC, open the device manager to figure out which COM port is used by the hardware.
  
  11. Assume COM9 is used by the  hardware, and assume the user wants to run the zephyr hello_world, the follow command can be used:

      **python reindeer_config.py --port=COM9 --reset --elf=C:\GitHub\Reindeer\bitstream_and_binary\zephyr\hello_world.elf --console_enable --run**


If everything is correct, the screen output should be like the following:

    ==============================================================================
    # Copyright (c) 2018, PulseRain Technology LLC
    # Reindeer Configuration Utility, Version 1.0
    ==============================================================================
    baud_rate  =  115200
    com_port   =  COM9
    toolchain  =  riscv-none-embed-
    ==============================================================================
    Reseting CPU ...
    Loading  C:\GitHub\Reindeer\bitstream_and_binary\zephyr\hello_world.elf
    __start 80000000

    //================================================================
    //== Section  vector
    //================================================================
             addr = 0x80000000, length = 1044 (0x414)

    //================================================================
    //== Section  reset
    //================================================================
            addr = 0x80004000, length = 4 (0x4)

    //================================================================
    //== Section  exceptions
    //================================================================
             addr = 0x80004004, length = 620 (0x26c)

    //================================================================
    //== Section  text
    //================================================================
             addr = 0x80004270, length = 7172 (0x1c04)

    //================================================================
    //== Section  devconfig
    //================================================================
             addr = 0x80005e74, length = 36 (0x24)

    //================================================================
    //== Section  rodata
    //================================================================
             addr = 0x80005e98, length = 1216 (0x4c0)

    //================================================================
    //== Section  datas
    //================================================================
             addr = 0x80006358, length = 28 (0x1c)

    //================================================================
    //== Section  initlevel
    //================================================================
             addr = 0x80006374, length = 36 (0x24)

    ===================> start the CPU, entry point = 0x80000000
    ***** Booting Zephyr OS zephyr-v1.13.0-2-gefde7b1e4a *****
    Hello World! riscv32

## Running the Compliance Test on Hardware

All the .elf files for compliance test can be found in https://github.com/PulseRain/Reindeer/tree/master/sim/compliance

To run the compliance test and capture the signature output, please do the following:

1. Determine the case to run. The following will use case [**I-ADD-01**](https://github.com/PulseRain/Reindeer/blob/master/sim/compliance/I-ADD-01.elf) as an example.

2. Determine the signature address. 
  In the case of I-ADD-01, open the file https://github.com/PulseRain/Reindeer/blob/master/sim/compliance/I-ADD-01.out32
  
  The I-ADD-01.out32 shows the address of **begin_signature** and **end_signature** as 0x80002030 and 0x800020e0

3. Use Python Script to load the .elf image of compliance test

  **python reindeer_config.py --port=COM9 --reset --elf=C:\GitHub\Reindeer\sim\compliance\I-ADD-01.elf --dump_addr=0x80002030 --dump_length=176 --run**

  This command will load the test case, and dump the signature data before the test case is executed.

        ====> 80002030 ffffffff
        ====> 80002034 ffffffff
        ====> 80002038 ffffffff
        ====> 8000203c ffffffff
        ====> 80002040 ffffffff
        ====> 80002044 ffffffff
        ====> 80002048 ffffffff
        ====> 8000204c ffffffff
        ====> 80002050 ffffffff
        ====> 80002054 ffffffff
        ====> 80002058 ffffffff
        ====> 8000205c ffffffff
        ====> 80002060 ffffffff
        ====> 80002064 ffffffff
        ====> 80002068 ffffffff
        ====> 8000206c ffffffff
        ====> 80002070 ffffffff
        ====> 80002074 ffffffff
        ====> 80002078 ffffffff
        ====> 8000207c ffffffff
        ====> 80002080 ffffffff
        ====> 80002084 ffffffff
        ====> 80002088 ffffffff
        ====> 8000208c ffffffff
        ====> 80002090 ffffffff
        ====> 80002094 ffffffff
        ====> 80002098 ffffffff
        ====> 8000209c ffffffff
        ====> 800020a0 ffffffff
        ====> 800020a4 ffffffff
        ====> 800020a8 ffffffff
        ====> 800020ac ffffffff
        ====> 800020b0 ffffffff
        ====> 800020b4 ffffffff
        ====> 800020b8 ffffffff
        ====> 800020bc ffffffff
        ====> 800020c0 ffffffff
        ====> 800020c4 ffffffff
        ====> 800020c8 ffffffff
        ====> 800020cc ffffffff
        ====> 800020d0 ffffffff
        ====> 800020d4 ffffffff
        ====> 800020d8 ffffffff
        ====> 800020dc ffffffff


3. Now reset the hardware to put the soft CPU into hold again. And dump the signature region for the 2nd time

  **python reindeer_config.py --port=COM9 --reset --dump_addr=0x80002030 --dump_length=176 --run**

And if it goes smooth, the output should be like the following:

        ====> 80002030 00000000
        ====> 80002034 00000000
        ====> 80002038 00000001
        ====> 8000203c ffffffff
        ====> 80002040 7fffffff
        ====> 80002044 80000000
        ====> 80002048 00000001
        ====> 8000204c 00000001
        ====> 80002050 00000002
        ====> 80002054 00000000
        ====> 80002058 80000000
        ====> 8000205c 80000001
        ====> 80002060 ffffffff
        ====> 80002064 ffffffff
        ====> 80002068 00000000
        ====> 8000206c fffffffe
        ====> 80002070 7ffffffe
        ====> 80002074 7fffffff
        ====> 80002078 7fffffff
        ====> 8000207c 7fffffff
        ====> 80002080 80000000
        ====> 80002084 7ffffffe
        ====> 80002088 fffffffe
        ====> 8000208c ffffffff
        ====> 80002090 80000000
        ====> 80002094 80000000
        ====> 80002098 80000001
        ====> 8000209c 7fffffff
        ====> 800020a0 ffffffff
        ====> 800020a4 00000000
        ====> 800020a8 00000001
        ====> 800020ac 0000abcd
        ====> 800020b0 0000abce
        ====> 800020b4 0000abcf
        ====> 800020b8 0000abd0
        ====> 800020bc 0000abd1
        ====> 800020c0 0000abd2
        ====> 800020c4 0000abd3
        ====> 800020c8 00000000
        ====> 800020cc 00000000
        ====> 800020d0 00000000
        ====> 800020d4 36925814
        ====> 800020d8 36925814
        ====> 800020dc 36925814

compare the above output against the signature in https://github.com/riscv/riscv-compliance/blob/master/riscv-test-suite/rv32i/references/I-ADD-01.reference_output


## Running the Zephor Sample Application

The PulseRain Reindeer soft CPU has been successfully verified with the following 3 Zephyr applications. 
* hello_world
* synchronization
* philosophers

And the .elf image of those applications can be found in [**Reindeer/bitstream_and_binary/zephyr/**](https://github.com/PulseRain/Reindeer/tree/master/bitstream_and_binary/zephyr)

To run the synchronization applications, please do the following:
 
**python reindeer_config.py --port=COM9 --reset --elf=C:\GitHub\Reindeer\bitstream_and_binary\zephyr\synchronization.elf --console_enable --run**

And the output is like

        ***** Booting Zephyr OS zephyr-v1.13.0-2-gefde7b1e4a *****
        threadA: Hello World from riscv32!
        threadB: Hello World from riscv32!
        threadA: Hello World from riscv32!
        threadB: Hello World from riscv32!
        threadA: Hello World from riscv32!
        threadB: Hello World from riscv32!


To run the philosophers application, please do the following:
 
**python reindeer_config.py --port=COM9 --reset --elf=C:\GitHub\Reindeer\bitstream_and_binary\zephyr\philosophers.elf --console_enable --run**

And the output is like

        ***** Booting Zephyr OS zephyr-v1.13.0-2-gefde7b1e4a *****
         [2J [15;1HDemo Description
        ----------------
        An implementation of a solution to the Dining Philosophers
        problem (a classic multi-thread synchronization problem).
        This particular implementation demonstrates the usage of multiple
        preemptible and cooperative threads of differing priorities, as
        well as dynamic mutexes and thread sleeping.
         [5;1HPhilosopher 4 [C:-1]        STARVING
         [5;1HPhilosopher 4 [C:-1]    HOLDING ONE FORK
         [5;1HPhilosopher 4 [C:-1]   EATING  [  25 ms ]
         [6;1HPhilosopher 5 [C:-2]        STARVING
        ...

One thing special about philosophers application is that its output is targeting a VT100 terminal instead of command line. To view its output better, it is recommended to press "ctrl-c" to quit the python script, and use a terminal emulator (such as Tera Term or Putty) to view it. The terminal emulator should be set as **115200 baud rate, 8 bit data, none parity, 1 stop bit and no flow control**. The following is the better view for the philosophers

![zephyr philosophers](https://github.com/PulseRain/Reindeer/raw/master/docs/philosophers.GIF "zephyr philosophers")

## Running the Benchmark

Thanks to its 2 x 2 pipeline layout, the PulseRain Reindeer can close at very high clock rate.
 
At this point, the bitstream for [**Gnarly Grey UPDuinoV2 board (Lattice UP5K)**](http://www.latticesemi.com/en/Products/DevelopmentBoardsAndKits/GnarlyGreyUPDuinoBoard) runs at **24MHz**, while the bitstream for 
[**Future Electronics Creative board (Microsemi SmartFusion2 M2S025)**](https://www.futureelectronics.com/p/development-tools--development-tool-hardware/futurem2sf-evb-future-electronics-dev-tools-3091560) runs at **160MHz**. 

*Please note that there is no crystal oscillator on the UPDuinoV2 board. The FPGA on that board runs off an on-chip RC oscillator (HSOSC primitive). And the HSOSC only supports 12MHz, 24MHz or 48MHz option. There is no middle ground between those frequencies. That's why 24MHz is chosen for the UPDuinoV2.*

[**Dhrystone**](https://github.com/PulseRain/riscv-tests/tree/master/benchmarks/dhrystone) has been ported to the Reindeer soft CPU for RV32I instruction set. Its .elf image file (160MHz) is at [**here**](https://github.com/PulseRain/Reindeer/raw/master/bitstream_and_binary/Dhrystone/dhrystone_RV32I.riscv).

To run the Dhrystone, please do the followiing:

**python reindeer_config.py --port=COM9 --reset --elf=C:\GitHub\Reindeer\bitstream_and_binary\Dhrystone\dhrystone_RV32I.riscv --console_enable --run**

For RV32I, Reindeer soft CPU can score 71364 on [**Future Electronics Creative board (Microsemi SmartFusion2 M2S025)**](https://www.futureelectronics.com/p/development-tools--development-tool-hardware/futurem2sf-evb-future-electronics-dev-tools-3091560)
The score on [**Gnarly Grey UPDuinoV2 board (Lattice UP5K)**](http://www.latticesemi.com/en/Products/DevelopmentBoardsAndKits/GnarlyGreyUPDuinoBoard) is simply scaled by a factor of 24/160.

For RV32IM, Reindeer soft CPU can score 81967 on [**Future Electronics Creative board (Microsemi SmartFusion2 M2S025)**](https://www.futureelectronics.com/p/development-tools--development-tool-hardware/futurem2sf-evb-future-electronics-dev-tools-3091560)


  * # Regenerate the Bitstream
  
## [**Gnarly Grey UPDuinoV2 board (Lattice UP5K)**](http://www.latticesemi.com/en/Products/DevelopmentBoardsAndKits/GnarlyGreyUPDuinoBoard)

Use Lattice Radiant software to open https://github.com/PulseRain/Reindeer/blob/master/build/par/Lattice/UPDuinoV2/UPDuinoV2.rdf and build

## [**Future Electronics Creative board (Microsemi SmartFusion2 M2S025)**](https://www.futureelectronics.com/p/development-tools--development-tool-hardware/futurem2sf-evb-future-electronics-dev-tools-3091560)

1. Use synplify_pro (part of  Microsemi Libero SOC V11.9) to open https://github.com/PulseRain/Reindeer/blob/master/build/synth/Microsemi/Reindeer.prj, and generate Reindeer.vm

2. Close synplify_pro and use Libero SOC V11.9 to open https://github.com/PulseRain/Reindeer/blob/master/build/par/Microsemi/creative/creative.prjx, import the Reindeer.vm produced in the previous step, and start the build process to generate bitstream. (In the repository, the Reindeer.vm has already been imported and put in https://github.com/PulseRain/Reindeer/tree/master/build/par/Microsemi/creative/hdl.)

    
  * # Miscellaneous 
## UART Configuration

Both [**Gnarly Grey UPDuinoV2 board (Lattice UP5K)**](http://www.latticesemi.com/en/Products/DevelopmentBoardsAndKits/GnarlyGreyUPDuinoBoard) and [**Future Electronics Creative board (Microsemi SmartFusion2 M2S025)**](https://www.futureelectronics.com/p/development-tools--development-tool-hardware/futurem2sf-evb-future-electronics-dev-tools-3091560) have FTDI chip that can convert between UART and USB. And the UART can be shared by the programmer and the FPGA. So there is no need for extra wire to make additional serial port. If terminal emulator software is used, the UART should be configured as **115200 baud rate, 8 bit data, none parity, 1 stop bit and no flow control** 

## LED

The status of the soft CPU is indicated by different color of LEDs on both [**Gnarly Grey UPDuinoV2 board (Lattice UP5K)**](http://www.latticesemi.com/en/Products/DevelopmentBoardsAndKits/GnarlyGreyUPDuinoBoard) and [**Future Electronics Creative board (Microsemi SmartFusion2 M2S025)**](https://www.futureelectronics.com/p/development-tools--development-tool-hardware/futurem2sf-evb-future-electronics-dev-tools-3091560). After power on reset, the LED will turn red, which indicates the hold/paused state. When the soft CPU becomes active, the LED will turn into green.

## Configuration of the soft CPU

For Lattice UP5K FPGA, the configuration of soft CPU is determined by https://github.com/PulseRain/Reindeer/raw/master/submodules/PulseRain_MCU/common/Lattice/UP5K/config.vh.

For Microsemi SmartFusion2 FPGA, the configuration of soft CPU is determined by https://github.com/PulseRain/Reindeer/raw/master/submodules/PulseRain_MCU/common/Microsemi/SmartFusion2/config.vh

By default, the Reindeer soft CPU only supports RV32I. To make it support hardware mul/div (RV32IM), please turn "`define ENABLE_HW_MUL_DIV" to 1 in config.h, and rebuild to generate a new bitstream.


  
 
