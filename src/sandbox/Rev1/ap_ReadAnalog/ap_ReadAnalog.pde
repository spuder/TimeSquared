/*
*  ap_ReadAnalog
*  
*  Reads an analog input from the input pin and sends the value 
*  followed by a line break over the serial port. 
* 
*  This file is part of the Arduino meets Processing Project:
*  For more information visit http://www.arduino.cc.
*
*  copyleft 2005 by Melvin Ochsmann for Malm� University
*
*/

// variables for input pin and control LED
  int analogInput = 3;
  int LEDpin = 12;
  
// variable to store the value 
  int value = 0;
  
// a threshold to decide when the LED turns on
  int threshold = 300;
 
void setup(){

// declaration of pin modes
  pinMode(analogInput, INPUT);
  pinMode(LEDpin, OUTPUT);
  
// begin sending over serial port
  Serial.begin(9600);
}

void loop(){
// read the value on analog input
  value = analogRead(analogInput);

  // if value greater than threshold turn on LED
  analogWrite(LEDpin, value);

  // print out value over the serial port
  Serial.println(value);
  Serial.println();

  // and a signal that serves as seperator between two values 
  

  // wait for a bit to not overload the port
  delay(75);	
}
