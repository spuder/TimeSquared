#include <LedControl.h>


#include "WProgram.h"
void setup();
void loop ();
LedControl lc1=LedControl(3,5,4,1);


void setup() {
  
lc1.shutdown(0,false);
lc1.setIntensity(0,8);

}

void loop () {
}
void setIntensity(int addr, int intensity);

int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

