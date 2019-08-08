unit BaminOrderRelationMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,
  Vcl.ComCtrls;

type
  TOnNewDeliveryFunc = function(AOrderNo, ARoadNameAddress, AAddress, AAddressDetail, APhoneNo: PWideChar;
    ALatitude, ALongitude: PWideChar; ATitle: PWideChar; AQuantity: Integer; AAmount, APaymentType: Integer;
    Amemo: PWideChar): Boolean; stdcall;
  TOnStatusChangedProc = procedure(AOrderNo: PWideChar; AOrderStatus: Integer); stdcall;
  TOnDisconnectedProc = procedure(); stdcall;

type
  TDeliveryItem = record
    RoadName: string;
    Address: string;
    AddressDetail: string;
    PhoneNo: string;
    Latitude: string;
    Longitude: string;
    Amount: Integer;
    Quantity: Integer;
    OrderNo: string;

    ATitle: string;
    PaymentType: Integer;
  end;
  PDeliveryItem = ^TDeliveryItem;

  TFrmBaminOrderRelationMain = class(TForm)
    Memo1: TMemo;
    btnRegCallback: TButton;
    btnInitializeService: TButton;
    ListView1: TListView;
    btnSetDeliveryCompleted: TButton;
    btnFinalizeService: TButton;
    btnChangeRiderStatus: TButton;
    procedure btnRegCallbackClick(Sender: TObject);
    procedure btnInitializeServiceClick(Sender: TObject);
    procedure btnSetDeliveryCompletedClick(Sender: TObject);
    procedure ListView1Click(Sender: TObject);
    procedure btnFinalizeServiceClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnChangeRiderStatusClick(Sender: TObject);
  private
  public

  end;

function OnNewDeliveryFunc(AOrderNo, ARoadNameAddress, AAddress, AAddressDetail, APhoneNo: PWideChar;
  ALatitude, ALongitude: PWideChar; ATitle: PWideChar; AQuantity: Integer; AAmount, APaymentType: Integer;
  AMemo: PWideChar): Boolean; stdcall;
procedure OnStatusChangedProc(AOrderNo: PWideChar; AOrderStatus: Integer); stdcall;
procedure OnDisconnectedProc(); stdcall;

const
  PT_PREPAYED = 0;
  PT_MEET_CARD = 1;
  PT_MEET_CASH = 2;

  OS_NEW = 0;
  OS_RECEIPT = 1;
  OS_COMPLETED = 2;
  OS_CANCELED = 3;

  DS_RIDER_ASSIGNED = 0;
  DS_PICKUP_COMPLETED = 1;
  DS_DELIVERY_COMPLETED = 2;

const
  ERR_CONNECTION_FAILED = -1;
  ERR_UNAUTHENTICATED = 401;
  ERR_UNKNOWN_SIGN_KEY = 404;
  ERR_BAD_REQUEST = 500;

var
  FrmBaminOrderRelationMain: TFrmBaminOrderRelationMain;

implementation

{$R *.dfm}

uses CreateDelivery, ChangeDeliveryStatus;

{$IFDEF WIN64}
function IsBaeminInstalled(): Boolean; stdcall; external 'BMOrderRelayx64.dll';
function IsBaeminRunning(): Boolean; stdcall; external 'BMOrderRelayx64.dll';
function RegisterNewDeliveryFunction(AEvent: TOnNewDeliveryFunc): Boolean; stdcall; external 'BMOrderRelayx64.dll';
function RegisterStatusChangedFunction(AEvent: TOnStatusChangedProc): Boolean; stdcall; external 'BMOrderRelayx64.dll';
function RegisterDisconnectedFunction(AEvent: TOnDisconnectedProc): Boolean; stdcall; external 'BMOrderRelayx64.dll';
function InitializeService(ASignKey: PWideChar): Integer; stdcall; external 'BMOrderRelayx64.dll';
function FinalizeService(): Integer; stdcall; external 'BMOrderRelayx64.dll';
function SetDeliveryCompleted(AOrderNo: PWideChar): Boolean; stdcall; external 'BMOrderRelayx64.dll';
function UpdateDeliveryStatus(AOrderNo: PWideChar; ADeliveryStatus: Integer;
  ARiderKey: PWideChar; ARiderName: PWideChar; ETA: Integer): Boolean; stdcall; external 'BMOrderRelayx64.dll';
{$ELSE}
function IsBaeminInstalled(): Boolean; stdcall; external 'BMOrderRelay.dll';
function IsBaeminRunning(): Boolean; stdcall; external 'BMOrderRelay.dll';
function RegisterNewDeliveryFunction(AEvent: TOnNewDeliveryFunc): Boolean; stdcall; external 'BMOrderRelay.dll';
function RegisterStatusChangedFunction(AEvent: TOnStatusChangedProc): Boolean; stdcall; external 'BMOrderRelay.dll';
function RegisterDisconnectedFunction(AEvent: TOnDisconnectedProc): Boolean; stdcall; external 'BMOrderRelay.dll';
function InitializeService(ASignKey: PWideChar): Integer; stdcall; external 'BMOrderRelay.dll';
function FinalizeService(): Integer; stdcall; external 'BMOrderRelay.dll';
function SetDeliveryCompleted(AOrderNo: PWideChar): Boolean; stdcall; external 'BMOrderRelay.dll';
function UpdateDeliveryStatus(AOrderNo: PWideChar; ADeliveryStatus: Integer;
  ARiderKey: PWideChar; ARiderName: PWideChar; ETA: Integer): Boolean; stdcall; external 'BMOrderRelay.dll';
{$ENDIF}

{ TFrmBaminOrderRelationMain }

procedure TFrmBaminOrderRelationMain.btnFinalizeServiceClick(Sender: TObject);
begin
  if FinalizeService <> S_OK then
    ShowMessage('Error FinalizeService');
  Memo1.Lines.Add('Finalize Service');
end;

procedure TFrmBaminOrderRelationMain.btnInitializeServiceClick(Sender: TObject);
begin
  //if InitializeService(PChar('Test Mode Gear')) <> S_OK then
  if InitializeService(PChar('hJTk2rWrfc6C1UEmk9Uvc2MGpUuOpEw3q8i1/4+EUcFObqlNhzCvVHFM')) <> S_OK then
    ShowMessage('Error InitializeService');
  Memo1.Lines.Add('Initialize Service');
end;

procedure TFrmBaminOrderRelationMain.btnRegCallbackClick(Sender: TObject);
begin
  if not RegisterNewDeliveryFunction(OnNewDeliveryFunc) then
    ShowMessage('Error RegisterNewDeliveryFunction!');
  if not RegisterStatusChangedFunction(OnStatusChangedProc) then
    ShowMessage('Error RegisterStatusChangedFunction!');    
  if not RegisterDisconnectedFunction(OnDisconnectedProc) then 
    ShowMessage('Error RegisterDisconnectedFunction');
  Memo1.Lines.Add('Register Callback Functions');
end;

procedure TFrmBaminOrderRelationMain.btnSetDeliveryCompletedClick(Sender: TObject);
var
  Item : TListItem;
  ItemData : PDeliveryItem;
begin
  Item := ListView1.Selected;
  if Item = nil then Exit;
  ItemData := PDeliveryItem(Item.Data);
  if ItemData = nil then Exit;
  if SetDeliveryCompleted( PWideChar(ItemData.OrderNo)) then
  begin
    Dispose(ItemData);
    ListView1.Items.Delete(Item.Index);
  end;
end;

procedure TFrmBaminOrderRelationMain.btnChangeRiderStatusClick(Sender: TObject);
var
  Item : TListItem;
  ItemData : PDeliveryItem;
begin
  Item := ListView1.Selected;
  if Item = nil then Exit;
  ItemData := PDeliveryItem(Item.Data);
  if ItemData = nil then Exit;

  FrmChangeDeliveryStatus.edOrderNo.Text := ItemData.OrderNo;
  if FrmChangeDeliveryStatus.ShowModal = mrOk then
  begin
    with FrmChangeDeliveryStatus do
    begin
      UpdateDeliveryStatus(PWideChar(ItemData.OrderNo), rgDeliveryStatus.ItemIndex, PWideChar(edRiderCode.Text), PWideChar(edRiderName.Text), seETA.Value);
    end;
  end;
end;

procedure TFrmBaminOrderRelationMain.FormShow(Sender: TObject);
begin
  if IsBaeminInstalled() then
    Memo1.Lines.Add('PC������ ��ġ�Ǿ����ϴ�.');
end;

procedure TFrmBaminOrderRelationMain.ListView1Click(Sender: TObject);
begin
  btnSetDeliveryCompleted.Enabled := (ListView1.Selected <> nil);
  btnChangeRiderStatus.Enabled := (ListView1.Selected <> nil);
end;

function OnNewDeliveryFunc(AOrderNo, ARoadNameAddress, AAddress, AAddressDetail, APhoneNo: PWideChar;
  ALatitude, ALongitude: PWideChar; ATitle: PWideChar; AQuantity: Integer; AAmount, APaymentType: Integer;
  AMemo: PWideChar): Boolean;
var
  Res : Boolean;
begin
  Res := False;
  TThread.Synchronize(nil, TThreadProcedure(
  procedure
  var
    frmNew: TFrmCreateDelivery;
    ItemData: PDeliveryItem;
    Item : TListItem;
  begin
    with FrmBaminOrderRelationMain do
    begin
      Memo1.Lines.Add('=====================================================================');
      Memo1.Lines.Add('OrderNo: ' + AOrderNo);
      Memo1.Lines.Add('Road Name Address: ' + ARoadNameAddress + ' ' + AAddressDetail);
      Memo1.Lines.Add('Address: ' + AAddress + ' ' + AAddressDetail);
      Memo1.Lines.Add('PhoneNo: ' + APhoneNo);
      Memo1.Lines.Add('Latitude: ' + ALatitude);
      Memo1.Lines.Add('Longitude: ' + ALongitude);
      if AQuantity > 1 then
        Memo1.Lines.Add(ATitle + Format(' �� %d��', [AQuantity-1]))
      else
        Memo1.Lines.Add(ATitle);
      Memo1.Lines.Add('AAmount: ' + FormatFloat('#,##0', AAmount));
      case APaymentType of
        PT_PREPAYED: Memo1.Lines.Add('Payment Type: �ٷΰ���');
        PT_MEET_CARD: Memo1.Lines.Add('Payment Type: ������ ���� ī��');
        PT_MEET_CASH: Memo1.Lines.Add('Payment Type: ������ ���� ����');
      end;
      if AMemo <> '' then
        Memo1.Lines.Add('Memo: ' + AMemo);
    end;
    frmNew := TFrmCreateDelivery.Create(FrmBaminOrderRelationMain);
    try
      frmNew.edOrderNo.Text := AOrderNo;
      frmNew.edRoadNameAddress.Text := ARoadNameAddress;
      frmNew.edAddress.Text := AAddress;
      frmNew.edAddressDetail.Text := AAddressDetail;
      frmNew.edPhoneNo.Text := APhoneNo;
      frmNew.edLatitude.Text := ALatitude;
      frmNew.edLongitude.Text := ALongitude;
      frmNew.edTitle.Text := ATitle;
      frmNew.edAmount.Text := FormatFloat('#,##0', AAmount);
      frmNew.edQuantity.Text := IntToStr(AQuantity);
      frmNew.rgPaymentType.ItemIndex := APaymentType;
      if frmNew.ShowModal = mrOk then
      begin
        New(ItemData);
        ItemData.OrderNo        := AOrderNo;
        ItemData.RoadName       := frmNew.edRoadNameAddress.Text;
        ItemData.Address        := frmNew.edAddress.Text;
        ItemData.AddressDetail  := frmNew.edAddressDetail.Text;
        ItemData.PhoneNo        := frmNew.edPhoneNo.Text;
        ItemData.Latitude       := frmNew.edLatitude.Text;
        ItemData.Longitude      := frmNew.edLongitude.Text;
        ItemData.Amount         := AAmount;
        ItemData.Quantity       := AQuantity;
        ItemData.PaymentType    := frmNew.rgPaymentType.ItemIndex;
        Item := FrmBaminOrderRelationMain.ListView1.Items.Add;
        Item.Caption := ItemData.OrderNo;
        Item.SubItems.Add(ItemData.RoadName + ' ' + ItemData.AddressDetail);
        Item.SubItems.Add(Format('%s, %s', [ItemData.Latitude, ItemData.Longitude]));
        case frmNew.rgPaymentType.ItemIndex of
          PT_PREPAYED: Item.SubItems.Add('�ٷΰ���');
          PT_MEET_CARD: Item.SubItems.Add('������ ���� ī��');
          PT_MEET_CASH: Item.SubItems.Add('������ ���� ����');
        end;
        Item.Data := ItemData;
        Res := True;
      end;
    finally
      frmNew.Free;
    end;
  end));
  Result := Res;
end;

procedure OnStatusChangedProc(AOrderNo: PWideChar; AOrderStatus: Integer);

begin
  TThread.Synchronize(nil, TThreadProcedure(
  procedure
  var
    I: Integer;
    ItemData: PDeliveryItem;
  begin
    if AOrderStatus = OS_COMPLETED then
    begin
      with FrmBaminOrderRelationMain do
      begin
        for I := ListView1.Items.Count-1 downto 0 do
        begin
          ItemData := PDeliveryItem(ListView1.Items[I].Data);
          if ItemData.OrderNo = AOrderNo then
          begin
            Dispose(ItemData);
            ListView1.Items.Delete(I);
          end;
        end;
      end;
    end;
  end));
end;

procedure OnDisconnectedProc();
begin
  TThread.Synchronize(nil, TThreadProcedure(
  procedure
  begin
    with FrmBaminOrderRelationMain do
    begin
      Memo1.Lines.Add('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
      Memo1.Lines.Add('Disconnected!!!');
    end;
  end));
end;



end.
