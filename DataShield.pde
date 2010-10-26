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
  s_logFile.print(string);
}

void logFlush()
{
  s_logFile.sync();
}

//------------------------------------------------------------------------------------------

#define LOG_INTERVAL  1000
#define SYNC_INTERVAL 1000
uint32_t syncTime = 0;

void setup(void)
{
  Serial.begin(9600);
  initLog();

  s_logFile.println("LOGGING TEH BALLOON DATAZ");    
  logFlush();
}

void loop(void)
{
  logString("Test string, ");
  
  DateTime now = s_realTimeClock.now();
  uint32_t m = millis();
  
  s_logFile.print(m);
  s_logFile.print(", ");    

  s_logFile.print(now.unixtime());
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
 
  s_logFile.print(", MAD DATAZZZ");

  s_logFile.println();
  Serial.println("Logging");
  
  Serial.println("Syncing");
  logFlush();
  delay(1500);
}
