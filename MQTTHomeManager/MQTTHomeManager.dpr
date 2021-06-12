program MQTTHomeManager;

uses
  System.StartUpCopy,
  FMX.Forms,
  UFormHomeManager in 'UFormHomeManager.pas' {HomeManagerForm},
  UFrGenericRoom in 'UFrGenericRoom.pas' {FrGenericRoom: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(THomeManagerForm, HomeManagerForm);
  Application.Run;
end.
