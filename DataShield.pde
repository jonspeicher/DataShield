// -------------------------------------------------------------------------------------------------
// TBD - TBD
// A project of HackPittsburgh (http://www.hackpittsburgh.org)
//
// Copyright (c) 2010 Jonathan Speicher (jonathan@hackpittsburgh.org)
// Licensed under the MIT license: http://creativecommons.org/licenses/MIT
// -------------------------------------------------------------------------------------------------

#include <Wire.h>

#include "RTClib.h"
#include "SdFat.h"

static RTC_DS1307 s_realTimeClock;
static Sd2Card    s_sdCard;
static SdVolume   s_fatVolume;
static SdFile     s_rootDirectory;
static SdFile     s_logFile;

void initLog()
{
  Wire.begin();  
  s_realTimeClock.begin();

  s_sdCard.init();
  s_fatVolume.init(s_sdCard);
  s_rootDirectory.openRoot(s_fatVolume);
  
  char name[] = "LOGGER00.CSV";
  
  for (uint8_t i = 0; i < 100; i++) 
  {
    name[6] = i/10 + '0';
    name[7] = i%10 + '0';
    if (s_logFile.open(s_rootDirectory, name, O_CREAT | O_EXCL | O_WRITE)) break;
  }
  
  Serial.print("Logging to: ");
  Serial.println(name);
}

void logString(char string[])
{
}


// A simple data logger for the Arduino analog pins
#define LOG_INTERVAL  1000 // mills between entries
#define ECHO_TO_SERIAL   1 // echo data to serial port
#define WAIT_TO_START    0 // Wait for serial input in setup()
#define SYNC_INTERVAL 1000 // mills between calls to sync()
uint32_t syncTime = 0;     // time of last sync()

// the digital pins that connect to the LEDs
#define redLEDpin 2
#define greenLEDpin 3

// The analog pins that connect to the sensors
#define photocellPin 0           // analog 0
#define tempPin 1                // analog 1
#define BANDGAPREF 14            // special indicator that we want to measure the bandgap

#define aref_voltage 3.3         // we tie 3.3V to ARef and measure it with a multimeter!
#define bandgap_voltage 1.1      // this is not super guaranteed but its not -too- off


// --------

void error(char *str)
{
  Serial.print("error: ");
  Serial.println(str);
  while(1);
}

void setup(void)
{
  Serial.begin(9600);
  initLog();

  
  
  

  // write header
  s_logFile.writeError = 0;


  }
  

  s_logFile.println("millis,stamp,datetime,light,temp,vcc");    
#if ECHO_TO_SERIAL
  Serial.println("millis,stamp,datetime,light,temp,vcc");
#endif //ECHO_TO_SERIAL

  // attempt to write out the header to the file
  if (s_logFile.writeError || !s_logFile.sync()) {
    error("write header");
  }
  
  pinMode(redLEDpin, OUTPUT);
  pinMode(greenLEDpin, OUTPUT);
 
  // If you want to set the aref to something other than 5v
  analogReference(EXTERNAL);
}

void loop(void)
{
  DateTime now;
  
  // clear print error
  s_logFile.writeError = 0;

  // delay for the amount of time we want between readings
  delay((LOG_INTERVAL -1) - (millis() % LOG_INTERVAL));
  
  digitalWrite(redLEDpin, HIGH);

  // log milliseconds since starting
  uint32_t m = millis();
  s_logFile.print(m);           // milliseconds since start
  s_logFile.print(", ");    
#if ECHO_TO_SERIAL
  Serial.print(m);         // milliseconds since start
  Serial.print(", ");  
#endif

  // fetch the time
  now = s_realTimeClock.now();
  // log time
  s_logFile.print(now.unixtime()); // seconds since 1/1/1970
  s_logFile.print(", ");
  s_logFile.print('"');
  s_logFile.print(now.year(), DEC);
  s_logFile.print("/");
  s_logFile.print(now.month(), DEC);
  s_logFile.print("/");
  s_logFile.print(now.day(), DEC);
  s_logFile.print(" ");
  s_logFile.print(now.hour(), DEC);
  s_logFile.print(":");
  s_logFile.print(now.minute(), DEC);
  s_logFile.print(":");
  s_logFile.print(now.second(), DEC);
  s_logFile.print('"');
#if ECHO_TO_SERIAL
  Serial.print(now.unixtime()); // seconds since 1/1/1970
  Serial.print(", ");
  Serial.print('"');
  Serial.print(now.year(), DEC);
  Serial.print("/");
  Serial.print(now.month(), DEC);
  Serial.print("/");
  Serial.print(now.day(), DEC);
  Serial.print(" ");
  Serial.print(now.hour(), DEC);
  Serial.print(":");
  Serial.print(now.minute(), DEC);
  Serial.print(":");
  Serial.print(now.second(), DEC);
  Serial.print('"');
#endif //ECHO_TO_SERIAL

  analogRead(photocellPin);
  delay(10); 
  int photocellReading = analogRead(photocellPin);  
  
  analogRead(tempPin); 
  delay(10);
  int tempReading = analogRead(tempPin);    
  
  // converting that reading to voltage, for 3.3v arduino use 3.3, for 5.0, use 5.0
  float voltage = tempReading * aref_voltage / 1024;  
  float temperatureC = (voltage - 0.5) * 100 ;
  float temperatureF = (temperatureC * 9 / 5) + 32;
  
  s_logFile.print(", ");    
  s_logFile.print(photocellReading);
  s_logFile.print(", ");    
  s_logFile.print(temperatureF);
#if ECHO_TO_SERIAL
  Serial.print(", ");   
  Serial.print(photocellReading);
  Serial.print(", ");    
  Serial.print(temperatureF);
#endif //ECHO_TO_SERIAL

  // Log the estimated 'VCC' voltage by measuring the internal 1.1v ref
  analogRead(BANDGAPREF); 
  delay(10);
  int refReading = analogRead(BANDGAPREF); 
  float supplyvoltage = (bandgap_voltage * 1024) / refReading; 
  
  s_logFile.print(", ");
  s_logFile.print(supplyvoltage);
#if ECHO_TO_SERIAL
  Serial.print(", ");   
  Serial.print(supplyvoltage);
#endif // ECHO_TO_SERIAL

  s_logFile.println();
#if ECHO_TO_SERIAL
  Serial.println();
#endif // ECHO_TO_SERIAL

  if (s_logFile.writeError) error("write data");
  digitalWrite(redLEDpin, LOW);
  
  //don't sync too often - requires 2048 bytes of I/O to SD card
  if ((millis() - syncTime) <  SYNC_INTERVAL) return;
  syncTime = millis();
  
  // blink LED to show we are syncing data to the card & updating FAT!
  digitalWrite(greenLEDpin, HIGH);
  if (!s_logFile.sync()) error("sync");
  digitalWrite(greenLEDpin, LOW);
}
