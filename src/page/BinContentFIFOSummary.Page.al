///<summary>
/// 2025.11             Jesper Harder       117.1       Created new page for viewing bin content FIFO information, including oldest entry date, average age in days, and number of FIFO layers.
///</summary>

page 50055 "Bin Content FIFO Summary"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Bin Content";
    Caption = 'Bin Content FIFO Summary';
    AdditionalSearchTerms = 'SCANPAN, FIFO Summary, FIFO Info, FIFO Information, Bin FIFO, Bin FIFO Summary';
    Editable = false;
    SourceTableView = where(Quantity = filter(> 0));

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Style = Favorable;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                }
                field("Oldest Entry Date"; OldestEntryDate)
                {
                    ApplicationArea = All;
                    Caption = 'Oldest FIFO Entry';
                }
                field("Avg Age Days"; AvgAgeDays)
                {
                    ApplicationArea = All;
                    Caption = 'Avg Age (Days)';
                    StyleExpr = AgeStyle;
                }

                field("Oldest Bin Entry Date"; OldestBinEntryDate)
                {
                    ApplicationArea = All;
                    Caption = 'Ældste placering i boks';
                    ToolTip = 'Angiver datoen for den ældste lagerpost i denne specifikke placering.';
                }

                field("FIFO Layers"; FIFOLayers)
                {
                    ApplicationArea = All;
                    Caption = 'No. of Layers';
                    Style = StrongAccent;
                    StyleExpr = true;

                    trigger OnDrillDown()
                    begin
                        ShowFIFOLayerDetails();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowFIFOLayers)
            {
                ApplicationArea = All;
                Caption = 'Show FIFO Layers';
                Image = EntriesList;
                ToolTip = 'Show detailed FIFO layers for selected bin.';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    ShowFIFOLayerDetails();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalculateFIFOInfo();
    end;

    local procedure CalculateFIFOInfo()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
        TotalQty: Decimal;
        WeightedAge: Decimal;
    begin
        Clear(OldestEntryDate);
        Clear(OldestBinEntryDate);
        Clear(AvgAgeDays);
        FIFOLayers := 0;
        TotalQty := 0;
        WeightedAge := 0;

        // Get FIFO info from Item Ledger Entries
        ItemLedgerEntry.SetCurrentKey("Item No.", "Location Code", "Open", "Variant Code", "Unit of Measure Code", "Posting Date");
        ItemLedgerEntry.SetRange("Item No.", Rec."Item No.");
        ItemLedgerEntry.SetRange("Location Code", Rec."Location Code");
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetFilter("Remaining Quantity", '>0');

        if ItemLedgerEntry.FindSet() then begin
            OldestEntryDate := ItemLedgerEntry."Posting Date";
            repeat
                FIFOLayers += 1;
                TotalQty += ItemLedgerEntry."Remaining Quantity";
                WeightedAge += (Today - ItemLedgerEntry."Posting Date") * ItemLedgerEntry."Remaining Quantity";
            until ItemLedgerEntry.Next() = 0;

            if TotalQty <> 0 then
                AvgAgeDays := Round(WeightedAge / TotalQty, 1);
        end;

        // Get oldest bin placement date from Warehouse Entries
        WarehouseEntry.SetCurrentKey("Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code");
        WarehouseEntry.SetRange("Item No.", Rec."Item No.");
        WarehouseEntry.SetRange("Bin Code", Rec."Bin Code");
        WarehouseEntry.SetRange("Location Code", Rec."Location Code");
        WarehouseEntry.SetFilter(Quantity, '>0');  // Positive entries (items placed in bin)
        if WarehouseEntry.FindFirst() then
            OldestBinEntryDate := WarehouseEntry."Registering Date";

        SetAgeStyle();
    end;

    local procedure SetAgeStyle()
    begin
        case true of
            AvgAgeDays > 180:
                AgeStyle := 'Unfavorable';
            AvgAgeDays > 90:
                AgeStyle := 'Attention';
            else
                AgeStyle := 'Favorable';
        end;
    end;

    local procedure ShowFIFOLayerDetails()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        FIFOLayerDetailsPage: Page "FIFO Layer Details";
    begin
        ItemLedgerEntry.SetCurrentKey("Item No.", "Location Code", "Open", "Variant Code", "Unit of Measure Code", "Posting Date");
        ItemLedgerEntry.SetRange("Item No.", Rec."Item No.");
        ItemLedgerEntry.SetRange("Location Code", Rec."Location Code");
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetFilter("Remaining Quantity", '>0');

        FIFOLayerDetailsPage.SetTableView(ItemLedgerEntry);
        FIFOLayerDetailsPage.SetBinInfo(Rec."Location Code", Rec."Bin Code", Rec."Item No.");
        FIFOLayerDetailsPage.RunModal();
    end;

    var
        OldestEntryDate: Date;
        OldestBinEntryDate: Date;
        AvgAgeDays: Integer;
        FIFOLayers: Integer;
        AgeStyle: Text;
}