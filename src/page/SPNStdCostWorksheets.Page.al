page 50049 "SPN StdCost Worksheets"
{
    ///<summary>
    /// 2025.10             Jesper Harder       116.1       SPN SKU Std. Cost Worksheet – create draft from locked SKUs implement (preserve fixed costs)
    /// </summary>
    PageType = List;
    ApplicationArea = All;
    SourceTable = "StdCostWkshHeader";
    UsageCategory = Lists;
    Caption = 'SPN Std. Cost Worksheets';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                //field(Name; Rec.Name) { ApplicationArea = All; }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    DrillDown = true;
                    trigger OnDrillDown()
                    begin
                        PAGE.Run(PAGE::"SPN StdCost Worksheet", Rec);
                    end;
                }
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
        }
    }

    actions
    {
        area(navigation)
        {
            action(OpenDocument)
            {
                ApplicationArea = All;
                Caption = 'Open';
                Image = EditLines;
                RunObject = page "SPN StdCost Worksheet";
                RunPageLink = Name = field(Name);
            }
        }
        area(Creation)
        {
            action(CreateDraftFromLocked)
            {
                Caption = 'Create Draft from Locked SKUs';
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Create;
                Enabled = Rec.Status = Rec.Status::Draft; // ✅ only for Draft rows
                trigger OnAction()
                var
                    Mgr: Codeunit "SPNStdCostManager";
                    Hdr: Record "StdCostWkshHeader";
                    Created: Integer;
                begin
                    Hdr.Get(Rec.Name);
                    if Hdr.Status <> Hdr.Status::Draft then
                        Error('Only Draft worksheets can be built.');
                    Mgr.BuildDraftFromLockedSKUs(Hdr, Created);
                    if Created = 0 then
                        Message('No SKUs marked for manual standard cost were found, or all were previously implemented.')
                    else
                        PAGE.Run(PAGE::"SPN StdCost Worksheet", Hdr);
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
