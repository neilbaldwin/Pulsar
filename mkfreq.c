/*
Period Table Generator for NT2
by Damian Yerrick <tepples@spamcop.net>
Damian Yerrick hereby disclaims all exclusive rights under copyright
in this work and donates this work to the public domain.
*/

#include <sys/types.h>
#include <stdio.h>
#include <math.h>

//#define NES_FREQ_FACTOR (1789772.7 / 16)
#define NES_FREQ_FACTOR   (1662607.0 / 16)
#define FREQ_STEP 1.003616665975463 //(1.059463094) /* 12edo */
#define LOW_C 32.703196
#define FREQ_TABLE_SIZE 12 * 16

unsigned char freq_lo[FREQ_TABLE_SIZE];
unsigned char freq_hi[FREQ_TABLE_SIZE];

void pr_table(unsigned char *base, size_t len)
{
  unsigned int twelveness = 0;
  unsigned int i;

  for(i = 0; i < FREQ_TABLE_SIZE; i++)
  {
    if(twelveness == 0)
      fputs("  .byte ", stdout);

    printf("$%02x", (unsigned int)base[i]);

    if(++twelveness == 16)
    {
      twelveness = 0;
      fputc('\n', stdout);
    }
    else
      fputc(',', stdout);
  }
  if(twelveness)
    fputc('\n', stdout);
}

int main(void)
{
  double cur_freq = LOW_C;
  unsigned int i;
unsigned int freq_i;

for (i = 0; i < (9*16);i++)
{
     cur_freq *= FREQ_STEP;
}

  for(i = 0; i < FREQ_TABLE_SIZE; i++)
  {
    freq_i = floor(NES_FREQ_FACTOR / cur_freq - 0.5);

    freq_lo[i] = freq_i & 0x00ff;
    freq_hi[i] = freq_i >> 8;
cur_freq *= FREQ_STEP;
}

  fputs("Tone2PeriodLoTab:\n", stdout);
  pr_table(freq_lo, FREQ_TABLE_SIZE);

  fputs("Tone2PeriodHiTab:\n", stdout);
  pr_table(freq_hi, FREQ_TABLE_SIZE);

  return 0;
}

