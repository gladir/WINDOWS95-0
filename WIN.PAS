{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/windows95-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program WIN;

Uses {$IFDEF FPC}
      DOS,Windows,PtcMouse,PtcCrt,PtcGraph
     {$ELSE}
      DOS,Crt,Graph
     {$ENDIF};

Var
 MenuVisible:Boolean;
 MouseX,MouseY:LongInt;
 ShutdownDialogVisible:Boolean;
 SelectedShutdownOption:Integer; {  CenterX := GetMaxX div 2;
 CenterY := GetMaxY div 2;
 DialogX2 := CenterX + 200;
 DialogY2 := CenterY + 70;

 IsMouseOnRunCancelButton := (x >= DialogX2 - 85) and (x <= DialogX2 - 10) and
                            (y >= DialogY2 - 35) and (y <= DialogY2 - 15);dre, 2=Redemarrer, 3=Quitter }
 HighlightedMenuItem:Integer; { 0=aucun, 1-8=element du menu }
 RunDialogVisible:Boolean;
 RunCommand:String;
 CursorPos:Integer;

{ Variables pour la boîte de dialogue Date/Heure }
Var
 DateTimeDialogVisible: Boolean;
 CurrentTab: Integer; { 1=Date et heure, 2=Fuseau horaire }
 SelectedHour, SelectedMin, SelectedSec: Word;
 SelectedYear, SelectedMonth, SelectedDay: Word;
 TimeZone: String;
 CurrentSec100, DayOfWeek: Word;

{$IFNDEF FPC}
 Function SetAPMMode(Mode:Word):Boolean;Assembler;ASM
   { Connecter l'interface RM }
  MOV AX,5301h
  XOR BX,BX
  INT 15h
   { Active le pilote APM 1.1 }
  MOV AX,530Eh
  XOR BX,BX
  MOV CX,0101h
  INT 15h
   { Active l'APM }
  MOV AX,5308h
  MOV BX,1
  MOV CX,BX
  INT 15h
   { Demande la mode sp?cifier }
  MOV AX,5307h
  mov BX,1
  MOV CX,Mode
  INT 15h
  MOV AL,0
  JC  @Error
  MOV AL,True
@Error:
@End:
 END;

 Function MouseDriverFound:Boolean;
 Var
  Regs:Registers;
 Begin
  Regs.AX:=0;
  Intr($33,Regs);
  MouseDriverFound:=Regs.AX=$FFFF;
 End;

 Procedure GetMouseState(Var X,Y,Button:LongInt);
 Var
  Regs:Registers;
 Begin
  Regs.AX:=$0003;
  Intr($33,Regs);
  Button:=Regs.BX;
  X:=Regs.CX;
  Y:=Regs.DX;
 End;

 Function GetMouseButton:Word;
 Var
  X,Y,Button:LongInt;
 Begin
  GetMouseState(X,Y,Button);
  GetMouseButton:=Button;
 End;
{$ENDIF}

 { Fonction simple pour simuler GetTickCount }
Function GetTickCount: LongInt;Begin
 {$IFDEF FPC}
  GetTickCount:=GetTickCount64;
 {$ELSE}
  GetTickCount:=MemL[Seg0040:$006C]; { Turbo Pascal - lecture directe de la m�moire }
 {$ENDIF}
End;

{ Convertit un entier en chaîne }
Function IntToStr(Value:Integer):String;
Var
 S:String;
Begin
 Str(Value,S);
 IntToStr:=S;
End;

{ Obtient l'heure actuelle au format Windows 95 }
Function GetCurrentTime:String;
Var
 Hour,Min,Sec,Sec100:Word;
 TimeStr:String;
 MinStr:String;
Begin
 {$IFDEF FPC}
  GetTime(Hour,Min,Sec,Sec100);
 {$ELSE}
  GetTime(Hour,Min,Sec,Sec100);
 {$ENDIF}
  { Formatage des minutes avec zéro initial }
 If Min<10 Then MinStr:='0'+IntToStr(Min)
           Else MinStr:=IntToStr(Min);
 { Format 12 heures avec AM/PM comme Windows 95 }
 If Hour=0 Then TimeStr:='12:'+MinStr+' AM' Else
 If Hour<12 Then TimeStr:=IntToStr(Hour)+':'+MinStr+' AM' Else
 If Hour=12 Then TimeStr:='12:'+MinStr+' PM'
            Else TimeStr:=IntToStr(Hour-12)+':'+MinStr+' PM';
 GetCurrentTime := TimeStr;
End;

{ Obtient la date actuelle au format Windows 95 }
Function GetCurrentDate:String;
Var
 Year,Month,Day,DayOfWeek:Word;
 DateStr:String;
 MonthStr,DayStr:String;
Begin
 {$IFDEF FPC}
  GetDate(Year, Month, Day, DayOfWeek);
 {$ELSE}
  GetDate(Year, Month, Day, DayOfWeek);
 {$ENDIF}
 { Formatage avec zéros initiaux }
 If Month<10 Then MonthStr:='0'+IntToStr(Month)
             Else MonthStr:=IntToStr(Month);
 If Day<10 Then DayStr:='0'+IntToStr(Day)
           Else DayStr:=IntToStr(Day);
  { Format MM/DD/YYYY comme Windows 95 américain }
 DateStr:=MonthStr + '/'+DayStr + '/'+IntToStr(Year);
 GetCurrentDate:=DateStr;
End;

Procedure InitScr;
Var
 GraphDriver,GraphMode:Integer;
Begin
 {$IFDEF FPC}
  GraphDriver:=VGA;
  GraphMode:=VGAHi;
 {$ELSE}
  GraphDriver:=Detect;
  GraphMode:=VGAHi;
 {$ENDIF}
 InitGraph(GraphDriver, GraphMode,'');
 If GraphResult <> grOk then
 Begin
  WriteLn('Erreur d''initialisation graphique!');
  Halt(1);
 End;
End;

{ Dessine une bordure 3D enfoncée }
Procedure Draw3DBorder(x1,y1,x2,y2:Integer;Raised:Boolean);Begin
 If Raised Then Begin
  SetColor(White);
  Line(x1, y1, x2-1, y1);     { Haut }
  Line(x1, y1, x1, y2-1);     { Gauche }
  SetColor(DarkGray);
  Line(x2, y1, x2, y2);       { Droite }
  Line(x1, y2, x2, y2);       { Bas }
 End
  Else
 Begin
  SetColor(DarkGray);
  Line(x1, y1, x2-1, y1);     { Haut }
  Line(x1, y1, x1, y2-1);     { Gauche }
  SetColor(White);
  Line(x2, y1, x2, y2);       { Droite }
  Line(x1, y2, x2, y2);       { Bas }
 End;
End;

{ Dessine l'icône Windows 95 (quatre carrés colorés) }
Procedure DrawWindowsIcon(x, y: Integer);
Begin
 { Carré rouge (en haut à gauche) }
 SetFillStyle(SolidFill, Red);
 Bar(x, y, x + 4, y + 4);

 { Carré vert (en haut à droite) }
 SetFillStyle(SolidFill, Green);
 Bar(x + 5, y, x + 9, y + 4);

 { Carré bleu (en bas à gauche) }
 SetFillStyle(SolidFill, Blue);
 Bar(x, y + 5, x + 4, y + 9);

 { Carré jaune (en bas à droite) }
 SetFillStyle(SolidFill, Yellow);
 Bar(x + 5, y + 5, x + 9, y + 9);

 { Bordure noire autour de l'icône }
 SetColor(Black);
 Rectangle(x - 1, y - 1, x + 10, y + 10);
End;

{ Dessine la barre de tâches Windows 95 }
Procedure DrawTaskbar;
Var
 MaxX,MaxY:Integer;
 TimeStr, DateStr: String;
 ClockWidth: Integer;
Begin
 MaxX:=GetMaxX;
 MaxY:=GetMaxY;
  { Fond de la barre de tâches (gris) }
 SetFillStyle(SolidFill, LightGray);
 Bar(0, MaxY - 30, MaxX, MaxY);
  { Bordure supérieure de la barre de tâches }
 SetColor(White);
 Line(0, MaxY - 30, MaxX, MaxY - 30);
  { Dessine le bouton Démarrer }
 SetFillStyle(SolidFill, LightGray);
 Bar(2, MaxY - 28, 90, MaxY - 2);
 Draw3DBorder(2, MaxY - 28, 90, MaxY - 2, True);

 { Icône Windows à gauche }
 DrawWindowsIcon(6, MaxY - 22);

 { Texte "Démarrer" à droite de l'icône }
 SetColor(Black);
 SetTextStyle(DefaultFont, HorizDir, 1);
 OutTextXY(20, MaxY - 20, 'Demarrer');

 { Horloge à droite de la barre de tâches }
 TimeStr := GetCurrentTime;
 DateStr := GetCurrentDate;
 ClockWidth := 95; { Largeur pour afficher MM/DD/YYYY complètement }

 { Zone de l'horloge avec bordure enfoncée }
 SetFillStyle(SolidFill, LightGray);
 Bar(MaxX - ClockWidth, MaxY - 28, MaxX - 2, MaxY - 2);
 Draw3DBorder(MaxX - ClockWidth, MaxY - 28, MaxX - 2, MaxY - 2, False);

 { Affichage de l'heure }
 SetColor(Black);
 SetTextStyle(DefaultFont, HorizDir, 1);
 OutTextXY(MaxX - ClockWidth + 5, MaxY - 23, TimeStr);

 { Affichage de la date (plus petite) }
 OutTextXY(MaxX - ClockWidth + 5, MaxY - 12, DateStr);
End;

{ Dessine le menu Démarrer }
Procedure DrawStartMenu;
Var
 MaxY:Integer;
 MenuItems:Array[1..8] of String;
 i:Integer;
Begin
 MaxY := GetMaxY;
  { Définition des éléments du menu }
 MenuItems[1] := 'Programmes';
 MenuItems[2] := 'Documents';
 MenuItems[3] := 'Parametres';
 MenuItems[4] := 'Rechercher';
 MenuItems[5] := 'Aide';
 MenuItems[6] := 'Executer...';
 MenuItems[7] := '_______________';
 MenuItems[8] := 'Arreter...';
  { Fond du menu }
 SetFillStyle(SolidFill, LightGray);
 Bar(2, MaxY - 220, 180, MaxY - 32);
  { Bordure du menu }
 Draw3DBorder(2, MaxY - 220, 180, MaxY - 32, True);
  { Bande bleue à gauche avec "Windows 95" }
 SetFillStyle(SolidFill, Blue);
 Bar(4, MaxY - 218, 25, MaxY - 34);
 SetColor(White);
 SetTextStyle(DefaultFont, VertDir, 1);
 OutTextXY(20, MaxY - 160, 'Windows 95 - 0');
  { Éléments du menu }
 SetTextStyle(DefaultFont, HorizDir, 1);
 For i:=1 to 8 do Begin
  If MenuItems[i] <> '_______________'Then
  Begin
   { Dessiner la surbrillance si l'élément est survolé }
   If (HighlightedMenuItem = i) and (i <> 7) Then
   Begin
    SetFillStyle(SolidFill, Blue);
    Bar(28, MaxY - 210 + (i-1) * 20, 177, MaxY - 192 + (i-1) * 20);
    SetColor(White);
   End
   Else
    SetColor(Black);

   OutTextXY(30, MaxY - 205 + (i-1) * 20, MenuItems[i]);
  End
  Else
  Begin
   { Ligne de séparation }
   SetColor(DarkGray);
   Line(30, MaxY - 200 + (i-1) * 20, 175, MaxY - 200 + (i-1) * 20);
   SetColor(White);
   Line(30, MaxY - 199 + (i-1) * 20, 175, MaxY - 199 + (i-1) * 20);
  End;
 End;
End;

{ Dessine le bureau Windows 95 }
Procedure DrawDesktop;Begin
  { Fond du bureau (Teal/Turquoise) }
 SetFillStyle(SolidFill, Cyan);
 Bar(0, 0, GetMaxX, GetMaxY - 31);
  { Dessine la barre de tâches }
 DrawTaskbar;
End;

{ Vérifie si la souris est sur le bouton Démarrer }
Function IsMouseOnStartButton(x,y:Integer):Boolean;
Var
 MaxY:Integer;
Begin
 MaxY:=GetMaxY;
 IsMouseOnStartButton := (x >= 2) and (x <= 90) and (y >= MaxY - 28) and (y <= MaxY - 2);
End;

 { Vérifie si la souris est sur une option du menu Démarrer }
Function IsMouseOnMenuItem(x,y:Integer;ItemNumber:Integer):Boolean;
Var
 MaxY: Integer;
Begin
 MaxY:=GetMaxY;
 IsMouseOnMenuItem:=(x >= 30) and (x <= 175) and
                    (y >= MaxY - 210 + (ItemNumber-1) * 20) and
                    (y <= MaxY - 190 + (ItemNumber-1) * 20);
End;

 { Dessine un bouton radio }
Procedure DrawRadioButton(x,y:Integer;Selected:Boolean;Text:String);Begin
  { Cercle du bouton radio }
 SetColor(Black);
 Circle(x + 6, y + 6, 5);
 SetColor(White);
 Circle(x + 6, y + 6, 4);
 SetFillStyle(SolidFill, White);
 FloodFill(x + 6, y + 6, White);
 { Point central si sélectionné }
 If Selected Then Begin
  SetColor(Black);
  SetFillStyle(SolidFill, Black);
  FillEllipse(x + 6, y + 6, 2, 2);
 End;
  { Texte à côté }
 SetColor(Black);
 SetTextStyle(DefaultFont, HorizDir, 1);
 OutTextXY(x + 18, y + 2, Text);
End;

{ Dessine la boîte de dialogue d'arrêt }
Procedure DrawShutdownDialog;
Var
 CenterX,CenterY:Integer;
 DialogX1,DialogY1,DialogX2,DialogY2:Integer;
Begin
 CenterX := GetMaxX div 2;
 CenterY := GetMaxY div 2;
  { Dimensions de la boîte de dialogue }
 DialogX1 := CenterX - 150;
 DialogY1 := CenterY - 80;
 DialogX2 := CenterX + 150;
 DialogY2 := CenterY + 80;
  { Fond de la boîte de dialogue }
 SetFillStyle(SolidFill, LightGray);
 Bar(DialogX1, DialogY1, DialogX2, DialogY2);
  { Bordure 3D }
 Draw3DBorder(DialogX1, DialogY1, DialogX2, DialogY2, True);
  { Barre de titre }
 SetFillStyle(SolidFill, Blue);
 Bar(DialogX1 + 2, DialogY1 + 2, DialogX2 - 2, DialogY1 + 20);
 SetColor(White);
 SetTextStyle(DefaultFont, HorizDir, 1);
 OutTextXY(DialogX1 + 8, DialogY1 + 8, 'Arreter Windows');
  { Icône d'information (simulée par un cercle) }
 SetColor(Blue);
 SetFillStyle(SolidFill, Blue);
 FillEllipse(DialogX1 + 20, DialogY1 + 45, 12, 12);
 SetColor(White);
 OutTextXY(DialogX1 + 17, DialogY1 + 40, 'i');
  { Texte principal }
 SetColor(Black);
 OutTextXY(DialogX1 + 45, DialogY1 + 35, 'Que voulez-vous faire ?');
  { Boutons radio }
 DrawRadioButton(DialogX1 + 45, DialogY1 + 55, SelectedShutdownOption = 1, 'Eteindre l''ordinateur');
 DrawRadioButton(DialogX1 + 45, DialogY1 + 75, SelectedShutdownOption = 2, 'Redemarrer l''ordinateur');
 DrawRadioButton(DialogX1 + 45, DialogY1 + 95, SelectedShutdownOption = 3, 'Quitter Windows 95');
  { Boutons OK et Annuler }
 SetFillStyle(SolidFill, LightGray);
 Bar(DialogX2 - 120, DialogY2 - 35, DialogX2 - 70, DialogY2 - 10);
 Draw3DBorder(DialogX2 - 120, DialogY2 - 35, DialogX2 - 70, DialogY2 - 10, True);
 OutTextXY(DialogX2 - 105, DialogY2 - 28, 'OK');
 Bar(DialogX2 - 60, DialogY2 - 35, DialogX2 - 10, DialogY2 - 10);
 Draw3DBorder(DialogX2 - 60, DialogY2 - 35, DialogX2 - 10, DialogY2 - 10, True);
 OutTextXY(DialogX2 - 45, DialogY2 - 28, 'Annuler');
End;

{ Vérifie si la souris est sur un bouton radio }
Function IsMouseOnRadioButton(x,y:Integer;ButtonNumber:Integer):Boolean;
Var
 CenterX,CenterY:Integer;
 DialogX1,DialogY1:Integer;
Begin
 CenterX := GetMaxX div 2;
 CenterY := GetMaxY div 2;
 DialogX1 := CenterX - 150;
 DialogY1 := CenterY - 80;
 IsMouseOnRadioButton:=(x >= DialogX1 + 45) and (x <= DialogX1 + 250) and
                       (y >= DialogY1 + 55 + (ButtonNumber-1) * 20) and
                       (y <= DialogY1 + 70 + (ButtonNumber-1) * 20);
End;

 { Vérifie si la souris est sur le bouton OK }
Function IsMouseOnOKButton(x,y:Integer):Boolean;
Var
 CenterX,CenterY:Integer;
 DialogX2,DialogY2:Integer;
Begin
 CenterX := GetMaxX div 2;
 CenterY := GetMaxY div 2;
 DialogX2 := CenterX + 150;
 DialogY2 := CenterY + 80;
 IsMouseOnOKButton :=(x >= DialogX2 - 120) and (x <= DialogX2 - 70) and
                     (y >= DialogY2 - 35) and (y <= DialogY2 - 10);
End;

{ Vérifie si la souris est sur le bouton Annuler }
Function IsMouseOnCancelButton(x,y:Integer):Boolean;
Var
 CenterX:Integer;
 CenterY:Integer;
 DialogX2,DialogY2:Integer;
Begin
 CenterX := GetMaxX div 2;
 CenterY := GetMaxY div 2;
 DialogX2 := CenterX + 150;
 DialogY2 := CenterY + 80;
 IsMouseOnCancelButton := (x >= DialogX2 - 60) and (x <= DialogX2 - 10) and
                         (y >= DialogY2 - 35) and (y <= DialogY2 - 10);
End;

{ Dessine la boîte de dialogue Exécuter }
Procedure DrawRunDialog;
Var
 CenterX, CenterY: Integer;
 DialogX1, DialogY1, DialogX2, DialogY2: Integer;
 TextWidth: Integer;
Begin
 CenterX := GetMaxX div 2;
 CenterY := GetMaxY div 2;

 { Dimensions de la boîte de dialogue }
 DialogX1 := CenterX - 200;
 DialogY1 := CenterY - 70;
 DialogX2 := CenterX + 200;
 DialogY2 := CenterY + 70;

 { Fond de la boîte de dialogue }
 SetFillStyle(SolidFill, LightGray);
 Bar(DialogX1, DialogY1, DialogX2, DialogY2);

 { Bordure 3D }
 Draw3DBorder(DialogX1, DialogY1, DialogX2, DialogY2, True);

 { Barre de titre }
 SetFillStyle(SolidFill, Blue);
 Bar(DialogX1 + 2, DialogY1 + 2, DialogX2 - 2, DialogY1 + 20);
 SetColor(White);
 SetTextStyle(DefaultFont, HorizDir, 1);
 OutTextXY(DialogX1 + 8, DialogY1 + 8, 'Executer');

 { Icône (simulée par un rectangle) }
 SetColor(Blue);
 SetFillStyle(SolidFill, Blue);
 Bar(DialogX1 + 15, DialogY1 + 35, DialogX1 + 35, DialogY1 + 55);
 SetColor(White);
 OutTextXY(DialogX1 + 22, DialogY1 + 42, 'R');

 { Texte principal }
 SetColor(Black);
 OutTextXY(DialogX1 + 50, DialogY1 + 30, 'Tapez le nom d''un programme, d''un dossier,');
 OutTextXY(DialogX1 + 50, DialogY1 + 45, 'd''un document ou d''une ressource Internet,');
 OutTextXY(DialogX1 + 50, DialogY1 + 60, 'et Windows l''ouvrira pour vous.');

 { Label "Ouvrir :" }
 OutTextXY(DialogX1 + 15, DialogY1 + 80, 'Ouvrir :');

 { Zone de texte }
 SetFillStyle(SolidFill, White);
 Bar(DialogX1 + 70, DialogY1 + 77, DialogX2 - 15, DialogY1 + 95);
 Draw3DBorder(DialogX1 + 70, DialogY1 + 77, DialogX2 - 15, DialogY1 + 95, False);

 { Texte saisi }
 SetColor(Black);
 OutTextXY(DialogX1 + 75, DialogY1 + 82, RunCommand);

 { Curseur }
 If (GetTickCount div 500) mod 2 = 0 then { Clignotement }
 Begin
  SetColor(Black);
  Line(DialogX1 + 75 + Length(RunCommand) * 8, DialogY1 + 82,
       DialogX1 + 75 + Length(RunCommand) * 8, DialogY1 + 92);
 End;

 { Boutons de la boîte de dialogue }
 SetFillStyle(SolidFill, LightGray);

 { Bouton Parcourir à gauche - plus large }
 Bar(DialogX1 + 15, DialogY2 - 35, DialogX1 + 95, DialogY2 - 15);
 Draw3DBorder(DialogX1 + 15, DialogY2 - 35, DialogX1 + 95, DialogY2 - 15, True);
 OutTextXY(DialogX1 + 20, DialogY2 - 28, 'Parcourir...');

 { Bouton OK décalé vers la gauche }
 Bar(DialogX2 - 140, DialogY2 - 35, DialogX2 - 95, DialogY2 - 15);
 Draw3DBorder(DialogX2 - 140, DialogY2 - 35, DialogX2 - 95, DialogY2 - 15, True);
 OutTextXY(DialogX2 - 120, DialogY2 - 28, 'OK');

 { Bouton Annuler à droite - plus large }
 Bar(DialogX2 - 85, DialogY2 - 35, DialogX2 - 10, DialogY2 - 15);
 Draw3DBorder(DialogX2 - 85, DialogY2 - 35, DialogX2 - 10, DialogY2 - 15, True);
 OutTextXY(DialogX2 - 75, DialogY2 - 28, 'Annuler');
End;

{ Vérifie si la souris est sur le bouton OK de la boîte Exécuter }
Function IsMouseOnRunOKButton(x, y: Integer): Boolean;
Var
 CenterX, CenterY: Integer;
 DialogX2, DialogY2: Integer;
Begin
 CenterX := GetMaxX div 2;
 CenterY := GetMaxY div 2;
 DialogX2 := CenterX + 200;
 DialogY2 := CenterY + 70;

 IsMouseOnRunOKButton := (x >= DialogX2 - 140) and (x <= DialogX2 - 95) and
                        (y >= DialogY2 - 35) and (y <= DialogY2 - 15);
End;

{ Vérifie si la souris est sur le bouton Annuler de la boîte Exécuter }
Function IsMouseOnRunCancelButton(x, y: Integer): Boolean;
Var
 CenterX, CenterY: Integer;
 DialogX2, DialogY2: Integer;
Begin
 CenterX := GetMaxX div 2;
 CenterY := GetMaxY div 2;
 DialogX2 := CenterX + 200;
 DialogY2 := CenterY + 60;

 IsMouseOnRunCancelButton := (x >= DialogX2 - 60) and (x <= DialogX2 - 10) and
                            (y >= DialogY2 - 30) and (y <= DialogY2 - 10);
End;

{ Vérifie si la souris est sur le bouton Parcourir de la boîte Exécuter }
Function IsMouseOnRunBrowseButton(x, y: Integer): Boolean;
Var
 CenterX, CenterY: Integer;
 DialogX1, DialogY2: Integer;
Begin
 CenterX := GetMaxX div 2;
 CenterY := GetMaxY div 2;
 DialogX1 := CenterX - 200;
 DialogY2 := CenterY + 70;

 IsMouseOnRunBrowseButton := (x >= DialogX1 + 15) and (x <= DialogX1 + 95) and
                            (y >= DialogY2 - 35) and (y <= DialogY2 - 15);
End;

{ Vérifie si la souris est sur l'onglet Date et heure }
Function IsMouseOnDateTab(x, y: Integer): Boolean;
Var
 CenterX, CenterY: Integer;
 DialogX1, DialogY1: Integer;
Begin
 CenterX := GetMaxX div 2;
 CenterY := GetMaxY div 2;
 DialogX1 := CenterX - 200;
 DialogY1 := CenterY - 150;
 
 IsMouseOnDateTab := (x >= DialogX1 + 5) and (x <= DialogX1 + 120) and
                     (y >= DialogY1 + 25) and (y <= DialogY1 + 45);
End;

{ Vérifie si la souris est sur l'onglet Fuseau horaire }
Function IsMouseOnTimezoneTab(x, y: Integer): Boolean;
Var
 CenterX, CenterY: Integer;
 DialogX1, DialogY1: Integer;
Begin
 CenterX := GetMaxX div 2;
 CenterY := GetMaxY div 2;
 DialogX1 := CenterX - 200;
 DialogY1 := CenterY - 150;
 
 IsMouseOnTimezoneTab := (x >= DialogX1 + 125) and (x <= DialogX1 + 250) and
                        (y >= DialogY1 + 25) and (y <= DialogY1 + 45);
End;

{ Vérifie si la souris est sur le bouton X de fermeture }
Function IsMouseOnDateTimeCloseButton(x, y: Integer): Boolean;
Var
 CenterX, CenterY: Integer;
 DialogX2, DialogY1: Integer;
Begin
 CenterX := GetMaxX div 2;
 CenterY := GetMaxY div 2;
 DialogX2 := CenterX + 200;
 DialogY1 := CenterY - 150;
 
 IsMouseOnDateTimeCloseButton := (x >= DialogX2 - 22) and (x <= DialogX2 - 4) and
                                (y >= DialogY1 + 4) and (y <= DialogY1 + 18);
End;

{ Vérifie si la souris est sur le bouton OK de la boîte Date/Heure }
Function IsMouseOnDateTimeOKButton(x, y: Integer): Boolean;
Var
 CenterX, CenterY: Integer;
 DialogX2, DialogY2: Integer;
Begin
 CenterX := GetMaxX div 2;
 CenterY := GetMaxY div 2;
 DialogX2 := CenterX + 200;
 DialogY2 := CenterY + 150;
 
 IsMouseOnDateTimeOKButton := (x >= DialogX2 - 250) and (x <= DialogX2 - 200) and
                             (y >= DialogY2 - 35) and (y <= DialogY2 - 15);
End;

{ Vérifie si la souris est sur le bouton Annuler de la boîte Date/Heure }
Function IsMouseOnDateTimeCancelButton(x, y: Integer): Boolean;
Var
 CenterX, CenterY: Integer;
 DialogX2, DialogY2: Integer;
Begin
 CenterX := GetMaxX div 2;
 CenterY := GetMaxY div 2;
 DialogX2 := CenterX + 200;
 DialogY2 := CenterY + 150;
 
 IsMouseOnDateTimeCancelButton := (x >= DialogX2 - 190) and (x <= DialogX2 - 110) and
                                 (y >= DialogY2 - 35) and (y <= DialogY2 - 15);
End;

{ Vérifie si la souris est sur le bouton Appliquer de la boîte Date/Heure }
Function IsMouseOnDateTimeApplyButton(x, y: Integer): Boolean;
Var
 CenterX, CenterY: Integer;
 DialogX2, DialogY2: Integer;
Begin
 CenterX := GetMaxX div 2;
 CenterY := GetMaxY div 2;
 DialogX2 := CenterX + 200;
 DialogY2 := CenterY + 150;
 
 IsMouseOnDateTimeApplyButton := (x >= DialogX2 - 105) and (x <= DialogX2 - 5) and
                                (y >= DialogY2 - 35) and (y <= DialogY2 - 15);
End;

{ Vérifie si la souris est sur l'horloge de la barre de tâches }
Function IsMouseOnClock(x, y: Integer): Boolean;
Var
 MaxX, MaxY, ClockWidth: Integer;
Begin
 MaxX := GetMaxX;
 MaxY := GetMaxY;
 ClockWidth := 95;
 
 IsMouseOnClock := (x >= MaxX - ClockWidth) and (x <= MaxX - 2) and
                   (y >= MaxY - 28) and (y <= MaxY - 2);
End;

{ Dessine l'horloge analogique }
Procedure DrawAnalogClock(CenterX, CenterY, Radius: Integer; H, M, S: Integer);
Var
 HourAngle, MinuteAngle, SecondAngle: Real;
 HourX, HourY, MinuteX, MinuteY, SecondX, SecondY: Integer;
Begin
 { Cercle de l'horloge }
 SetColor(Black);
 Circle(CenterX, CenterY, Radius);
 SetFillStyle(SolidFill, White);
 FloodFill(CenterX, CenterY, Black);
 
 { Marques des heures }
 SetColor(Black);
 OutTextXY(CenterX - 3, CenterY - Radius + 5, '12');
 OutTextXY(CenterX + Radius - 8, CenterY - 5, '3');
 OutTextXY(CenterX - 3, CenterY + Radius - 15, '6');
 OutTextXY(CenterX - Radius + 5, CenterY - 5, '9');
 
 { Calcul des angles (en radians) }
 HourAngle := (H mod 12 + M / 60.0) * Pi / 6.0 - Pi / 2.0;
 MinuteAngle := M * Pi / 30.0 - Pi / 2.0;
 SecondAngle := S * Pi / 30.0 - Pi / 2.0;
 
 { Aiguille des heures }
 HourX := CenterX + Round(Cos(HourAngle) * (Radius - 20));
 HourY := CenterY + Round(Sin(HourAngle) * (Radius - 20));
 SetColor(Black);
 Line(CenterX, CenterY, HourX, HourY);
 Line(CenterX + 1, CenterY, HourX + 1, HourY);
 
 { Aiguille des minutes }
 MinuteX := CenterX + Round(Cos(MinuteAngle) * (Radius - 10));
 MinuteY := CenterY + Round(Sin(MinuteAngle) * (Radius - 10));
 Line(CenterX, CenterY, MinuteX, MinuteY);
 
 { Aiguille des secondes }
 SecondX := CenterX + Round(Cos(SecondAngle) * (Radius - 5));
 SecondY := CenterY + Round(Sin(SecondAngle) * (Radius - 5));
 SetColor(Red);
 Line(CenterX, CenterY, SecondX, SecondY);
 
 { Centre de l'horloge }
 SetColor(Black);
 SetFillStyle(SolidFill, Black);
 FillEllipse(CenterX, CenterY, 3, 3);
End;

{ Dessine le calendrier }
Procedure DrawCalendar(x, y: Integer; Year, Month, Day: Integer);
Var
 i, j, FirstDay, DaysInMonth, CurrentDay: Integer;
 MonthNames: Array[1..12] of String;
Begin
 MonthNames[1] := 'Janvier'; MonthNames[2] := 'Fevrier'; MonthNames[3] := 'Mars';
 MonthNames[4] := 'Avril'; MonthNames[5] := 'Mai'; MonthNames[6] := 'Juin';
 MonthNames[7] := 'Juillet'; MonthNames[8] := 'Aout'; MonthNames[9] := 'Septembre';
 MonthNames[10] := 'Octobre'; MonthNames[11] := 'Novembre'; MonthNames[12] := 'Decembre';
 
 { Fond du calendrier }
 SetFillStyle(SolidFill, White);
 Bar(x, y, x + 200, y + 150);
 Draw3DBorder(x, y, x + 200, y + 150, False);
 
 { En-tête du mois }
 SetColor(Black);
 SetTextStyle(DefaultFont, HorizDir, 1);
 OutTextXY(x + 10, y + 10, MonthNames[Month] + ' ' + IntToStr(Year));
 
 { Jours de la semaine }
 OutTextXY(x + 10, y + 30, 'D  L  M  M  J  V  S');
 
 { Calcul du premier jour du mois (simulation simple) }
 FirstDay := ((Year - 1900) * 365 + Month * 30 + Day) mod 7;
 
 { Calcul du nombre de jours dans le mois }
 Case Month of
  2: If Year mod 4 = 0 Then DaysInMonth := 29 Else DaysInMonth := 28;
  4, 6, 9, 11: DaysInMonth := 30;
  Else DaysInMonth := 31;
 End;
 
 { Affichage des jours }
 CurrentDay := 1;
 For i := 0 to 5 do
  For j := 0 to 6 do
  Begin
   If (i = 0) and (j < FirstDay) Then
    { Jours vides au début }
   Else If CurrentDay <= DaysInMonth Then
   Begin
    If CurrentDay = Day Then
    Begin
     { Jour sélectionné }
     SetFillStyle(SolidFill, Blue);
     Bar(x + 10 + j * 25, y + 50 + i * 15, x + 30 + j * 25, y + 65 + i * 15);
     SetColor(White);
    End
    Else
     SetColor(Black);
    
    OutTextXY(x + 15 + j * 25, y + 52 + i * 15, IntToStr(CurrentDay));
    Inc(CurrentDay);
   End;
  End;
End;

{ Dessine un spinner pour les heures/minutes/secondes }
Procedure DrawTimeSpinner(x, y: Integer; Value: Integer; MaxValue: Integer; Selected: Boolean);
Begin
 { Fond }
 SetFillStyle(SolidFill, White);
 Bar(x, y, x + 40, y + 20);
 
 If Selected Then
 Begin
  SetColor(Blue);
  SetFillStyle(SolidFill, Blue);
  Bar(x + 1, y + 1, x + 39, y + 19);
  SetColor(White);
 End
 Else
 Begin
  SetColor(Black);
  Draw3DBorder(x, y, x + 40, y + 20, False);
 End;
 
 { Valeur }
 If Value < 10 Then
  OutTextXY(x + 8, y + 6, '0' + IntToStr(Value))
 Else
  OutTextXY(x + 8, y + 6, IntToStr(Value));
 
 { Boutons + et - }
 SetColor(Black);
 SetFillStyle(SolidFill, LightGray);
 Bar(x + 42, y, x + 52, y + 9);
 Bar(x + 42, y + 11, x + 52, y + 20);
 Draw3DBorder(x + 42, y, x + 52, y + 9, True);
 Draw3DBorder(x + 42, y + 11, x + 52, y + 20, True);
 
 { Symboles + et - }
 SetColor(Black);
 Line(x + 45, y + 4, x + 49, y + 4);
 Line(x + 47, y + 2, x + 47, y + 6);
 Line(x + 45, y + 15, x + 49, y + 15);
End;

{ Dessine les onglets de la boîte Date/Heure }
Procedure DrawDateTimeTabs(x, y: Integer; CurrentTab: Integer);
Begin
 { Onglet Date et heure }
 If CurrentTab = 1 Then
 Begin
  SetFillStyle(SolidFill, LightGray);
  Bar(x + 5, y + 25, x + 120, y + 45);
  SetColor(Black);
  OutTextXY(x + 15, y + 32, 'Date et heure');
  Draw3DBorder(x + 5, y + 25, x + 120, y + 45, True);
 End
 Else
 Begin
  SetFillStyle(SolidFill, DarkGray);
  Bar(x + 5, y + 27, x + 120, y + 45);
  SetColor(Black);
  OutTextXY(x + 15, y + 34, 'Date et heure');
  Draw3DBorder(x + 5, y + 27, x + 120, y + 45, False);
 End;
 
 { Onglet Fuseau horaire }
 If CurrentTab = 2 Then
 Begin
  SetFillStyle(SolidFill, LightGray);
  Bar(x + 125, y + 25, x + 250, y + 45);
  SetColor(Black);
  OutTextXY(x + 135, y + 32, 'Fuseau horaire');
  Draw3DBorder(x + 125, y + 25, x + 250, y + 45, True);
 End
 Else
 Begin
  SetFillStyle(SolidFill, DarkGray);
  Bar(x + 125, y + 27, x + 250, y + 45);
  SetColor(Black);
  OutTextXY(x + 135, y + 34, 'Fuseau horaire');
  Draw3DBorder(x + 125, y + 27, x + 250, y + 45, False);
 End;
End;

{ Procédure principale pour dessiner la boîte de dialogue Date/Heure }
Procedure DrawDateTimeDialog;
Var
 CenterX, CenterY: Integer;
 DialogX1, DialogY1, DialogX2, DialogY2: Integer;
 H, M, S: Word;
 Year, Month, Day, DayOfWeek: Word;
Begin
 CenterX := GetMaxX div 2;
 CenterY := GetMaxY div 2;
 
 { Dimensions de la boîte de dialogue }
 DialogX1 := CenterX - 200;
 DialogY1 := CenterY - 150;
 DialogX2 := CenterX + 200;
 DialogY2 := CenterY + 150;
 
 { Fond de la boîte de dialogue }
 SetFillStyle(SolidFill, LightGray);
 Bar(DialogX1, DialogY1, DialogX2, DialogY2);
 
 { Bordure 3D }
 Draw3DBorder(DialogX1, DialogY1, DialogX2, DialogY2, True);
 
 { Barre de titre }
 SetFillStyle(SolidFill, Blue);
 Bar(DialogX1 + 2, DialogY1 + 2, DialogX2 - 2, DialogY1 + 22);
 SetColor(White);
 SetTextStyle(DefaultFont, HorizDir, 1);
 OutTextXY(DialogX1 + 8, DialogY1 + 8, 'Proprietes Date/Heure');
 
 { Bouton X de fermeture }
 SetFillStyle(SolidFill, LightGray);
 Bar(DialogX2 - 22, DialogY1 + 4, DialogX2 - 4, DialogY1 + 18);
 Draw3DBorder(DialogX2 - 22, DialogY1 + 4, DialogX2 - 4, DialogY1 + 18, True);
 SetColor(Black);
 OutTextXY(DialogX2 - 17, DialogY1 + 8, 'X');
 
 { Bouton ? d'aide }
 SetFillStyle(SolidFill, LightGray);
 Bar(DialogX2 - 42, DialogY1 + 4, DialogX2 - 24, DialogY1 + 18);
 Draw3DBorder(DialogX2 - 42, DialogY1 + 4, DialogX2 - 24, DialogY1 + 18, True);
 SetColor(Black);
 OutTextXY(DialogX2 - 37, DialogY1 + 8, '?');
 
 { Dessiner les onglets }
 DrawDateTimeTabs(DialogX1, DialogY1, CurrentTab);
 
 { Contenu selon l'onglet sélectionné }
 GetTime(H, M, S, DayOfWeek);
 GetDate(Year, Month, Day, DayOfWeek);
 
 If CurrentTab = 1 Then
 Begin
  { Onglet Date et heure }
  
  { Calendrier }
  DrawCalendar(DialogX1 + 15, DialogY1 + 60, Year, Month, Day);
  
  { Horloge analogique }
  DrawAnalogClock(DialogX1 + 280, DialogY1 + 120, 45, H, M, S);
  
  { Réglages de l'heure }
  SetColor(Black);
  OutTextXY(DialogX1 + 230, DialogY1 + 190, 'Heure:');
  DrawTimeSpinner(DialogX1 + 230, DialogY1 + 205, H, 23, False);
  
  OutTextXY(DialogX1 + 285, DialogY1 + 190, 'Min:');
  DrawTimeSpinner(DialogX1 + 285, DialogY1 + 205, M, 59, False);
  
  OutTextXY(DialogX1 + 335, DialogY1 + 190, 'Sec:');
  DrawTimeSpinner(DialogX1 + 335, DialogY1 + 205, S, 59, False);
 End
 Else
 Begin
  { Onglet Fuseau horaire }
  SetColor(Black);
  OutTextXY(DialogX1 + 15, DialogY1 + 60, 'Fuseau horaire :');
  
  { Zone de liste déroulante simulée }
  SetFillStyle(SolidFill, White);
  Bar(DialogX1 + 15, DialogY1 + 80, DialogX1 + 350, DialogY1 + 100);
  Draw3DBorder(DialogX1 + 15, DialogY1 + 80, DialogX1 + 350, DialogY1 + 100, False);
  SetColor(Black);
  OutTextXY(DialogX1 + 20, DialogY1 + 85, '(GMT+01:00) Paris, Madrid, Rome');
  
  { Carte du monde simulée }
  SetFillStyle(SolidFill, Blue);
  Bar(DialogX1 + 15, DialogY1 + 120, DialogX1 + 350, DialogY1 + 200);
  SetColor(Yellow);
  OutTextXY(DialogX1 + 170, DialogY1 + 155, 'EUROPE');
 End;
 
 { Boutons }
 SetFillStyle(SolidFill, LightGray);
 
 { Bouton OK - décalé de 30px supplémentaires vers la gauche }
 Bar(DialogX2 - 250, DialogY2 - 35, DialogX2 - 200, DialogY2 - 15);
 Draw3DBorder(DialogX2 - 250, DialogY2 - 35, DialogX2 - 200, DialogY2 - 15, True);
 SetColor(Black);
 OutTextXY(DialogX2 - 235, DialogY2 - 28, 'OK');
 
 { Bouton Annuler - décalé de 30px supplémentaires vers la gauche }
 Bar(DialogX2 - 190, DialogY2 - 35, DialogX2 - 110, DialogY2 - 15);
 Draw3DBorder(DialogX2 - 190, DialogY2 - 35, DialogX2 - 110, DialogY2 - 15, True);
 SetColor(Black);
 OutTextXY(DialogX2 - 170, DialogY2 - 28, 'Annuler');
 
 { Bouton Appliquer - texte décalé de 5px vers la gauche }
 Bar(DialogX2 - 105, DialogY2 - 35, DialogX2 - 5, DialogY2 - 15);
 Draw3DBorder(DialogX2 - 105, DialogY2 - 35, DialogX2 - 5, DialogY2 - 15, True);
 SetColor(Black);
 OutTextXY(DialogX2 - 80, DialogY2 - 28, 'Appliquer');
End;

{ Exécute la commande saisie }
Procedure ExecuteRunCommand;
Var
 Command:String;
Begin
 Command := RunCommand;
 If Command<>''Then Begin
  SetColor(White);
  SetTextStyle(DefaultFont, HorizDir, 2);
  OutTextXY(100, 200, 'Execution de : ' + Command);
  { Tentative d'exécution de la commande }
  {$IFDEF FPC}
   { Sous Free Pascal, on peut utiliser les fonctions système }
   Exec(GetEnv('COMSPEC'), '/C '+Command);
  {$ELSE}
   { Sous Turbo Pascal }
   Exec(GetEnv('COMSPEC'), '/C '+Command);
  {$ENDIF}
 End;
End;

{ Exécute l'action sélectionnée dans la boîte d'arrêt }
Procedure ExecuteShutdownAction;Begin
 Case SelectedShutdownOption of
  1:Begin
   SetColor(White);
   SetTextStyle(DefaultFont, HorizDir, 2);
   OutTextXY(100, 200, 'Extinction de l''ordinateur...');
   {$IFNDEF FPC}
    SetAPMMode(3);
   {$ELSE}
    Delay(2000);
    Halt(0);
   {$ENDIF}
  End;
  2:Begin
   SetColor(White);
   SetTextStyle(DefaultFont, HorizDir, 2);
   OutTextXY(100, 200, 'Redemarrage de l''ordinateur...');
   {$IFNDEF FPC}
    MemW[Seg0040:$72]:=$1234;
    ASM
     INT 19h
    END;
   {$ELSE}
    Halt(0);
   {$ENDIF}
  End;
  3:Begin
   SetColor(White);
   SetTextStyle(DefaultFont, HorizDir, 2);
   OutTextXY(100, 200, 'Fermeture de Windows 95...');
   Delay(2000);
   Halt(0);
  End;
 End;
End;

{ Gère la saisie de texte dans la boîte Exécuter }
Procedure HandleRunDialogKeyboard(Key:Char);Begin
 Case Key of
  #8: Begin { Backspace }
   If Length(RunCommand)>0 Then Begin
    Delete(RunCommand, Length(RunCommand), 1);
    DrawRunDialog;
   End;
  End;
  #13: Begin { Entrée }
   ExecuteRunCommand;
   RunDialogVisible := False;
   DrawDesktop;
  End;
  #27:Begin { Échap }
   RunDialogVisible := False;
   DrawDesktop;
  End;
  #32..#126: Begin { Caractères imprimables }
   If Length(RunCommand)<50 Then Begin
    RunCommand:=RunCommand+Key;
    DrawRunDialog;
   End;
  End;
 End;
End;

{ Détermine quel élément du menu est survolé par la souris }
Function GetHoveredMenuItem(x,y:Integer):Integer;
Var
 MaxY:Integer;
 i:Integer;
Begin
 MaxY:=GetMaxY;
 GetHoveredMenuItem:=0; { Par défaut, aucun élément }
 For i:=1 to 8 do Begin
  If(i <> 7)and { Ignorer la ligne de séparation }
    (x >= 28) and (x <= 177)and
    (y >= MaxY - 210 + (i-1) * 20) and
    (y <= MaxY - 192 + (i-1) * 20)Then Begin
   GetHoveredMenuItem := i;
   Break;
  End;
 End;
End;

{ Gestionnaire d'événements souris }
Procedure HandleMouse;
Var
 MouseButton: LongInt;
 MousePressed: Boolean;
 i: Integer;
 NewHighlightedItem: Integer;
Begin
 GetMouseState(MouseX, MouseY, MouseButton);
 MousePressed:=(MouseButton and 1)<>0; { Bouton gauche pressé }

 { Gestion de la surbrillance du menu }
 If MenuVisible and not ShutdownDialogVisible and not RunDialogVisible Then
 Begin
  NewHighlightedItem := GetHoveredMenuItem(MouseX, MouseY);
  If NewHighlightedItem <> HighlightedMenuItem Then
  Begin
   HighlightedMenuItem := NewHighlightedItem;
   DrawStartMenu; { Redessiner le menu avec la nouvelle surbrillance }
  End;
 End
 Else
 Begin
  If HighlightedMenuItem <> 0 Then
  Begin
   HighlightedMenuItem := 0;
   If MenuVisible Then DrawStartMenu;
  End;
 End;

 If(MousePressed)Then Begin
  If DateTimeDialogVisible Then Begin
   { Gestion des clics dans la boîte de dialogue Date/Heure }
   If IsMouseOnDateTab(MouseX, MouseY) Then Begin
    CurrentTab := 1;
    DrawDateTimeDialog;
   End
   Else If IsMouseOnTimezoneTab(MouseX, MouseY) Then Begin
    CurrentTab := 2;
    DrawDateTimeDialog;
   End
   Else If IsMouseOnDateTimeCloseButton(MouseX, MouseY) Then Begin
    DateTimeDialogVisible := False;
    DrawDesktop;
    If MenuVisible Then DrawStartMenu;
   End
   Else If IsMouseOnDateTimeOKButton(MouseX, MouseY) Then Begin
    { Appliquer les changements et fermer }
    DateTimeDialogVisible := False;
    DrawDesktop;
    If MenuVisible Then DrawStartMenu;
   End
   Else If IsMouseOnDateTimeCancelButton(MouseX, MouseY) Then Begin
    DateTimeDialogVisible := False;
    DrawDesktop;
    If MenuVisible Then DrawStartMenu;
   End
   Else If IsMouseOnDateTimeApplyButton(MouseX, MouseY) Then Begin
    { Appliquer les changements sans fermer }
    { TODO: Implémenter l'application des changements }
   End;

   { Attendre que le bouton soit relâché }
   Repeat
    GetMouseState(MouseX, MouseY, MouseButton);
   Until (MouseButton and 1) = 0;
  End
  Else If RunDialogVisible Then Begin
   { Gestion des clics dans la boîte de dialogue Exécuter }
   If IsMouseOnRunOKButton(MouseX, MouseY) Then Begin
    ExecuteRunCommand;
    RunDialogVisible := False;
    DrawDesktop;
   End
   Else If IsMouseOnRunCancelButton(MouseX, MouseY) Then Begin
    RunDialogVisible := False;
    DrawDesktop;
   End
   Else If IsMouseOnRunBrowseButton(MouseX, MouseY) Then Begin
    { TODO: Ouvrir le sélecteur de fichiers }
   End;

   { Attendre que le bouton soit relâché }
   Repeat
    GetMouseState(MouseX, MouseY, MouseButton);
   Until (MouseButton and 1) = 0;
  End
  Else If ShutdownDialogVisible Then Begin
   { Gestion des clics dans la boîte de dialogue d'arrêt }
   For i:=1 to 3 do Begin
    If IsMouseOnRadioButton(MouseX,MouseY,i)Then Begin
     SelectedShutdownOption := i;
     DrawShutdownDialog;
    End;
   End;
   If IsMouseOnOKButton(MouseX, MouseY)Then Begin
    ExecuteShutdownAction;
   End
    Else
   If IsMouseOnCancelButton(MouseX,MouseY)Then Begin
    ShutdownDialogVisible := False;
    HighlightedMenuItem := 0;
    DrawDesktop;
    If(MenuVisible)Then DrawStartMenu;
   End;
    { Attendre que le bouton soit relâché }
   Repeat
    GetMouseState(MouseX,MouseY,MouseButton);
   Until(MouseButton and 1)=0;
  End
   Else
  If(MenuVisible)Then Begin
   { Vérifier les clics sur les éléments du menu }
   If IsMouseOnMenuItem(MouseX, MouseY, 6) Then Begin { Exécuter... }
    MenuVisible := False;
    HighlightedMenuItem := 0;
    RunDialogVisible := True;
    RunCommand := '';
    DrawDesktop;
    DrawRunDialog;
   End
   Else If IsMouseOnMenuItem(MouseX, MouseY,8)Then Begin { Arrêter... }
    MenuVisible := False;
    HighlightedMenuItem := 0;
    ShutdownDialogVisible := True;
    SelectedShutdownOption := 1; { Par défaut: Eteindre }
    DrawDesktop;
    DrawShutdownDialog;
   End
    Else
   Begin
    { Fermer le menu si clic ailleurs }
    MenuVisible := False;
    HighlightedMenuItem := 0;
    DrawDesktop;
   End;
    { Attendre que le bouton soit relâché }
   Repeat
    GetMouseState(MouseX,MouseY,MouseButton);
   Until (MouseButton and 1)=0;
  End
   Else
  If IsMouseOnStartButton(MouseX, MouseY)Then Begin
   MenuVisible:=Not MenuVisible;
   HighlightedMenuItem := 0;
   DrawDesktop;
   If MenuVisible Then DrawStartMenu;
   { Attendre que le bouton soit relâché }
   Repeat
    GetMouseState(MouseX,MouseY,MouseButton);
   Until(MouseButton and 1)=0;
  End
  Else If IsMouseOnClock(MouseX, MouseY) Then Begin
   { Ouvrir la boîte de dialogue Date/Heure }
   DateTimeDialogVisible := True;
   CurrentTab := 1; { Commencer sur l'onglet Date et heure }
   MenuVisible := False;
   HighlightedMenuItem := 0;

   { Initialiser avec l'heure actuelle }
   GetTime(SelectedHour, SelectedMin, SelectedSec, CurrentSec100);
   GetDate(SelectedYear, SelectedMonth, SelectedDay, DayOfWeek);
   TimeZone := '(GMT-05:00) Heure de l''Est (Canada et États-Unis)';

   DrawDesktop;
   DrawDateTimeDialog;

   { Attendre que le bouton soit relâché }
   Repeat
    GetMouseState(MouseX, MouseY, MouseButton);
   Until (MouseButton and 1) = 0;
  End;
 End;
End;

{ Met à jour l'affichage de l'horloge }
Procedure UpdateClock;Begin
 { Redessiner seulement la zone de l'horloge }
 DrawTaskbar;
End;

{ Boucle principale }
Procedure MainLoop;
Var
 Key:Char;
 LastMinute: Word;
 CurrentHour, CurrentMin, CurrentSec, CurrentSec100: Word;
Begin
 MenuVisible:=False;
 ShutdownDialogVisible:=False;
 RunDialogVisible:=False;
 SelectedShutdownOption:=1;
 HighlightedMenuItem:=0;
 RunCommand:='';
 DateTimeDialogVisible:=False;
 CurrentTab:=1;
  { Initialiser la dernière minute pour la mise à jour de l'horloge }
 GetTime(CurrentHour, CurrentMin, CurrentSec, CurrentSec100);
 LastMinute := CurrentMin;
 DrawDesktop;
 Repeat
  HandleMouse;
   { Mise à jour de l'horloge chaque minute }
  GetTime(CurrentHour, CurrentMin, CurrentSec, CurrentSec100);
  If CurrentMin <> LastMinute Then
  Begin
   LastMinute := CurrentMin;
   If not ShutdownDialogVisible and not RunDialogVisible Then
    UpdateClock;
  End;
  If(KeyPressed)Then Begin
   Key:=ReadKey;
   { Si la boîte Exécuter est ouverte, gérer la saisie }
   If(RunDialogVisible)Then Begin
    HandleRunDialogKeyboard(Key);
   End
    Else
   Begin
    { Gestion des touches normales }
    Case Key of
     ' ':Begin { Barre d'espace pour afficher/masquer le menu }
      If Not ShutdownDialogVisible Then Begin
       MenuVisible:=Not MenuVisible;
       HighlightedMenuItem:=0;
       DrawDesktop;
       If(MenuVisible)Then DrawStartMenu;
      End;
     End;
     'r','R':Begin { Touche R pour Exécuter }
      If MenuVisible and not ShutdownDialogVisible then
      Begin
       MenuVisible := False;
       RunDialogVisible := True;
       RunCommand := '';
       HighlightedMenuItem := 0;
       DrawDesktop;
       DrawRunDialog;
      End;
     End;
     'a','A':Begin { Touche A pour ouvrir Arrêter }
      If(MenuVisible and not ShutdownDialogVisible)Then Begin
       MenuVisible:=False;
       ShutdownDialogVisible:=True;
       SelectedShutdownOption:=1;
       HighlightedMenuItem:=0;
       DrawDesktop;
       DrawShutdownDialog;
      End;
     End;
     '1': Begin { Sélectionner option 1 }
      If ShutdownDialogVisible Then Begin
       SelectedShutdownOption:=1;
       DrawShutdownDialog;
      End;
     End;
     '2': Begin { Sélectionner option 2 }
      If ShutdownDialogVisible Then Begin
       SelectedShutdownOption:=2;
       DrawShutdownDialog;
      End;
     End;
     '3': Begin { Sélectionner option 3 }
      If ShutdownDialogVisible Then Begin
       SelectedShutdownOption:=3;
       DrawShutdownDialog;
      End;
     End;
     #13: Begin { Entrée pour valider }
      If(ShutdownDialogVisible)Then ExecuteShutdownAction;
     End;
     #27: Begin { ESC }
      If(ShutdownDialogVisible)Then Begin
       ShutdownDialogVisible:=False;
       DrawDesktop;
       If(MenuVisible)Then DrawStartMenu;
      End
       Else
      If RunDialogVisible Then Begin
       RunDialogVisible := False;
       DrawDesktop;
      End
      Else
       Key := 'q'; { Quitter si pas de dialogue ouvert }
     End;
    End;
   End;
  End;
 Until Key = 'q';
End;

BEGIN
 InitScr;
 {$IFDEF FPC}
  InitMouse;
 {$ENDIF}
 MainLoop;
 {$IFDEF FPC}
  {DoneMouse;}
 {$ENDIF}
 CloseGraph;
END.
