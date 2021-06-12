unit UMQTTHomeClient;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, TMS.MQTT.Global, TMS.MQTT.Logging,
  TMS.MQTT.FileLogging, TMS.MQTT.Client, Vcl.Samples.Spin, Vcl.StdCtrls,
  Vcl.ExtCtrls,JSON, Vcl.BaseImageCollection, Vcl.ImageCollection;

type
  TFormHomeClient = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Panel1: TPanel;
    edtHostName: TEdit;
    Label2: TLabel;
    spEdtPort: TSpinEdit;
    Label3: TLabel;
    edtRoomName: TEdit;
    MQTTClient: TTMSMQTTClient;
    MQTTFileLogger: TTMSMQTTFileLogger;
    btnConnect: TButton;
    btnDisconnect: TButton;
    pnlStatus: TPanel;
    GroupBox2: TGroupBox;
    Label5: TLabel;
    spEdtTemperature: TSpinEdit;
    chkCurtainsOpened: TCheckBox;
    btnSendData: TButton;
    StatusTimer: TTimer;
    DisconnectTimer: TTimer;
    cmbRoomType: TComboBox;
    Label4: TLabel;
    imgList: TImageCollection;
    imgOpened: TImage;
    imgClosed: TImage;
    procedure btnConnectClick(Sender: TObject);
    procedure MQTTClientConnectedStatusChanged(ASender: TObject;
      const AConnected: Boolean; AStatus: TTMSMQTTConnectionStatus);
    procedure MQTTClientPublishReceived(ASender: TObject; APacketID: Word;
      ATopic: string; APayload: TArray<System.Byte>);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure StatusTimerTimer(Sender: TObject);
    procedure btnSendDataClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure DisconnectTimerTimer(Sender: TObject);
    procedure cmbRoomTypeChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    FCommandTopic:string;
    FStatusTopic : string;
    FInitTopic : string;
    FByeTopic : string;
    FroomName:string;
    procedure  ManagePictures;
    procedure ManageCommand(jsonString:string);
    procedure SendInit;
    procedure SendBye;
  public
    { Public declarations }
  end;

var
  FormHomeClient: TFormHomeClient;

implementation

uses System.NetEncoding;

const aClientId = 'HomeControl';
const houseName = 'MyHouse';





{$R *.dfm}



procedure TFormHomeClient.btnConnectClick(Sender: TObject);
begin
  MQTTClient.BrokerHostName := edtHostName.Text;
  MQTTClient.BrokerPort := spEdtPort.Value;
  MQTTClient.ClientID := houseName+'_'+edtRoomName.Text;
  MQTTClient.Connect();
end;

procedure TFormHomeClient.btnDisconnectClick(Sender: TObject);
begin
  SendBye;
  DisconnectTimer.Enabled := true;
end;

procedure TFormHomeClient.btnSendDataClick(Sender: TObject);
begin
  StatusTimerTimer(nil);
end;

procedure  TFormHomeClient.ManagePictures;
var imageClosedIndex,imageOpenedIndex:integer;
begin
  imageClosedIndex := cmbRoomType.ItemIndex*2;
  imageOpenedIndex := imageClosedIndex+1;
  imgClosed.Picture.Bitmap.Assign(imgList.GetBitmap(imageClosedIndex,imgClosed.Width,imgClosed.Height));
  imgOpened.Picture.Bitmap.Assign(imgList.GetBitmap(imageOpenedIndex,imgOpened.Width,imgOpened.Height));
end;

procedure TFormHomeClient.cmbRoomTypeChange(Sender: TObject);
begin
  ManagePictures;
end;

procedure TFormHomeClient.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not MQTTClient.IsConnected ;
  if not CanClose then
    ShowMessage('Please disconnect before to close');
end;

procedure TFormHomeClient.FormCreate(Sender: TObject);
begin
  ManagePictures;
end;

procedure TFormHomeClient.ManageCommand(jsonString: string);
var aJson:TJsonValue;
    aValue:string;
begin
  aJson := TJSONObject.ParseJSONValue(jsonString);
  if aJson.FindValue('temperature')<>nil then
  begin
    aValue := aJson.FindValue('temperature').Value;
    spEdtTemperature.Value := string.ToInteger(aValue);
  end;
  if aJson.FindValue('curtainopened')<>nil then
  begin
    aValue := aJson.FindValue('curtainopened').Value;
    chkCurtainsOpened.Checked := string.ToBoolean(aValue);
  end;
  aJson.Free;
end;

procedure TFormHomeClient.MQTTClientConnectedStatusChanged(ASender: TObject;
  const AConnected: Boolean; AStatus: TTMSMQTTConnectionStatus);
begin
  if Aconnected then
  begin
    pnlStatus.Caption := 'Connected';
    FroomName := edtRoomName.Text;
    FCommandTopic := 'home/'+uppercase(houseName)+'/'+FroomName+'/commands';
    FStatusTopic := 'home/'+uppercase(houseName)+'/status';
    FInitTopic := 'home/'+uppercase(houseName)+'/init';
    FByeTopic := 'home/'+uppercase(houseName)+'/bye';
    MQTTClient.Subscribe(FCommandTopic);
    SendInit;
    StatusTimer.Enabled := True;
  end
  else
  begin
    pnlStatus.Caption := 'Not Connected';
  end;
end;

procedure TFormHomeClient.MQTTClientPublishReceived(ASender: TObject; APacketID: Word;
  ATopic: string; APayload: TArray<System.Byte>);
var jsonString:string;
begin
  //
  jsonString := TEncoding.UTF8.GetString(APayload);
  if ATopic = FCommandTopic then
  begin
    ManageCommand(jsonString);
  end
end;

procedure TFormHomeClient.SendBye;
var LPacketPayload:string;
    aJson:TJsonObject;
begin
  if MQTTClient.IsConnected then
  begin
    aJson := TJSONObject.Create;
    aJson.AddPair('roomname',edtRoomName.text);
    LPacketPayload := aJson.ToString;
    MQTTClient.Publish(FByeTopic, LPacketPayload, qosAtMostOnce, true);
    aJson.Free;
  end;
end;

procedure TFormHomeClient.SendInit;
var LPacketPayload:string;
    aJson:TJsonObject;
begin
  if MQTTClient.IsConnected then
  begin
    aJson := TJSONObject.Create;
    aJson.AddPair('roomname',edtRoomName.text);
    aJson.AddPair('roomtype',cmbRoomType.Text);
    LPacketPayload := aJson.ToString;
    MQTTClient.Publish(FInitTopic, LPacketPayload, qosAtMostOnce, true);
    aJson.Free;
  end;
end;

procedure TFormHomeClient.StatusTimerTimer(Sender: TObject);
var LPacketPayload:string;
    aJson:TJsonObject;
begin
  if MQTTClient.IsConnected then
  begin
    aJson := TJSONObject.Create;
    aJson.AddPair('roomname',edtRoomName.text);
    aJson.AddPair('temperature',spEdtTemperature.Value.ToString);
    aJson.AddPair('curtainsopened',BoolToStr(chkCurtainsOpened.Checked,True));
    aJson.AddPair('tick',GetTickCount64.ToString);
    LPacketPayload := aJson.ToString;
    MQTTClient.Publish(FStatusTopic, LPacketPayload, qosAtMostOnce, true);
    aJson.Free;
  end;
end;

procedure TFormHomeClient.DisconnectTimerTimer(Sender: TObject);
begin
  DisconnectTimer.Enabled := False;
  MQTTClient.Disconnect;
  MQTTClient.Logger := nil;
end;

end.
