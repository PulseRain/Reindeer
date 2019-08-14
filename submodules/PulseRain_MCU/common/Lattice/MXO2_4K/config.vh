/*
###############################################################################
# Copyright (c) 2018, PulseRain Technology LLC 
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
###############################################################################
*/

`ifndef CONFIG_VH
`define CONFIG_VH


//----------------------------------------------------------------------------
//  memory size 
//----------------------------------------------------------------------------

`define MEM_SIZE_IN_BYTES   (8 * 1024)
`define MEM_ADDR_BITS       ($clog2(`MEM_SIZE_IN_BYTES / 4))

`define MM_REG_SIZE_IN_BYTES   (32)
`define MM_REG_ADDR_BITS       ($clog2(`MM_REG_SIZE_IN_BYTES / 4))

`define DEFAULT_STACK_ADDR    (((`MEM_SIZE_IN_BYTES) - 8)| 32'h80000000)

//----------------------------------------------------------------------------
//  clock 
//----------------------------------------------------------------------------
`define MCU_MAIN_CLK_RATE                  36000000


//----------------------------------------------------------------------------
//  peripheral addresses
//----------------------------------------------------------------------------

`define UART_TX_ADDR                       (3'b100)
`define UART_BAUD_RATE                      115200
`define UART_TX_BAUD_PERIOD                (`MCU_MAIN_CLK_RATE / `UART_BAUD_RATE)
`define UART_TX_BAUD_PERIOD_BITS           ($clog2(`UART_TX_BAUD_PERIOD))
`define UART_STABLE_COUNT                  (`MCU_MAIN_CLK_RATE  / `UART_BAUD_RATE / 2)

`define MTIME_LOW_ADDR                     (3'b000)
`define MTIME_HIGH_ADDR                    (3'b001)

`define MTIMECMP_LOW_ADDR                  (3'b010)
`define MTIMECMP_HIGH_ADDR                 (3'b011)

//----------------------------------------------------------------------------
//  hardware mul/div
//----------------------------------------------------------------------------

`define DISABLE_OCD                         0

`define ENABLE_HW_MUL_DIV                   0

`define SMALL_MACHINE_TIMER                 0
`define SMALL_CSR_SET                       0

`endif
