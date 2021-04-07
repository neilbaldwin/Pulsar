#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#define PI 3.142
#define TABLE_SIZE 64
#define NES_FREQ_FACTOR (1789772.7 / 16)
#define FREQ_STEP 1.059463094  /* 12edo */
#define LOW_C 32.703196
#define FREQ_TABLE_SIZE 96

unsigned char freq_lo[FREQ_TABLE_SIZE];
unsigned char freq_hi[FREQ_TABLE_SIZE];

int main (int arg, const char * argv[])
{
	unsigned char sinTab [TABLE_SIZE];
	int x;
	int sixteen = 0;
	
	for (x=0;x<TABLE_SIZE;x++)
	{
		sinTab[x] = sin (x * (PI) / (TABLE_SIZE/2)) * 64;
		if (sixteen==0) printf("\nDB ");
		printf("$%.2x", sinTab[x]);
		if ((sixteen++)<15){
			printf(",");
		} else
		{
			sixteen=0;
		}
	}
	return 0;
}