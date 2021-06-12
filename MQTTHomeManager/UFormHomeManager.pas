unit UFormHomeManager;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.TabControl, FMX.Controls.Presentation, TMS.MQTT.Global, TMS.MQTT.Client,
  System.Generics.Collections,UfrGenericRoom, FMX.Objects, System.ImageList,
  FMX.ImgList;

type
  THomeManagerForm = class(TForm)
    Header: TToolBar;
    Footer: TToolBar;
    HeaderLabel: TLabel;
    MainTabControl: TTabControl;
    MQTT: TTMSMQTTClient;
    lblStatus: TLabel;
    Image1: TImage;
    imgList: TImageList;
    procedure FormCreate(Sender: TObject);
    procedure MQTTConnectedStatusChanged(ASender: TObject;
      const AConnected: Boolean; AStatus: TTMSMQTTConnectionStatus);
    procedure MQTTPublishReceived(ASender: TObject; APacketID: Word;
      ATopic: string; APayload: TArray<System.Byte>);
  private
    { Private declarations }
    FRoomDictionnary:TDictionary<string,TFrGenericRoom>;
    FStatusTopic : string;
    FInitTopic : string;
    FByeTopic : string;
    function GetImageIndexByRoomType(roomType:string):integer;
    procedure AddRoom(roomName,roomType:string);
    procedure ManageInit(jsonString:string);
    procedure ManageBye(jsonString:string);
    function GetJsonValue(jsonString,paramName: string):string;
    procedure ManageRoomStatus(jsonString:string);
  public
    { Public declarations }
  end;

var
  HomeManagerForm: THomeManagerForm;

implementation

uses JSon;

const houseName = 'MyHouse';

{$R *.fmx}

procedure THomeManagerForm.AddRoom(roomName,roomType: string);
var anItem: TTabItem;
    aFrame:TFrGenericRoom;
    abitMapopened,abitmapClosed:TBitMap;
    imgIndexClosed:integer;
    aSizeF:TSizeF;
begin
  if not FRoomDictionnary.ContainsKey(roomName) then
  begin
    imgIndexClosed := GetImageIndexByRoomType(roomType);
    if imgIndexClosed<>-1 then
    begin
      aSizeF.cx := 1024;
      aSizeF.cy := 1024;
      abitmapClosed := imgList.Destination.ImageList.Bitmap(aSizeF,imgIndexClosed);
      abitMapopened := imgList.Destination.ImageList.Bitmap(aSizeF,imgIndexClosed+1);
    end
    else
    begin
      abitmapClosed := nil;
      abitmapopened := nil;
    end;
    anItem := MainTabControl.Add();
    anItem.Text := roomName;
    aFrame := TFrGenericRoom.Create(anItem,roomName,abitMapopened,abitmapClosed,MQTT);
    aFrame.Parent := anItem;
    aFrame.Owner := anItem;
    aFrame.Align := TAlignLayout.Client;
    FRoomDictionnary.AddOrSetValue(roomName,aFrame);
  end;
end;

procedure THomeManagerForm.FormCreate(Sender: TObject);
begin
  FRoomDictionnary:=TDictionary<string,TFrGenericRoom>.Create;
  MQTT.BrokerHostName := 'broker.hivemq.com';
  MQTT.ClientID := 'HomeMonitor';
  FInitTopic := 'home/'+uppercase(houseName)+'/init';
  FByeTopic := 'home/'+uppercase(houseName)+'/bye';
  FStatusTopic := 'home/'+uppercase(houseName)+'/status';
  MQTT.Connect();
end;

procedure THomeManagerForm.ManageBye(jsonString: string);
var roomname:string;
    aFrame:TFrGenericRoom;
begin
  roomname := GetJsonValue(jsonString,'roomname');
  if FRoomDictionnary.ContainsKey(roomname) then
  begin
    FRoomDictionnary.TryGetValue(roomname,aFrame);
    FRoomDictionnary.Remove(roomname);
    aFrame.Owner.Free;
  end;
end;

function THomeManagerForm.GetImageIndexByRoomType(roomType: string): integer;
begin
  Result := -1;
  if roomtype='Living Room' then
    Result := 0
  else if roomtype='Kitchen' then
    Result := 2
  else if roomtype='Sleeping Room' then
    Result := 4;
end;

function THomeManagerForm.GetJsonValue(jsonString,paramName: string):string;
var
  aJson: TJSONValue;
begin
  Result := '';
  aJson := TJSONObject.ParseJSONValue(jsonString);
  if aJson.FindValue(paramName)<>nil then
    Result := aJson.FindValue(paramName).Value;
  aJson.Free;
end;


procedure THomeManagerForm.ManageInit(jsonString: string);
var
    roomname,roomType : string;
begin
  roomname :=  GetJsonValue(jsonString,'roomname');
  roomType :=  GetJsonValue(jsonString,'roomtype');
  AddRoom(roomname,roomType);
end;

procedure THomeManagerForm.ManageRoomStatus(jsonString: string);
var aJson:TJsonValue;
    tempVal,roomname:string;
    openedcurtainsStr : string;
    isOpened:boolean;
    aTemperature :integer;
    aFrame:TFrGenericRoom;
begin
   aJson := TJSONObject.ParseJSONValue(jsonString);
   roomname := aJson.FindValue('roomname').Value;
   tempVal := aJson.FindValue('temperature').Value;
   openedcurtainsStr := aJson.FindValue('curtainsopened').Value;
   aTemperature :=string.ToInteger(tempVal);
   isOpened := string.ToBoolean(openedcurtainsStr);
   if FRoomDictionnary.ContainsKey(roomname) then
   begin
     FRoomDictionnary.TryGetValue(roomname,aFrame);
     aFrame.ManageStatus(aTemperature,isOpened);
   end;
   aJson.Free;
end;

procedure THomeManagerForm.MQTTConnectedStatusChanged(ASender: TObject;
  const AConnected: Boolean; AStatus: TTMSMQTTConnectionStatus);
begin
  //do
  if Aconnected then
  begin
    MQTT.Subscribe(FInitTopic);
    MQTT.Subscribe(FByeTopic);
    MQTT.Subscribe(FStatusTopic);
    lblStatus.Visible := False;
  end
  else
  begin
    lblStatus.Visible := True;
  end;
end;




procedure THomeManagerForm.MQTTPublishReceived(ASender: TObject;
  APacketID: Word; ATopic: string; APayload: TArray<System.Byte>);
var jsonString:string;
begin
  //
  jsonString := TEncoding.UTF8.GetString(APayload);
  if ATopic = FInitTopic then
  begin
    ManageInit(jsonString);
  end
  else if ATopic = FByeTopic then
  begin
    ManageBye(jsonString);
  end
  else if ATopic = FStatusTopic then
  begin
    ManageRoomStatus(jsonString);
  end;
end;

end.
