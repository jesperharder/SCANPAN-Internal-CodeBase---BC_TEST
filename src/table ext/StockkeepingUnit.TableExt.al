/// <summary>
/// 2025.10  Jesper Harder  116.1
/// </summary>
tableextension 50034 StockkeepingUnit extends "Stockkeeping Unit"
{
    // Per-SKU fields to control & separate costing for divisions.

    fields
    {
        field(50000; "SPN Std. Cost Manually Updated"; Boolean)
        {
            Caption = 'Std. Cost is manually updated';
            DataClassification = CustomerContent;

            // When TRUE, manually triggered updates will not change the Standard Cost for this SKU.
            // Your guard subscribers enforce this.
        }
    }
}
