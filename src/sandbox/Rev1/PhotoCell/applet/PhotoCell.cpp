/*

 
 */

#include "WProgram.h"
void setup();
void loop();
int getBrightness();
void setBrightness();
int sensorPin = 0;    // select the input pin for the potentiometer
int ledPin = 9;      // select the pin for the LED
int sensorValue = 0;  // variable to store the value coming from the sensor
int mostLightValue = -1000;
int leastLightValue = 1000;

void setup() {
  // declare the ledPin as an OUTPUT:
  pinMode(ledPin, OUTPUT);  // LED using PWM based on input brightness
  pinMode(sensorPin, INPUT); // Photocell to detect brightness
  Serial.begin(9600); // Enable serial output DEBUG
} // End setup ********************************************************************


void loop() {
  
  getBrightness();
  setBrightness();
  Serial.println(sensorValue);   // DEBUG


} // End Loop********************************************************************


int getBrightness() {
 
  sensorValue = analogRead(sensorPin);   // Reads the Photocell 
   
  mostLightValue = max(sensorValue,mostLightValue);
  leastLightValue = min(sensorValue,leastLightValue);

  return sensorValue; // Replaces origional value of the sensor with new value
}


void setBrightness() {
  if ( (sensorValue / 4) < 2 ) {    // If input is 0, light will flicker, this eliminates that, also prevents reaching 0 and turning off
    analogWrite(ledPin,1);
  }
  else analogWrite(ledPin, sensorValue /4);  // Sets the led value 0 - 255
  
}

int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

