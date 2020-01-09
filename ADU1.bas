'--------------------------------------------------------------
'                   Thomas Jensen | stdout.no
'--------------------------------------------------------------
'  file: ALARM_DISABLING_UNIT_1 v1.1
'  date: 22/04/2010
'--------------------------------------------------------------
$regfile = "attiny2313.dat"
$crystal = 8000000
Config Watchdog = 1024
Config Portb = Output
Config Portd = Input

'input D
'PD.0 Reset button
'PD.1 Stack lights signal
'PD.2 Jumper for setting long stop timer

'output B
'PB.0 Red LED
'PB.1 Blue LED
'PB.2 Stack lights relay N.O
'PB.3 Power LED

Dim A As Byte
Dim Lifesignal As Integer
Dim Alarm_timer As Word
Dim Alarm_timeout As Word
Dim Lystaarn_delay As Integer
Dim Reset_aktiv1 As Bit
Dim Reset_aktiv2 As Bit
Dim Led1 As Integer
Dim Led2 As Integer
Dim Service_exit As Word
Dim Service_enter As Integer

Alarm_timer = 0
Lifesignal = 11
Lystaarn_delay = 20
Reset_aktiv1 = 0
Reset_aktiv2 = 0
Led1 = 0
Led2 = 0
Service_enter = 0
Service_exit = 0

Portb = 0

Portb.1 = Not Portb.0                                       'boot
For A = 1 To 10
    Portb.0 = Not Portb.0
    Portb.1 = Not Portb.1
    Waitms 200
Next A

Portb = 0

Waitms 1000

Start Watchdog

Main:
'set timeout value
If Pind.2 = 1 Then Alarm_timeout = 36000                    '60 min
If Pind.2 = 0 Then Alarm_timeout = 18000                    '30 min

'counter for long stops
If Lystaarn_delay > 0 And Alarm_timer < 37000 Then Incr Alarm_timer

'no longer alarm situation
If Lystaarn_delay = 0 Then
   Alarm_timer = 0
   Reset_aktiv1 = 0
   Reset_aktiv2 = 0
   Portb.2 = 0
   End If

'stack light status
If Pind.1 = 0 Then Lystaarn_delay = 20
If Lystaarn_delay > 0 Then Decr Lystaarn_delay

'alarm triggered, reset possible
If Lystaarn_delay > 0 And Pind.0 = 1 Then Reset_aktiv1 = 1
If Alarm_timer > Alarm_timeout And Pind.0 = 1 Then Reset_aktiv2 = 1

'set red led
If Lystaarn_delay > 0 Then
   If Reset_aktiv1 = 0 And Alarm_timer < Alarm_timeout And Led1 = 0 Then
      Led1 = 5
      Portb.2 = 0
   End If
   If Reset_aktiv1 = 1 And Alarm_timer < Alarm_timeout Then
      Led1 = 5
      Portb.2 = 1
   End If
End If

'set blue led
If Alarm_timer > Alarm_timeout Then
   If Reset_aktiv2 = 0 And Led2 = 0 Then
      Led2 = 5
      Portb.2 = 0
   End If
   If Reset_aktiv2 = 1 Then
      Led2 = 5
      Portb.2 = 1
   End If
End If

'handle red led
If Led1 > 0 Then Decr Led1
If Led1 = 4 Then Portb.0 = 1
If Led1 = 2 Then Portb.0 = 0

'handle blue led
If Led2 > 0 Then Decr Led2
If Led2 = 4 Then Portb.1 = 1
If Led2 = 2 Then Portb.1 = 0

'lifesignal
If Lifesignal > 0 Then Lifesignal = Lifesignal - 1
If Lifesignal = 3 Then Portb.3 = 1
If Lifesignal = 1 Then Portb.3 = 0
If Lifesignal = 0 Then Lifesignal = 11

'handle service mode timer
If Pind.0 = 1 And Portb.0 = 0 And Portb.1 = 0 Then Incr Service_enter
If Pind.0 = 0 Then Service_enter = 0
If Service_enter = 200 Then
   Service_enter = 0
   For A = 1 To 10
      Portb.0 = Not Portb.0
      Portb.1 = Not Portb.1
      Reset Watchdog
      Waitms 100
   Next A
   Goto Service
End If

Reset Watchdog
Waitms 100
Goto Main
End

'service loop
Do
Service:
Portb.0 = 0
Portb.1 = 0
Portb.2 = 1

'lifesignal
Portb.3 = Not Portb.3

'exit loop
If Pind.0 = 1 Or Service_exit > 54000 Then
   Portb.3 = 0
   Lifesignal = 11
   Service_exit = 0
   Lystaarn_delay = 20
   Reset_aktiv1 = 1
   Goto Main
End If

'do loop
Incr Service_exit
Reset Watchdog
Waitms 100
Loop
End