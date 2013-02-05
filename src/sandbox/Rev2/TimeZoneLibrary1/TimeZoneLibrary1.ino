/*---------------------------------------------------------------
  TimeZone library example sketch
  
  This sketch now modifies the current time based on the number of 
  times the buttons connected to pins 4 and 5 are pushed. 
  
  Revision 1.1 (4 Febuary 2013)
  Spencer Owen
  -Added button library
  -added array of timezones
  
  
  Origional TimeZone library example sketch
  Jack Christensen Aug 2012                                            
                                                                       
  This work is licensed under the Creative Commons Attribution-        
  ShareAlike 3.0 Unported License.
  
*/---------------------------------------------------------------


#include <DS1307RTC.h>   //http://www.arduino.cc/playground/Code/Time
#include <Time.h>        //http://www.arduino.cc/playground/Code/Time
#include <Timezone.h>    //https://github.com/JChristensen/Timezone
#include <Wire.h>        //http://arduino.cc/en/Reference/Wire (supplied with the Arduino IDE)
#include <Button.h>      //https://github.com/JChristensen/Button


#define leftButtonPin  4
#define rightButtonPin 5
Button leftButton(leftButtonPin, false, false, 25);
Button rightButton(rightButtonPin, false, false, 25);

float displayMillis = millis();


//US Eastern Time Zone (New York, Detroit)
TimeChangeRule EDT = {"EDT", Second, Sun, Mar, 2, -240};    //Daylight time = UTC - 4 hours
TimeChangeRule EST = {"EST", First, Sun, Nov, 2, -300};     //Standard time = UTC - 5 hours
Timezone Eastern(EDT, EST);
TimeChangeRule CDT = {"CDT", Second, Sun, Mar, 2, -300};    //-5 hours
TimeChangeRule CST = {"CST", First, Sun, Nov, 2, -360};     //-6 hours
Timezone Central(CDT, CST);
TimeChangeRule MDT = {"MDT", Second, Sun, Mar, 2, -360};    // -6 hours
TimeChangeRule MST = {"MST", First, Sun, Nov, 2, -420};    // - 7 hours
Timezone Mountain(MDT, MST);
TimeChangeRule PDT = {"PDT", Second, Sun, Mar, 2, -420};    // -7 hours
TimeChangeRule PST = {"PST", First, Sun, Nov, 2, -480};    // - 8 hours
Timezone Pacific(PDT, PST);
TimeChangeRule utcRule = {"UTC", First, Sun, Nov, 2, 0};    //No change for UTC
Timezone UTC(utcRule, utcRule);

//Timezone myTZ(EDT, EST);
//Timezone myTZ(MDT, MST);

time_t utc;
time_t local;
time_t lastUTC;
time_t tSet;
Timezone *timezones[] = { &Pacific, &Mountain, &Central, &Eastern, &UTC };
char     *tzNames[]   = { "Pacific","Mountain","Central","Eastern","UTC"};
Timezone *tz;               //pointer to the time zone
uint8_t tzIndex;            //index to the timezones[] array (persisted in RTC SRAM)
//char *tzNames[] = {  "UTC  ","Eastern", "Central", "Mountain", "Pacific"};


TimeChangeRule *tcr;        //pointer to the time change rule, use to get TZ abbrev

const uint8_t monthDays[] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
tmElements_t tmSet;




//If TimeChangeRules are already stored in EEPROM, comment out the three
//lines above and uncomment the line below.
//Timezone myTZ(100);       //assumes rules stored at EEPROM address 100



void setup(void)
{
    Serial.begin(115200);
    setSyncProvider(RTC.get);   // the function to get the time from the RTC
    if(timeStatus()!= timeSet) 
        Serial.println("Unable to sync with the RTC");
    else
        Serial.println("RTC has set the system time"); 
   
   tzIndex = 0; //set which timezone index of the array we want 0=PDT,1=MDT ect.. 
   tz = timezones[tzIndex];
}

void loop(void)
{
   rightButton.read();
   leftButton.read();
  
   if ( leftButton.wasReleased() ) {

            if (tzIndex > 0 ) { //c doesn't have array.length, had to hard code array length :(
              tzIndex = tzIndex - 1;
            }else {
              Serial.println("Lowest in timeZone array is 0");
            }
            tz = timezones[tzIndex];
            Serial.print("tzIndex = ");
            Serial.println(tzIndex);


   } 
   if ( rightButton.wasReleased() ) {
            if (tzIndex < 4 ) { //c doesn't have array.length, had to hard code array length :(
              tzIndex = tzIndex + 1;
            }else {
              Serial.println("Highest in timeZone array is 3");
            }
            tz = timezones[tzIndex];
            Serial.print("tzIndex = ");
            Serial.println(tzIndex);
   
   }
   //Display the time every second
   //Don't use a delay() because we need to poll the buttons as fast as possible
   if ( millis() - displayMillis > 1000 ) {
      displayMillis = millis(); 
      Serial.println();
      utc = now();
      printTime(utc, "UTC");
      //local = myTZ.toLocal(utc, &tcr);
      local = (*tz).toLocal(utc,&tcr);
      printTime(local, tcr -> abbrev);
   }
   

}

//Function to print time with time zone
void printTime(time_t t, char *tz)
{
    sPrintI00(hour(t));
    sPrintDigits(minute(t));
    sPrintDigits(second(t));
    Serial.print(' ');
    Serial.print(dayShortStr(weekday(t)));
    Serial.print(' ');
    sPrintI00(day(t));
    Serial.print(' ');
    Serial.print(monthShortStr(month(t)));
    Serial.print(' ');
    Serial.print(year(t));
    Serial.print(' ');
    Serial.print(tz);
    Serial.println();
}

//Print an integer in "00" format (with leading zero).
//Input value assumed to be between 0 and 99.
void sPrintI00(int val)
{
    if (val < 10) Serial.print('0');
    Serial.print(val, DEC);
    return;
}

//Print an integer in ":00" format (with leading zero).
//Input value assumed to be between 0 and 99.
void sPrintDigits(int val)
{
    Serial.print(':');
    if(val < 10) Serial.print('0');
    Serial.print(val, DEC);
}

