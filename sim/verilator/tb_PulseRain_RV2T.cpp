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

#include "verilated.h"
#include <chrono>
#include <thread>
#include <getopt.h>
#include <cstdio>
#include <iostream>
#include  <iomanip>
#include <ios>
#include <fstream>
#include <memory>
#include <stdexcept>
#include <string>
#include <array>
#include <regex>
#include <list>
#include "VPulseRain_RV2T_MCU.h"

constexpr vluint64_t TOTAL_RUN_CYCLES = 2000;
constexpr vluint32_t DEFAULT_STACK_INIT_VALUE  = 0x8000F000;

std::list <vluint32_t> sig_list;

VPulseRain_RV2T_MCU *uut;

typedef VPulseRain_RV2T_MCU UUT;


//===========================================================================
// TOOL-CHAIN
//===========================================================================
// toolchain prefix, which can be also set by command line parameters
//===========================================================================

std::string toolchain {"riscv32-zephyr-elf-"};



//===========================================================================
// elf file generated based on  
// https://github.com/riscv/riscv-compliance
//===========================================================================

std::string elf_file {""};

//===========================================================================
// reference file from 
// https://github.com/riscv/riscv-compliance/tree/master/riscv-test-suite/rv32i/references
//===========================================================================

std::string ref_file {""};

//===========================================================================
// start address  
//===========================================================================

vluint32_t start_address = 0x80000000;

//===========================================================================
// address of "begin_signature", "end_signature"  
//===========================================================================

vluint32_t begin_signature_addr = 0x80000000;
vluint32_t end_signature_addr   = 0x80000000;

//===========================================================================
// class of testbench
//===========================================================================
class testbench
{
    public:
    
        vluint64_t main_time;
        vluint32_t cycles;
        
        testbench (const vluint32_t p, UUT *u) : 
            clk_period(p), 
            clk_half_period (p / 2),
            uut (u)
        {
            main_time = 0;
            uut->clk = 0;
            uut->reset_n = 0;
            uut->start = 0;
            cycles = 0;
        }
    
        void run (vluint32_t num_of_cycles = 1)
        {
            vluint64_t end_time = main_time + (vluint64_t)(num_of_cycles * clk_period);
            
            while (end_time > main_time) {
                half_cycle();
              //  uut->eval();
            }
            
            cycles += num_of_cycles;
        }
        
        void reset (vluint32_t num_of_cycles = 10)
        {
            vluint64_t end_time = main_time + (vluint64_t)(num_of_cycles * clk_period);
            
            uut->clk = 0;
            uut->reset_n = 0;
            uut->eval();
            
            run (num_of_cycles);
            uut->reset_n = 1;
            uut->eval();
            
            cycles += num_of_cycles;
            
        }
   
    private:
        
        const vluint32_t clk_period;
        const vluint32_t clk_half_period;
        UUT *uut;
        
        void half_cycle ()
        {
            
            main_time += (vluint64_t)clk_half_period;
            uut->clk = 1 - uut->clk;
            uut->eval();
            
        }
        
};



//===========================================================================
// exec()
//
// Remarks:
//      function to execute shell command and capture the output
//===========================================================================
std::string exec(const char* cmd) {
    std::array<char, 1024> buffer;
    std::string result;
    
    std::string new_cmd {cmd};
    new_cmd += " 2>&1";

    std::shared_ptr<FILE> pipe(popen(new_cmd.c_str(), "r"), pclose);
    if (!pipe) {
      throw std::runtime_error("popen() failed!");
    }

    while (!feof(pipe.get())) {
        if (fgets(buffer.data(), 1024, pipe.get()) != nullptr)
            result += buffer.data();
    }
    return result;
} // End of exec()


//===========================================================================
// Lists for ELF sections
//===========================================================================

typedef struct {
    std::string       name;
    unsigned long     size;
    unsigned long     vma;
    unsigned long     lma;
} section_t;

std::list <section_t> section_list;
std::list <std::vector<std::string>> section_property_list;
std::list <std::string> section_name_list;



std::string bin_file_name (std::string name)
{
    return "./obj_dir/" + name + ".bin";
}

//===========================================================================
// prepare_elf_section_list()
//
// Remarks:
//      parse elf file to extract information for each section
//===========================================================================

void prepare_elf_section_list(std::string elf_file)
{
    std::string objdump = toolchain + "objdump";
    std::string objcopy = toolchain + "objcopy";
    
    std::string cmd = objdump + " -h " + elf_file;
    
    //==std::cout << "cmd ==> " << cmd << "\n";
    
    std::string cmd_output {exec (cmd.c_str())};
    
    //std::cout << "output is ============> \n" << cmd_output << "\n";
   
   
    std::regex section_regexp {"^\\s*\\d*\\s([\\.|\\-|\\w]*)\\s*(\\w*)\\s*(\\w*)\\s*(\\w*)"};
    std::smatch m;
    
    std::istringstream iss {cmd_output};
 
    //std::cout << "**********************************************\n";
        
    bool capture_next = false;
    section_t section;
    
    for (std::string line; std::getline(iss, line); ) {
        if (capture_next) {
            std::istringstream iss(line);
            
            std::vector<std::string> 
                results(std::istream_iterator<std::string>{iss},
                                 std::istream_iterator<std::string>());    
        
            section_property_list.push_back (results);
            section_name_list.push_back (section.name);
            
            
           // for (std::vector<std::string>::const_iterator i = results.begin(); i != results.end(); ++i) {
           //         std::cout << *i << '*';
           // }
           // std::cout << "\n";
        }
                                 
        capture_next = false;
        if (std::regex_search (line, m, section_regexp)) {
           
            if (!std::string(m[2]).empty()) {
                capture_next = true;
                section.name = m[1];
                section.size = std::stoul(m[2], nullptr, 16);
                section.vma  = std::stoul(m[3], nullptr, 16);
                section.lma  = std::stoul(m[4], nullptr, 16);
            
                section_list.push_back(section);
            }
        }
        
        
    }

//    std::cout << "#########################################\n";
    auto it_property = section_property_list.begin();
    bool generate_bin_file;
    
    for (auto name = section_name_list.begin(); name != section_name_list.end(); ++name) {
        
        generate_bin_file = false;
        
        for (std::vector<std::string>::const_iterator i = it_property->begin(); i != it_property->end(); ++i) {
            if (i->rfind ("LOAD", 0) == 0) {
                generate_bin_file = true;
            }
        } // End of for i    
        
        if (generate_bin_file) {
            cmd = objcopy + " --dump-section " + '\"' + *name + "=" + \
                  bin_file_name (*name) + '\"' + " " + elf_file;
            
           // std::cout << cmd << "\n";
        
            exec (cmd.c_str());
        }
        
        ++it_property;
    }

}


//===========================================================================
// uut_memory_load()
//
// Remarks:
//      load data into UUT's memory
//===========================================================================

void uut_memory_load (testbench *tb, UUT *uut, unsigned char* memblock, unsigned long lma, unsigned long length)
{
    vluint32_t addr;
    vluint32_t data;
    vluint32_t offset;
    
    for (addr = lma; addr < (lma + length); addr = addr + 4) {
        offset = addr - lma;
        data = (memblock[offset] & 0xFF) + ((memblock[offset + 1] << 8) & 0xFF00) + 
                  ((memblock[offset + 2] << 16) & 0xFF0000) + ((memblock[offset + 3] << 24) & 0xFF000000);
        std::cout << "\t" << std::setfill('0') << std::setw(8) << std::hex << addr << " " << std::setfill('0') << std::setw(8) << data << std::dec << "\n";
       
        uut->ocd_rw_addr = addr >> 2;
        uut->ocd_write_word = data;
        uut->ocd_write_enable = 1;
        tb->run();
        uut->ocd_write_enable = 0;
        tb->run();
 
    } // End of for loop
    
} // End of uut_memory_load()


//===========================================================================
// uut_memory_peek()
//
// Remarks:
//      read UUT's memory
//===========================================================================

int uut_memory_peek (testbench *tb, UUT *uut, unsigned long lma, unsigned long length, bool to_match_sig_list = false)
{
    vluint32_t addr;
    vluint32_t data;
    vluint32_t offset;
    
    
    std::list<vluint32_t>::iterator  sig_it {} ;
    
    int mismatch = 0;
    
    
    if (sig_list.size()) {
        sig_it = sig_list.begin();
    }
    
    for (addr = lma; addr < (lma + length); addr = addr + 4) {
        offset = addr - lma;
        
        uut->ocd_rw_addr = (addr >> 2);
        uut->ocd_write_word = 0;
        uut->ocd_write_enable = 0;
        uut->ocd_read_enable = 1;
        tb->run();
        uut->ocd_read_enable = 0;
        tb->run();
       
        data = uut->ocd_mem_word_out;    
        
        std::cout << "\t" << std::setfill('0') << std::setw(8) << std::hex << addr << " " << std::setfill('0') << std::setw(8) << data << std::dec << " ";
        
        if (to_match_sig_list && sig_list.size()) {
            if( (*sig_it) == data) {
                std::cout << "PASS";
            } else {
                std::cout << "FAIL" << " Expect " << std::setfill('0') << std::setw(8) << std::hex << (*sig_it);
                mismatch = 1;
            }
            ++sig_it;
        }
        
        std::cout << "\n";
     
    } // End of for loop
    
    
    return mismatch;
    
} // End of uut_memory_peek()


//===========================================================================
// load_elf_sections()
//
// Remarks:
//      load text/data sections into UUT's memory
//===========================================================================

void load_elf_sections(testbench *tb, UUT *uut)
{
    auto it_property = section_property_list.begin();
    bool need_to_load = false;
    unsigned long length = 0;
    
    for (auto it = section_list.begin(); it != section_list.end(); ++it) {
        
        need_to_load = false;
        for (std::vector<std::string>::const_iterator i = it_property->begin(); i != it_property->end(); ++i) {
            if (i->rfind ("LOAD", 0) == 0) {
                need_to_load = true;
            }
        } // End of for i
        
        if (need_to_load) {
             std::cout << "\nLoading section " << it->name << " ... \t";
             
             std::streampos size;
             char * memblock;
             std::ifstream file (bin_file_name (it->name), std::ios::in|std::ios::binary|std::ios::ate);
             
             if (file.is_open()) {
                 size = file.tellg();
                 std::cout << size << " bytes, \tLMA = 0x" << std::hex << it->lma << std::dec << "\n\n";
                 memblock = new char [size];
                 file.seekg (0, std::ios::beg);
                 file.read (memblock, size);
                 file.close();
                 length = (unsigned long)size;
                 uut_memory_load (tb, uut, (unsigned char*)memblock, it->lma, length);
             }
        }
        
        ++it_property;
            
    } // End of for it
} // End of load_elf_sections()


//===========================================================================
// elf_label_process()
//
// Remarks:
//      process the elf file to extract "_start", "begin_signature", "end_signature"
//===========================================================================

void elf_label_process(std::string elf_file)
{
    std::string readelf = toolchain + "readelf";
    
    std::string cmd = readelf + " " + elf_file + " -a";
    
   // std::cout << "cmd ==> " << cmd << "\n";
    
    std::string cmd_output {exec (cmd.c_str())};
    
    if (cmd_output.find ("not found") != std::string::npos) {
        std::cout << cmd_output << "\n"; 
        exit(-1);
    }
    //std::cout << "output is ============> \n" << cmd_output << "\n";
   
   
    std::regex section_regexp {"^\\s*\\d*\\:\\s(\\w{8})\\s*(\\w*\\s*){5}(\\w*)"};
    std::smatch m;
    
    std::istringstream iss {cmd_output};
    
    std::string sec_label {};
    
    for (std::string line; std::getline(iss, line); ) {

        if (std::regex_search (line, m, section_regexp)) {
            sec_label = m[3];
            if (sec_label == "_start") {
                start_address = std::stoul (m[1], nullptr, 16);
            } else if (sec_label == "begin_signature") {
                begin_signature_addr = std::stoul (m[1], nullptr, 16);
            } else if (sec_label == "end_signature") {
                end_signature_addr = std::stoul (m[1], nullptr, 16);
            }
        }
    } // End of for loop
    
} // End of elf_label_process()


//===========================================================================
// ref_file_process()
//
// Remarks:
//      process the reference file
//===========================================================================
    
void ref_file_process(std::string ref_file)
{
    int i, j;
    std::ifstream infile(ref_file);
    
    std::string line;
    std::string signature;
    
    vluint32_t data;
    
    sig_list = {};
    
    while (std::getline(infile, line))
    {
        std::istringstream iss(line);
        
        if (!(iss >> signature)) { 
            break; 
        } else {
            // std::cout << std::hex << "==> " << signature << "\n";
            
            for (i = 0; i < 4; ++i) {
                
                data = 0;
                for (j = 0; j < 8; ++j) {
                    data += (std::stoul (signature.substr(31 - i * 8 - j, 1), nullptr, 16)) << (j*4);
                } // End of for loop j
                
                sig_list.push_back (data);
                
               // std::cout << std::setfill('0') << std::setw(8) << std::hex << data << "\n";
        
            } // End of for loop i
        }
        
    } // End of while loop
    
} // End of ref_file_process()


//===========================================================================
//  MAIN
//
//===========================================================================

int main(int argc, char** argv) {
    
    if (argc > 1) {
        elf_file = std::string(argv[1]);
    }
        
    const char* const short_opts = "r:t:s:";
    const option long_opts[] = {
            {"reference", required_argument, nullptr, 'r'},
            {"toolchain", required_argument, nullptr, 't'},
            {"start", required_argument, nullptr, 's'}
    };

    while (true)
    {
        const auto opt = getopt_long(argc, argv, short_opts, long_opts, nullptr);
       
        if (-1 == opt) {
            break;
        }
        
        switch (opt) {
            case 'r':
                ref_file = std::string(optarg);
                break;
            
            case 't':
                toolchain = std::string(optarg);
                break;

            case 's':
                start_address = std::stoul(optarg);
                break;
            default:
                
                break;
        }
    } // End of while loop
  
    
    if (elf_file.empty()) {
        std::cout << "elf file is not provided!\n";
        return 0;
    }        
    
    Verilated::commandArgs(argc, argv); 
    
    std::cout << "\n\n\n";
    std::cout << "=============================================================\n";
    std::cout << "=== PulseRain Technology, RISC-V RV32IM Test Bench\n";
    std::cout << "=============================================================\n";
    std::cout << "\n";
    
    std::cout << "     elf file \t: " << elf_file << "\n";
    if (!ref_file.empty()) {
        std::cout << "     reference\t: " << ref_file << "\n";
        ref_file_process (ref_file);
    }
    
    elf_label_process(elf_file);
    
    std::cout << "     toolchain \t: " << toolchain << "\n";
    
    std::cout << "\n     start address \t\t= 0x" << std::setfill('0') << std::setw(8) << std::hex;
    std::cout << start_address << "\n";
    
    if (end_signature_addr > begin_signature_addr) {
        std::cout << "     begin signature address \t= 0x" << std::setfill('0') << std::setw(8) << std::hex;
        std::cout << begin_signature_addr << "\n";
        
        std::cout << "     end signature address \t= 0x" << std::setfill('0') << std::setw(8) << std::hex;
        std::cout << end_signature_addr << "\n";
    }
    
    std::this_thread::sleep_for(std::chrono::seconds(1));
      
    prepare_elf_section_list (elf_file);
    
    uut = new UUT; // Create instance
    
    testbench t {10, uut};
    
    uut->reset_n = 0; // Set some inputs
    uut->sync_reset = 0;
    
    std::cout << "\n=============> reset..." << "\n";
    
    uut->sync_reset = 0;
    uut->ocd_reg_we = 0;
    uut->ocd_reg_read_addr = 0;
    uut->ocd_reg_write_addr = 0;
    uut->ocd_reg_write_data = 0;
    uut->ocd_read_enable = 0;
    uut->ocd_write_enable = 0;
    uut->ocd_rw_addr = 0;
    uut->ocd_write_word = 0;
    uut->start = 0;
    uut->start_address = start_address;
    
    t.reset();
    std::cout << "=============> init stack ..." << "\n";
    uut->ocd_reg_we = 1;
    uut->ocd_reg_write_addr = 2; // SP
    uut->ocd_reg_write_data = DEFAULT_STACK_INIT_VALUE;
    t.run();
    uut->ocd_reg_we = 0;
    t.run();
    
    std::cout << "=============> load elf file..." << "\n";
    
    load_elf_sections(&t, uut);
    
    t.run(); 
    
    std::cout << "\n=============> start running ..." << "\n";
    
    uut->start = 1;
    t.run();
    uut->start = 0;
    t.run();
    
    for (int i = 0; i < TOTAL_RUN_CYCLES; ++i) {
        std::cout << "\t";
        std::cout << std::setfill('0') << std::setw(4) << std::dec << i << " ";
        std::cout << std::setfill('0') << std::setw(8) << std::hex << uut->peek_pc << "  ";
        std::cout << std::setfill('0') << std::setw(8) << std::hex << uut->peek_ir << "  ";
        if (int(uut->peek_mem_write_en)) {
            std::cout << std::hex << int(uut->peek_mem_write_en) << "  ";
            std::cout << std::setfill('0') << std::setw(8) << std::hex << uut->peek_mem_addr * 4 << "  ";
            std::cout << std::setfill('0') << std::setw(8) << std::hex << uut->peek_mem_write_data << " ";
        } 
        
        std::cout << "\n";
        
        t.run();
    } // End of for loop
        
    t.reset();
    
    int ret = 0;
    
    if (sig_list.size()) {
        std::cout << "\n========> Matching signature ...\n\n";
        
        if (uut_memory_peek (&t, uut, begin_signature_addr, sig_list.size() * 4, true)) {
            std::cout << "\n======> Signature MISMATCH!!!\n";
            ret = -1;
        } else {
            std::cout << "\n======> Signature ALL MATCH!!!\n";
        }
    
    }
 
    std::cout << "\n";
    std::cout << "=============================================================\n";
    std::cout << "Simulation exit " << elf_file << "\n";
    std::cout << "=============================================================\n";
    std::cout << "\n";
    
    uut->final();

    delete uut;
    
    return ret;
}
