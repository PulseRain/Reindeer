#!/usr/bin/python3
###############################################################################
# Copyright (c) 2018, PulseRain Technology LLC 
#
# This program is distributed under a dual license: an open source license, 
# and a commercial license. 
# 
# The open source license under which this program is distributed is the 
# GNU Public License version 3 (GPLv3).
#
# And for those who want to use this program in ways that are incompatible
# with the GPLv3, PulseRain Technology LLC offers commercial license instead.
# Please contact PulseRain Technology LLC (www.pulserain.com) for more detail.
#
###############################################################################

import sys
from ROM_Hex_Format import *


#==============================================================================
# main            
#==============================================================================

if __name__ == "__main__":

    #=========================================================================
    # print banner
    #=========================================================================
    
    print ("===============================================================================")
    print ("# Copyright (c) 2019, PulseRain Technology LLC ")
    print ("# Utility for Hex File Total Size, Version 1.0")
    print (" ")
    
    #=========================================================================
    # get command line options
    #=========================================================================
    
    if (len(sys.argv) < 2):
        print ("Please provide file name for hex file.")
        sys.exit(1)
    
    file_name = sys.argv[1]
    
    intel_hex_file =  Intel_Hex(file_name)
    
    print ("Total ", intel_hex_file.total_size)
    