


/// <summary>
/// PageExtension "StockkeepingUnitListExtSC" (ID 50034) extends Record Stockkeeping Unit List.
/// 2025.10  Jesper Harder  116.1
/// </summary>
pageextension 50034 StockkeepingUnitList extends "Stockkeeping Unit List"
{
    layout
    {
        addafter(Description)
        {
            field("Vendor No."; Rec."Vendor No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
            }
        }
        addafter("Vendor No.")
        {
            field("Reorder Point1"; Rec."Reorder Point")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
            }
            field("Safety Stock Quantity52170"; Rec."Safety Stock Quantity")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
            }
        }

        addafter(Inventory)
        {
            field("Reordering Policy"; Rec."Reordering Policy")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
            }
            field("Standard Cost"; "Standard Cost")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the SKU, Standard Cost. IT can be different from the item standard cost.';
            }
        }
    }


    actions
    {
        addlast(Processing)
        {
            group("SPN Standard Cost")
            {
                action(EnableSPNStdCostManual)
                {
                    ApplicationArea = All;
                    Caption = 'Enable Manual Std. Cost';
                    Image = UpdateUnitCost;
                    ToolTip = 'Executes the Enable Manual Std. Cost action.';

                    trigger OnAction()
                    begin
                        UpdateManualStdCostFlag(true);
                    end;
                }

                action(DisableSPNStdCostManual)
                {
                    ApplicationArea = All;
                    Caption = 'Disable Manual Std. Cost';
                    Image = ReOpen;
                    ToolTip = 'Executes the Disable Manual Std. Cost action.';

                    trigger OnAction()
                    begin
                        UpdateManualStdCostFlag(false);
                    end;
                }
            }
        }
    }

    local procedure UpdateManualStdCostFlag(NewValue: Boolean)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        EligibleRecords: Integer;
        LocationFilter: Text;
    begin
        LocationFilter := Rec.GetFilter("Location Code");
        if LocationFilter = '' then
            Error(LocationFilterMissingErr);

        PrepareStockkeepingUnitFilters(StockkeepingUnit, LocationFilter);

        EligibleRecords := CountEligibleStockkeepingUnits(StockkeepingUnit);
        if EligibleRecords = 0 then
            Error(NoRecordsForFilterErr, LocationFilter, GenProdPostingGroupFilterTxt);

        if not Confirm(ConfirmUpdateLbl, false, EligibleRecords, LocationFilter, GetManualStdCostState(NewValue)) then
            exit;
        PrepareStockkeepingUnitFilters(StockkeepingUnit, LocationFilter);
        StockkeepingUnit.LockTable();
        ApplyManualStdCostFlag(StockkeepingUnit, NewValue);

        Message(UpdateCompletedMsg, EligibleRecords, GetManualStdCostState(NewValue));
    end;

    local procedure PrepareStockkeepingUnitFilters(var StockkeepingUnit: Record "Stockkeeping Unit"; LocationFilter: Text)
    begin
        StockkeepingUnit.Reset();
        StockkeepingUnit.CopyFilters(Rec);
        StockkeepingUnit.SetFilter("Location Code", LocationFilter);
    end;

    local procedure CountEligibleStockkeepingUnits(var StockkeepingUnit: Record "Stockkeeping Unit"): Integer
    var
        Item: Record Item;
        Count: Integer;
    begin
        Count := 0;

        if StockkeepingUnit.FindSet() then
            repeat
                if IsSkuEligibleForManualStdCost(StockkeepingUnit, Item) then
                    Count += 1;
            until StockkeepingUnit.Next() = 0;

        exit(Count);
    end;

    local procedure ApplyManualStdCostFlag(var StockkeepingUnit: Record "Stockkeeping Unit"; NewValue: Boolean)
    var
        Item: Record Item;
    begin
        if StockkeepingUnit.FindSet(true) then
            repeat
                if IsSkuEligibleForManualStdCost(StockkeepingUnit, Item) then begin
                    StockkeepingUnit."SPN Std. Cost Manually Updated" := NewValue;
                    StockkeepingUnit.Modify(false);
                end;
            until StockkeepingUnit.Next() = 0;
    end;

    local procedure IsSkuEligibleForManualStdCost(var StockkeepingUnit: Record "Stockkeeping Unit"; var Item: Record Item): Boolean
    begin
        if not Item.Get(StockkeepingUnit."Item No.") then
            exit(false);

        exit((Item."Gen. Prod. Posting Group" = GenProdPostingGroupFilterTxt) and
             (Item."Costing Method" = Item."Costing Method"::Standard));
    end;

    local procedure GetManualStdCostState(NewValue: Boolean): Text[30]
    begin
        if NewValue then
            exit(ManualStdCostEnabledTxt);

        exit(ManualStdCostDisabledTxt);
    end;

    var
        ConfirmUpdateLbl: Label 'Set the manual std. cost flag for %1 stockkeeping unit(s) with Location Code filter ''%2'' to %3?', Comment = '%1=number of records, %2=location filter text, %3=target state description';
        LocationFilterMissingErr: Label 'Add a Location Code filter before running this action.';
        NoRecordsForFilterErr: Label 'No stockkeeping units with Location Code ''%1'' are linked to items where Gen. Prod. Posting Group = ''%2'' and Costing Method = Standard.', Comment = '%1=location filter text, %2=Gen. Prod. Posting Group filter text';
        ManualStdCostEnabledTxt: Label 'enabled';
        ManualStdCostDisabledTxt: Label 'disabled';
        UpdateCompletedMsg: Label 'Updated the manual std. cost flag to %2 on %1 stockkeeping unit(s).', Comment = '%1=number of records, %2=target state description';
        GenProdPostingGroupFilterTxt: Label 'INTERN';
}
