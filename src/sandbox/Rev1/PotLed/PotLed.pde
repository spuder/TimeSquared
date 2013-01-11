
int val;
void setup()
{
  pinMode(2,OUTPUT);
  pinMode(3,OUTPUT);
  pinMode(4,OUTPUT);
  pinMode(5,OUTPUT);
  Serial.begin(9600);
  
}

void loop()
{
  Serial.println(analogRead(0));
  val = analogRead(0);
 if (val > 100)
 digitalWrite(2,HIGH);
 if (val < 100)
 digitalWrite(2,LOW);
  
  if (val > 200)
 digitalWrite(3,HIGH);
 if (val < 200)
 digitalWrite(3,LOW); 
 
   if (val > 300)
 digitalWrite(4,HIGH);
 if (val < 300)
 digitalWrite(4,LOW);
 
   if (val > 400 )
 digitalWrite(5,HIGH);
 if (val < 400)
 digitalWrite(5,LOW);
 delay(100);
}

