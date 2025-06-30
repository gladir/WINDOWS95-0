{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025
  @website(https://www.gladir.com/windows95-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Program WIN;

Uses {$IFDEF FPC}
      Windows,PtcMouse,PtcCrt,PtcGraph
     {$ELSE}
      Crt,Graph
     {$ENDIF};

Var
 MenuVisible: Boolean;
 MouseX, MouseY: LongInt;

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
Procedure Draw3DBorder(x1, y1, x2, y2: Integer; Raised: Boolean);
Begin
 If Raised then
 Begin
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
 MaxX, MaxY: Integer;
Begin
 MaxX := GetMaxX;
 MaxY := GetMaxY;

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
 MaxY: Integer;
 MenuItems: Array[1..8] of String;
 i: Integer;
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
 For i := 1 to 8 do
 Begin
  If MenuItems[i] <> '_______________' then
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
Procedure DrawDesktop;
Begin
 { Fond du bureau (Teal/Turquoise) }
 SetFillStyle(SolidFill, Cyan);
 Bar(0, 0, GetMaxX, GetMaxY - 31);

 { Dessine la barre de tâches }
 DrawTaskbar;
End;

{ Vérifie si la souris est sur le bouton Démarrer }
Function IsMouseOnStartButton(x, y: Integer): Boolean;
Var
 MaxY: Integer;
Begin
 MaxY := GetMaxY;
 IsMouseOnStartButton := (x >= 2) and (x <= 60) and (y >= MaxY - 28) and (y <= MaxY - 2);
End;

{ Gestionnaire d'événements souris }
Procedure HandleMouse;
Var
 MouseButton: LongInt;
 MousePressed: Boolean;
Begin
 {$IFDEF FPC}
  GetMouseState(MouseX, MouseY, MouseButton);
  MousePressed := (MouseButton and 1) <> 0; { Bouton gauche pressé }

  If MousePressed then
  Begin
   If IsMouseOnStartButton(MouseX, MouseY) then
   Begin
    MenuVisible := not MenuVisible;
    DrawDesktop;
    If MenuVisible then
     DrawStartMenu;
    { Attendre que le bouton soit relâché }
    Repeat
     GetMouseState(MouseX, MouseY, MouseButton);
    Until (MouseButton and 1) = 0;
   End
   Else If MenuVisible then
   Begin
    MenuVisible := False;
    DrawDesktop;
    { Attendre que le bouton soit relâché }
    Repeat
     GetMouseState(MouseX, MouseY, MouseButton);
    Until (MouseButton and 1) = 0;
   End;
  End;
 {$ENDIF}
End;

{ Boucle principale }
Procedure MainLoop;
Var
 Key: Char;
Begin
 MenuVisible := False;
 DrawDesktop;

 Repeat
  {$IFDEF FPC}
   HandleMouse;
   If KeyPressed then
    Key := ReadKey;
  {$ELSE}
   If KeyPressed then
    Key := ReadKey;
  {$ENDIF}

  { Gestion des touches }
  Case Key of
   ' ': Begin { Barre d'espace pour afficher/masquer le menu }
         MenuVisible := not MenuVisible;
         DrawDesktop;
         If MenuVisible then
          DrawStartMenu;
        End;
   #27: Key := 'q'; { ESC = Quitter }
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
