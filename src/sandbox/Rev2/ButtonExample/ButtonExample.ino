/*
  State change detection (edge detection)
 	
 Often, you don't need to know the state of a digital input all the time,
 but you just need to know when the input changes from one state to another.
 For example, you want to know when a button goes from OFF to ON.  This is called
 state change detection, or edge detection.
 
 This example shows how to detect when a button or button changes from off to on
 and on to off.
 	
 The circuit:
 * pushbutton attached to pin 2 from +5V
 * 10K resistor attached to pin 2 from ground
 * LED attached from pin 13 to ground (or use the built-in LED on
   most Arduino boards)
 
 created  27 Sep 2005
 modified 30 Aug 2011
 by Tom Igoe

This example code is in the public domain.
 	
 http://arduino.cc/en/Tutorial/ButtonStateChange
 
 */

// this constant won't change:
const int  leftButton   = 4;
const int  rightButton  = 5;    // the pin that the pushbutton is attached to.

const int ledPin = 13;       // the pin that the LED is attached to

// Variables will change:
int leftButtonPushCounter = 0;   // counter for the number of button presses
int rightButtonPushCounter =0;

int leftButtonState  = 0;         // current state of the button
int rightButtonState = 0;

int leftButtonLastState = 0;     // previous state of the button
int rightButtonLastState = 0;

int currentTimeZone = 12;

void setup() {
  // initialize the button pin as a input:
  pinMode(rightButton, INPUT);
  pinMode(leftButton, INPUT);
  // initialize the LED as an output:
  pinMode(ledPin, OUTPUT);
  // initialize serial communication:
  Serial.begin(115200);
}


void loop() {
  // read the pushbutton input pin:
  rightButtonState = digitalRead(rightButton);
  leftButtonState = digitalRead(leftButton);

  // compare the buttonState to its previous state
  if (rightButtonState != rightButtonLastState) {
    // if the state has changed, increment the counter
    if (rightButtonState == HIGH) {
      // if the current state is HIGH then the button
      // wend from off to on:
      rightButtonPushCounter++;
      currentTimeZone++;
      Serial.println(currentTimeZone);
    } 
    else {
      // if the current state is LOW then the button
      // wend from on to off:
      //Serial.println("off"); 
    }
  }
  // save the current state as the last state, 
  //for next time through the loop
  rightButtonLastState = rightButtonState;
  
  
    if (leftButtonState != leftButtonLastState) {
    // if the state has changed, increment the counter
    if (leftButtonState == HIGH) {
      // if the current state is HIGH then the button
      // wend from off to on:
      leftButtonPushCounter++;
      currentTimeZone--;
      Serial.println(currentTimeZone);
    } 
    else {
      // if the current state is LOW then the button
      // wend from on to off:
      //Serial.println("off"); 
    }
  }
  leftButtonLastState = leftButtonState;


  
}









