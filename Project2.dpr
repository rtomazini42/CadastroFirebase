program Project2;

uses
  System.StartUpCopy,
  FMX.Forms,
  main in 'Unit\main.pas' {Form2},
  Firebase.Auth in 'Firebase\Firebase.Auth.pas',
  Firebase.Database in 'Firebase\Firebase.Database.pas',
  Firebase.Interfaces in 'Firebase\Firebase.Interfaces.pas',
  Firebase.Request in 'Firebase\Firebase.Request.pas',
  Firebase.Response in 'Firebase\Firebase.Response.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
