/*
pageextension 50039 "SPN StdCost Worksheet Ext" extends "Standard Cost Worksheet"
{
    actions
    {
        addafter("&Implement Standard Cost Changes")
        {
            action("SPN Implement (Preserve Flagged SKUs)")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Implement (SPN – preserve flagged SKUs)';
                Image = ImplementCostChanges;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Runs Implement Standard Cost Changes and then restores Standard Cost on SKUs marked "Std. Cost is manually updated".';

                trigger OnAction()
                var
                    Wrapper: Codeunit "SPN Implement Std Cost Wrapper";
                begin
                    Wrapper.RunForWorksheet(Rec."Standard Cost Worksheet Name"); // same parameter as base
                end;
            }

        }
        addlast(Creation)
        {
           group(SPNInfo)
            {
                Caption = 'SPN: SKUs marked "Std. Cost is manually updated" remain fixed on the SKU card; AUNING postings use fixed per-SKU cost.';
            }
        }
    }
}
*/