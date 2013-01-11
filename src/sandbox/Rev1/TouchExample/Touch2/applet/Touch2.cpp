#include <CapSense.h>

/*
 * CapitiveSense Library Demo Sketch
 * Paul Badger 2008
 * Uses a high value resistor e.g. 10M between send pin and receive pin
 * Resistor effects sensitivity, experiment with values, 50K - 50M. Larger resistor values yield larger sensor values.
 * Receive pin is the sensor pin - try different amounts of foil/metal on this pin
 * Best results are obtained if sensor foil and wire is covered with an insulator such as paper or plastic sheet
 */


#include "WProgram.h"
void setup();
void loop();
void touchCheck();
void checkLeft();
void checkRight();
CapSense   rightPin = CapSense(10,11);        // 10M resistor between pins 4 & 2, pin 2 is sensor pin, add wire, foil
CapSense   leftPin = CapSense(10,9);        // 10M resistor between pins 4 & 6, pin 6 is sensor pin, add wire, foil
//CapSense   cs_4_8 = CapSense(4,8);        // 10M resistor between pins 4 & 8, pin 8 is sensor pin, add wire, foil

const int pin13 = 13;

long lastRightValue;
long lastLeftValue;
int i;
int w;
int x;
int y;
boolean z;
void setup() {

  pinMode(pin13, OUTPUT);
 //cs_4_2.set_CS_AutocaL_Millis(0x11111111);     // turn off autocalibrate on channel 1 - just as an example
 //cs_4_5.set_CS_AutocaL_Millis(0x11111111);
 Serial.begin(9600);

i=0;
w-=0;
x=0;
y=0;
z == false;

}

void loop()  {
/*
// tap left or right to turn led's on or off. Hold right corner for 5 seconds to go right one time zone, Hold left corner for 5 seconds to go left one 
time zone. Hold both corners for 7 seconds to force time update. 
	
	on high
		start counting
		.10 second interupt
			if low break (debounce) Must have accidently bumped it, or interfierence
			if high continue waiting
		.25 seconds interupt - Short Tap
			if low turn lights off
			if high continue waiting
			
		5 second interupt - Wants to update time zone 
			if right low - setTime(+1)
			if left low - setTime(-1)
			if high continue waiting
		7 second interupt
			GetWWVBTime()
			Stop monitoring all sensors. Avoid interupts. \
			
	
	
	
	Alternative method. On high start counting, if positive reaches 2 or 3 in 5 main loops, then dim display
*/

	// function put seperate to avoid two consecutive true results, calling next step twice. 
	if (x > 2) { // Elimates accidental bumps, someone wants an action. 
			x = 0; // Reset counters to avoid doing action twice
			y = 0; 
		checkRight(); // Go to another method. 
	
	}
	else touchCheck();// Sensor shows no activity, resume patrol.  
	
	
	
	
	if (z == true){ // when there is an event, 
		if ( y > 15 ) { // it has 15 loops to meet criteria before discarded
			Serial.print("reset---");
			x = 0;
			y = 0;
			z == false; // Times up, gard is let down. 
		}
		y++; // give more time. 
		
		if (w > 6) { // Button is being held down
			
		}
	}
	
	 
/*
	for (x = 0; x < 4; x=x) {

	touchCheck();
	void reset_CS_AutoCal();
	delay(50);	
	}
	Serial.print("Happy Festivius");
	delay(1000);
*/
}

//___________________________________________________________________________

void touchCheck() {
   long start = millis();
   long total1 =  rightPin.capSense(10);
   long total2 =  leftPin.capSense(10);

 if ( ( (lastRightValue) % (total1) ) > 1 ) {
	x++; // Means something is happening
	w++;
	z == true;
	
	
 }
 
 if ( ( (lastLeftValue) % (total2) ) > 1 ) {

   // Serial.println(" Left Touched ");

 }
 
 if ( ( total1 > 100) && (total2 > 100) ) {
   // Serial.println(" Both Touched ");

 }   
   

 

 //    Serial.print(millis() - start);        // check on performance in milliseconds
 //    Serial.print("\t");                    // tab character for debug windown spacing
 // 
 //    Serial.print(total1);                  // print sensor output 1
 //    Serial.print("\t");
 //    Serial.print(total2);                  // print sensor output 2
 //    Serial.println("\t");
 // //   Serial.println(total3);                // print sensor output 3
 // 
    
if (i = 1000) {
	Serial.print((lastRightValue) % (total1) );
	
}
else i++;

		Serial.print((lastRightValue) % (total1) );

	delay(50);                             // arbitrary delay to limit data to serial port 
 //    

    lastRightValue = total1;
    lastLeftValue = total2;

}


void checkLeft() {
	
}

void checkRight() {
	Serial.print("hooray&************************");
	
}

int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

