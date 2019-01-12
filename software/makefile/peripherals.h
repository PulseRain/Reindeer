/*
###############################################################################
# Copyright (c) 2016, PulseRain Technology LLC 
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License (LGPL) as 
# published by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
# or FITNESS FOR A PARTICULAR PURPOSE.  
# See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
###############################################################################
*/
#ifndef PERIPHERALS_H
#define PERIPHERALS_H

#include "common_type.h"

//============================================================================================
// UART 
//============================================================================================

volatile uint32_t* const REG_UART_TX = (uint32_t*) 0x20000010;

//============================================================================================
// MTIME 
//============================================================================================
volatile uint32_t* const REG_MTIME_LOW  = (uint32_t*) 0x20000008;
volatile uint32_t* const REG_MTIME_HIGH = (uint32_t*) 0x2000000C;



#endif
