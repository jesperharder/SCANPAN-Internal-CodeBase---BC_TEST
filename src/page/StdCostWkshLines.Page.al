///<summary>
/// 2025.10             Jesper Harder       116.1       SPN SKU Std. Cost Worksheet – create draft from locked SKUs implement (preserve fixed costs)
/// </summary>
page 50043 "StdCostWkshLines"
{
    PageType = ListPart;
    SourceTable = "StdCostWkshLine";
    Caption = 'Std. Cost Worksheet Lines';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Worksheet Name"; Rec."Worksheet Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Worksheet Name field.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Line No. field.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Item No. field.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Location Code field.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Variant Code field.';
                }
                field("Current Standard Cost"; Rec."Current Standard Cost")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Current Standard Cost field.';
                }
                field("New Standard Cost"; Rec."New Standard Cost")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the New Standard Cost field.';
                }
                field("Locked Flag Snapshot"; Rec."Locked Flag Snapshot")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Locked Flag Snapshot field.';
                }
                field("Note"; Rec."Note")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Note field.';
                }
                field(Implemented; Rec.Implemented)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Implemented field.';
                }
                field("Implemented By"; Rec."Implemented By")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Implemented By field.';
                }
                field("Implemented At"; Rec."Implemented At")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Implemented At field.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(RecalculateLine)
            {
                ApplicationArea = All;
                Caption = 'Recalculate Line';
                Image = Recalculate;
                ToolTip = 'Executes the Recalculate Line action.';
                trigger OnAction()
                var
                    Mgr: Codeunit "SPNStdCostManager";
                    L: Record StdCostWkshLine;
                begin
                    L := Rec;
                    Mgr.Worksheet_RecalculateLine(L);
                    Rec := L;
                    CurrPage.Update(false);
                end;
            }

            action(ValidateCanImplement)
            {
                ApplicationArea = All;
                Caption = 'Validate';
                Image = Check;
                ToolTip = 'Executes the Validate action.';
                trigger OnAction()
                var
                    Mgr: Codeunit "SPNStdCostManager";
                    Msg: Text;
                    Ok: Boolean;
                begin
                    Ok := Mgr.Guard_ValidateCanImplement(Rec."Item No.", CompanyName(), Msg);
                    if Ok then
                        Message('OK: %1', Msg)
                    else
                        Error(Msg);
                end;
            }
        }
    }
    procedure SetEditable(IsEditable: Boolean)
    begin
        CurrPage.Editable(IsEditable);
    end;
}
