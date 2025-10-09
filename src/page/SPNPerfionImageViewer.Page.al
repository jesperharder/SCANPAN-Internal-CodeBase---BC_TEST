page 50073 "SPN Perfion Image Viewer"
{
    PageType = Card;
    SourceTable = "SPN Perfion Store"; // <-- Tilføj denne linje
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Perfion Image Viewer';

    layout
    {
        area(content)
        {
            group(Product)
            {
                field("Item No."; "Item No.")
                {
                    ApplicationArea = All;
                    Editable = true;
                    ToolTip = 'Enter the item number to retrieve images from Perfion.';
                }
            }

            group(Images)
            {
                group(Row1)
                {
                    field(Image1; Image1) { ApplicationArea = All; ShowCaption = false; }
                    field(Image2; Image2) { ApplicationArea = All; ShowCaption = false; }
                }
                group(Row2)
                {
                    field(Image3; Image3) { ApplicationArea = All; ShowCaption = false; }
                    field(Image4; Image4) { ApplicationArea = All; ShowCaption = false; }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(NewSearch)
            {
                ApplicationArea = All;
                Caption = 'Nyt søgning';
                trigger OnAction()
                begin
                    Rec.DeleteAll();
                    Rec.Init();
                    Rec.Insert();
                    CurrPage.Update();
                end;
            }
            action(LoadImages)
            {
                ApplicationArea = All;
                Caption = 'Load Images';
                trigger OnAction()
                begin
                    LoadImageURLs(Rec);
                    CurrPage.Update();
                end;
            }
        }
    }

    var
        Helper: Codeunit "SPN Perfion Image Helper";

    local procedure LoadImageURLs(var Rec: Record "SPN Perfion Store")
    var
        PIM: Codeunit "PIMimages";
        RawXml: Text;
        EncodedXml: Text;
        DecodedXml: Text;
        Guid: Text;
        Url: Text;
        I: Integer;
        InStr: InStream;
    begin
        // Nulstil billeder
        Clear(Rec.Image1);
        Clear(Rec.Image2);
        Clear(Rec.Image3);
        Clear(Rec.Image4);

        if Rec."Item No." = '' then
            exit;

        // Kald til Perfion
        RawXml := PIM.MakeRequest(
            'http://cdn.scanpan.dk/Perfion/GetData.asmx',
            '<Query>' +
                '<Select languages="EN">' +
                    '<Feature id="Produktbillede1" />' +
                    '<Feature id="Produktbillede2" />' +
                    '<Feature id="Produktbillede3" />' +
                    '<Feature id="Produktbillede4" />' +
                '</Select>' +
                '<From id="Product" />' +
                '<Where><Clause id="Varenummer" operator="Match" value="' + Rec."Item No." + '"/></Where>' +
            '</Query>'
        );

        // Træk ExecuteQueryResult
        EncodedXml := ExtractBetween(RawXml, '<ExecuteQueryResult>', '</ExecuteQueryResult>');
        if EncodedXml = '' then
            exit;

        // Decode HTML
        DecodedXml := HtmlDecode(EncodedXml);

        for I := 1 to 4 do begin
            Guid := GetElementInnerText(DecodedXml, 'Produktbillede' + Format(I));
            if StrLen(Guid) = 36 then begin
                Url := PIM.formatGUIDtoURL(Guid, 600, 600);
                if Helper.DownloadImageAsStream(Url, InStr) then begin
                    case I of
                        1: Rec.Image1.ImportStream(InStr, 'Image1', 'image/jpeg', 'jpg');
                        2: Rec.Image2.ImportStream(InStr, 'Image2', 'image/jpeg', 'jpg');
                        3: Rec.Image3.ImportStream(InStr, 'Image3', 'image/jpeg', 'jpg');
                        4: Rec.Image4.ImportStream(InStr, 'Image4', 'image/jpeg', 'jpg');
                    end;
                end else begin
                    Message('Kunne ikke hente billede fra %1', Url);
                end;
            end;
        end;
    end;

    /// HTML decode
    local procedure HtmlDecode(Value: Text): Text
    begin
        Value := ReplaceAll(Value, '&lt;', '<');
        Value := ReplaceAll(Value, '&gt;', '>');
        Value := ReplaceAll(Value, '&amp;', '&');
        exit(Value);
    end;

    /// ReplaceAll helper
    local procedure ReplaceAll(Input: Text; FindWhat: Text; ReplaceWith: Text): Text
    var
        R: Text;
        p: Integer;
        L: Integer;
        RightLen: Integer;
    begin
        R := Input;
        L := StrLen(FindWhat);
        if (L = 0) or (R = '') then
            exit(R);

        p := StrPos(R, FindWhat);
        while p > 0 do begin
            RightLen := StrLen(R) - (p + L) + 1;
            R := CopyStr(R, 1, p - 1) + ReplaceWith + CopyStr(R, p + L, RightLen);
            p := StrPos(R, FindWhat);
        end;
        exit(R);
    end;

    /// Extract text between tags
    local procedure ExtractBetween(S: Text; StartTag: Text; EndTag: Text): Text
    var
        p1: Integer;
        p2: Integer;
        startAfter: Integer;
        len: Integer;
    begin
        p1 := StrPos(S, StartTag);
        if p1 = 0 then
            exit('');
        startAfter := p1 + StrLen(StartTag);
        p2 := StrPos(CopyStr(S, startAfter, StrLen(S) - startAfter + 1), EndTag);
        if p2 = 0 then
            exit('');
        p2 := startAfter + p2 - 1;
        len := p2 - startAfter;
        exit(CopyStr(S, startAfter, len));
    end;

    /// Get inner text of first element <TagName>...</TagName>
    local procedure GetElementInnerText(Xml: Text; TagName: Text): Text
    var
        Search: Text;
        StartTagPrefix: Text;
        CloseTag: Text;
        pStart: Integer;
        subAfterStart: Text;
        pGT: Integer;
        contentStartPos: Integer;
        restAfterOpen: Text;
        pClose: Integer;
        len: Integer;
    begin
        Search := Xml;
        StartTagPrefix := '<' + TagName;
        CloseTag := '</' + TagName + '>';

        pStart := StrPos(Search, StartTagPrefix);
        if pStart = 0 then
            exit('');

        subAfterStart := CopyStr(Search, pStart, StrLen(Search) - pStart + 1);
        pGT := StrPos(subAfterStart, '>');
        if pGT = 0 then
            exit('');

        contentStartPos := pStart + pGT - 1;
        restAfterOpen := CopyStr(Search, contentStartPos + 1, StrLen(Search) - contentStartPos);
        pClose := StrPos(restAfterOpen, CloseTag);
        if pClose = 0 then
            exit('');

        len := pClose - 1;
        exit(CopyStr(Search, contentStartPos + 1, len));
    end;

    trigger OnOpenPage()
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Insert();
    end;
}
