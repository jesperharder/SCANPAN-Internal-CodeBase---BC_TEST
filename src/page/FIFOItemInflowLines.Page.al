


// Underliste: alle åbne vareposteringer med resterende antal (>0) i FIFO-rækkefølge
page 50072 "FIFO Item Inflow Lines"
{
    PageType = ListPart;
    //ApplicationArea = All;
    SourceTable = "Item Ledger Entry";
    SourceTableView =
        SORTING("Posting Date", "Entry No.") ORDER(Ascending)
        WHERE("Remaining Quantity" = FILTER(> 0));

    layout
    {
        area(content)
        {
            repeater(Entries)
            {
                field("Posting Date"; "Posting Date")
                {
                    ToolTip = 'Specifies the value of the Posting Date field.';
                }
                field("Entry No."; "Entry No.")
                {
                    ToolTip = 'Specifies the value of the Entry No. field.';
                }
                field("Entry Type"; "Entry Type")
                {
                    ToolTip = 'Specifies the value of the Entry Type field.';
                }
                field("Document No."; "Document No.")
                {
                    ToolTip = 'Specifies the value of the Document No. field.';
                }
                field("Quantity"; Quantity)
                {
                    ToolTip = 'Specifies the value of the Quantity field.';
                }
                field("Remaining Quantity"; "Remaining Quantity")
                {
                    ToolTip = 'Specifies the value of the Remaining Quantity field.';
                }
                field("Location Code"; "Location Code")
                {
                    ToolTip = 'Specifies the value of the Location Code field.';
                }
                field("All Bin Codes"; AllBinCodes)
                {
                    Caption = 'All Bin Codes';
                    ApplicationArea = All;
                    ToolTip = 'Lists all bin codes with contents for this item and location.';
                }
            }
        }
    }
    var
        BinContent: Record "Bin Content";
        AllBinCodes: Text[250]; // You may need a longer length if many bins

    trigger OnAfterGetRecord()
    begin
        AllBinCodes := '';
        BinContent.Reset();
        BinContent.SetRange("Location Code", Rec."Location Code");
        BinContent.SetRange("Item No.", Rec."Item No.");
        //BinContent.SetRange("Variant Code", Rec."Variant Code");
        if BinContent.FindSet() then
            repeat
                if BinContent.Quantity <> 0 then begin
                    if AllBinCodes <> '' then
                        AllBinCodes += ', ';
                    //AllBinCodes += BinContent."Bin Code";
                    AllBinCodes += BinContent."Bin Code" + ' (' + Format(BinContent.Quantity) + ')';

                end;
            until BinContent.Next() = 0;
    end;

    procedure SetFilters(Location: Code[20])
    begin
        if Location <> '' then
            Rec.SetRange("Location Code", Location)
        else
            Rec.SetRange("Location Code");

        CurrPage.Update(false);
    end;
}


