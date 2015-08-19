clean:
	rm -f *~ *.*~ *.o  *.bin 

all:
	rm -f *.o  *.bin 
	make -f Makefile_446 --no-print-directory
	
	rm -f *.o  
	make -f Makefile_465 --no-print-directory
