/**
 * There are multiple ways to use a 1307 and each has its own library
 * This is ladyada's solution which I think is the best.
 * 
 * http://www.ladyada.net/learn/breakoutplus/ds1307rtc.html
 *
 * I could not get this working with 1.8K ohm resistors, as soon 
 * as I removed the resistors, it worked perfectly.

 Pinout
  
  Arduino Uno,Diminulve ect...
  SDA ->  Analog 4
  SCL ->  Analog 5
  
  Arduino Mega
  SDA -> 20
  SCL -> 21
 */


#include <Wire.h>

//This is ladyada's 1307 library
//https://github.com/adafruit/RTClib
#include "RTClib.h"

RTC_DS1307 RTC;

void setup() {
  Serial.begin(115200);
  Wire.begin();
  RTC.begin();
  Serial.println("Arduino Starting Up");


  if (! RTC.isrunning()) {
    Serial.println("RTC is NOT running!");
    // following line sets the RTC to the date & time this sketch was compiled
    RTC.adjust(DateTime(__DATE__, __TIME__));
  }

}

void loop () {
  
DateTime now = RTC.now();
 
    Serial.print(now.year(), DEC);
    Serial.print('/');
    Serial.print(now.month(), DEC);
    Serial.print('/');
    Serial.print(now.day(), DEC);
    Serial.print(' ');
    Serial.print(now.hour(), DEC);
    Serial.print(':');
    Serial.print(now.minute(), DEC);
    Serial.print(':');
    Serial.print(now.second(), DEC);
    Serial.println();
 
    Serial.print(" since 1970 = ");
    Serial.print(now.unixtime());
    Serial.print("s = ");
    Serial.print(now.unixtime() / 86400L);
    Serial.println("d");

  // calculate a date which is 7 days and 30 seconds into the future
  DateTime future (now.unixtime() + 7 * 86400L + 30);

  Serial.print(" now + 7d + 30s: ");
  Serial.print(future.year(), DEC);
  Serial.print('/');
  Serial.print(future.month(), DEC);
  Serial.print('/');
  Serial.print(future.day(), DEC);
  Serial.print(' ');
  Serial.print(future.hour(), DEC);
  Serial.print(':');
  Serial.print(future.minute(), DEC);
  Serial.print(':');
  Serial.print(future.second(), DEC);
  Serial.println();

  Serial.println();
  delay(3000);
}

