#include <stdlib.h>
#include <stdio.h>

#define NAMETABLE_SIZE 1024

const char *nametableFiles [] = {
			"hintA",
			"hintB",
			"hintC",
			"hintD",
			"hintE",
			"hintF",
			"hintG",
			"hintH",
			"hintI",
			"hintJ",
			"hintK",
			"hintL",
			"hintM",
			"hintN",
			"hintO",
			"hintP",
			"hintQ",
			"hintR",
			"hintS",
			"hintT",
			"hintU",
			"hintV",
			"hintW",
			"hintX",
			"hintY",
			"hintZ"
		};
			
		
const char *pathName = "nametables/";
		
int getFileSize (FILE *file)
{
	int size;
	fseek(file, 0, SEEK_END);
	size = ftell(file);
	fseek(file, 0, SEEK_SET);
	return size;
}

int main (int argc, const char * argv[])
{
	int i;
	unsigned int x;
	int length = sizeof(nametableFiles) / sizeof(nametableFiles[0]);
	unsigned char lineBuffer [14];
	
	FILE *inputFile;
	FILE *outputFile;
	char inputFileName[50];
	char outputFileName[50];
	
	for (i=0;i<length;i++)
	{
		sprintf(inputFileName, "%s%s.nam", pathName, nametableFiles[i]);
		printf("%s\n",inputFileName);
		inputFile = fopen(inputFileName, "rb");
		
		//Output window
		sprintf(outputFileName, "%s%s.bin", pathName, nametableFiles[i]);
		outputFile = fopen(outputFileName, "wb");
		for (x=0;x<8;x++)
		{
			fseek(inputFile, (x * 32), SEEK_SET);
			fread(lineBuffer,1,14,inputFile);
			fwrite(lineBuffer,1,14,outputFile);
			//printf("%d\n",x);
		}
		fclose(outputFile);
		
	}
	return 0;
}
