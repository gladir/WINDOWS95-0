{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/windows95-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program WIN;

Uses {$IFDEF FPC}
      Windows,PtcMouse,PtcCrt,PtcGraph
     {$ELSE}
      DOS,Crt,Graph
     {$ENDIF};

Var
 MenuVisible:Boolean;
 MouseX,MouseY:LongInt;
 ShutdownDialogVisible:Boolean;
 SelectedShutdownOption:Integer; { 1=Eteindre, 2=Redemarrer, 3=Quitter }

{$IFNDEF FPC}
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

{ Dessine la barre de tâches Windows 95 }
Procedure DrawTaskbar;
Var
 MaxX,MaxY:Integer;
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
 Bar(2, MaxY - 28, 60, MaxY - 2);
 Draw3DBorder(2, MaxY - 28, 80, MaxY - 2, True);
  { Texte "Démarrer" }
 SetColor(Black);
 SetTextStyle(DefaultFont, HorizDir, 1);
 OutTextXY(8, MaxY - 20, 'Demarrer');
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
 SetColor(Black);
 SetTextStyle(DefaultFont, HorizDir, 1);
 For i:=1 to 8 do Begin
  If MenuItems[i] <> '_______________'Then
   OutTextXY(30, MaxY - 205 + (i-1) * 20, MenuItems[i])
  Else
  Begin
   { Ligne de séparation }
   SetColor(DarkGray);
   Line(30, MaxY - 200 + (i-1) * 20, 175, MaxY - 200 + (i-1) * 20);
   SetColor(White);
   Line(30, MaxY - 199 + (i-1) * 20, 175, MaxY - 199 + (i-1) * 20);
   SetColor(Black);
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
 IsMouseOnStartButton := (x >= 2) and (x <= 60) and (y >= MaxY - 28) and (y <= MaxY - 2);
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
 CenterX, CenterY: Integer;
 DialogX2, DialogY2: Integer;
Begin
 CenterX := GetMaxX div 2;
 CenterY := GetMaxY div 2;
 DialogX2 := CenterX + 150;
 DialogY2 := CenterY + 80;
 IsMouseOnCancelButton := (x >= DialogX2 - 60) and (x <= DialogX2 - 10) and
                         (y >= DialogY2 - 35) and (y <= DialogY2 - 10);
End;

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
   { Demande la mode sp�cifier }
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
{$ENDIF}

 { Exécute l'action sélectionnée }
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
   Delay(2000);
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

{ Gestionnaire d'événements souris }
Procedure HandleMouse;
Var
 MouseButton: LongInt;
 MousePressed: Boolean;
 i: Integer;
Begin
 GetMouseState(MouseX, MouseY, MouseButton);
 MousePressed:=(MouseButton and 1)<>0; { Bouton gauche pressé }
 If(MousePressed)Then Begin
  If ShutdownDialogVisible Then Begin
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
   If IsMouseOnMenuItem(MouseX, MouseY,8)Then Begin { Arrêter... }
    MenuVisible := False;
    ShutdownDialogVisible := True;
    SelectedShutdownOption := 1; { Par défaut: Eteindre }
    DrawDesktop;
    DrawShutdownDialog;
   End
    Else
   Begin
    { Fermer le menu si clic ailleurs }
    MenuVisible := False;
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
   DrawDesktop;
   If MenuVisible Then DrawStartMenu;
   { Attendre que le bouton soit relâché }
   Repeat
    GetMouseState(MouseX,MouseY,MouseButton);
   Until(MouseButton and 1)=0;
  End;
 End;
End;

 { Boucle principale }
Procedure MainLoop;
Var
 Key:Char;
Begin
 MenuVisible:=False;
 ShutdownDialogVisible:=False;
 SelectedShutdownOption:=1;
 DrawDesktop;
 Repeat
  HandleMouse;
  If(KeyPressed)then Key:=ReadKey;
   { Gestion des touches }
  Case Key of
   ' ':Begin { Barre d'espace pour afficher/masquer le menu }
    If Not ShutdownDialogVisible Then Begin
     MenuVisible:=Not MenuVisible;
     DrawDesktop;
     If(MenuVisible)Then DrawStartMenu;
    End;
   End;
   'a','A':Begin { Touche A pour ouvrir Arrêter }
    If(MenuVisible and not ShutdownDialogVisible)Then Begin
     MenuVisible:=False;
     ShutdownDialogVisible:=True;
     SelectedShutdownOption:=1;
     DrawDesktop;
     DrawShutdownDialog;
    End;
   End;
   '1': Begin { Sélectionner option 1 }
    If ShutdownDialogVisible Then Begin
     SelectedShutdownOption := 1;
     DrawShutdownDialog;
    End;
   End;
   '2': Begin { Sélectionner option 2 }
    If ShutdownDialogVisible Then Begin
     SelectedShutdownOption := 2;
     DrawShutdownDialog;
    End;
   End;
   '3': Begin { Sélectionner option 3 }
    If ShutdownDialogVisible Then Begin
     SelectedShutdownOption := 3;
     DrawShutdownDialog;
    End;
   End;
   #13: Begin { Entrée pour valider }
    If ShutdownDialogVisible Then ExecuteShutdownAction;
   End;
   #27: Begin { ESC }
    If(ShutdownDialogVisible)Then Begin
     ShutdownDialogVisible:=False;
     DrawDesktop;
     If MenuVisible Then DrawStartMenu;
    End
     Else
    Key := 'q'; { Quitter si pas de dialogue ouvert }
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
