page 50048 "SPN StdCost Worksheet"
{
    ///<summary>
    /// Standard Cost Worksheet Document Page
    /// Main interface for managing standard cost worksheets with locked SKUs.
    /// Provides header/line document structure with status-based editability control.
    ///
    /// Change Log:
    /// 2025.10    Jesper Harder    116.1    SPN SKU Std. Cost Worksheet – create draft from locked SKUs 
    ///                                      implement (preserve fixed costs)
    /// </summary>

    PageType = Document;
    SourceTable = "StdCostWkshHeader";
    UsageCategory = None;
    Caption = 'SPN Std. Cost Worksheet';
    AdditionalSearchTerms = 'SPN Standard Cost Worksheet,SPN Std Cost Worksheet,SPN StdCostWkshHeader';
    layout
    {
        area(content)
        {
            // ============================================================================
            // HEADER SECTION
            // ============================================================================
            group(General)
            {
                Caption = 'General';

                // Worksheet identification
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique identifier for this worksheet.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the worksheet purpose.';
                }

                // Status control (system-managed)
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false; // Status is system-controlled, changes via actions only
                    ToolTip = 'Specifies the current status of the worksheet. Draft worksheets can be edited, Implemented worksheets are locked.';
                    Style = Strong;
                    StyleExpr = true;
                }

                // Audit trail - Creation information
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the user who created this worksheet.';
                }

                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies when this worksheet was created.';
                }

                // Audit trail - Implementation information
                field("Implemented By"; Rec."Implemented By")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the user who implemented this worksheet.';
                }

                field("Implemented At"; Rec."Implemented At")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies when this worksheet was implemented.';
                }
            }

            // ============================================================================
            // LINES SUBPAGE
            // ============================================================================
            /// <summary>
            /// Worksheet lines showing item/SKU standard cost changes to be applied.
            /// Linked to header via Worksheet Name.
            /// </summary>
            part(Lines; "StdCostWkshLines")
            {
                ApplicationArea = All;
                SubPageLink = "Worksheet Name" = field(Name);
                UpdatePropagation = Both;
            }
        }
    }

    // ============================================================================
    // ACTIONS
    // ============================================================================
    actions
    {
        area(processing)
        {
            /// <summary>
            /// Populates the worksheet with lines from all manually locked SKUs
            /// that have not yet been implemented.
            /// Only available in Draft status.
            /// </summary>
            action(CreateDraftFromLocked)
            {
                Caption = 'Create Draft from Locked SKUs';
                ApplicationArea = All;
                Image = Create;
                Enabled = IsDraft; // Only clickable in Draft status
                ToolTip = 'Populate this worksheet with all SKUs that are marked for manual standard cost maintenance and have not been implemented yet.';

                trigger OnAction()
                var
                    Hdr: Record "StdCostWkshHeader";
                    Mgr: Codeunit "SPNStdCostManager";
                    Created: Integer;
                begin
                    // Load current record and populate lines
                    Hdr := Rec;
                    Mgr.BuildDraftFromLockedSKUs(Hdr, Created);

                    // Provide user feedback
                    if Created = 0 then
                        Message('No SKUs marked for manual standard cost were found, or all were previously implemented.')
                    else
                        Message('%1 line(s) created from locked SKUs.', Created);

                    // Refresh the page to show new lines
                    CurrPage.Update(false);
                end;
            }

            /// <summary>
            /// Applies the implementation - updates all SKU standard costs based on worksheet lines.
            /// Changes worksheet status to Implemented and locks it from further editing.
            /// Only available in Draft status.
            /// </summary>
            action(ApplyImplementation)
            {
                ApplicationArea = All;
                Caption = 'Apply';
                Image = Post;
                Enabled = IsDraft; // Disabled when not Draft status
                ToolTip = 'Apply this worksheet by updating all SKU standard costs and marking it as Implemented. This action cannot be undone.';

                trigger OnAction()
                var
                    Hdr: Record "StdCostWkshHeader";
                    Mgr: Codeunit "SPNStdCostManager";
                begin
                    // Confirm before proceeding with implementation
                    if not Confirm('This will update all SKU standard costs and lock the worksheet. Continue?', false) then
                        exit;

                    // Apply the implementation with per-line commits for safety
                    Hdr := Rec;
                    Mgr.ApplyImplementation(Hdr, true);

                    // Refresh page to show updated status
                    CurrPage.Update(false);

                    Message('Implementation completed for %1.', Rec.Name);
                end;
            }
        }
    }

    // ============================================================================
    // VARIABLES
    // ============================================================================
    var
        /// <summary>
        /// Tracks whether the current worksheet is in Draft status.
        /// Used to control editability and action availability.
        /// </summary>
        IsDraft: Boolean;

    // ============================================================================
    // LOCAL PROCEDURES
    // ============================================================================

    /// <summary>
    /// Updates the editability state of the page based on worksheet status.
    /// Draft worksheets are editable, Implemented worksheets are read-only.
    /// </summary>
    local procedure UpdateEditability()
    begin
        // Check if current record is in Draft status
        IsDraft := (Rec.Status = Rec.Status::Draft);

        // Make entire card read-only when not Draft
        // This prevents accidental changes to implemented worksheets
        CurrPage.Editable(IsDraft);
    end;

    // ============================================================================
    // TRIGGERS
    // ============================================================================

    /// <summary>
    /// Fired when the page is opened.
    /// Initializes editability state.
    /// </summary>
    trigger OnOpenPage()
    begin
        UpdateEditability();
    end;

    /// <summary>
    /// Fired after each record is retrieved.
    /// Updates editability state for the current record.
    /// </summary>
    trigger OnAfterGetRecord()
    begin
        UpdateEditability();
    end;
}
