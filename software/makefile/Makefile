RISCV_PREFIX = riscv-none-embed-

CC  = $(RISCV_PREFIX)gcc
CXX = $(RISCV_PREFIX)g++
AS  = $(RISCV_PREFIX)as
LD  = $(RISCV_PREFIX)gcc
OBJDUMP = $(RISCV_PREFIX)objdump

CFLAGS = -I. 
CFLAGS += --specs=nosys.specs -march=rv32i -mabi=ilp32 -Os -fno-builtin-printf -fdata-sections -ffunction-sections -fno-exceptions -fno-unwind-tables -fno-rtti
CFLAGS += -W -DVMAJOR=1 -DVMINOR=1 -D__GXX_EXPERIMENTAL_CXX0X__

LDFLAGS = -T ./Reindeer.ld --specs=nosys.specs -march=rv32i -mabi=ilp32 -Os -fdata-sections -ffunction-sections -Wl,--gc-sections -static -fno-exceptions -fno-unwind-tables -fno-rtti

#pattern rule


#== Put all the object files here
obj = main.o Print.o Stream.o HardwareSerial.o Reindeer.o
      
target = step.elf
dump = $(patsubst %.elf,%.dump,$(target)) 


all: $(obj)
	@echo "====> Linking $(target)"
	@$(LD) $(LDFLAGS) $(obj) -o $(target) 
	@chmod 755 $(target)
	@echo "===> Dumping sections for $@"
	@$(OBJDUMP) --disassemble-all --disassemble-zeroes --section=.text --section=.text.startup --section=.data --section=.rodata --section=.sdata --section=.sdata2 --section=.init_array --section=.fini_array $(target) > $(dump)

	
	
	
%.o : %.c 
	@echo "===> Building $@"
	@echo "============> Building Dependency"
	@$(CC) $(CFLAGS) -M $< | sed "s,$(@F)\s*:,$@ :," > $*.d
	@echo "============> Generating OBJ"
	@$(CC) $(CFLAGS) -c -o $@ $<; \
	if [ $$? -ge 1 ] ; then \
		exit 1; \
	fi
	@echo "----------------------------------------------------------------------------"

%.o : %.cpp 
	@echo "===> Building $@"
	@echo "============> Building Dependency"
	@$(CXX) $(CFLAGS) -M $< | sed "s,$(@F)\s*:,$@ :," > $*.d
	@echo "============> Generating OBJ"
	@$(CXX) $(CFLAGS) -c -o $@ $<; \
	if [ $$? -ge 1 ] ; then \
		exit 1; \
	fi
	@echo "----------------------------------------------------------------------------"

    
    
dependency = $(patsubst %.o,%.d,$(obj)) 

ifneq "$(MAKECMDGOALS)" "clean"
	-include $(dependency)
endif

	
clean :
	-@rm -vf $(target)
	-@find . -type f \( -name "*.riscv" -o -name "*.d" -o -name "*.o" -o -name "*.lst" -o -name "*.dump" \
	                    -o -name "*.bin" -o -name "*.out" -o -name "*.elf" \) -exec rm -vf {} \;


.PHONY: clean all
