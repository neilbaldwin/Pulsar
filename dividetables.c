#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>

#define TABLE_SIZE 32

int main (int arg, const char * argv[])
{
	unsigned char divideTable [TABLE_SIZE];
	int x;
	int sixteen = 0;
	char buf [5];
	float y;
	int t=1;
	for (y=1.0;y<8.5;y+=0.5)
	{
		sprintf(buf, "%d",t);
		printf("divideBy%s:",buf);
		t++;
	
	for (x=0;x<TABLE_SIZE;x++)
	{
		divideTable [x] = (unsigned char) x / y;
		if (sixteen==0) printf("\nDB ");
		printf("$%.2x", divideTable[x]);
		if ((sixteen++)<15){
			printf(",");
		} else
		{
			sixteen=0;
		}
	}
	printf("\n\n");
}
	return 0;
}