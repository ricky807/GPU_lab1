lab1: main.o timing.o
	nvcc -arch=sm_30 -o lab1 timing.o main.o

main.o: main.cu
	nvcc -arch=sm_30 -c main.cu

timing.o: timing.c timing.h
	g++ -c -x c++ timing.c -I.

clean:
	rm -r *.o lab1