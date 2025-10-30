tableextension 50034 "SPN SKU Ext" extends "Stockkeeping Unit"
{
    // Per-SKU fields to control & separate costing for divisions.

    fields
    {
        field(50000; "SPN Std. Cost Manually Updated"; Boolean)
        {
            Caption = 'Std. Cost is manually updated';
            DataClassification = CustomerContent;

            // When TRUE, automated processes must not change this SKU's Standard Cost.
            // Your guard subscribers enforce this.
        }

        field(50010; "SPN Fixed Std. Cost"; Decimal)
        {
            Caption = 'Fixed Std. Cost (Sales)';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;

            // Used by AUNING postings (override in Item Jnl.-Post Line events).
        }

        field(50011; "SPN Variable Std. Cost"; Decimal)
        {
            Caption = 'Variable Std. Cost (Prod)';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;

            // Optional: RYOM's journal-to-journal cost snapshot (if you choose to use it).
        }
    }
}
