page 50073 "SPN Perfion Image Viewer"
{
    ApplicationArea = All;
    Caption = 'Perfion Image Viewer';
    PageType = Card;
    SourceTable = "SPN Perfion Store";
    SourceTableTemporary = true;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Identification)
            {
                Caption = 'Product';
                field("Item No."; "Item No.")
                {
                    ApplicationArea = All;
                    Editable = true;
                    ToolTip = 'Enter or select the item number to retrieve images from Perfion.';

                    trigger OnValidate()
                    begin
                        LoadImagesForCurrentItem();
                        CurrPage.Update(false);
                    end;
                }
            }

            group(ImageGrid)
            {
                ShowCaption = false;

                group(Row1)
                {
                    ShowCaption = false;
                    field(Image1; Image1)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Editable = false;
                    }
                    field(Image2; Image2)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Editable = false;
                    }
                }

                group(Row2)
                {
                    ShowCaption = false;
                    field(Image3; Image3)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Editable = false;
                    }
                    field(Image4; Image4)
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Editable = false;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ResetSearch)
            {
                ApplicationArea = All;
                Caption = 'Clear';
                Image = Clear;
                ToolTip = 'Clear the current item number and remove the downloaded images.';

                trigger OnAction()
                begin
                    ResetCurrentRecord();
                    CurrPage.Update(false);
                end;
            }

            action(RefreshImages)
            {
                ApplicationArea = All;
                Caption = 'Load Images';
                Image = Refresh;
                ToolTip = 'Download the four latest images from Perfion for the current item.';

                trigger OnAction()
                begin
                    LoadImagesForCurrentItem();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        PerfionHelper: Codeunit "SPN Perfion Image Helper";

    trigger OnOpenPage()
    begin
        ResetCurrentRecord();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Rec.CalcFields(Image1, Image2, Image3, Image4);
    end;

    local procedure ResetCurrentRecord()
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Insert();
    end;

    local procedure LoadImagesForCurrentItem()
    var
        PerfionImages: Codeunit "PIMimages";
        ResponseXml: Text;
        EncodedResult: Text;
        PlainXml: Text;
        ImageGuid: Text;
        ImageUrl: Text;
        StreamIn: InStream;
        Index: Integer;
    begin
        ClearImageMedia();

        if Rec."Item No." = '' then begin
            Rec.Modify(true);
            exit;
        end;

        ResponseXml := PerfionImages.MakeRequest(
            'http://cdn.scanpan.dk/Perfion/GetData.asmx',
            BuildQueryPayload(Rec."Item No."));

        EncodedResult := ExtractBetween(ResponseXml, '<ExecuteQueryResult>', '</ExecuteQueryResult>');
        if EncodedResult = '' then begin
            Rec.Modify(true);
            exit;
        end;

        PlainXml := HtmlDecode(EncodedResult);

        for Index := 1 to 4 do begin
            ImageGuid := GetElementInnerText(PlainXml, 'Produktbillede' + Format(Index));
            if IsValidGuid(ImageGuid) then begin
                ImageUrl := PerfionImages.formatGUIDtoURL(ImageGuid, 600, 600);
                if PerfionHelper.DownloadImageAsStream(ImageUrl, StreamIn) then
                    ImportImage(Index, StreamIn);
            end;
        end;

        Rec.Modify(true);
    end;

    local procedure ClearImageMedia()
    begin
        Clear(Rec.Image1);
        Clear(Rec.Image2);
        Clear(Rec.Image3);
        Clear(Rec.Image4);
    end;

    local procedure ImportImage(ImageIndex: Integer; var SourceStream: InStream)
    begin
        case ImageIndex of
            1:
                Rec.Image1.ImportStream(SourceStream, 'Image1', 'image/jpeg', 'jpg');
            2:
                Rec.Image2.ImportStream(SourceStream, 'Image2', 'image/jpeg', 'jpg');
            3:
                Rec.Image3.ImportStream(SourceStream, 'Image3', 'image/jpeg', 'jpg');
            4:
                Rec.Image4.ImportStream(SourceStream, 'Image4', 'image/jpeg', 'jpg');
        end;
    end;

    local procedure BuildQueryPayload(ItemNo: Code[20]): Text
    begin
        exit(
            '<Query>' +
                '<Select languages="EN">' +
                    '<Feature id="Produktbillede1" />' +
                    '<Feature id="Produktbillede2" />' +
                    '<Feature id="Produktbillede3" />' +
                    '<Feature id="Produktbillede4" />' +
                '</Select>' +
                '<From id="Product" />' +
                '<Where><Clause id="Varenummer" operator="Match" value="' + ItemNo + '"/></Where>' +
            '</Query>');
    end;

    local procedure HtmlDecode(Value: Text): Text
    begin
        Value := ReplaceAll(Value, '&lt;', '<');
        Value := ReplaceAll(Value, '&gt;', '>');
        Value := ReplaceAll(Value, '&amp;', '&');
        exit(Value);
    end;

    local procedure ReplaceAll(Input: Text; FindWhat: Text; ReplaceWith: Text): Text
    var
        Result: Text;
        Position: Integer;
        PatternLength: Integer;
        RemainingLength: Integer;
    begin
        Result := Input;
        PatternLength := StrLen(FindWhat);

        if (PatternLength = 0) or (Result = '') then
            exit(Result);

        Position := StrPos(Result, FindWhat);
        while Position > 0 do begin
            RemainingLength := StrLen(Result) - (Position + PatternLength) + 1;
            Result := CopyStr(Result, 1, Position - 1) + ReplaceWith + CopyStr(Result, Position + PatternLength, RemainingLength);
            Position := StrPos(Result, FindWhat);
        end;

        exit(Result);
    end;

    local procedure ExtractBetween(Source: Text; StartTag: Text; EndTag: Text): Text
    var
        StartPos: Integer;
        EndPos: Integer;
        StartAfter: Integer;
        ContentLength: Integer;
    begin
        StartPos := StrPos(Source, StartTag);
        if StartPos = 0 then
            exit('');

        StartAfter := StartPos + StrLen(StartTag);
        EndPos := StrPos(CopyStr(Source, StartAfter, StrLen(Source) - StartAfter + 1), EndTag);
        if EndPos = 0 then
            exit('');

        EndPos := StartAfter + EndPos - 1;
        ContentLength := EndPos - StartAfter;
        exit(CopyStr(Source, StartAfter, ContentLength));
    end;

    local procedure GetElementInnerText(Xml: Text; TagName: Text): Text
    var
        StartTagPrefix: Text;
        CloseTag: Text;
        StartPos: Integer;
        AfterStart: Text;
        ClosingIndex: Integer;
        ClosePos: Integer;
    begin
        StartTagPrefix := '<' + TagName;
        CloseTag := '</' + TagName + '>';

        StartPos := StrPos(Xml, StartTagPrefix);
        if StartPos = 0 then
            exit('');

        AfterStart := CopyStr(Xml, StartPos, StrLen(Xml) - StartPos + 1);
        ClosingIndex := StrPos(AfterStart, '>');
        if ClosingIndex = 0 then
            exit('');

        AfterStart := CopyStr(Xml, StartPos + ClosingIndex, StrLen(Xml) - (StartPos + ClosingIndex) + 1);
        ClosePos := StrPos(AfterStart, CloseTag);
        if ClosePos = 0 then
            exit('');

        exit(CopyStr(AfterStart, 1, ClosePos - 1));
    end;

    local procedure IsValidGuid(Value: Text): Boolean
    begin
        exit(StrLen(Value) = 36);
    end;
}