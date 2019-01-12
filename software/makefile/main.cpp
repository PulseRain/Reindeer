#include "Arduino.h"
#include "HardwareSerial.h"

int cnt = 0;
extern void myprint(const char* str, ...);

extern HardwareSerial Serial;

int foo()
{
   int k = 0;
   k = k + 1;
   k = k - cnt;
   
   return k;
        
}

int main()
{
    int t = 0;
    
    while(1) {
        //t = t - cnt;
        t = t + foo();
      Serial.println("xxxxxx  ddddd");
      
      //  myprint ("ssss    %d    y  iiiiiuk\n", t);
    }
      
    return 0;
}
