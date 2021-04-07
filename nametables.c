#include <stdlib.h>
#include <stdio.h>

#define NAMETABLE_SIZE 1024

const char *nametableFiles [] = {
			"chain",
			"drumkit",
			"envelope",
			"pattern",
			"song",
			"table",
			"instrument",
			"vibrato",
			"duty",
			"navmenu",
			"speed",
			"setup",
			"echo",
			"fx"
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
	unsigned char lineBuffer [17];
	
	FILE *inputFile;
	FILE *outputFile;
	char inputFileName[50];
	char outputFileName[50];
	
	for (i=0;i<length;i++)
	{
		sprintf(inputFileName, "%s%s.nam", pathName, nametableFiles[i]);
		printf("%s\n",inputFileName);
		inputFile = fopen(inputFileName, "rb");
		
		//Output header
		sprintf(outputFileName, "%sheader_%s.bin", pathName, nametableFiles[i]);
		outputFile = fopen(outputFileName, "wb");
		//printf("%s\n",outputFileName);
		
		fread(lineBuffer, 1, 17, inputFile);
		fwrite(lineBuffer, 1, 17, outputFile);
		fclose (outputFile);

		
		//Output window
		sprintf(outputFileName, "%swindow_%s.bin", pathName, nametableFiles[i]);
		outputFile = fopen(outputFileName, "wb");
		for (x=1;x<17;x++)
		{
			fseek(inputFile, (x * 32)+3, SEEK_SET);
			fread(lineBuffer,1,14,inputFile);
			fwrite(lineBuffer,1,14,outputFile);
			//printf("%d\n",x);
		}
		fclose(outputFile);
		
		//Output title
		sprintf(outputFileName, "%stitle_%s.bin", pathName, nametableFiles[i]);
		outputFile = fopen(outputFileName, "wb");
		fseek(inputFile, 17 * 32, SEEK_SET);
		fread(lineBuffer, 1, 17, inputFile);
		fwrite(lineBuffer, 1, 17, outputFile);
		fclose (outputFile);		
		fclose(inputFile);

		
	}
	return 0;
}
