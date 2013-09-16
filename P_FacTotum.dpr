program P_FacTotum;

uses
  Vcl.Forms,
  U_Main in 'U_Main.pas' {F_FacTotum},
  Vcl.Themes,
  Vcl.Styles,
  U_Classes in 'Units\U_Classes.pas',
  U_Functions in 'Units\U_Functions.pas',
  U_DataBase in 'DataBase\U_DataBase.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Metropolis UI Dark');
  Application.CreateForm(TF_FacTotum, F_FacTotum);
  Application.Run;
end.
