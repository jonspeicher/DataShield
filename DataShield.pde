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

void logString(char userString[])
{
  char timeString[40];
  DateTime wall = s_realTimeClock.now();
  
  sprintf(timeString, "%ld, \"%02d-%02d-%04d %d:%02d:%02d\", ", 
    millis(), wall.month(), wall.day(), wall.year(), wall.hour(), wall.minute(), wall.second());
    
  s_logFile.print(timeString);
  s_logFile.println(userString);
}

void logFlush()
{
  s_logFile.sync();
}

//------------------------------------------------------------------------------------------

void setup(void)
{
  Serial.begin(9600);
  
  initLog();
  logString("LOG BEGIN");    
  logFlush();
}

void loop(void)
{
  Serial.println("Logging data...");
  
  logString("data, data, data, data, data");
  logFlush();
  delay(5000);
}
