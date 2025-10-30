pageextension 50008 "StockkeepingUnitCard" extends "Stockkeeping Unit Card"
{
    // NAV REF (UI-eksponering):
    //   OBJECT Form 30 Item Card  (JH0184)
    //   Din form havde en CheckBox med SourceExpr="Std.Cost is manually updated"
    //   Vi viser feltet på SKU-kortet (BC-tilsvarende placering).

    layout
    {
        addlast(General) // Justér FastTab-navn efter jeres layout (fx "Costs")
        {
            field("SPN Std. Cost Manually Updated"; Rec."SPN Std. Cost Manually Updated")
            {
                ApplicationArea = All;

                // Kommentar bevaret som forklaring i BC:
                //   [DAN] "Std.Kostpris opdateres manuelt"
                //   [ENU] "Std. Cost is manually updated"
                ToolTip = 'If selected, Standard Cost changes on this SKU will be blocked by batch or mass update processes.';
            }
        }
    }
}
