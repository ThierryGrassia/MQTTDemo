program MQTTHomeClient;

uses
  Vcl.Forms,
  UMQTTHomeClient in 'UMQTTHomeClient.pas' {FormHomeClient};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormHomeClient, FormHomeClient);
  Application.Run;
end.
