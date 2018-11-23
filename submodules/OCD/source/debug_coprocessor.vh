`ifndef DEBUG_COPROCESSOR_VH
`define DEBUG_COPROCESSOR_VH

`define                     DEBUG_DATA_WIDTH        8
`define                     DEBUG_FRAME_LENGTH      12
`define                     DEBUG_EXT_FRAME_LENGTH (`DEBUG_FRAME_LENGTH + 128 - 4 + 2) // 128 bytes data, minus 4 in the front, with 16 bit CRC

`define                     DEBUG_SYNC_LENGTH       3
`define                     DEBUG_CRC_LEN           2
`define                     DEBUG_FRAME_TYPE_LEN    1
`define                     DEBUG_FRAME_ADDR_LEN    2
`define                     DEBUG_FRAME_DATA_LEN    (`DEBUG_FRAME_LENGTH - `DEBUG_SYNC_LENGTH - `DEBUG_CRC_LEN - `DEBUG_FRAME_TYPE_LEN - `DEBUG_FRAME_ADDR_LEN)

`define                     DEBUG_SYNC              (24'h5AA501)
`define                     DEBUG_SYNC_2            (8'h5A)
`define                     DEBUG_SYNC_1            (8'hA5)
`define                     DEBUG_SYNC_0            (8'h01)


`define                     DEBUG_REPLY_SYNC        (24'h80A55A)

`define                     DEBUG_TYPE_PRAM_WRITE_4_BYTES_WITHOUT_ACK   (7'b101_1100)
`define                     DEBUG_TYPE_PRAM_WRITE_4_BYTES_WITH_ACK      (7'b101_1101)

`define                     DEBUG_TYPE_PRAM_WRITE_128_BYTES_WITH_ACK    (7'b101_1011)
`define                     DEBUG_TYPE_PRAM_READ_4_BYTES                (7'b110_1101)
`define                     DEBUG_TYPE_PAUSE_ON_WITH_ACK                (7'b010_1101)
`define                     DEBUG_TYPE_PAUSE_OFF_WITH_ACK               (7'b011_1101)

`define                     DEBUG_TYPE_BREAK_ON_WITH_ACK                (7'b111_1101)
`define                     DEBUG_TYPE_BREAK_OFF_WITH_ACK               (7'b001_1101)

`define                     DEBUG_TYPE_CPU_RESET_WITH_ACK               (7'b100_1011)
`define                     DEBUG_TYPE_RUN_PULSE_WITH_ACK               (7'b100_1001)
`define                     DEBUG_TYPE_READ_CPU_STATUS                  (7'b010_1111)
`define                     DEBUG_TYPE_READ_DATA_MEM                    (7'b110_1111)
`define                     DEBUG_TYPE_WRITE_DATA_MEM                   (7'b010_1011)
`define                     DEBUG_TYPE_UART_SEL                         (7'b010_1010)
`define                     DEBUG_TYPE_COUNTER_CONFIG                   (7'b110_1011)

`define                     DEBUG_TYPE_ACK                              (7'b110_0101) 

`define                     DEBUG_PRAM_ADDR_WIDTH                       16
`define                     DEBUG_ACK_PAYLOAD_BITS                      (7 * 8)
`define                     DEBUG_CPU_RESET_LENGTH                      6

`define                     OP_DBG_ACK                                  0
`define                     OP_READ_BACK_4_BYTES                        1
`define                     OP_CPU_STATUS_ACK                           2
`define                     OP_DATA_MEM_READ                            3

`define                     DBG_NUM_OF_OPERATIONS                       4

`endif


