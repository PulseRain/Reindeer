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

#ifndef _ARDUINO_H
#define _ARDUINO_H

#include "common_type.h"
#include "peripherals.h"

//============================================================================================
// Constant definition
//============================================================================================

constexpr uint8_t INPUT  = 0;
constexpr uint8_t OUTPUT = 1;

constexpr uint8_t HIGH   = 1;
constexpr uint8_t LOW    = 0;

#ifndef false
#define false 0
#endif

#ifndef true
#define true 1
#endif

//============================================================================================
// Function prototype
//============================================================================================
extern uint32_t micros ();
extern uint32_t millis ();

#endif
