/*
###############################################################################
# Copyright (c) 2018, PulseRain Technology LLC 
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

#ifndef COMMON_TYPE_H
#define COMMON_TYPE_H


//============================================================================================
// Data Type Definition
//============================================================================================

typedef unsigned long long  uint64_t;
typedef long long           int64_t;

typedef unsigned long       uint32_t;
typedef long                int32_t;

typedef unsigned short      uint16_t;
typedef short               int16_t;

typedef unsigned char       uint8_t;
typedef signed char         int8_t;

static_assert(sizeof(uint32_t) == 4, "");
static_assert(sizeof(int32_t)  == 4, "");

static_assert(sizeof(uint16_t) == 2, "");
static_assert(sizeof(int16_t)  == 2, "");

static_assert(sizeof(uint8_t)  == 1, "");
static_assert(sizeof(int8_t)   == 1, "");

typedef uint8_t byte;
typedef uint16_t word;
typedef uint8_t boolean;

#endif
