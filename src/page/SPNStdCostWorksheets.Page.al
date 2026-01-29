page 50049 "SPN StdCost Worksheets"
{
    // 2025.10  Jesper Harder  116.1
    // SPN SKU Std. Cost Worksheet – create draft from locked SKUs (preserve fixed costs)

    PageType = List;
    ApplicationArea = All;
    SourceTable = "StdCostWkshHeader";
    UsageCategory = Lists;
    Caption = 'SPN Std. Cost Worksheets';
    AdditionalSearchTerms = 'SPN Standard Cost Worksheets,SPN Std Cost Worksheets,SPN StdCostWkshHeader';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    ToolTip = 'Identifies the Standard Cost worksheet. Click to open the worksheet.';
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        // Open the card/document page for the selected worksheet
                        PAGE.Run(PAGE::"SPN StdCost Worksheet", Rec);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Describes the worksheet purpose or scope.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Shows the current status. Non-draft worksheets are read-only.';
                    Editable = false; // Status is system-controlled
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                    Caption = 'Created By';
                    ToolTip = 'User who created the worksheet.';
                    Editable = false;
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    Caption = 'Created At';
                    ToolTip = 'Date/time when the worksheet was created.';
                    Editable = false;
                }
                field("Implemented By"; Rec."Implemented By")
                {
                    ApplicationArea = All;
                    Caption = 'Implemented By';
                    ToolTip = 'User who implemented the worksheet.';
                    Editable = false;
                }
                field("Implemented At"; Rec."Implemented At")
                {
                    ApplicationArea = All;
                    Caption = 'Implemented At';
                    ToolTip = 'Date/time when the worksheet was implemented.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        // Modern action areas: use Processing for actions that do something on the record.
        area(Processing)
        {
            action(OpenDocument)
            {
                ApplicationArea = All;
                Caption = 'Open';
                Image = EditLines;
                ToolTip = 'Open the selected worksheet to view or edit its lines.';
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;

                // Route to the document page for this header
                RunObject = page "SPN StdCost Worksheet";
                RunPageLink = Name = field(Name);
            }

            action(CreateDraftFromLocked)
            {
                ApplicationArea = All;
                Caption = 'Create Draft from Locked SKUs';
                Image = Create;
                ToolTip = 'Builds a new draft from SKUs locked for manual standard cost (preserving fixed costs).';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                // Enable only for Draft status. (Kept as a property to avoid extra page logic.)
                Enabled = Rec.Status = Rec.Status::Draft;

                trigger OnAction()
                var
                    StdCostWkshHeader: Record "StdCostWkshHeader";
                    SPNStdCostManager: Codeunit "SPNStdCostManager";
                    Created: Integer;
                begin
                    // Hard validation – only Draft allows creation
                    StdCostWkshHeader.Get(Rec.Name);
                    if StdCostWkshHeader.Status <> StdCostWkshHeader.Status::Draft then
                        Error('Only Draft worksheets can be built.');

                    SPNStdCostManager.BuildDraftFromLockedSKUs(StdCostWkshHeader, Created);

                    if Created = 0 then
                        Message('No SKUs marked for manual standard cost were found, or all were previously implemented.')
                    else
                        PAGE.Run(PAGE::"SPN StdCost Worksheet", StdCostWkshHeader);
                end;
            }
        }
    }

    var
        IsDraft: Boolean;

    local procedure UpdateEditability()
    begin
        // Keep the list editable only when current line is Draft.
        IsDraft := (Rec.Status = Rec.Status::Draft);
        CurrPage.Editable(IsDraft);
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
