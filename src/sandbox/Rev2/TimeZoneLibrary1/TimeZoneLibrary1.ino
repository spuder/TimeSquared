/*----------------------------------------------------------------------*
 * Timezone library example sketch.                                     *
 * Self-adjusting clock for one time zone using an external real-time   *
 * clock, either a DS1307 or DS3231 (e.g. Chronodot).                   *
 * Assumes the RTC is set to UTC.                                       *
 * TimeChangeRules can be hard-coded or read from EEPROM, see comments. *
 * Check out the Chronodot at http://www.macetech.com/store/            *
 *                                                                      *
 * Jack Christensen Aug 2012                                            *
 *                                                                      *
 * This work is licensed under the Creative Commons Attribution-        *
 * ShareAlike 3.0 Unported License. To view a copy of this license,     *
 * visit http://creativecommons.org/licenses/by-sa/3.0/ or send a       *
 * letter to Creative Commons, 171 Second Street, Suite 300,            *
 * San Francisco, California, 94105, USA.                               *
 *----------------------------------------------------------------------*/

#include <DS1307RTC.h>   //http://www.arduino.cc/playground/Code/Time
#include <Time.h>        //http://www.arduino.cc/playground/Code/Time
#include <Timezone.h>    //https://github.com/JChristensen/Timezone
#include <Wire.h>        //http://arduino.cc/en/Reference/Wire (supplied with the Arduino IDE)

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


Timezone *timezones[] = { &Eastern, &Central, &Mountain, &Pacific, &UTC };
Timezone *tz;               //pointer to the time zone
uint8_t tzIndex;            //index to the timezones[] array (persisted in RTC SRAM)
char *tzNames[] = { "Eastern", "Central", "Mountain", "Pacific", "UTC  " };
TimeChangeRule *tcr;        //pointer to the time change rule, use to get TZ abbrev
time_t utc, local, lastUTC, tSet;
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
}

void loop(void)
{
    Serial.println();
    utc = now();
    printTime(utc, "UTC");
    //local = myTZ.toLocal(utc, &tcr);
    local = (*tz).toLocal(utc,&tcr);
    printTime(local, tcr -> abbrev);
    delay(10000);
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

/*

        case SET_TZ:
            STATE = SET_CALIB;
            tzIndex = setVal("Timezone: ", tzIndex, 0, sizeof(tzNames)/sizeof(tzNames[0]) - 1, 0);
            if (STATE == RUN) break;
            tz = timezones[tzIndex];
            RTC.sramWrite(TZ_INDEX_ADDR, tzIndex);    //save it
            break;
*/
