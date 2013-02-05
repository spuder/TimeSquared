/*
*************************************************************
This code works, but has one big consideration. 
The timezone offset is changable by two buttons on pins 4 and 5.
Pressing the left button, decrements the UTC offset by 1, the right does the opposite

The problem is that the time is not updated until the radio (wwvb,dc77) actually gets
the time. This is problematic because it could take days for that to happen.

Example, a person in MDT would push the left button 7 times, then wait
several hours or days until the radio updates the clock before
they would even notice the change. 

A better approach might be to always save the time as UTC and compensate
with a TimeZone Library like https://github.com/JChristensen/Timezone
**************************************************************
*/


/*
radioClock_timeZone is the same as radioClock_1, however it includes time zone support via 2 buttons. 

This sketch polls and saves the radio time to/from a 1307 Real Time Clock Module. 
The result is the time is not lost after a power cycle. Additionally, the current time 
is updated at every opportunity instead of just once at startup. 

  Created by Spencer Owen
  https://github.com/spudstud
  2 Feburary 2012
  Arduino 1.0.3
  Arduino Mega 2560
  
  Revision 1.1: (5 Febuary 2012)
    Implemented Button library https://github.com/JChristensen/Button
  
  Revision 1.0: (2 Feburary 2012)
    Polls 1307 on startup, and saves to 1307 on wireless update
    Checks buttons for time zone compensation
    Only tested with wwvb module http://spuder.wordpress.com/2010/05/26/arduino-atomic-clock/
*/

//The library folder must have Time, TimeAlarms, and radioclocks libraries
//They can not be nested inside other folders
#include <Time.h>
#include <TimeAlarms.h>
#include <RadioClocks.h> //http://code.google.com/p/radioclock/
#include <PrintTime.h>   //http://code.google.com/p/radioclock/
#include <Button.h>      //https://github.com/JChristensen/Button

#include <Wire.h> //Library for i2c serial communicaiton
#include <DS1307RTC.h> //basic 1307 ic library that gets and sets time_t objects

//Pin the radio clock is connected to. *Arduino only supports interupts on pins 2 and 3
const int     signalPin = 2;
//
const boolean inverted = false;
//signalLED blinks every time a pulse is received from the radio
const int     signalLED = 13;

time_t prevDisplay = 0; // Keep track of the last time we displayed the time getTime()
int oldCount = -1;      // last number of bits logged

// uncomment the line that matches the protocol of the connected module
//DCF77 radioClock(signalPin, inverted, signalLED);
//MSF60 radioClock(signalPin, inverted, signalLED);
WWVB  radioClock(signalPin, inverted, signalLED);

//Put a led between pins 8 and 9, it will light up for 10 seconds on successful time update
int  ledPositive = 8; 
int  ledGround   = 9;

//Buttons to manually change timeZone
#define leftButtonPin 4
#define rightButtonPin 5

Button leftButton(leftButtonPin, false, false, 20);    //Declare the button
Button rightButton(rightButtonPin, false, false, 20);    //Declare the button


int currentTimeZone = 0; //Offset for UTC


void setup()
{
  Serial.begin(115200);
  Wire.begin();
  
  pinMode(ledPositive, OUTPUT);
  pinMode(ledGround, OUTPUT);
  digitalWrite(ledPositive, LOW);
  digitalWrite(ledGround, LOW);
  
  /* 
  setSyncProvider tells the Time object where to pull its time from
  examples could be a ntp server, a RTC, ect..
  Here we are pulling from the 1307
  This only pulls the time once, then stores it as a time_t object
  You can query that time_t object with the function "now()"
  */
  setSyncProvider(RTC.get); 
  if(timeStatus()!= timeSet) 
     Serial.println("Unable to sync with the RTC");
  else
     Serial.println("RTC has set the system time");
 
 /*Attach interupt to wwvb module
   Everytime the status of pin 2 on the arduino changes, the callback is called
 */
  radioClock.setTimeCallback(syncCallback);
  
  // start the Radio Clock
  radioClock.start();
 
}

void loop() 
{
  if (radioClock.getStatus() == status_synced)
  {
    Serial.println("*** - Radio has updated time ready!! - ***");
    digitalWrite(ledPositive, HIGH);
   
    //Set the 1307 Real Time Clock to the new current time
    RTC.set( now() );
    /*
      No way to reset "radioClock.getStatus()" without an enhancment
      The library would have to include a function called radioClock.setStatus()
      If we don't reset the status, then it will show the time 
      is always ready to be synced after getting it just once
    */
    radioClock.stop();
    radioClock.start();
  }
  
  //Turn off the led after 10 seconds
  if (second() > 10) {
    digitalWrite(ledPositive, LOW);
  }
  
  //Comment out to hide time
  showTime();
  radioClock.diags();
  //Comment out to hide the signal strength
  showCount();
  
  leftButton.read();
  rightButton.read();
  if (leftButton.wasReleased()) {
    currentTimeZone--;
            radioClock.setTimeZoneOffset(currentTimeZone);
            //setTime(( hour() - 1), minute(),second(),day(), month(), year());
            Serial.print("UTC " );
            Serial.println(currentTimeZone);
  }
  if (rightButton.wasReleased()) {
    currentTimeZone++;
            radioClock.setTimeZoneOffset(currentTimeZone);
            //setTime(( hour() - 1), minute(),second(),day(), month(), year());
            Serial.print("UTC " );
            Serial.println(currentTimeZone);
  }

   
}


// update the internal time of the Time library
void syncCallback(time_t syncedtime)
{
    // this is called from an intterupt so don't spend too much time here
    setTime(syncedtime);
}

// check if time changed and if time has been syncrhonized at least once, if yes, print it.
void showTime()
{
    time_t currentTime = getTime();
    if(currentTime != 0 && currentTime != prevDisplay){
      prevDisplay = currentTime;
      printTime(currentTime);
      Serial.println();
    }
}

time_t getTime()
{
  // getStatus will set the error LED in case of an error
  radioClock.getStatus();
  // time status is calculated in a call to now()
  time_t result = now();
  if (timeStatus()!= timeNotSet)
    return result;
  return 0;
}

// check if count, eg number of bits received, has changed, if yes, print it.
void showCount()
{
  int count = radioClock.getTickCount();
  if(count != oldCount){
    Serial.print("count="); Serial.println(count);
    oldCount = count;
  }
}

/*
The library provides 2 alternatives to synchronize the internal time of the Time library:

  * use Time.setSyncProvider(provider), where provider calls RadioClock.getTime()
              pro: re-sync intervall can be set in Time
              con: Time polls RadioClock.getTime() until a time is available. The accuracy at sync is 1 sec
  * use RadioClock.setTimeCallback(callback), where callback calls Time.setTime(time)
              pro: synching is done immediatly when a time message has been received. The accuracy at sync is in the millis.
              con: no re-sync intervall
              
*/
