codeunit 50025 "SPNStdCostManager"
{
    ///<summary>
    /// Standard Cost Management for Stockkeeping Units (SKUs)
    /// Manages the creation, validation, and implementation of standard cost worksheets
    /// with special handling for manually locked SKUs.
    ///
    /// Change Log:
    /// 2025.10    Jesper Harder    116.1    SPN SKU Std. Cost Worksheet – create draft from locked SKUs 
    ///                                      implement (preserve fixed costs)
    /// </summary>

    Access = Public;
    SingleInstance = false;

    // ============================================================================
    // PUBLIC API PROCEDURES
    // ============================================================================
    #region Public API

    /// <summary>
    /// Creates a new draft worksheet populated with all manually locked SKUs that haven't been implemented yet.
    /// </summary>
    /// <returns>The worksheet name (code) if successful; empty string if no SKUs were found</returns>
    procedure CreateNewDraftFromLockedSKUs(): Code[20]
    var
        StdCostWkshHeader: Record "StdCostWkshHeader";
        StdCostWkshLine: Record "StdCostWkshLine";
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        Cnt: Integer;
        NewName: Code[20];
    begin
        // Create a fresh header; Name generated in OnInsert()
        StdCostWkshHeader.Init();
        StdCostWkshHeader.Insert(true);
        StdCostWkshHeader.Description := 'Draft from locked SKUs';
        StdCostWkshHeader.Modify(true);
        NewName := StdCostWkshHeader.Name;

        // Only process SKUs that are manually locked for std. cost
        StockkeepingUnit.SetRange("SPN Std. Cost Manually Updated", true);

        if StockkeepingUnit.FindSet(true, false) then
            repeat
                // Skip if this combo was already implemented anywhere
                if not HasImplementedLine(StockkeepingUnit."Item No.", StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code") then
                    // Avoid duplicates within this header
                    if not LineExists(NewName, StockkeepingUnit."Item No.", StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code") then begin
                        // Initialize new line
                        StdCostWkshLine.Init();
                        StdCostWkshLine.Validate("Worksheet Name", NewName);
                        StdCostWkshLine.Validate("Line No.", GetNextLineNo(NewName));
                        StdCostWkshLine.Validate("Item No.", StockkeepingUnit."Item No.");
                        StdCostWkshLine.Validate("Location Code", StockkeepingUnit."Location Code");
                        StdCostWkshLine.Validate("Variant Code", StockkeepingUnit."Variant Code");

                        // Set Current Standard Cost from Item, New Standard Cost from SKU
                        if Item.Get(StockkeepingUnit."Item No.") then
                            StdCostWkshLine.Validate("Current Standard Cost", Item."Standard Cost");
                        StdCostWkshLine.Validate("New Standard Cost", StockkeepingUnit."Standard Cost");

                        // Snapshot the lock flag for audit trail
                        StdCostWkshLine.Validate("Locked Flag Snapshot", true);

                        StdCostWkshLine.Insert(true);
                        Cnt += 1;
                    end;
            until StockkeepingUnit.Next() = 0;

        // Clean up if no lines were created
        if Cnt = 0 then begin
            StdCostWkshHeader.Delete(true);
            exit('');
        end;

        exit(NewName);
    end;

    /// <summary>
    /// Populates an existing draft worksheet with lines from manually locked SKUs.
    /// </summary>
    /// <param name="StdCostWkshHeader">The worksheet header to populate (must be in Draft status)</param>
    /// <param name="CreatedCount">Returns the number of lines created</param>
    procedure BuildDraftFromLockedSKUs(var StdCostWkshHeader: Record "StdCostWkshHeader"; var CreatedCount: Integer)
    var
        StdCostWkshLine: Record "StdCostWkshLine";
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        // Only Draft worksheets can be modified
        if StdCostWkshHeader.Status <> StdCostWkshHeader.Status::Draft then
            Error('Only Draft worksheets can be built. Current status is %1.', Format(StdCostWkshHeader.Status));

        CreatedCount := 0;

        // Filter SKUs that are marked for manual std. cost update
        StockkeepingUnit.SetRange("SPN Std. Cost Manually Updated", true);

        if StockkeepingUnit.FindSet(true, false) then
            repeat
                if Item.Get(StockkeepingUnit."Item No.") then
                    // Avoid creating duplicate lines
                    if not LineExists(StdCostWkshHeader.Name, StockkeepingUnit."Item No.", StockkeepingUnit."Location Code", StockkeepingUnit."Variant Code") then begin
                        // Initialize and populate new line
                        StdCostWkshLine.Init();
                        StdCostWkshLine.Validate("Worksheet Name", StdCostWkshHeader.Name);
                        StdCostWkshLine.Validate("Line No.", GetNextLineNo(StdCostWkshHeader.Name));
                        StdCostWkshLine.Validate("Item No.", StockkeepingUnit."Item No.");
                        StdCostWkshLine.Validate("Location Code", StockkeepingUnit."Location Code");
                        StdCostWkshLine.Validate("Variant Code", StockkeepingUnit."Variant Code");

                        // Set current cost from Item, new cost from SKU
                        if Item.Get(StockkeepingUnit."Item No.") then
                            StdCostWkshLine.Validate("Current Standard Cost", Item."Standard Cost");
                        StdCostWkshLine.Validate("New Standard Cost", StockkeepingUnit."Standard Cost");

                        // Snapshot the lock flag for audit trail
                        StdCostWkshLine.Validate("Locked Flag Snapshot", true);
                        StdCostWkshLine.Insert(true);
                        CreatedCount += 1;
                    end;
            until StockkeepingUnit.Next() = 0;
    end;

    /// <summary>
    /// Applies the implementation of a worksheet, updating all SKU standard costs.
    /// </summary>
    /// <param name="StdCostWkshHeader">The worksheet header to implement</param>
    /// <param name="CommitPerLine">If true, commits after each line (safer but slower)</param>
    procedure ApplyImplementation(var StdCostWkshHeader: Record "StdCostWkshHeader"; CommitPerLine: Boolean)
    begin
        Implementation_Apply(StdCostWkshHeader, CommitPerLine);
    end;

    /// <summary>
    /// Recalculates a worksheet line (placeholder for future functionality).
    /// </summary>
    /// <param name="StdCostWkshLine">The worksheet line to recalculate</param>
    procedure Worksheet_RecalculateLine(var StdCostWkshLine: Record "StdCostWkshLine")
    var
        StdCostWkshHeader: Record "StdCostWkshHeader";
    begin
        // Verify worksheet exists
        if not StdCostWkshHeader.Get(StdCostWkshLine."Worksheet Name") then
            Error('Worksheet %1 not found.', StdCostWkshLine."Worksheet Name");

        // Prevent changes to implemented worksheets
        if StdCostWkshHeader.Status = StdCostWkshHeader.Status::Implemented then
            Error('Worksheet %1 is implemented and lines cannot be changed.', StdCostWkshHeader.Name);

        // TODO: Add recalculation logic here
    end;

    #endregion

    // ============================================================================
    // VALIDATION & GUARD PROCEDURES
    // ============================================================================
    #region Validation

    /// <summary>
    /// Validates whether an item can have its standard cost implemented.
    /// Checks costing method and other business rules.
    /// </summary>
    /// <param name="ItemNo">The item number to validate</param>
    /// <param name="CompanyName">The company name for logging</param>
    /// <param name="Message">Returns error message if validation fails</param>
    /// <returns>True if validation passes, false otherwise</returns>
    procedure Guard_ValidateCanImplement(ItemNo: Code[20]; CompanyName: Text[100]; var Message: Text): Boolean
    var
        Item: Record Item;
    begin
        Message := '';

        // Check if item exists
        if not Item.Get(ItemNo) then begin
            Message := StrSubstNo(ItemNotFoundErr, ItemNo);
            exit(false);
        end;

        // Verify costing method is Standard
        if Item."Costing Method" <> Item."Costing Method"::Standard then begin
            Message := StrSubstNo(CheckCostingMethodErr, ItemNo);
            exit(false);
        end;

        // TODO: Add additional checks:
        // - Blocked flags
        // - Pending ledger entries
        // - Open orders
        // - Inventory revaluation in progress

        exit(true);
    end;

    #endregion

    // ============================================================================
    // IMPLEMENTATION ENGINE
    // ============================================================================
    #region Implementation

    /// <summary>
    /// Internal procedure to apply worksheet implementation.
    /// Processes all non-implemented lines and updates SKU standard costs.
    /// </summary>
    /// <param name="StdCostWkshHeader">The worksheet header to implement</param>
    /// <param name="CommitPerLine">If true, commits after each line</param>
    local procedure Implementation_Apply(var StdCostWkshHeader: Record "StdCostWkshHeader"; CommitPerLine: Boolean)
    var
        StdCostWkshLine: Record "StdCostWkshLine";
        Msg: Text;
        Ok: Boolean;
        NowDT: DateTime;
    begin
        // Prevent re-implementation
        if StdCostWkshHeader.Status = StdCostWkshHeader.Status::Implemented then
            Error('Worksheet %1 is already implemented and cannot be changed.', StdCostWkshHeader.Name);

        NowDT := CurrentDateTime();

        // Process all non-implemented lines for this worksheet
        StdCostWkshLine.SetRange("Worksheet Name", StdCostWkshHeader."Name");
        StdCostWkshLine.SetRange(Implemented, false);
        if StdCostWkshLine.FindSet(true, false) then
            repeat
                // Attempt to implement the line
                Ok := Implementation_ImplementItem(StdCostWkshLine, false, Msg);
                if not Ok then
                    Error('Line %1 failed: %2', StdCostWkshLine."Line No.", Msg);

                // Mark line as implemented with audit information
                StdCostWkshLine."Implemented By" := CopyStr(UserId(), 1, 50);
                StdCostWkshLine."Implemented At" := NowDT;
                StdCostWkshLine.Implemented := true;
                StdCostWkshLine.Modify(false);

                // Optional commit per line for safety
                if CommitPerLine then
                    Commit();
            until StdCostWkshLine.Next() = 0;

        // Finalize header status
        StdCostWkshHeader.Validate(Status, StdCostWkshHeader.Status::Implemented);
        StdCostWkshHeader.Modify(false);
    end;

    /// <summary>
    /// Implements a single worksheet line by updating the SKU's standard cost.
    /// </summary>
    /// <param name="StdCostWkshLine">The worksheet line to implement</param>
    /// <param name="DryRun">If true, validates only without making changes</param>
    /// <param name="ResultMsg">Returns result or error message</param>
    /// <returns>True if successful, false otherwise</returns>
    local procedure Implementation_ImplementItem(var StdCostWkshLine: Record "StdCostWkshLine"; DryRun: Boolean; var ResultMsg: Text): Boolean
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        Ok: Boolean;
        Msg: Text;
    begin
        // Validate item can be implemented
        Ok := Guard_ValidateCanImplement(StdCostWkshLine."Item No.", CopyStr(CompanyName(), 1, 50), Msg);
        if not Ok then begin
            ResultMsg := Msg;
            exit(false);
        end;

        if not DryRun then begin
            // Update the SKU's Standard Cost
            if not StockkeepingUnit.Get(StdCostWkshLine."Location Code", StdCostWkshLine."Item No.", StdCostWkshLine."Variant Code") then begin
                ResultMsg := StrSubstNo(SKUNotFoundErr, StdCostWkshLine."Item No.", StdCostWkshLine."Location Code", StdCostWkshLine."Variant Code");
                exit(false);
            end;

            // Apply the new standard cost
            StockkeepingUnit.Validate("Standard Cost", StdCostWkshLine."New Standard Cost");
            StockkeepingUnit.Modify(true);

            ResultMsg := StrSubstNo(SKUStandardCostUpdatedMsg,
                StdCostWkshLine."Item No.",
                StdCostWkshLine."Location Code",
                StdCostWkshLine."Variant Code",
                StdCostWkshLine."New Standard Cost");
        end else
            // Dry run mode - report what would happen
            ResultMsg := StrSubstNo(SKUStandardCostDryRunMsg, StdCostWkshLine."Item No.", StdCostWkshLine."New Standard Cost");

        exit(true);
    end;

    #endregion

    // ============================================================================
    // EVENT SUBSCRIBERS
    // ============================================================================
    #region Events

    /// <summary>
    /// Event subscriber for Item.Standard Cost validation.
    /// Placeholder for future guard logic when Item standard cost changes.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterValidateEvent', 'Standard Cost', false, false)]
    local procedure Item_OnAfterValidate_StandardCost(var Rec: Record Item; var xRec: Record Item; CurrFieldNo: Integer)
    begin
        // TODO: Add guard logic if needed when Item standard cost changes
        // For example:
        // - Check if any locked SKUs exist for this item
        // - Warn user about potential conflicts
        // - Update related worksheets
    end;

    /// <summary>
    /// Event subscriber for SKU.Standard Cost validation.
    /// Prevents manual changes to standard cost on locked SKUs.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Stockkeeping Unit", 'OnBeforeValidateEvent', 'Standard Cost', false, false)]
    local procedure SKU_OnBeforeValidate_StandardCost(var Rec: Record "Stockkeeping Unit"; var xRec: Record "Stockkeeping Unit"; CurrFieldNo: Integer)
    begin
        // Only enforce lock if SKU is marked as manually updated
        if not Rec."SPN Std. Cost Manually Updated" then
            exit;

        // If cost hasn't changed, allow the validation
        if Rec."Standard Cost" = xRec."Standard Cost" then
            exit;

        // Prevent the change with clear error message
        Error(StandardCostLockedErr, Rec."Item No.", Rec."Location Code", Rec."Variant Code");
    end;

    #endregion

    // ============================================================================
    // HELPER FUNCTIONS
    // ============================================================================
    #region Helpers

    /// <summary>
    /// Checks if a worksheet line already exists for the given item/location/variant combination.
    /// </summary>
    local procedure LineExists(WorksheetName: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]): Boolean
    var
        StdCostWkshLine: Record "StdCostWkshLine";
    begin
        StdCostWkshLine.SetRange("Worksheet Name", WorksheetName);
        StdCostWkshLine.SetRange("Item No.", ItemNo);
        StdCostWkshLine.SetRange("Location Code", LocationCode);
        StdCostWkshLine.SetRange("Variant Code", VariantCode);
        exit(not StdCostWkshLine.IsEmpty);
    end;

    /// <summary>
    /// Gets the next available line number for a worksheet (increments by 10000).
    /// </summary>
    local procedure GetNextLineNo(WorksheetName: Code[20]): Integer
    var
        StdCostWkshLine: Record "StdCostWkshLine";
    begin
        StdCostWkshLine.SetRange("Worksheet Name", WorksheetName);
        if StdCostWkshLine.FindLast() then
            exit(StdCostWkshLine."Line No." + 10000);
        exit(10000);
    end;

    /// <summary>
    /// Checks if an implemented line exists for the given item/location/variant combination
    /// across all worksheets.
    /// </summary>
    local procedure HasImplementedLine(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]): Boolean
    var
        StdCostWkshLine: Record "StdCostWkshLine";
    begin
        StdCostWkshLine.SetRange("Item No.", ItemNo);
        StdCostWkshLine.SetRange("Location Code", LocationCode);
        StdCostWkshLine.SetRange("Variant Code", VariantCode);
        StdCostWkshLine.SetRange(Implemented, true);
        exit(not StdCostWkshLine.IsEmpty);
    end;

    #endregion

    // ============================================================================
    // VARIABLES & CONSTANTS
    // ============================================================================
    #region Variables

    var
        // Error Messages
        StandardCostLockedErr: Label 'Standard Cost cannot be changed for SKU %1 | %2 | %3 because it is locked for manual maintenance.', Comment = 'Error message when trying to change standard cost on locked SKU %1 | %2 | %3';
        ItemNotFoundErr: Label 'Item %1 not found.', Comment = 'Error message when item is not found %1';
        CheckCostingMethodErr: Label 'Item %1 has unsupported costing method for standard cost implementation.', Comment = 'Error message when item has unsupported costing method %1';
        SKUNotFoundErr: Label 'SKU for Item %1, Location %2, Variant %3 not found.', Comment = 'Error message when SKU is not found for Item %1, Location %2, Variant %3';

        // Success Messages
        SKUStandardCostUpdatedMsg: Label 'SKU standard cost for Item %1 (Loc: %2, Var: %3) updated to %4.', Comment = 'Message when SKU standard cost is updated for Item %1 (Loc: %2, Var: %3) to %4.';
        SKUStandardCostDryRunMsg: Label 'SKU standard cost for Item %1 would be updated to %2 (dry-run).', Comment = 'Message when SKU standard cost would be updated for Item %1 to %2 in dry-run mode.';

    #endregion
}


/*
codeunit 50025 "SPNStdCostManager"
{
    ///<summary>
    /// 2025.10             Jesper Harder       116.1       SPN SKU Std. Cost Worksheet – create draft from locked SKUs implement (preserve fixed costs)
    /// </summary>

    Access = Public;
    SingleInstance = false;

    // ------------- PUBLIC PROCEDURES -------------
    procedure CreateNewDraftFromLockedSKUs(): Code[20]
    var
        Header: Record "StdCostWkshHeader";
        Line: Record "StdCostWkshLine";
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        Cnt: Integer;
        NewName: Code[20];
    begin
        // Create a fresh header; Name generated in OnInsert()
        Header.Init();
        Header.Insert(true);
        Header.Description := 'Draft from locked SKUs';
        Header.Modify(true);
        NewName := Header.Name;

        // Only SKUs manually locked for std. cost
        SKU.SetRange("SPN Std. Cost Manually Updated", true);

        if SKU.FindSet(true, false) then
            repeat
                // Skip if this combo was already implemented anywhere
                if not HasImplementedLine(SKU."Item No.", SKU."Location Code", SKU."Variant Code") then
                    // Avoid duplicates within this header
                    if not LineExists(NewName, SKU."Item No.", SKU."Location Code", SKU."Variant Code") then begin
                        Line.Init();
                        Line.Validate("Worksheet Name", NewName);
                        Line.Validate("Line No.", GetNextLineNo(NewName));
                        Line.Validate("Item No.", SKU."Item No.");
                        Line.Validate("Location Code", SKU."Location Code");
                        Line.Validate("Variant Code", SKU."Variant Code");

                        // Current = Item."Standard Cost"; New = SKU."Standard Cost"
                        if Item.Get(SKU."Item No.") then
                            Line.Validate("Current Standard Cost", Item."Standard Cost");
                        Line.Validate("New Standard Cost", SKU."Standard Cost");

                        // Snapshot the lock flag
                        Line.Validate("Locked Flag Snapshot", true);

                        Line.Insert(true);
                        Cnt += 1;
                    end;
            until SKU.Next() = 0;

        if Cnt = 0 then begin
            Header.Delete(true); // remove empty header
            exit('');
        end;

        exit(NewName);
    end;

    procedure BuildDraftFromLockedSKUs(var Header: Record "StdCostWkshHeader"; var CreatedCount: Integer)
    var
        Line: Record "StdCostWkshLine";
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
    begin
        // Only Draft is allowed
        if Header.Status <> Header.Status::Draft then
            Error('Only Draft worksheets can be built. Current status is %1.', Format(Header.Status));

        CreatedCount := 0;

        // Filter SKUs that are marked for manual std. cost update
        SKU.SetRange("SPN Std. Cost Manually Updated", true);

        if SKU.FindSet(true, false) then
            repeat
                if not LineExists(Header.Name, SKU."Item No.", SKU."Location Code", SKU."Variant Code") then begin
                    Line.Init();
                    Line.Validate("Worksheet Name", Header.Name);
                    Line.Validate("Line No.", GetNextLineNo(Header.Name));
                    Line.Validate("Item No.", SKU."Item No.");
                    Line.Validate("Location Code", SKU."Location Code");
                    Line.Validate("Variant Code", SKU."Variant Code");

                    if Item.Get(SKU."Item No.") then
                        Line.Validate("Current Standard Cost", Item."Standard Cost");
                    Line.Validate("New Standard Cost", SKU."Standard Cost");

                    Line.Validate("Locked Flag Snapshot", true);
                    Line.Insert(true);
                    CreatedCount += 1;
                end;
            until SKU.Next() = 0;
    end;

    procedure ApplyImplementation(var Header: Record "StdCostWkshHeader"; CommitPerLine: Boolean)
    begin
        Implementation_Apply(Header, CommitPerLine);
    end;

    // ------------- EVENTS -------------
    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterValidateEvent', 'Standard Cost', false, false)]
    local procedure Item_OnAfterValidate_StandardCost(var Rec: Record Item; var xRec: Record Item; CurrFieldNo: Integer)
    begin
        // TODO: Add guard logic if needed when Item standard cost changes
    end;

    [EventSubscriber(ObjectType::Table, Database::"Stockkeeping Unit", 'OnBeforeValidateEvent', 'Standard Cost', false, false)]
    local procedure SKU_OnBeforeValidate_StandardCost(var Rec: Record "Stockkeeping Unit"; var xRec: Record "Stockkeeping Unit"; CurrFieldNo: Integer)
    begin
        if not Rec."SPN Std. Cost Manually Updated" then
            exit;

        if Rec."Standard Cost" = xRec."Standard Cost" then
            exit;

        Error(StandardCostLockedErr, Rec."Item No.", Rec."Location Code", Rec."Variant Code");
    end;

    var
        StandardCostLockedErr: Label 'Standard Cost cannot be changed for SKU %1 | %2 | %3 because it is locked for manual maintenance.', Comment = 'Error message when trying to change standard cost on locked SKU %1 | %2 | %3';
        ItemNotFoundErr: Label 'Item %1 not found.', Comment = 'Error message when item is not found %1';
        CheckCostingMethodErr: Label 'Item %1 has unsupported costing method for standard cost implementation.', Comment = 'Error message when item has unsupported costing method %1';
        SKUNotFoundErr: Label 'SKU for Item %1, Location %2, Variant %3 not found.', Comment = 'Error message when SKU is not found for Item %1, Location %2, Variant %3';
        SKUStandardCostUpdatedMsg: Label 'SKU standard cost for Item %1 (Loc: %2, Var: %3) updated to %4.', Comment = 'Message when SKU standard cost is updated for Item %1 (Loc: %2, Var: %3) to %4.';
        SKUStandardCostDryRunMsg: Label 'SKU standard cost for Item %1 would be updated to %2 (dry-run).', Comment = 'Message when SKU standard cost would be updated for Item %1 to %2 in dry-run mode.';
    // ------------- INTERNALS: GUARD -------------
    #region Guard
    procedure Guard_ValidateCanImplement(ItemNo: Code[20]; CompanyName: Text[100]; var Message: Text): Boolean
    var
        Item: Record Item;
    begin
        Message := '';
        if not Item.Get(ItemNo) then begin
            Message := StrSubstNo(ItemNotFoundErr, ItemNo);
            exit(false);
        end;

        // Check costing method
        if Item."Costing Method" <> Item."Costing Method"::Standard then begin
            Message := StrSubstNo(CheckCostingMethodErr, ItemNo);
            exit(false);
        end;

        // TODO: Add additional checks (blocked flags, pending ledger entries, etc.)

        exit(true);
    end;
    #endregion

    // ------------- INTERNALS: IMPLEMENTATION -------------
    #region Implementation
    local procedure Implementation_Apply(var Header: Record "StdCostWkshHeader"; CommitPerLine: Boolean)
    var
        Line: Record "StdCostWkshLine";
        Msg: Text;
        Ok: Boolean;
        NowDT: DateTime;
    begin
        if Header.Status = Header.Status::Implemented then
            Error('Worksheet %1 is already implemented and cannot be changed.', Header.Name);

        NowDT := CurrentDateTime();

        // Process non-implemented lines for this worksheet
        Line.SetRange("Worksheet Name", Header."Name");
        Line.SetRange(Implemented, false);
        if Line.FindSet(true, false) then
            repeat
                Ok := Implementation_ImplementItem(Line, false, Msg);
                if not Ok then
                    Error('Line %1 failed: %2', Line."Line No.", Msg);

                // Mark line as implemented
                Line."Implemented By" := CopyStr(UserId(), 1, 50);
                Line."Implemented At" := NowDT;
                Line.Implemented := true;
                Line.Modify(false);

                if CommitPerLine then
                    Commit();
            until Line.Next() = 0;

        // Finalize header as Implemented
        Header.Validate(Status, Header.Status::Implemented);
        Header.Modify(false);
    end;

    local procedure Implementation_ImplementItem(var Line: Record "StdCostWkshLine"; DryRun: Boolean; var ResultMsg: Text): Boolean
    var
        SKU: Record "Stockkeeping Unit";
        Ok: Boolean;
        Msg: Text;
    begin
        // Validate before apply
        Ok := Guard_ValidateCanImplement(Line."Item No.", CopyStr(CompanyName(), 1, 50), Msg);
        if not Ok then begin
            ResultMsg := Msg;
            exit(false);
        end;

        if not DryRun then begin
            // Update the SKU's Standard Cost
            if not SKU.Get(Line."Location Code", Line."Item No.", Line."Variant Code") then begin
                ResultMsg := StrSubstNo(SKUNotFoundErr, Line."Item No.", Line."Location Code", Line."Variant Code");
                exit(false);
            end;

            SKU.Validate("Standard Cost", Line."New Standard Cost");
            SKU.Modify(true);

            ResultMsg := StrSubstNo(SKUStandardCostUpdatedMsg, Line."Item No.", Line."Location Code", Line."Variant Code", Line."New Standard Cost");
        end else
            ResultMsg := StrSubstNo(SKUStandardCostDryRunMsg, Line."Item No.", Line."New Standard Cost");

        exit(true);
    end;
    #endregion

    // ------------- HELPER FUNCTIONS -------------
    local procedure LineExists(WorksheetName: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]): Boolean
    var
        Line: Record "StdCostWkshLine";
    begin
        Line.SetRange("Worksheet Name", WorksheetName);
        Line.SetRange("Item No.", ItemNo);
        Line.SetRange("Location Code", LocationCode);
        Line.SetRange("Variant Code", VariantCode);
        exit(not Line.IsEmpty);
    end;

    local procedure GetNextLineNo(WorksheetName: Code[20]): Integer
    var
        Line: Record "StdCostWkshLine";
    begin
        Line.SetRange("Worksheet Name", WorksheetName);
        if Line.FindLast() then
            exit(Line."Line No." + 10000);
        exit(10000);
    end;

    local procedure HasImplementedLine(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]): Boolean
    var
        L: Record "StdCostWkshLine";
    begin
        L.SetRange("Item No.", ItemNo);
        L.SetRange("Location Code", LocationCode);
        L.SetRange("Variant Code", VariantCode);
        L.SetRange(Implemented, true);
        exit(not L.IsEmpty);
    end;

    procedure Worksheet_RecalculateLine(var Line: Record "StdCostWkshLine")
    var
        StdCostWkshHeader: Record "StdCostWkshHeader";
    begin
        if not StdCostWkshHeader.Get(Line."Worksheet Name") then
            Error('Worksheet %1 not found.', Line."Worksheet Name");
        if StdCostWkshHeader.Status = StdCostWkshHeader.Status::Implemented then
            Error('Worksheet %1 is implemented and lines cannot be changed.', StdCostWkshHeader.Name);

    end;

}
*/
