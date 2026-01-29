///<summary>
/// 2025.10 | Author: Jesper Harder | Version: 116.1 | ProjectId: SPN-STD-COST
/// Purpose:
///   Expose "Std. Cost is manually updated" on the Stockkeeping Unit Card,
///   mirroring legacy UI behavior from NAV (Form 30 Item Card - JH0184).
/// Notes:
///   - Setting this flag blocks batch/mass updates from changing Standard Cost on the SKU.
/// 2025.10  Jesper Harder  116.1
///</summary>

pageextension 50008 StockkeepingUnitCard extends "Stockkeeping Unit Card"
{
    // NAV reference (UI exposure):
    //   OBJECT Form 30 "Item Card" (JH0184)
    //   Original had a CheckBox SourceExpr="Std.Cost is manually updated".
    //   We surface the equivalent field on the SKU card in BC.

    layout
    {
        // Place the field at the end of the "General" FastTab. 
        // If your environment uses a different FastTab (e.g., "Costs"), adjust the target container accordingly.
        addlast(General)
        {
            field("SPN Std. Cost Manually Updated"; Rec."SPN Std. Cost Manually Updated")
            {
                ApplicationArea = All;
                ToolTip = 'If selected, manually triggered updates will not change the Standard Cost for this SKU.';
            }
        }
    }
}
