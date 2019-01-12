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

from collections import namedtuple

class ROM_Hex_Format:

    _data_record = namedtuple ("data_record", "address byte_count data_list")
    
    @property
    def start_address(self):
        return self._start_address
            
    @property
    def data_record_list(self):
        return self._data_record_list
    
    def _data_extract(self):
        return []
        
    def __init__ (self, file_name="", addr_length_in_bytes=0, hex_list=[]):
        self.hex_list = hex_list
        self.word_addr_factor = 1
        self.file_name = file_name
        self._addr_length_in_bytes = addr_length_in_bytes
        (self._start_address, self._data_record_list) = self._data_extract()
        
    def _get_data_record_key (self, record):
        return record.address
        
class Intel_Hex(ROM_Hex_Format):

    _RECORD_TYPE_DATA              = 0
    _RECORD_TYPE_EOF               = 1
    _RECORD_TYPE_EXT_SEG_ADDR      = 2
    _RECORD_TYPE_START_SEG_ADDR    = 3
    _RECORD_TYPE_EXT_LINEAR_ADDR   = 4
    _RECORD_TYPE_START_LINEAR_ADDR = 5
     
    def _line_process(self, line, data_record_list):
        tmp_line = line.strip()
        assert (tmp_line[0] == ':')
        byte_count = int(tmp_line[1:3], 16)
        address = int (tmp_line[3:7], 16)
        record_type = int (tmp_line[7:9], 16)
                    
        #assert (record_type <= self._RECORD_TYPE_EXT_SEG_ADDR)
        checksum_in_file = int (tmp_line[9 + byte_count * 2: 11 + byte_count * 2], 16)
        checksum = 0
                    
        if (record_type == self._RECORD_TYPE_DATA):
            data = []
            for i in range (0, byte_count * 2, 2):
                data_byte = int (tmp_line [9 + i : 11 + i], 16)
                data.append(data_byte)
                checksum = (checksum + data_byte) % 256
            
            checksum = checksum + byte_count
            checksum = checksum + record_type
            checksum = checksum + (address & 0xFF)
            checksum = checksum + ((address >> 8) & 0xFF)
            checksum = (256- (checksum % 256)) % 256
            
            assert (checksum == checksum_in_file)
            
            assert (len(data) == byte_count)
            address = self.base_segment_addr * 65536 + address * self.word_addr_factor
            
            data_record_list.append(self._data_record(address, byte_count, data))
            self.total_size = self.total_size + byte_count;
            
            #if (address < 50):
            #    print ("addr = ", address, "cnt = ", byte_count, "data = ", [hex(i) for i in data])
            
        elif (record_type == self._RECORD_TYPE_EOF):
            assert (tmp_line == ":00000001FF")
        elif (record_type == self._RECORD_TYPE_EXT_LINEAR_ADDR):
            assert (byte_count == 2)
            assert (address == 0)
            self.base_segment_addr = int (tmp_line[9:13], 16)
            
        elif (record_type == self._RECORD_TYPE_START_LINEAR_ADDR):
            self.entry_addr = int (tmp_line[9:17], 16)
        else:
            assert (tmp_line == ":020000020000FC")
            self.word_addr_factor = 4
        
        return data_record_list
    
        
    def _data_extract(self):
        data_record_list = []
        word_addr_factor = 1
        try:
            
            if (not self.file_name):
                for line in self.hex_list:
                    data_record_list = self._line_process (line, data_record_list)
                    
            else:
                with open (self.file_name) as file:
                    for line in file:
                        data_record_list = self._line_process (line, data_record_list)
                    
            sorted_data_record_list = sorted (data_record_list, key=self._get_data_record_key)
            sorted_data_record_list.append(self._data_record(0, 0, []))
                        
        except IOError:
            print ("Fail to open Hex File: ", self.file_name)
            return (0, [])
                    
        return (0, sorted_data_record_list)     
            
    
    def __init__ (self, file_name="", addr_length_in_bytes=0, hex_list=[]):
        self.base_segment_addr = 0
        self.entry_addr = 0
        self.total_size = 0
        super().__init__ (file_name, addr_length_in_bytes, hex_list)
       
    
    
class Motorola_SREC(ROM_Hex_Format):
    _RECORD_TYPE_HEADER          = 0
    _RECORD_TYPE_DATA_16BIT_ADDR = 1
    _RECORD_TYPE_DATA_24BIT_ADDR = 2
    _RECORD_TYPE_DATA_32BIT_ADDR = 3
    _RECORD_TYPE_RESERVED        = 4
    _RECORD_TYPE_16BIT_COUNT     = 5
    _RECORD_TYPE_24BIT_COUNT     = 6
    _RECORD_TYPE_32BIT_ADDR_TERM = 7
    _RECORD_TYPE_24BIT_ADDR_TERM = 8
    _RECORD_TYPE_16BIT_ADDR_TERM = 9
    
    
    def _data_extract(self):
        data_record_list = []
        total_data_record = 0
        record_count_in_file = 0
        start_address_in_file = 0
        
        with open (self.file_name) as file:
            for line in file:
                tmp_line = line.strip()
                assert (tmp_line[0] == 'S')
                
                record_type = int (tmp_line[1:2], 16)
                
                addr_length_in_bytes = 0
                record_count_in_bytes = 0
                start_addr_in_bytes = 0
                header_length_in_bytes = 0
              
                if (record_type == self._RECORD_TYPE_HEADER):
                    print ("It is a header")
                elif (record_type == self._RECORD_TYPE_DATA_16BIT_ADDR):
                    addr_length_in_bytes = 2
                elif (record_type == self._RECORD_TYPE_DATA_24BIT_ADDR):
                    addr_length_in_bytes = 3
                elif (record_type == self._RECORD_TYPE_DATA_32BIT_ADDR):
                    addr_length_in_bytes = 4
                elif (record_type == self._RECORD_TYPE_16BIT_COUNT):
                    record_count_in_bytes = 2
                elif (record_type == self._RECORD_TYPE_24BIT_COUNT):
                    record_count_in_bytes = 3
                elif (record_type == self._RECORD_TYPE_32BIT_ADDR_TERM):
                    start_addr_in_bytes = 4
                elif (record_type == self._RECORD_TYPE_24BIT_ADDR_TERM):
                    start_addr_in_bytes = 3
                elif (record_type == self._RECORD_TYPE_16BIT_ADDR_TERM):
                    start_addr_in_bytes = 2
                else:
                    assert 0, "unknown record type"
                
                if (self._addr_length_in_bytes and addr_length_in_bytes):
                        addr_length_in_bytes = self._addr_length_in_bytes
                
                byte_count = int (tmp_line[2:4], 16)
                
                if (addr_length_in_bytes):
                    assert (~record_count_in_bytes)
                    assert (~start_addr_in_bytes)
                    assert (~header_length_in_bytes)
                    
                    address = int (tmp_line [4: 4 + addr_length_in_bytes*2], 16)
                        
                    data = []
                    total_data_record = total_data_record + 1
                    for i in range (0, (byte_count - addr_length_in_bytes - 1)  * 2, 2):
                        data_byte = int (tmp_line [4 + addr_length_in_bytes*2 + i : 6 + addr_length_in_bytes*2 + i], 16)
                        data.append(data_byte)
                                        
                    data_record_list.append(self._data_record(address, byte_count - addr_length_in_bytes - 1, data))
                    print (data)
                   
                   
                if (record_count_in_bytes):
                    assert (~addr_length_in_bytes)
                    assert (~start_addr_in_bytes)
                    assert (~header_length_in_bytes)
                    
                    record_count_in_file = int (tmp_line [4: 4 + record_count_in_bytes*2], 16)
                                   
                if (start_addr_in_bytes):
                    assert (~addr_length_in_bytes)
                    assert (~record_count_in_bytes)
                    assert (~header_length_in_bytes)
                    
                    start_address_in_file = int (tmp_line [4: 4 + start_addr_in_bytes*2], 16)
                    
                content_length_in_bytes = header_length_in_bytes + addr_length_in_bytes + record_count_in_bytes + start_addr_in_bytes;
                assert (content_length_in_bytes)
                
                checksum = 0
                for i in range (0, byte_count * 2, 2):
                    print (tmp_line [2 + i: 4 + i])
                    checksum = (checksum + int (tmp_line [2 + i: 4 + i], 16)) % 256
                    
                checksum = 255 - checksum
                checksum_in_file = int (tmp_line[2 + byte_count * 2: 4 + byte_count * 2], 16)
                assert (checksum == checksum_in_file)
        
        if (record_count_in_file):
            assert (record_count_in_file == total_data_record)
            
        return (start_address_in_file, data_record_list)     



            
def main():
     # intel_hex_file =  Intel_Hex("./hello.ihx")
      intel_hex_file =  Intel_Hex("./sketch_dec22a.ino.hex")
     # data_record_list = rom_hex_file.data_extract()
      print (intel_hex_file.data_record_list)
      print (intel_hex_file.start_address)
      
      
      for record in intel_hex_file.data_record_list:
            print ("addr = %x" % record.address)
#      motorola_srec_file = Motorola_SREC("./hello.s37", 3)
 #     print (motorola_srec_file.data_record_list)
  #    print (motorola_srec_file.start_address)
      
      print (intel_hex_file.total_size)
      
if __name__ == "__main__":
    main()        

