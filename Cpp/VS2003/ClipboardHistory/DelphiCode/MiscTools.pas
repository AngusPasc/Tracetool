{-----------------------------------------------------------------------------
 Unit Name: MiscTools
 Author:    Pierre Castelain
 Purpose: Diverses fonctions et proc�dure utilitaires pour CliboardViewer
 History:
-----------------------------------------------------------------------------}


unit MiscTools;

interface
uses
 Classes, SysUtils, Windows, ShellAPI, Graphics;

function ValueIsBetween(const Value, First, Last: Integer): boolean;
procedure GetHDropFiles(const Handle: HDROP; FileNames: TStrings);
function CalcDrawSize(GraphicSize, DrawingSize :TSize): TSize;
procedure AdjustGraphicSize(const AWidth, AHeight: Integer; AGraphic: TGraphic);
procedure FillWithLocaleInfo(const LocaleHandle: THandle; Infos: TStrings);

implementation

{-----------------------------------------------------------------------------
  Procedure: ValueIsBetween
  Author:    Pierre
  Date:      29-sept.-2002
  Arguments: const Value, First, Last: Integer
  Result:    boolean
  Purpose: La valeur Value est-elle comprise dans l'intervalle [First,Last]
-----------------------------------------------------------------------------}
function ValueIsBetween(const Value, First, Last: Integer): boolean;
begin
  result:= (First <= Value) and (Value <= Last);
end;

{-----------------------------------------------------------------------------
  Procedure: GetHDropFiles
  Author:    Pierre
  Date:      29-sept.-2002
  Arguments: const Handle: HDROP; FileNames: TStrings
  Result:    None
  Purpose: R�cup�re la liste des fichiers d�sign�e par le handle et ajoute
    ceux-ci dans Filenames.
-----------------------------------------------------------------------------}
procedure GetHDropFiles(const Handle: HDROP; FileNames: TStrings);
var
  count, i, bufferSize: UINT;
  buffer: PChar;
begin
  // Appel initial pour connaitre le nombre de fichiers
  count:= DragQueryFile(Handle, $FFFFFFFF, nil, 0);

  for i:=0 to count -1 do
  begin
    // Premier appel pour connaitre la taille du buffer � allouer
    bufferSize:= DragQueryFile(Handle, i, nil, 0);
    buffer:= StrAlloc(bufferSize + 1); // +1 pour 0 terminal

    // Deuxi�me appel pour r�cup�rer le nom
    DragQueryFile(Handle, i, buffer, bufferSize + 1);
    FileNames.Add(buffer);

    // On lib�re le buffer
    StrDispose(buffer);
  end;
end;

{-----------------------------------------------------------------------------
  Procedure: CalcDrawSize
  Author:    Pierre
  Date:      29-sept.-2002
  Arguments: GraphicSize, DrawingSize :TSize
  Result:    TSize
  Purpose: Calcule la taille maximale d'une image dans un objet graphique
    en conservant le ratio original.
-----------------------------------------------------------------------------}
function CalcDrawSize(GraphicSize, DrawingSize :TSize): TSize;
var
  RatioGS, RatioDS: extended;
begin
  RatioGS:= GraphicSize.cx / GraphicSize.cy;
  RatioDS:= DrawingSize.cx / DrawingSize.cy;
  if RatioGS > RatioDS then
  begin
    result.cx:= DrawingSize.cx;
    result.cy:= Trunc(result.cx / RatioGS);
  end
  else
  begin
    result.cy:= DrawingSize.cy;
    result.cx:= Trunc(result.cy * RatioGS);
  end;
end;

{-----------------------------------------------------------------------------
  Procedure: Size
  Author:    Pierre
  Date:      29-sept.-2002
  Arguments: const X, Y: Integer
  Result:    TSize
  Purpose: Construit un record de type TSize � la vol�e
-----------------------------------------------------------------------------}
function Size(const X, Y: Integer): TSize;
begin
  result.cx:= X;
  result.cy:= Y;
end;

{-----------------------------------------------------------------------------
  Procedure: AdjustGraphicSize
  Author:    Pierre
  Date:      29-sept.-2002
  Arguments: const AWidth, AHeight: Integer; AGraphic: TGraphic
  Result:    None
  Purpose: Ajuste la taille du TGraphic en fonction de la taille du conteneur
    fournie en conservant le ratio original.
-----------------------------------------------------------------------------}
procedure AdjustGraphicSize(const AWidth, AHeight: Integer; AGraphic: TGraphic);
var
  graphicSize: TSize;
begin
  with AGraphic do
    graphicSize:= Size(Width, Height);

  graphicSize:= CalcDrawSize(graphicSize, Size(AWidth, AHeight));

  with AGraphic do
  begin
    Width:= graphicSize.cx;
    Height:= graphicSize.cy
  end;
end;

{-----------------------------------------------------------------------------
  Procedure: FillWithLocaleInfo
  Author:    Pierre
  Date:      29-sept.-2002
  Arguments: const LocaleHandle: THandle; Infos: TStrings
  Result:    None
  Purpose: R�cup�re une partie des informations r�gionales et internationales
    associ�es au handle fourni.
-----------------------------------------------------------------------------}
procedure FillWithLocaleInfo(const LocaleHandle: THandle; Infos: TStrings);

  function GetLocaleInfoStr(const LocaleID: LCID; LocaleType: LCTYPE): string;
  var
    buffer: PChar;
    bufferSize: UINT;
  begin
    // Un premier appel pour connaitre la taille du buffer � allouer
    bufferSize:= GetLocaleInfo(LocaleID, LocaleType, nil, 0);
    // On alloue le buffer en cons�quence (+1 pour le z�ro terminal)
    buffer:= StrAlloc(BufferSize + 1);
    // Un deuxi�me appel pour obtenir l'information souhait�e (LocaleType)
    GetLocaleInfo(LocaleID, LocaleType, buffer, bufferSize);
    // On retourne le texte obtenu
    result:= buffer;
    // Et on lib�re la m�moire allou�e
    StrDispose(buffer);
  end;

type
  PLCID = ^LCID;
var
  LocaleID: PLCID;
begin
  // On commence par r�cup�rer la valeur du LocaleID point�e par le handle
  LocaleID:= GlobalLock(LocaleHandle);
  try
    // On interroge le syst�me pour chaque valeur que l'on veut r�cup�rer
    // Les constantes d�crivant le type d'information � r�cup�rer sont d�finies
    // dans Windows.pas
    Infos.Add('Language ID : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_ILANGUAGE));

    Infos.Add('Nom de la langue (dans la langue courante) : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_SLANGUAGE));

    Infos.Add('Nom de la langue (en anglais) : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_SENGLANGUAGE));

    Infos.Add('Nom de la langue (abr�g�) : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_SABBREVLANGNAME));

    Infos.Add('Nom de la langue (dans la langue native) : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_SNATIVELANGNAME));


    Infos.Add('Code pays : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_ICOUNTRY));

    Infos.Add('Nom du pays (dans la langue courante) : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_SCOUNTRY));

    Infos.Add('Nom du pays (en anglais) : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_SENGCOUNTRY));

    Infos.Add('Nom du pays (abr�g�) : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_SABBREVCTRYNAME));

    Infos.Add('Nom du pays (dans la langue native) : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_SNATIVECTRYNAME));


    Infos.Add('S�parateur d�cimal : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_SDECIMAL));

    Infos.Add('S�parateur des milliers : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_STHOUSAND));

    Infos.Add('Symbole de groupement de chiffres : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_SGROUPING));

    Infos.Add('Nombre de d�cimales : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_IDIGITS));

    Infos.Add('Afficher les z�ros en en-t�te : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_ILZERO));

    Infos.Add('Format de nombre n�gatif : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_INEGNUMBER));

    Infos.Add('Aper�u : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_SNATIVEDIGITS));


    Infos.Add('Symbole mon�taire local : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_SCURRENCY));

    Infos.Add('Symbole mon�taire international : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_SINTLSYMBOL));

    Infos.Add('S�parateur mon�taire d�cimal : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_SMONDECIMALSEP));

    Infos.Add('S�parateur mon�taire des milliers : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_SMONTHOUSANDSEP));

    Infos.Add('S�parateur mon�taire de groupement de chiffres : ' +
      GetLocaleInfoStr(LocaleID^, LOCALE_SMONGROUPING));

    Infos.Add('Etc');
  finally
    GlobalUnlock(LocaleHandle);
  end;
end;

end.
