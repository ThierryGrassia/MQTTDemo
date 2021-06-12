unit UFrGenericRoom;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.Layouts,TMS.MQTT.Global, TMS.MQTT.Client;

type
  TFrGenericRoom = class(TFrame)
    Background: TImage;
    layoutConnected: TLayout;
    lblStatus: TLabel;
    layoutTemperature: TLayout;
    Circle1: TCircle;
    lblTemp: TLabel;
    rectTemperatureCalc: TRectangle;
    lyBottom: TLayout;
    Layout1: TLayout;
    chkCurtainOpened: TCheckBox;
    tbarTemperature: TTrackBar;
    Image1: TImage;
    procedure tbarTemperatureChange(Sender: TObject);
    procedure chkCurtainOpenedClick(Sender: TObject);
  private
    { Private declarations }
    FRoomName : string;
    FMQTTClient:TTMSMQTTClient;
    FBitmapCurtainsClosed:TBitMap;
    FBitmapCurtainsOpened:TBitMap;
    FTemperature : integer;
    FWindowsOpened : boolean;
    FCommandTopic : string;
    procedure SendTemperatureCommand;
    procedure SendCurtainCommand;
  public
    { Public declarations }
    Owner:TFmxObject;
    constructor Create(AOwner: TComponent;aRoomName:string;abitmapWindowOpened,abitMapWindowClosed:TBitmap;
                        aMQTT:TTMSMQTTClient); reintroduce;
    procedure ManageStatus(aTemperature:integer;isOpened:boolean);
    procedure SetBackground(isOpened: boolean);
  end;

implementation

uses Json;

const houseName = 'MyHouse';



{$R *.fmx}

procedure TFrGenericRoom.chkCurtainOpenedClick(Sender: TObject);
begin
  SendCurtainCommand;
end;

constructor TFrGenericRoom.Create(AOwner: TComponent;aRoomName:string; abitmapWindowOpened,
  abitMapWindowClosed: TBitmap;aMQTT:TTMSMQTTClient);
begin
  inherited Create(AOwner);
  FRoomName := aRoomName;
  if (abitmapWindowOpened<>nil) and (abitMapWindowClosed<>nil) then
  begin
    FBitmapCurtainsClosed := TBitmap.Create(1024,1024);
    FBitmapCurtainsOpened := TBitmap.Create(1024,1024);
    FBitmapCurtainsOpened.Assign(abitmapWindowOpened);
    FBitmapCurtainsClosed.Assign(abitMapWindowClosed);
  end;
  FMQTTClient := aMQTT;
  FCommandTopic := 'home/'+uppercase(houseName)+'/'+FroomName+'/commands';
  ManageStatus(20,true);
end;

procedure TFrGenericRoom.ManageStatus(aTemperature:integer;isOpened:boolean);
begin
  if aTemperature<>FTemperature then
  begin
    FTemperature := aTemperature;
    if FTemperature<0 then
    begin
      rectTemperatureCalc.Fill.Color := TAlphaColorRec.Aqua;
      rectTemperatureCalc.Opacity := 0.08;
    end;
    if (FTemperature>=0) and (FTemperature<5) then
    begin
      rectTemperatureCalc.Fill.Color := TAlphaColorRec.Aqua;
      rectTemperatureCalc.Opacity := 0.06;
    end;
    if (FTemperature>=5) and (FTemperature<10) then
    begin
      rectTemperatureCalc.Fill.Color := TAlphaColorRec.Aqua;
      rectTemperatureCalc.Opacity := 0.04;
    end;
    if (FTemperature>=10) and (FTemperature<20) then
    begin
      rectTemperatureCalc.Fill.Color := TAlphaColorRec.Aqua;
      rectTemperatureCalc.Opacity := 0;
    end;

    if (FTemperature>=20) and (FTemperature<25) then
    begin
      rectTemperatureCalc.Fill.Color := TAlphaColorRec.Red;
      rectTemperatureCalc.Opacity := 0.04;
    end;
    if (FTemperature>=25) and (FTemperature<30) then
    begin
      rectTemperatureCalc.Fill.Color := TAlphaColorRec.Red;
      rectTemperatureCalc.Opacity := 0.04;
    end;
    if FTemperature>30 then
    begin
      rectTemperatureCalc.Fill.Color := TAlphaColorRec.Red;
      rectTemperatureCalc.Opacity := 0.08;
    end;
    Circle1.Fill.Color := rectTemperatureCalc.Fill.Color;
    lblTemp.FontColor := rectTemperatureCalc.Fill.Color;
    lblTemp.Text := inttostr(FTemperature)+' ° C';
    tbarTemperature.Value := FTemperature;
  end;
  SetBackground(isOpened);
end;

procedure TFrGenericRoom.SetBackground(isOpened: boolean);
begin
  if FWindowsOpened<>isOpened then
  begin
    if isOpened then
    begin
      Background.Bitmap.Assign(FBitmapCurtainsOpened);
    end
    else
    begin
      Background.Bitmap.Assign(FBitmapCurtainsClosed);
    end;
    FWindowsOpened := isOpened;
    chkCurtainOpened.IsChecked := isOpened;
  end;
  Background.Position.X:=0;
  Background.Position.Y:=0;
end;

procedure TFrGenericRoom.tbarTemperatureChange(Sender: TObject);
begin
  SendTemperatureCommand;
end;

procedure TFrGenericRoom.SendCurtainCommand;
var LPacketPayload:string;
    aJson:TJsonObject;
begin
  if FMQTTClient.IsConnected then
  begin
    aJson := TJSONObject.Create;
    aJson.AddPair('curtainopened',BoolToStr(chkCurtainOpened.IsPressed,True));
    LPacketPayload := aJson.ToString;
    FMQTTClient.Publish(FCommandTopic, LPacketPayload, qosAtMostOnce, true);
    aJson.Free;
  end;
end;

procedure TFrGenericRoom.SendTemperatureCommand;
var LPacketPayload:string;
    aJson:TJsonObject;
begin
  if FMQTTClient.IsConnected then
  begin
    aJson := TJSONObject.Create;
    aJson.AddPair('temperature',Trunc(tbarTemperature.Value).ToString);
    LPacketPayload := aJson.ToString;
    FMQTTClient.Publish(FCommandTopic, LPacketPayload, qosAtMostOnce, true);
    aJson.Free;
  end;
end;

end.
