all: objects.cpp
	g++ -o objects -std=c++14 -static objects.cpp

# Builds the program the 32-bit bytes in cpp/string_spec.rb were captured from.
# Needs g++-i686-linux-gnu, and qemu-i386 to run the result. Neither is needed
# to run the specs, which replay the captured bytes.
objects32: objects.cpp
	i686-linux-gnu-g++ -o objects32 -std=c++14 -static objects.cpp
