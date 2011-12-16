long xCnt = 0; // initialize the x axis integration variable
long yCnt = 0; // initialize the y axis integration variable
long xPrevCnt = 0; // initialize the x axis integration variable
unsigned int yPrevCnt = 0; // initialize the y axis integration variable
float ppiX = 157.4744*25.4; // conversion of pulses in x to inches
float ppiY = 157.76525*25.4; // conversion of pulses in y to inches
long lastPulseOnPos[]={0,0};
int laserCmd = 0;
int laserCmdPrev = 0;
int pulse = 0;
int pulseMS = 500;
int firstOnState = 0;
float PPI = 4;
unsigned long timeOld = 0;

float cumDist = 0;

#define turnLsrOff PORTB&=B01111111 //macro sets laser off
#define turnLsrOn PORTB|=B10000000 //macro sets laser on
#define lsrCmdPin ((PIND>>7)&1) // defines pin that laser comnd is on


void setup() {
  DDRA = 0x00;
  DDRC = 0x00;
  DDRL = 0x00;
  DDRB = DDRB|B01000000&B11000000;
  DDRG = DDRG&B11111000;
  DDRD = DDRD|B01111111;
}

void loop() {
  updateCounts();
  updateLaserCmd();
  if (laserCmd) {
    if (checkForMotion()){
      calcTravel();
      if (firstOnState) {
        cumDist = 0;
        timeOld = millis();
        pulse = 1;
        firstOnState = 0;
      }
      if (millis() - timeOld >= pulseMS) {pulse = 0;}
      if (cumDist >= 1/PPI) {
        cumDist = 0;
        timeOld = millis();
        pulse = 1;
      }
      if (pulse) {turnLsrOn;} else {turnLsrOff;}       
    }else{
      turnLsrOff;
    }
  }else{
    turnLsrOff;
  }
}

void calcTravel() {
  cumDist += sqrt(pow((xCnt-xPrevCnt)/ppiX,2) + pow((yCnt-yPrevCnt)/ppiY,2));
}

void updateCounts() {
  xPrevCnt = xCnt;
  yPrevCnt = yCnt;
  xCnt = PINA|(long)PINC<<8|(long)digitalRead(39)<<16;
  yCnt = PINL|(long)((PINB&B00111111)<<8)|(long)((PING&B00000011)<<14);
}

// This function reads the laser on/off command from the smooth stepper and stores the
// previous result.  This function checsk for the laser cmd going from 0 to 1 so timer
// and distcalc can be reset
void updateLaserCmd() {
  laserCmdPrev = laserCmd;
  laserCmd = lsrCmdPin;
  if ((laserCmdPrev == 0) && (laserCmd == 1)) {firstOnState = 1;}
}

// This function checks for motion in the x,y axis by comparint the previous count
// to the current count.  If the numbers are the same, then it there is no motion
int checkForMotion() {
  if ((xPrevCnt == xCnt) && (yPrevCnt == yCnt)) {return 0;} else {return 1;}
}

