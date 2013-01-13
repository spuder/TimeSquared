#include <Wire.h>
#define DS1307_I2C_ADDRESS 0x68

/**
There are multiple libraries and ways to use a 1307, This is option 1
I actually prefer ladyada's solution. This file is NOT her solution
It is crap. 


The good solution: 
http://www.ladyada.net/learn/breakoutplus/ds1307rtc.html
*/


//This is for arduino 1.0 only
//http://combustory.com/wiki/index.php/RTC1307_-_Real_Time_Clock

#define I2C_WRITE Wire.write
#define I2C_READ Wire.read



void setup () {
 Serial.begin(115200);
 Wire.begin();
}

void loop () {

  getDateFrom1307();
  delay(1000);
}


void getDateFrom1307() {
  Wire.beginTransmission(DS1307_I2C_ADDRESS);
  I2C_WRITE(0);
  Wire.endTransmission();
  Wire.requestFrom(DS1307_I2C_ADDRESS, 7);



  // A few of these need masks because certain bits are control bits
 int second     = bcdToDec(I2C_READ() & 0x7f);
 int  minute     = bcdToDec(I2C_READ());
 int  hour       = bcdToDec(I2C_READ() & 0x3f);  // Need to change this if 12 hour am/pm
 int dayOfWeek  = bcdToDec(I2C_READ());
 int dayOfMonth = bcdToDec(I2C_READ());
 int month      = bcdToDec(I2C_READ());
 int  year       = bcdToDec(I2C_READ());
 
  if (hour < 10)
    Serial.print("0");
  Serial.print(hour, DEC);
  Serial.print(":");
  if (minute < 10)
    Serial.print("0");
  Serial.print(minute, DEC);
  Serial.print(":");
  if (second < 10)
    Serial.print("0");
  Serial.print(second, DEC);
  Serial.print("  ");
//  Serial.print(Day[dayOfWeek]);
  Serial.print(", ");
  Serial.print(dayOfMonth, DEC);
  Serial.print(" ");
//  Serial.print(Mon[month]);
  Serial.print(" 20");
  if (year < 10)
    Serial.print("0");
  Serial.println(year, DEC);
  
  
  
}

// Convert normal decimal numbers to binary coded decimal
byte decToBcd(byte val)
{
  return ( (val/10*16) + (val%10) );
}
 
// Convert binary coded decimal to normal decimal numbers
byte bcdToDec(byte val)
{
  return ( (val/16*10) + (val%16) );
}
