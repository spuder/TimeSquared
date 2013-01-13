/*
I am having some trouble where the RTC always sows time as 165/165/165
According to this thread, this code should work
http://arduino.cc/forum/index.php/topic,18949.0.html
*/

//clock SDA to analog pin 4   SCL to analog pin 5

#define DEBUG            //compile serial monitor clock display
#define SETCLOCK     //compile clock setup code

#include "Wire.h"

#define DS1307_I2C_ADDRESS 0x68       //seven bit address
#define MAXLINE 10
#define Mode12 1
#define Mode24 0
#define AM 0
#define PM 1

static char *dayname[] =
{ "Sun",
"Mon",    
"Tue",  
"Wed",  
"Thu",
"Fri",
"Sat"
};

void setup()
{
  Wire.begin();
  Serial.begin(9600);

#ifdef SETCLOCK
  char ans[1];
  int serbytes=0;
  Serial.println("Enter 'y' to set clock");
  serbytes = getSerStrWait(ans, 1, 10);
  if (strcmp(ans, "y") == 0) {
    setClock();
  }  
#endif

}

void loop()
{
  byte second, minute, hour, dayOfWeek, dayOfMonth, month, year, ampm;

  getClock(&second, &minute, &hour, &dayOfWeek, &dayOfMonth, &month, &year, &ampm);

#ifdef DEBUG
  leadzero(hour);
  Serial.print(hour, DEC);
  Serial.print(":");
  leadzero(minute);
  Serial.print(minute, DEC);
  Serial.print(":");
  leadzero(second);
  Serial.print(second, DEC);
  if (ampm != ' ') {                       //not space
    Serial.print(" ");
    Serial.print(ampm);
    Serial.print("M");
  }  
  Serial.print(" ");
  leadzero(month);
  Serial.print(month, DEC);
  Serial.print("/");
  leadzero(dayOfMonth);
  Serial.print(dayOfMonth, DEC);
  Serial.print("/");
  leadzero(year);
  Serial.print(year, DEC);
  Serial.print(" ");
  Serial.println(dayname[dayOfWeek-1]);
#endif

  delay(1000);
}

void leadzero(byte val) {
  if (val < 10) {
    Serial.print("0");
  }  
}

#ifdef SETCLOCK
void setClock() {
 //prompt for time settings
 byte second, minute, hour, dayOfWeek, dayOfMonth, month, year;
 byte mode = 0;
 byte ampm = 0;
 char ans[1];
 char dig2[3];
 int serbytes=0;

 Serial.println("Enter 2 dig year");
 serbytes = getSerStr(dig2, 2);
 year = atoi(dig2);
 Serial.println("Enter 2 dig month");
 serbytes = getSerStr(dig2, 2);
 month = atoi(dig2);
 Serial.println("Enter 2 dig day of month (1-31)");
 serbytes = getSerStr(dig2, 2);
 dayOfMonth = atoi(dig2);

 Serial.println("Enter day of week where 1=SUN 2=MON 3=TUE 4=WED 5=THU 6=FRI 7=SAT");
 serbytes = getSerStr(dig2, 1);
 dayOfWeek = atoi(dig2);

 Serial.println("Enter clock mode - 12 or 24");
 serbytes = getSerStr(dig2, 2);
 if (strcmp(dig2, "12") == 0) {
   mode = Mode12;  
   Serial.println("Enter 'a' or 'p' for AM or PM");
   serbytes = getSerStr(ans, 1);
   if (strcmp(ans, "p") == 0) {
     ampm = PM;  
   }
 }  
 Serial.print("Enter 2 dig hour ");
 if (mode == Mode12) {
   Serial.println("(1-12)");
 }else{
   Serial.println("(0-23)");
 }  
 serbytes = getSerStr(dig2, 2);
 hour = decToBcd(atoi(dig2));

 Serial.println("Enter 2 dig minute");
 serbytes = getSerStr(dig2, 2);
 minute = atoi(dig2);
 second = 0;
 if (mode == Mode12) {
   bitSet(hour,  6);
   if (ampm == PM) {
      bitSet(hour, 5);
   }  
 }  
 Wire.beginTransmission(DS1307_I2C_ADDRESS);
 Wire.write(0);
 Wire.write(decToBcd(second));    // 0 to bit 7 starts the clock
 Wire.write(decToBcd(minute));
 Wire.write(hour);                                      //already formatted with bits 6 and 5
 Wire.write(decToBcd(dayOfWeek));
 Wire.write(decToBcd(dayOfMonth));
 Wire.write(decToBcd(month));
 Wire.write(decToBcd(year));
 Wire.endTransmission();
}
#endif

// Gets the date and time from the ds1307
void getClock(byte *second,
          byte *minute,
          byte *hour,
          byte *dayOfWeek,
          byte *dayOfMonth,
          byte *month,
          byte *year,
          byte *ampm)
{
  byte work;
  byte mode;          //12 or 24 hour
  byte ap_ind;       //am or pm indicator
  
  // Reset the register pointer
  Wire.beginTransmission(DS1307_I2C_ADDRESS);
  Wire.write(0);
  Wire.endTransmission();

  Wire.requestFrom(DS1307_I2C_ADDRESS, 7);

  // A few of these need masks because certain bits are control bits
  *second     = bcdToDec(Wire.read() & 0x7f);      //mask CH bit (bit 7)
  *minute     = bcdToDec(Wire.read());

//  *hour = bcdToDec(Wire.read());
  work = Wire.read();                                                // get hour byte
  mode =  bitRead(work, 6);                                         // if bit  6  set,  running 12 hour mode
  if (mode == Mode12) {
    ap_ind = bitRead(work, 5);                                      // if bit 5 set,  time is PM
    *hour = bcdToDec(work & 0x1f);                             // mask bits 5 thru 7 for 12 hour clock
    if (ap_ind == PM) {
      *ampm = 'P';
    }else{
      *ampm = 'A';
    }  
  }else{  
    *hour = bcdToDec(work & 0x3f);                             // mask bits 6 and 7 for 24 hour clock
    *ampm = ' ';  
  }  

  *dayOfWeek  = bcdToDec(Wire.read());
  *dayOfMonth = bcdToDec(Wire.read());
  *month      = bcdToDec(Wire.read());
  *year       = bcdToDec(Wire.read());
}

#ifdef SETCLOCK
int getSerStr(char line[], int lim) {
  int bytesread=0;
  int val=0;
  Serial.flush();  
  while(bytesread<lim) {              
    if( Serial.available() > 0) {
      val = Serial.read();
      if((val == 10) || (val == 13) || (val == '*')) {        
        break;                               // stop reading
      }
      line[bytesread] = val;             // add the digit          
      bytesread++;                     // ready to read next character  
    }
   }
   line[bytesread] = '\0';                              //terminate string  
   return(bytesread);
}

int getSerStrWait(char line[], int lim, int waitsecs) {
  int bytesread=0;
  int val=0;
  unsigned long waitms = 1000 * waitsecs;
  unsigned long start = millis();
  Serial.flush();  
  while(bytesread<lim) {              
    if( Serial.available() > 0) {
      val = Serial.read();
      if((val == 10) || (val == 13) || (val == '*')) {        
        break;                               // stop reading
      }
      line[bytesread] = val;             // add the digit          
      bytesread++;                     // ready to read next character  
    }
    if (millis() - start > waitms) {
      Serial.flush();
      line[0] = '\0';
      return(0);
    }  
   }
   line[bytesread] = '\0';                              //terminate string  
   return(bytesread);
}
#endif

//BCD to decimal conversion: decVal =(bcdVal.NIB1 * 10) + bcdVal.NIB0
//decimal to BCD conversion: bcdVal = (decVal / 10 <<4) + bcdVal // 10

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

// Stops the DS1307, but it has the side effect of setting seconds to 0
// Probably only want to use this for testing
/*void stopDs1307()
{
  Wire.beginTransmission(DS1307_I2C_ADDRESS);
  Wire.write(0);
  Wire.write(0x80);
  Wire.endTransmission();
}*/ 
 
