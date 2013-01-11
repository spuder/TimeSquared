#include <LedControl.h>


LedControl lc1=LedControl(3,5,4,1);


void setup() {
  
lc1.shutdown(0,false);
lc1.setIntensity(0,8);

}

void loop () {
  void clearDisplay(int, 0);
  void setLed(int 0, int 1, int 1, true);
}
//void setIntensity(int addr, int intensity);
