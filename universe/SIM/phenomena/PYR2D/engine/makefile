# program name of output
TARGET = exec

# definition of object files for modules and program
OBJECTS += pcf_ver1.04.o

# compiler
FC = gfortran

FFLAGS =

# compile option
# for gfortran
ifeq (${FC},gfortran)
	FFLAGS += -O3 -mcmodel=medium
endif

# suffix rule
.SUFFIXES : .o .f90 .f
.f90.o:
	${FC} -c $<

# linking
${TARGET} : ${OBJECTS}
	${FC} -o $@ ${OBJECTS} ${LDFLAGS} ${FFLAGS} 


.PHONY: clean
clean:
	${RM} ${TARGET} ${OBJECTS} ${MOD_FILES} *~ *.mod
