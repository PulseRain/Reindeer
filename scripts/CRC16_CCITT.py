#! python3
###############################################################################
# Copyright (c) 2016, PulseRain Technology LLC 
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
###############################################################################



###############################################################################
# References:
# http://stackoverflow.com/questions/25239423/crc-ccitt-16-bit-python-manual-calculation
###############################################################################

class CRC16_CCITT:
    
    _POLYNOMIAL = 0x1021
    _PRESET = 0xFFFF

    def _initial(self, c):
        crc = 0
        c = c << 8
        for j in range(8):
            if (crc ^ c) & 0x8000:
                crc = (crc << 1) ^ self._POLYNOMIAL
            else:
                crc = crc << 1
            c = c << 1
            
        return crc
   
    def _update_crc(self, crc, c):
        cc = 0xff & c

        tmp = (crc >> 8) ^ cc
        crc = (crc << 8) ^ self._tab[tmp & 0xff]
        crc = crc & 0xffff

        return crc
    
    def __init__ (self):
        self._tab = [ self._initial(i) for i in range(256) ]
    
    def get_crc (self, data_list):
        crc = self._PRESET
        for c in data_list:
            crc = self._update_crc(crc, c)
        return [(crc >> 8) & 0xFF, crc & 0xFF]     
    
    
def main():

    crc = CRC16_CCITT ()
    
    for i in range(256):
        print ("0x{0:08x},".format(crc._tab[i]))
    
if __name__ == "__main__":
    main()
    