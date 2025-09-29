page 50073 "SPN Perfion Image Viewer"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Perfion Image Viewer';
    SourceTable = Integer;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Product)
            {
                field(ItemNo; ItemNo)
                {
                    ApplicationArea = All;
                    Caption = 'Item No.';
                    ToolTip = 'Enter the item number to retrieve images from Perfion.';
                }
            }
            group(Images)
            {
                field(Image1Url; Image1Url) { ApplicationArea = All; Caption = 'Image 1 URL'; Editable = false; }
                field(Image2Url; Image2Url) { ApplicationArea = All; Caption = 'Image 2 URL'; Editable = false; }
                field(Image3Url; Image3Url) { ApplicationArea = All; Caption = 'Image 3 URL'; Editable = false; }
                field(Image4Url; Image4Url) { ApplicationArea = All; Caption = 'Image 4 URL'; Editable = false; }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(LoadImages)
            {
                ApplicationArea = All;
                Caption = 'Load Images';
                trigger OnAction()
                begin
                    LoadImageURLs();
                    CurrPage.Update();
                end;
            }
        }
    }

    var
        ItemNo: Code[20];
        Image1Url: Text[250];
        Image2Url: Text[250];
        Image3Url: Text[250];
        Image4Url: Text[250];

    local procedure LoadImageURLs()
    var
        PIM: Codeunit "PIMimages";
        RawXml: Text;
        EncodedXml: Text;
        DecodedXml: Text;
        Guid: Text;
    begin
        Clear(Image1Url); Clear(Image2Url); Clear(Image3Url); Clear(Image4Url);
        if ItemNo = '' then
            exit;

        // 1) Hent Perfion-data
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
                '<Where><Clause id="Varenummer" operator="Match" value="' + ItemNo + '"/></Where>' +
            '</Query>'
        );

        // 2) Træk den indlejrede XML ud af <ExecuteQueryResult>...</ExecuteQueryResult>
        EncodedXml := ExtractBetween(RawXml, '<ExecuteQueryResult>', '</ExecuteQueryResult>');
        if EncodedXml = '' then
            exit;

        // 3) HTML-decode (&lt; &gt; &amp;)
        DecodedXml := HtmlDecode(EncodedXml);

        // 4) Hent GUID’erne (robust: skipper self-closing feature-tags)
        Guid := GetElementInnerText(DecodedXml, 'Produktbillede1');
        if StrLen(Guid) = 36 then
            Image1Url := PIM.formatGUIDtoURL(Guid, 250, 250);

        Guid := GetElementInnerText(DecodedXml, 'Produktbillede2');
        if StrLen(Guid) = 36 then
            Image2Url := PIM.formatGUIDtoURL(Guid, 250, 250);

        Guid := GetElementInnerText(DecodedXml, 'Produktbillede3');
        if StrLen(Guid) = 36 then
            Image3Url := PIM.formatGUIDtoURL(Guid, 250, 250);

        Guid := GetElementInnerText(DecodedXml, 'Produktbillede4');
        if StrLen(Guid) = 36 then
            Image4Url := PIM.formatGUIDtoURL(Guid, 250, 250);
    end;

    /// Returns inner text for the first *non self-closing* <TagName ...> ... </TagName>
    /// Works without Xml* types. Safe for attributes on start tag.
    local procedure GetElementInnerText(Xml: Text; TagName: Text): Text
    var
        Search: Text;
        StartTagPrefix: Text;
        CloseTag: Text;
        pStart: Integer;
        subAfterStart: Text;
        pGT: Integer;
        charBeforeGT: Text[1];
        contentStartPos: Integer;
        restAfterOpen: Text;
        pClose: Integer;
        len: Integer;
    begin
        Search := Xml;
        StartTagPrefix := '<' + TagName;       // matches both <TagName> and <TagName ...>
        CloseTag := '</' + TagName + '>';

        while true do begin
            pStart := StrPos(Search, StartTagPrefix);
            if pStart = 0 then
                exit(''); // not found

            // from the found '<TagName', find the next '>'
            subAfterStart := CopyStr(Search, pStart, StrLen(Search) - pStart + 1);
            pGT := StrPos(subAfterStart, '>');
            if pGT = 0 then
                exit('');

            // check if it was a self-closing tag: ends with "/>"
            charBeforeGT := CopyStr(subAfterStart, pGT - 1, 1);
            if charBeforeGT = '/' then begin
                // skip this self-closing tag and continue searching
                Search := DelStr(Search, 1, pStart + pGT - 1);
                //continue;
            end;

            // we have an opening tag with content:
            contentStartPos := pStart + pGT - 1; // absolute position (in Search) of '>'
            restAfterOpen := CopyStr(Search, contentStartPos + 1, StrLen(Search) - contentStartPos);
            pClose := StrPos(restAfterOpen, CloseTag);
            if pClose = 0 then
                exit('');

            // inner text = chars between '>' and start of '</TagName>'
            len := pClose - 1; // exclude the '<' of closing tag
            exit(CopyStr(Search, contentStartPos + 1, len));
        end;
    end;

    /// HTML-decode (&lt; &gt; &amp;) using only core Text functions.
    local procedure HtmlDecode(Value: Text): Text
    begin
        Value := ReplaceAll(Value, '&lt;', '<');
        Value := ReplaceAll(Value, '&gt;', '>');
        // decode &amp; last to avoid breaking other entities mid-way
        Value := ReplaceAll(Value, '&amp;', '&');
        exit(Value);
    end;

    /// Replace all occurrences of FindWhat with ReplaceWith (no Text.Replace / ReplaceStr needed).
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

    /// Extracts substring between first occurrence of StartTag and EndTag (inclusive tags not returned).
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
        // p2 is relative to substring; convert to absolute by adding (startAfter - 1)
        p2 := startAfter + p2 - 1;
        len := p2 - startAfter;
        exit(CopyStr(S, startAfter, len));
    end;
}
