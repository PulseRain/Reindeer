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

###############################################################################
#== compliance test vector folder
###############################################################################

elf_folder = ../compliance
ref_folder = ../compliance/references

###############################################################################
#== Put all the source files here
###############################################################################

src_base = ../../submodules/PulseRain_MCU/source
src_sub = \
../PulseRain_processor_core/source/mul_div/absolute_value \
../PulseRain_processor_core/source/mul_div/long_slow_div_denom_reg \
../PulseRain_processor_core/source/mul_div/mul_div_32 \
../memory/microsemi/dual_port_ram \
../memory/microsemi/single_port_ram_8bit \
../memory/microsemi/single_port_ram \
../PulseRain_processor_core/source/RV2T_reg_file \
../PulseRain_processor_core/source/RV2T_memory \
../PulseRain_processor_core/source/RV2T_CSR \
../PulseRain_processor_core/source/RV2T_fetch_instruction \
../PulseRain_processor_core/source/RV2T_instruction_decode \
../PulseRain_processor_core/source/RV2T_execution_unit \
../PulseRain_processor_core/source/RV2T_data_access \
../PulseRain_processor_core/source/RV2T_controller \
../peripherals/UART/UART_TX

src_top = PulseRain_RV2T_MCU
testbench = tb_PulseRain_RV2T

src_sub_v = $(patsubst %, $(src_base)/%.v,$(src_sub))
src_top_v = $(src_top).v
testbench_cpp = $(testbench).cpp

 
target = ./obj_dir/VPulseRain_RV2T_MCU

###############################################################################
# All test cases
###############################################################################
all_test_cases =  \
I-ADD-01 \
I-ADDI-01 \
I-AND-01 \
I-ANDI-01 \
I-AUIPC-01 \
I-BEQ-01 \
I-BGE-01 \
I-BGEU-01 \
I-BLT-01 \
I-BLTU-01 \
I-BNE-01 \
I-CSRRC-01 \
I-CSRRCI-01 \
I-CSRRS-01 \
I-CSRRSI-01 \
I-CSRRW-01 \
I-CSRRWI-01 \
I-DELAY_SLOTS-01 \
I-EBREAK-01 \
I-ECALL-01 \
I-ENDIANESS-01 \
I-FENCE.I-01 \
I-IO \
I-JAL-01 \
I-JALR-01 \
I-LB-01 \
I-LBU-01 \
I-LH-01 \
I-LHU-01 \
I-LUI-01 \
I-LW-01 \
I-MISALIGN_JMP-01 \
I-MISALIGN_LDST-01 \
I-NOP-01 \
I-OR-01 \
I-ORI-01 \
I-RF_size-01 \
I-RF_width-01 \
I-RF_x0-01 \
I-SB-01 \
I-SH-01 \
I-SLL-01 \
I-SLLI-01 \
I-SLT-01 \
I-SLTI-01 \
I-SLTIU-01 \
I-SLTU-01 \
I-SRA-01 \
I-SRAI-01 \
I-SRL-01 \
I-SRLI-01 \
I-SUB-01 \
I-SW-01 \
I-XOR-01 \
I-XORI-01 \
MUL \
MULH \
MULHSU \
MULHU \
DIV \
DIVU \
REM \
REMU

rv32u_test_cases = illegal

test_run_case = $(filter-out $@, $(MAKECMDGOALS))

count_test_run_case = $(words $(test_run_case))
count_test_all = $(words $(all_test_cases))

build : $(target)

test : build
	@echo "====> Testing $(target)"    
	@echo "TEST CASE: $(test_run_case)"
	@for t in $(test_run_case) ; do \
		elf_file=$(elf_folder)/$$t.elf ;\
		ref_file=$(ref_folder)/$$t.reference_output ;\
		echo "testing $$elf_file  -r $$ref_file" ; \
		./obj_dir/V$(src_top) $$elf_file  -r $$ref_file || exit ; \
		sleep 1 ; \
	done
	@echo "====> Test PASSED, Total of $(count_test_run_case) case(s)"     

test_all : build
	@echo "====> Testing ALL"    
	@for t in $(all_test_cases) ; do \
		echo "TEST CASE: $$t" ; \
		elf_file=$(elf_folder)/$$t.elf ;\
		ref_file=$(ref_folder)/$$t.reference_output ;\
		echo "testing $$elf_file  -r $$ref_file" ; \
		./obj_dir/V$(src_top) $$elf_file  -r $$ref_file || exit ; \
		sleep 1 ; \
	done
	@echo "====> Test PASSED, Total of $(count_test_all) cases \n"    

test_trap : build
	@echo "====> Testing system instr"
	@for t in $(rv32u_test_cases) ; do \
		echo "TEST CASE: $$t" ; \
		elf_file=$(elf_folder)/$$t.elf ;\
		ref_file=$(ref_folder)/$$t.reference_output ;\
		echo "testing $$elf_file  -r $$ref_file" ; \
		./obj_dir/V$(src_top) $$elf_file  -r $$ref_file || exit ; \
		sleep 1 ; \
	done
	@echo "====> Test PASSED, Total of $(count_test_all) cases \n"

run : build
	@echo "runing $(test_run_case)" ;
	./obj_dir/V$(src_top) $(test_run_case)

$(target) : $(src_sub_v) $(src_base)/$(src_top_v) $(testbench_cpp)
	@echo "====> Building $(target)"
	for s in $(src_sub_v) ; do \
		verilator -I../../submodules/PulseRain_MCU/memory/microsemi -I../../submodules/PulseRain_MCU/common -I../../submodules/PulseRain_MCU/common/Microsemi/SmartFusion2 -I../../submodules/PulseRain_MCU/PulseRain_processor_core/source  -I../../submodules/PulseRain_MCU/PulseRain_processor_core/source/mul_div --cc $$s ; \
	done

	verilator -I../../submodules/PulseRain_MCU/peripherals/UART -I../../submodules/PulseRain_MCU/memory/microsemi -I../../submodules/PulseRain_MCU/common -I../../submodules/PulseRain_MCU/common/Microsemi/SmartFusion2 -I../../submodules/PulseRain_MCU/PulseRain_processor_core/source  -I../../submodules/PulseRain_MCU/PulseRain_processor_core/source/mul_div --cc $(src_base)/$(src_top_v) --exe $(testbench_cpp)
	
	make -j -C ./obj_dir -f V$(src_top).mk V$(src_top)

clean :
	@echo "====> Remove obj_dir"
	-@rm -rf ./obj_dir

help :
	@echo "*) To build : make or make build\n"
	@echo "*) To clean the build : make clean\n"
	@echo "*) To test single or multiple compliance cases : make test case1 case2 case3 ..."
	@echo "         for example : make test I-ADD-01 DIV I-FENCE.I-01"
	@echo "*) To test all compliance cases : make test_all\n"
	@echo "*) To run an elf file : make run file_name\n"
    
%:
	@true
    
.PHONY: clean test test_all help run build
