#include <stdio.h>
#include <stdlib.h>

int main()
{
   char *fptr;
   long i, k;

   i = 50000000000L;

   do {
      if(( fptr = (char *)malloc(i)) == NULL) {
         i = i - 1000;
      }
   }
   while (( fptr == NULL) && (i > 0));

   sleep(15);  /* for time to observe */
   for (k = 0; k < i; k++) {   /* so that the memory really gets allocated and not just reserved */
      fptr[k] = (char) (k & 255);
   }

   sleep(60);  /* O.K. now you have 1 minute */
   free(fptr); /* clean up, if we get here */

   return(0);
}
