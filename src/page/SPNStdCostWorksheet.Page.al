page 50048 "SPN StdCost Worksheet"
{
    ///<summary>
    /// 2025.10             Jesper Harder       116.1       SPN SKU Std. Cost Worksheet – create draft from locked SKUs implement (preserve fixed costs)
    /// </summary>
    PageType = Document;
    ApplicationArea = All;
    SourceTable = "StdCostWkshHeader";
    UsageCategory = Tasks;
    Caption = 'SPN Std. Cost Worksheet';


    layout
    {
        area(content)
        {
            group(General)
            {
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false; // Status is system-controlled
                }
                field("Created By"; Rec."Created By") { ApplicationArea = All; Editable = false; }
                field("Created At"; Rec."Created At") { ApplicationArea = All; Editable = false; }
                field("Implemented By"; Rec."Implemented By") { ApplicationArea = All; Editable = false; }
                field("Implemented At"; Rec."Implemented At") { ApplicationArea = All; Editable = false; }
            }
            part(Lines; "StdCostWkshLines")
            {
                ApplicationArea = All;
                SubPageLink = "Worksheet Name" = field(Name);
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(CreateDraftFromLocked)
            {
                Caption = 'Create Draft from Locked SKUs';
                ApplicationArea = All;
                Image = Create;
                Enabled = IsDraft; // ✅ only clickable in Draft
                trigger OnAction()
                var
                    Mgr: Codeunit "SPNStdCostManager";
                    Hdr: Record "StdCostWkshHeader";
                    Created: Integer;
                begin
                    Hdr := Rec;
                    Mgr.BuildDraftFromLockedSKUs(Hdr, Created);
                    if Created = 0 then
                        Message('No SKUs marked for manual standard cost were found, or all were previously implemented.')
                    else
                        CurrPage.Update(false);
                end;
            }
            action(ApplyImplementation)
            {
                ApplicationArea = All;
                Caption = 'Apply';
                Image = Post;
                Enabled = IsDraft; // disabled when not draft
                trigger OnAction()
                var
                    Mgr: Codeunit "SPNStdCostManager";
                    Hdr: Record "StdCostWkshHeader";
                begin
                    Hdr := Rec;
                    Mgr.ApplyImplementation(Hdr, true);
                    Message('Implementation completed for %1.', Rec.Name);
                end;
            }
        }
    }
    var
        IsDraft: Boolean;

    local procedure UpdateEditability()
    begin
        IsDraft := (Rec.Status = Rec.Status::Draft);
        CurrPage.Editable(IsDraft); // card becomes read-only when not Draft
    end;

    trigger OnOpenPage()
    begin
        UpdateEditability();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateEditability();
    end;

}
