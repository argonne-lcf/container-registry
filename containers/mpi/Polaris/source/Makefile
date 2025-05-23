#
# Definition of MACROS

CXX = CC # Use the HOST Cray compiler wrapper
CXXFLAGS = -g -O3 # Removed -fopenmp

CPP = cpp -P -traditional
CPPFLAGS =

# Add these lines if they are missing
LD = $(CXX)
LIB =
BINROOT=./
EX=hello_affinity
SHELL=/bin/sh
SRC = hello_affinity.cpp # Make sure this points to the correct cpp file
INC = $(wildcard *.h) # Assuming no specific headers needed beyond standard ones
OBJ = $(SRC:.cpp=.o)
# End added lines


$(EX):  $(OBJ)
	$(LD) -o $@ $(CXXFLAGS) $(OBJ) $(LIB)

####################################################################

$(OBJ): %.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $<

#
# -- Remove *.o and *~ from the directory
clean:
	rm -f *.o *~ $(EX)

#
# -- Remove *.o, *~, and executable from the directory
realclean: clean # simplified realclean


#
# -- Simple dependencies

$(OBJ) : $(INC) 