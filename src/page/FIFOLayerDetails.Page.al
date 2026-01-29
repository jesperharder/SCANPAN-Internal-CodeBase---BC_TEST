///<summary>
/// 2025.11             Jesper Harder       117.1       Created new page for viewing bin content FIFO information, including oldest entry date, average age in days, and number of FIFO layers.
///</summary>

page 50056 "FIFO Layer Details"
{
    PageType = List;
    //ApplicationArea = All;
    SourceTable = "Item Ledger Entry";
    Caption = 'FIFO Layer Details';
    AdditionalSearchTerms = 'SCANPAN, FIFO Layer Detail, FIFO Layers. FIFO Layer, Detail';
    Editable = false;
    SourceTableView = where("Remaining Quantity" = filter(> 0));

    layout
    {
        area(Content)
        {
            group(HeaderInfo)
            {
                Caption = 'Bin Information';

                field(LocationCodeHeader; LocationCode)
                {
                    ApplicationArea = All;
                    Caption = 'Location';
                    Editable = false;
                    Style = Strong;
                }
                /*
                                field(BinCodeHeader; BinCode)
                                {
                                    ApplicationArea = All;
                                    Caption = 'Bin';
                                    Editable = false;
                                    Style = Strong;
                                }
                */
                field(ItemNoHeader; ItemNo)
                {
                    ApplicationArea = All;
                    Caption = 'Item No.';
                    Editable = false;
                    Style = Strong;
                }
                field(TotalRemainingQty; TotalRemaining)
                {
                    ApplicationArea = All;
                    Caption = 'Total Remaining Qty';
                    Editable = false;
                    Style = Favorable;
                    StyleExpr = true;
                }
            }
            repeater(FIFOLayers)
            {
                Caption = 'FIFO Layers (Oldest First)';

                field("Layer No."; LayerNo)
                {
                    ApplicationArea = All;
                    Caption = 'Layer';
                    ToolTip = 'FIFO layer number (1 = oldest)';
                }
                field("Actual Bin Code"; ActualBinCode)
                {
                    ApplicationArea = All;
                    Caption = 'Faktisk placering';
                    ToolTip = 'Angiver den placering hvor dette FIFO-lag faktisk befinder sig.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Date of original receipt';
                    Style = Attention;
                }

                field("Bin Entry Date"; BinEntryDate)
                {
                    ApplicationArea = All;
                    Caption = 'Placeret i boks';
                    ToolTip = 'Specifies the date when this inventory entry was placed in this specific bin.';
                    Style = Subordinate;
                }

                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = All;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = All;
                    Style = Favorable;
                    ToolTip = 'Remaining quantity in this FIFO layer';
                }
                field("Invoiced Quantity"; Rec."Invoiced Quantity")
                {
                    ApplicationArea = All;
                }
                field("Cost Amount (Actual)"; Rec."Cost Amount (Actual)")
                {
                    ApplicationArea = All;
                }
                field("Unit Cost"; UnitCost)
                {
                    ApplicationArea = All;
                    Caption = 'Unit Cost';
                    DecimalPlaces = 2 : 5;
                    ToolTip = 'Unit cost for this layer';
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Age Days"; AgeDays)
                {
                    ApplicationArea = All;
                    Caption = 'Age (Days)';
                    StyleExpr = AgeStyle;
                }
                field("Cumulative Qty"; CumulativeQty)
                {
                    ApplicationArea = All;
                    Caption = 'Cumulative Qty';
                    ToolTip = 'Running total of remaining quantity (FIFO order)';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowItemLedgerEntry)
            {
                ApplicationArea = All;
                Caption = 'Show Entry';
                Image = EntriesList;

                trigger OnAction()
                var
                    ItemLedgerEntry: Record "Item Ledger Entry";
                begin
                    ItemLedgerEntry.Get(Rec."Entry No.");
                    Page.Run(Page::"Item Ledger Entries", ItemLedgerEntry);
                end;
            }
            action(ShowBinContent)
            {
                ApplicationArea = Warehouse;
                Caption = 'Show Bin Content';
                Image = Bin;

                trigger OnAction()
                var
                    BinContent: Record "Bin Content";
                begin
                    BinContent.SetRange("Item No.", ItemNo);
                    BinContent.SetRange("Location Code", LocationCode);
                    BinContent.SetRange("Bin Code", BinCode);
                    Page.Run(Page::"Bin Contents List", BinContent);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        // Ensure FIFO sorting
        Rec.SetCurrentKey("Item No.", "Location Code", "Open", "Variant Code", "Unit of Measure Code", "Posting Date");
        CalculateTotalRemaining();
    end;

    trigger OnAfterGetRecord()
    begin
        LayerNo += 1;
        CalculateUnitCost();
        CalculateAge();
        CalculateActualBinCode();
        CalculateBinEntryDate();
        CalculateCumulative();
        SetAgeStyle();
    end;

    local procedure CalculateTotalRemaining()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        TotalRemaining := 0;
        ItemLedgerEntry.CopyFilters(Rec);
        if ItemLedgerEntry.FindSet() then
            repeat
                TotalRemaining += ItemLedgerEntry."Remaining Quantity";
            until ItemLedgerEntry.Next() = 0;
    end;

    local procedure CalculateUnitCost()
    begin
        if Rec."Remaining Quantity" <> 0 then
            UnitCost := Rec."Cost Amount (Actual)" / Rec."Remaining Quantity"
        else
            UnitCost := 0;
    end;

    local procedure CalculateAge()
    begin
        AgeDays := Today - Rec."Posting Date";
    end;

    local procedure CalculateCumulative()
    begin
        CumulativeQty += Rec."Remaining Quantity";
    end;

    local procedure SetAgeStyle()
    begin
        case true of
            AgeDays > 180:
                AgeStyle := 'Unfavorable';
            AgeDays > 90:
                AgeStyle := 'Attention';
            else
                AgeStyle := 'Favorable';
        end;
    end;

    procedure SetBinInfo(NewLocationCode: Code[10]; NewBinCode: Code[20]; NewItemNo: Code[20])
    begin
        LocationCode := NewLocationCode;
        BinCode := NewBinCode;
        ItemNo := NewItemNo;
    end;

    local procedure CalculateBinEntryDate()
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        Clear(BinEntryDate);

        // Find warehouse entries for this item in this bin
        WarehouseEntry.SetCurrentKey("Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.");
        WarehouseEntry.SetRange("Item No.", Rec."Item No.");
        WarehouseEntry.SetRange("Bin Code", BinCode);
        WarehouseEntry.SetRange("Location Code", LocationCode);

        // If item tracking is used, filter by Lot/Serial to get the specific layer
        if Rec."Lot No." <> '' then
            WarehouseEntry.SetRange("Lot No.", Rec."Lot No.");
        if Rec."Serial No." <> '' then
            WarehouseEntry.SetRange("Serial No.", Rec."Serial No.");

        // Get entries with positive quantity (items placed in bin)
        WarehouseEntry.SetFilter(Quantity, '>0');

        // Find the first (oldest) entry
        if WarehouseEntry.FindFirst() then
            BinEntryDate := WarehouseEntry."Registering Date";
    end;

    local procedure CalculateActualBinCode()
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        Clear(ActualBinCode);

        WarehouseEntry.SetCurrentKey("Item No.", "Location Code", "Lot No.", "Serial No.");
        WarehouseEntry.SetRange("Item No.", Rec."Item No.");
        WarehouseEntry.SetRange("Location Code", LocationCode);

        if Rec."Lot No." <> '' then
            WarehouseEntry.SetRange("Lot No.", Rec."Lot No.");
        if Rec."Serial No." <> '' then
            WarehouseEntry.SetRange("Serial No.", Rec."Serial No.");

        WarehouseEntry.SetRange("Registering Date", Rec."Posting Date", CalcDate('<+30D>', Rec."Posting Date"));
        WarehouseEntry.SetFilter(Quantity, '>0');

        if WarehouseEntry.FindLast() then  // Get the most recent placement
            ActualBinCode := WarehouseEntry."Bin Code";
    end;

    var
        ActualBinCode: Code[20];
        LocationCode: Code[10];
        BinCode: Code[20];
        ItemNo: Code[20];
        LayerNo: Integer;
        UnitCost: Decimal;
        AgeDays: Integer;
        BinEntryDate: Date;
        CumulativeQty: Decimal;
        TotalRemaining: Decimal;
        AgeStyle: Text;
}