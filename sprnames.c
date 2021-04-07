#include <stdlib.h>
#include <stdio.h>
#include <math.h>

/*
SPR00_Y		.RES 1
SPR00_CHAR	.RES 1
SPR00_ATTR	.RES 1
SPR00_X		.RES 1
*/

int main (int arg, const char * argv[])
{
	unsigned int i;
	for (i=0;i<0x40;i++)
	{
		printf("SPR%.2X_Y: \t\t.RES 1\n",i);
		printf("SPR%.2X_CHAR: \t.RES 1\n",i);
		printf("SPR%.2X_ATTR: \t.RES 1\n",i);
		printf("SPR%.2X_X: \t\t.RES 1\n\n",i);
	}
	
	printf("\n");
	for (i=0;i<0X40;i++)
	{
		printf(".export SPR%.2X_Y,SPR%.2X_CHAR,SPR%.2X_ATTR,SPR%.2X_X\n",i,i,i,i);
	}
	
	return 0;
}