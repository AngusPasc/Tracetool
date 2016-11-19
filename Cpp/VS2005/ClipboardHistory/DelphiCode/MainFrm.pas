unit MainFrm;

interface

uses
    Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, ExtCtrls;

type
    TMainForm = class(TForm)
        Label1: TLabel;
        lbFormats: TListBox;
        Label2: TLabel;
        pnlView: TPanel;
        procedure FormCreate(Sender: TObject);
        procedure FormDestroy(Sender: TObject);
        procedure lbFormatsClick(Sender: TObject);
        procedure FormResize(Sender: TObject);
        function DisplayBin(FormatClp: Word): string;
    PRIVATE
    { Private declarations }
        FNextWindowHandle: HWND;
        FChained: boolean;
        procedure WMChangeCBChain(var msg: TMessage); MESSAGE WM_CHANGECBCHAIN;
        procedure WMDrawClipboard(var msg: TMessage); MESSAGE WM_DRAWCLIPBOARD;

        procedure UpdateList;
        procedure UpdateView(const ClipboardFormat: Word);
    PUBLIC
    { Public declarations }
        procedure Chain;
        procedure UnChain;
    end;

var
    MainForm: TMainForm;

implementation
uses
    ClipBrd, MiscTools;

{$R *.dfm}

{ TMainform }

{-----------------------------------------------------------------------------
  Procedure: TMainForm.Chain
  Author:    Pierre
  Date:      29-sept.-2002
  Arguments: None
  Result:    None
  Purpose: Enregistre la fen�tre dans la cha�ne des clipboard viewers
-----------------------------------------------------------------------------}

procedure TMainForm.Chain;
begin
    FNextWindowHandle := SetClipboardViewer(self.Handle);
    if (FNextWindowHandle = 0) and (GetLastError <> 0) then
    begin
        MessageDlg(SysErrorMessage(GetLastError), mtError, [mbOK], 0);
        FChained := false;
    end
    else
        FChained := true;
end;

{-----------------------------------------------------------------------------
  Procedure: TMainForm.UnChain
  Author:    Pierre
  Date:      29-sept.-2002
  Arguments: None
  Result:    None
  Purpose: D�branche la fen�tre de la cha�ne des clipboard viewers
-----------------------------------------------------------------------------}

procedure TMainForm.UnChain;
begin
    ChangeClipboardChain(self.Handle, FNextWindowHandle);
    FChained := false;
end;

{-----------------------------------------------------------------------------
  Procedure: TMainForm.UpdateList
  Author:    Pierre
  Date:      29-sept.-2002
  Arguments: None
  Result:    None
  Purpose: Stockage de tous les formats disponibles dans la TStringList du
    TListbox. Le num�ro de format est stock� dans la partie objet de chaque
    item, cela nous permet de reconnaitre le type lors d'un click.
-----------------------------------------------------------------------------}

procedure TMainForm.UpdateList;

    procedure AddItem(const Text: string; ClipboardFormat: Word);
    begin
    // Le format (num�ro) est transform� en objet pour le stockage
    // il sera d�cod� de la m�me mani�re
        lbFormats.Items.AddObject(Text, TObject(ClipboardFormat));
    end;

var
    i: Integer;
    clipFormat: Word;
begin
    lbFormats.Items.Clear;
    for i := 0 to ClipBoard.FormatCount - 1 do
    begin
        clipFormat := ClipBoard.Formats[i];
        case clipFormat of
      // Tous les cas courants
            CF_TEXT: AddItem('Texte (CF_TEXT)', clipFormat);
            CF_BITMAP: AddItem('Windows Bitmap (CF_BITMAP)', clipFormat);
            CF_METAFILEPICT: AddItem('Windows Metafile (CF_METAFILEPICT)', clipFormat);
            CF_SYLK: AddItem('Microsoft Symbolic Link (CF_SYLK)', clipFormat);
            CF_DIF: AddItem('Software Arts'' Data Interchange Format (CF_DIF)', clipFormat);
            CF_TIFF: AddItem('Tagged-image file format (CF_TIFF)', clipFormat);
            CF_OEMTEXT: AddItem('Texte au format OEM (CF_OEMTEXT)', clipFormat);
            CF_DIB: AddItem('Device Independant Bitmap (CF_DIB)', clipFormat);
            CF_PALETTE: AddItem('Palette (CF_PALETTE)', clipFormat);
            CF_PENDATA: AddItem('Extension pour Microsoft Windows for Pen Computing (CF_PENDATA)', clipFormat);
            CF_RIFF: AddItem('Son au format RIFF (CF_RIFF)', clipFormat);
            CF_WAVE: AddItem('Son au format WAV (CF_WAVE)', clipFormat);
            CF_UNICODETEXT: AddItem('Texte au format Unicode (CF_UNICODETEXT)', clipFormat);
            CF_ENHMETAFILE: AddItem('Windows Enhanced Metafile (CF_ENHMETAFILE)', clipFormat);
            CF_HDROP: AddItem('Liste de fichiers "lach�s" (CF_HDROP)', clipFormat);
            CF_LOCALE: AddItem('Information de langue sur le texte (CF_LOCALE)', clipFormat);
            CF_MAX: AddItem('CF_MAX', clipFormat);

            CF_OWNERDISPLAY: AddItem('Format sp�cifique (CF_OWNERDISPLAY)', clipFormat);
            CF_DSPTEXT: AddItem('Format texte priv� (CF_DSPTEXT)', clipFormat);
            CF_DSPBITMAP: AddItem('Format d''image priv� (CF_DSPBITMAP)', clipFormat);
            CF_DSPMETAFILEPICT: AddItem('Format de metafile priv� (CF_DSPMETAFILEPICT)', clipFormat);
            CF_DSPENHMETAFILE: AddItem('Format de metafile am�lior� priv� (CF_DSPENHMETAFILE)', clipFormat);
        else
      // Cas sp�ciaux
            begin
        // Valeur priv�es (d�clar�es par une application)
                if ValueIsBetween(clipFormat, CF_PRIVATEFIRST, CF_PRIVATELAST) then
                    AddItem(Format('Format priv� sp�cifique � une application [%d]',
                        [clipFormat]), clipFormat)
        // Objets GDI
                else if ValueIsBetween(clipFormat, CF_GDIOBJFIRST, CF_GDIOBJLAST) then
                    AddItem(Format('Format sp�cifique au GDI [%d]',
                        [clipFormat]), clipFormat)
        // Valeurs d�clar�es par une application
                else
                    AddItem(Format('Format inconnu (%d n''est pas un format pr�d�fini)',
                        [clipFormat]), clipFormat);
            end;
        end;
    end;
  // On simule un click sur le TListBox pour mettre � jour la vue
    lbFormatsClick(lbFormats);
  // On passe la fen�tre au premier plan
    BringToFront;
end;

{-----------------------------------------------------------------------------
  Procedure: TMainForm.UpdateView
  Author:    Pierre
  Date:      29-sept.-2002
  Arguments: const ClipboardFormat: Word
  Result:    None
  Purpose: Affichage du contenu du clipboard au format sp�cifi� si on sait le
    faire, sinon on indique notre incapacit�.
-----------------------------------------------------------------------------}

procedure TMainForm.UpdateView(const ClipboardFormat: Word);
begin
  // Suppression d'une vue �ventuelle
    if pnlView.ControlCount > 0 then
        pnlView.Controls[0].Free;
    pnlView.Caption := '';

    case ClipboardFormat of
        0: pnlView.Caption := 'Aucun format s�lectionn�';

    // On triche un peu en affichant la valeur textuelle (CF_TEXT) m�me
    // si on a cliqu� sur les formats OEM ou Unicode
        CF_TEXT, CF_OEMTEXT, CF_UNICODETEXT:
            with TMemo.Create(self) do
            try
                Parent := pnlView;
                Align := alClient;
                ScrollBars := ssBoth;
                Lines.Text := ClipBoard.AsText;
            except
                Free;
                pnlView.Caption := 'Erreur lors de la r�cup�ration du texte.';
            end;

    // Le clipboard contient une liste de fichiers
        CF_HDROP:
            with TListBox.Create(self) do
            try
                Parent := pnlView;
                Align := alClient;
                GetHDropFiles(ClipBoard.GetAsHandle(CF_HDROP), Items);
            except
                Free;
                pnlView.Caption := 'Erreur lors de la r�cup�ration des noms de fichier.';
            end;

    // Le clipboard contient une image (bitmap)
        CF_BITMAP, CF_DIB:
            with TImage.Create(self) do
            try
                Parent := pnlView;
                Align := alClient;
                Center := true;
                Picture.Bitmap.Assign(ClipBoard);
                if (Width < Picture.Graphic.Width) or (Height < Picture.Graphic.Height) then
                    AdjustGraphicSize(Width, Height, Picture.Graphic);
            except
                Free;
                pnlView.Caption := 'Erreur lors de la r�cup�ration de l''image.';
            end;

    // Le clipboard contient une image (metafile)
        CF_METAFILEPICT, CF_ENHMETAFILE:
            with TImage.Create(self) do
            try
                Parent := pnlView;
                Align := alClient;
                center := true;
                Picture.Metafile.Assign(ClipBoard);
                AdjustGraphicSize(Width, Height, Picture.Graphic);
            except
                Free;
                pnlView.Caption := 'Erreur lors de la r�cup�ration du metafile.';
            end;

    // Le clipboard contient des informations r�gionales (g�n�ralement
    // associ�es � une valeur textuelle.
        CF_LOCALE:
            with TMemo.Create(self) do
            try
                Parent := pnlView;
                Align := alClient;
                ScrollBars := ssBoth;
                FillWithLocaleInfo(ClipBoard.GetAsHandle(CF_LOCALE), Lines);
            except
                Free;
                pnlView.Caption := 'Erreur lors de la r�cup�ration du texte.';
            end;

    // On ne sait pas afficher le reste (pour l'instant).
    // Si quelqu'un a envie d'enrichir ce code, qu'il le fasse!
    else
        with TMemo.Create(self) do
        try
            Parent := pnlView;
            Align := alClient;
            ScrollBars := ssBoth;
            Font.Name := 'Courier New';
            Font.Size := 8;
            Lines.Text := DisplayBin(ClipboardFormat);
        except
            Free;
            pnlView.Caption := 'Erreur lors de la r�cup�ration du texte.';
        end;

        pnlView.Caption := 'Ce programme n''est pas capable d''afficher ce format.';
    end;
end;

{-----------------------------------------------------------------------------
  Procedure: TMainForm.WMChangeCBChain
  Author:    Pierre
  Date:      29-sept.-2002
  Arguments: var msg: TMessage
  Result:    None
  Purpose: Traitement du message WM_CHANGECBCHAIN indiquant que la cha�ne
    a �t� modifi�e (suppression d'un viewer de la liste)
-----------------------------------------------------------------------------}

procedure TMainForm.WMChangeCBChain(var msg: TMessage);
begin
  // Si la fen�tre supprim�e est celle qui suit la notre
  // on stocke le handle de la suivante
    if msg.WParam = Integer(FNextWindowHandle) then
        FNextWindowHandle := msg.LParam
  // Sinon, on passe le message aux fen�tres suivantes
    else if FNextWindowHandle <> 0 then
        SendMessage(FNextWindowHandle, msg.Msg, msg.WParam, msg.LParam);
    msg.Result := 0;
end;

{-----------------------------------------------------------------------------
  Procedure: TMainForm.WMDrawClipboard
  Author:    Pierre
  Date:      29-sept.-2002
  Arguments: var msg: TMessage
  Result:    None
  Purpose: Traitement du message WM_DRAWCLIPBOARD indiquant que le contenu
    du clipboard a �t� modifi�.
-----------------------------------------------------------------------------}

procedure TMainForm.WMDrawClipboard(var msg: TMessage);
begin
  // Nous sommes polis, alors on commence par passer le message � la fen�tre suivante
    if FNextWindowHandle <> 0 then
        SendMessage(FNextWindowHandle, msg.Msg, msg.WParam, msg.LParam);
  // Ensuite mise � jour de nos structures et de l'affichage
    UpdateList;
end;


procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Lors de la cr�ation de la fen�tre, on se branche sur la cha�ne
    Chain;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  // On se d�branche de la chaine lors de la destruction de la fen�tre
    UnChain;
end;

procedure TMainForm.lbFormatsClick(Sender: TObject);
var
    clipFormat: Word;
begin
    if lbFormats.ItemIndex <> -1 then
    // "D�codage" de la valeur du format de clipboard s�lectionn�e
        clipFormat := Word(lbFormats.Items.Objects[lbFormats.ItemIndex])
    else
        clipFormat := 0;
  // Mise � jour de la vue
    UpdateView(clipFormat);
end;


procedure TMainForm.FormResize(Sender: TObject);
begin
  // On simule un click lors du redimensionnement de la fen�tre pour forcer
  // le r�affichage �ventuel d'une image dans la vue.
  // C'est franchement sauvage comme m�thode, mais cela devrait suffire
  // pour l'instant.
    lbFormatsClick(lbFormats);
end;

function TMainForm.DisplayBin(FormatClp: Word): string;
var
    MyHandle: THandle;
    TextPtr: PChar;
    MyString: string;
    i: integer;
    hexa, ascii: string;
begin
    result := '';
    hexa := '';
    ascii := '';
    ClipBoard.Open;
    try
        MyHandle := Clipboard.GetAsHandle(FormatClp);
        TextPtr := GlobalLock(MyHandle);

        for i := 0 to 32 do
        begin
            hexa := hexa + format('%02X ', [ord(TextPtr[i])]);
            if ord(TextPtr[i]) < 32 then
            ascii := ascii + '.'
            else
            ascii := ascii + TextPtr[i];

            if ((i +1) mod 16) = 0 then
            begin
                result := result + hexa + '  ' + ascii + #13#10;
                ascii := '';
                hexa := '';
            end;
        end;

        GlobalUnlock(MyHandle);
    finally
        Clipboard.Close;
    end;
end;

end.

