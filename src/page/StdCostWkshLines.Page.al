///<summary>
/// 2025.10  Jesper Harder  116.1
/// SPN SKU Std. Cost Worksheet – create draft from locked SKUs implement (preserve fixed costs)
///</summary>
page 50043 "StdCostWkshLines"
{
    PageType = ListPart;
    SourceTable = "StdCostWkshLine";
    Caption = 'Std. Cost Worksheet Lines';
    AdditionalSearchTerms = 'Standard Cost Worksheet Lines,Std Cost Wksh Lines,StdCostWkshLine';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Worksheet Name"; Rec."Worksheet Name")
                {
                    ApplicationArea = All;
                    Caption = 'Worksheet Name';
                    Editable = false;
                    ToolTip = 'The worksheet header this line belongs to.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Line No.';
                    Editable = false;
                    ToolTip = 'The sequential line number assigned by the system.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Caption = 'Item No.';
                    ToolTip = 'The item whose standard cost is being managed on this line.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    Caption = 'Location Code';
                    ToolTip = 'The location for which the standard cost applies (blank means company-wide).';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Caption = 'Variant Code';
                    ToolTip = 'The item variant for which the standard cost applies (blank means base item).';
                }
                field("Current Standard Cost"; Rec."Current Standard Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Current Standard Cost';
                    Editable = false;
                    ToolTip = 'The current standard cost stored on the item or SKU.';
                }
                field("New Standard Cost"; Rec."New Standard Cost")
                {
                    ApplicationArea = All;
                    Caption = 'New Standard Cost';
                    ToolTip = 'The proposed standard cost to implement for this item/variant/location.';
                }
                field("Locked Flag Snapshot"; Rec."Locked Flag Snapshot")
                {
                    ApplicationArea = All;
                    Caption = 'Locked (Snapshot)';
                    Editable = false;
                    ToolTip = 'Shows whether the item/SKU was locked for manual standard cost at the time of snapshot.';
                }
                field(Note; Rec.Note)
                {
                    ApplicationArea = All;
                    Caption = 'Note';
                    ToolTip = 'Optional note about this line or its calculation.';
                }
                field(Implemented; Rec.Implemented)
                {
                    ApplicationArea = All;
                    Caption = 'Implemented';
                    Editable = false;
                    ToolTip = 'Indicates whether the new standard cost on this line has been implemented.';
                }
                field("Implemented By"; Rec."Implemented By")
                {
                    ApplicationArea = All;
                    Caption = 'Implemented By';
                    Editable = false;
                    ToolTip = 'User who implemented the standard cost from this line.';
                }
                field("Implemented At"; Rec."Implemented At")
                {
                    ApplicationArea = All;
                    Caption = 'Implemented At';
                    Editable = false;
                    ToolTip = 'Date and time when the standard cost from this line was implemented.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RecalculateLine)
            {
                ApplicationArea = All;
                Caption = 'Recalculate Line';
                Image = Recalculate;
                ToolTip = 'Recalculates the new standard cost on the selected line using the current rules.';

                trigger OnAction()
                var
                    StdCostWkshLine: Record "StdCostWkshLine";
                    Mgr: Codeunit "SPNStdCostManager";
                begin
                    // Work on a copy for clarity; the manager updates the record by reference.
                    StdCostWkshLine := Rec;
                    Mgr.Worksheet_RecalculateLine(StdCostWkshLine);
                    Rec := StdCostWkshLine;

                    // Refresh the UI to show recalculated values.
                    CurrPage.Update(false);
                end;
            }

            action(ValidateCanImplement)
            {
                ApplicationArea = All;
                Caption = 'Validate';
                Image = Check;
                ToolTip = 'Validates whether the selected line can be implemented in the current company.';

                trigger OnAction()
                var
                    Mgr: Codeunit "SPNStdCostManager";
                    Msg: Text;
                    Ok: Boolean;
                begin
                    Ok := Mgr.Guard_ValidateCanImplement(Rec."Item No.", CopyStr(CompanyName(), 1,50), Msg);
                    if Ok then
                        Message('OK: %1', Msg)
                    else
                        Error(Msg);
                end;
            }
        }
    }

    /// <summary>
    /// Allows the host page to toggle editability (e.g., only Draft headers are editable).
    /// </summary>
    procedure SetEditable(IsEditable: Boolean)
    begin
        CurrPage.Editable(IsEditable);
    end;
}
