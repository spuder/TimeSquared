/*
radioClock_1 is a simple sketch to elaborate on the GenericExample sketch provided in 
the radioclock library. 

This sketch polls and saves the radio time to/from a 1307 Real Time Clock Module. 
The result is the time is not lost after a power cycle. Additionally, the current time 
is updated at every opportunity instead of just once at startup. 

  Created by Spencer Owen
  https://github.com/spudstud
  2 Feburary 2012
  Arduino 1.0.3
  Arduino Mega 2560
  
  Revision 1.0: (2 Feburary 2012)
    Polls 1307 on startup, and saves to 1307 on wireless update
    Only tested with wwvb module http://spuder.wordpress.com/2010/05/26/arduino-atomic-clock/
*/

//The library folder must have Time, TimeAlarms, and radioclocks libraries
//They can not be nested inside other folders
#include <Time.h>
#include <TimeAlarms.h>
#include <RadioClocks.h>
#include <PrintTime.h>

#include <Wire.h> //Library for i2c serial communicaiton
#include <DS1307RTC.h> //basic 1307 ic library that gets and sets time_t objects

//Pin 2 and 3 on arduinos support interupt functions
const int     signalPin = 2;
//
const boolean inverted = false;
//signalLED blinks every time a pulse is received from the radio
const int     signalLED = 13;

// uncomment the line that matches the protocol of the connected module
//DCF77 radioClock(signalPin, inverted, signalLED);
//MSF60 radioClock(signalPin, inverted, signalLED);
WWVB  radioClock(signalPin, inverted, signalLED);

//Put a led between pins 8 and 9, it will light up for 10 seconds on successful time update
int  ledPositive = 8; 
int  ledGround   = 9;

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
  
  delay(1000);
  
  Serial.print( hour() );
  Serial.print(":");
  Serial.print( minute() );
  Serial.print(":");
  Serial.print( second() );
  Serial.print(" ");
  Serial.print( day() );
  Serial.print("-");
  Serial.print( month() );
  Serial.print("-");
  Serial.print( year() ); 
  Serial.println(); 
 
}

// update the internal time of the Time library
void syncCallback(time_t syncedtime)
{
    // this is called from an intterupt so don't spend too much time here
    setTime(syncedtime);
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
