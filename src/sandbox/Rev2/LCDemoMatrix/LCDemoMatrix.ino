#include <LedControl.h>
//There are 3 or 4 Maxim 72xx Libraries, 
//http://playground.arduino.cc/Main/LEDMatrix


/*
 Now we need a LedControl to work with.
 pin 12 is connected to the DataIn 
 pin 11 is connected to the CLK 
 pin 10 is connected to LOAD 
 */
LedControl ledDriver1=LedControl(5,6,7,1);
LedControl ledDriver2=LedControl(9,3,4,1);

/* we always wait a bit between updates of the display */
unsigned long delaytime=100;

int brightness;

void setup() {
  brightness = 15;
  /*
   The MAX72XX is in power-saving mode on startup,
   we have to do a wakeup call
   */
  ledDriver1.shutdown(0,false);
  ledDriver2.shutdown(0,false);
  /* Set the brightness to a medium values 0 darkest, 15 brightest*/
  ledDriver1.setIntensity(0,brightness);
  ledDriver2.setIntensity(0,brightness);
  /* and clear the display */
  ledDriver1.clearDisplay(0);
  ledDriver2.clearDisplay(0);
  
  
  for (int row=0; row<8; row++)
  {
    for (int column=0; column<8; column++)
     {     ledDriver1.setLed(0, row, column, true);
        
     }
  }//end forloop
  
  
}

/*
 This method will display the characters for the
 word "Arduino" one after the other on the matrix. 
 (you need at least 5x7 leds to see the whole chars)
 */
void writeArduinoOnMatrix() {
  /* here is the data for the characters */
  byte a[5]={B01111110,B10001000,B10001000,B10001000,B01111110};
  byte r[5]={B00111110,B00010000,B00100000,B00100000,B00010000};
  byte d[5]={B00011100,B00100010,B00100010,B00010010,B11111110};
  byte u[5]={B00111100,B00000010,B00000010,B00000100,B00111110};
  byte i[5]={B00000000,B00100010,B10111110,B00000010,B00000000};
  byte n[5]={B00111110,B00010000,B00100000,B00100000,B00011110};
  byte o[5]={B00011100,B00100010,B00100010,B00100010,B00011100};

  /* now display them one by one with a small delay */
  ledDriver1.setRow(0,0,a[0]);
  ledDriver1.setRow(0,1,a[1]);
  ledDriver1.setRow(0,2,a[2]);
  ledDriver1.setRow(0,3,a[3]);
  ledDriver1.setRow(0,4,a[4]);
  delay(delaytime);
  ledDriver1.setRow(0,0,r[0]);
  ledDriver1.setRow(0,1,r[1]);
  ledDriver1.setRow(0,2,r[2]);
  ledDriver1.setRow(0,3,r[3]);
  ledDriver1.setRow(0,4,r[4]);
  delay(delaytime);
  ledDriver1.setRow(0,0,d[0]);
  ledDriver1.setRow(0,1,d[1]);
  ledDriver1.setRow(0,2,d[2]);
  ledDriver1.setRow(0,3,d[3]);
  ledDriver1.setRow(0,4,d[4]);
  delay(delaytime);
  ledDriver1.setRow(0,0,u[0]);
  ledDriver1.setRow(0,1,u[1]);
  ledDriver1.setRow(0,2,u[2]);
  ledDriver1.setRow(0,3,u[3]);
  ledDriver1.setRow(0,4,u[4]);
  delay(delaytime);
  ledDriver1.setRow(0,0,i[0]);
  ledDriver1.setRow(0,1,i[1]);
  ledDriver1.setRow(0,2,i[2]);
  ledDriver1.setRow(0,3,i[3]);
  ledDriver1.setRow(0,4,i[4]);
  delay(delaytime);
  ledDriver1.setRow(0,0,n[0]);
  ledDriver1.setRow(0,1,n[1]);
  ledDriver1.setRow(0,2,n[2]);
  ledDriver1.setRow(0,3,n[3]);
  ledDriver1.setRow(0,4,n[4]);
  delay(delaytime);
  ledDriver1.setRow(0,0,o[0]);
  ledDriver1.setRow(0,1,o[1]);
  ledDriver1.setRow(0,2,o[2]);
  ledDriver1.setRow(0,3,o[3]);
  ledDriver1.setRow(0,4,o[4]);
  delay(delaytime);
  ledDriver1.setRow(0,0,0);
  ledDriver1.setRow(0,1,0);
  ledDriver1.setRow(0,2,0);
  ledDriver1.setRow(0,3,0);
  ledDriver1.setRow(0,4,0);
  delay(delaytime);
}

/*
  This function lights up a some Leds in a row.
 The pattern will be repeated on every row.
 The pattern will blink along with the row-number.
 row number 4 (index==3) will blink 4 times etc.
 */
void rows() {
  for(int row=0;row<8;row++) {
    delay(delaytime);
    ledDriver1.setRow(0,row,B10100000);
    ledDriver2.setRow(0,row,B10100000);
    delay(delaytime);
    ledDriver1.setRow(0,row,(byte)0);
    ledDriver2.setRow(0,row,(byte)0);
    for(int i=0;i<row;i++) {
      delay(delaytime);
      ledDriver1.setRow(0,row,B10100000);
      ledDriver2.setRow(0,row,B10100000);
      delay(delaytime);
      ledDriver1.setRow(0,row,(byte)0);
      ledDriver2.setRow(0,row,(byte)0);
    }
  }
}

/*
  This function lights up a some Leds in a column.
 The pattern will be repeated on every column.
 The pattern will blink along with the column-number.
 column number 4 (index==3) will blink 4 times etc.
 */
void columns() {
  for(int col=0;col<8;col++) {
    delay(delaytime);
    ledDriver1.setColumn(0,col,B10100000);
    delay(delaytime);
    ledDriver1.setColumn(0,col,(byte)0);
    for(int i=0;i<col;i++) {
      delay(delaytime);
      ledDriver1.setColumn(0,col,B10100000);
      delay(delaytime);
      ledDriver1.setColumn(0,col,(byte)0);
    }
  }
}

/* 
 This function will light up every Led on the matrix.
 The led will blink along with the row-number.
 row number 4 (index==3) will blink 4 times etc.
 */
void single() {
  for(int row=0;row<8;row++) {
    for(int col=0;col<8;col++) {
      delay(delaytime);
      ledDriver1.setLed(0,row,col,true);
      ledDriver2.setLed(0,row,col,true);
      delay(delaytime);
      for(int i=0;i<col;i++) {
        ledDriver1.setLed(0,row,col,false);
        ledDriver2.setLed(0,row,col,false);
        delay(delaytime);
        ledDriver1.setLed(0,row,col,true);
        ledDriver2.setLed(0,row,col,true);
        
        
        delay(delaytime);
      }
    }
  }
}
void spencersTest() {
  for (int row=0; row<8; row++)
  {
    for (int column=0; column<8; column++)
     {     ledDriver1.setLed(0, row, column, true);
        delay(delaytime);
     }
  }//end forloop
  ledDriver1.clearDisplay(0);
  
  brightness = brightness - 5;
  ledDriver1.setIntensity(0,brightness);

}//end spencersTest

void brightnessTest() {
  
  brightness = brightness - 3;
  ledDriver1.setIntensity(0, brightness);
  delay(1000);
  if (brightness < 0)
    {
      brightness =15;
    }  
}

void loop() {
 //spencersTest(); 
 brightnessTest();
 // writeArduinoOnMatrix();
 // rows();
 // columns();
 // single();
}
