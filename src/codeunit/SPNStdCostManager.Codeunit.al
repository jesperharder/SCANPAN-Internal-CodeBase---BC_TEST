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

    // ------------- INTERNALS: GUARD -------------
    #region Guard
    procedure Guard_ValidateCanImplement(ItemNo: Code[20]; CompanyName: Text[100]; var Message: Text): Boolean
    var
        Item: Record Item;
    begin
        Message := '';
        if not Item.Get(ItemNo) then begin
            Message := StrSubstNo('Item %1 not found.', ItemNo);
            exit(false);
        end;

        // Check costing method
        if Item."Costing Method" = Item."Costing Method"::Specific then begin
            Message := 'Specific costing items are not supported for standard cost implementation.';
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
        EffectiveDate: Date;
        NowDT: DateTime;
    begin
        if Header.Status = Header.Status::Implemented then
            Error('Worksheet %1 is already implemented and cannot be changed.', Header.Name);

        // Effective date
        if Header."Implemented At" <> 0DT then
            EffectiveDate := DT2Date(Header."Implemented At")
        else
            EffectiveDate := Today;

        NowDT := CurrentDateTime();

        // Process non-implemented lines for this worksheet
        Line.SetRange("Worksheet Name", Header."Name");
        Line.SetRange(Implemented, false);
        if Line.FindSet(true, false) then
            repeat
                Ok := Implementation_ImplementItem(Line, EffectiveDate, false, Msg);
                if not Ok then
                    Error('Line %1 failed: %2', Line."Line No.", Msg);

                // Mark line as implemented
                Line."Implemented By" := UserId();
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

    local procedure Implementation_ImplementItem(var Line: Record "StdCostWkshLine"; EffectiveDate: Date; DryRun: Boolean; var ResultMsg: Text): Boolean
    var
        SKU: Record "Stockkeeping Unit";
        Ok: Boolean;
        Msg: Text;
    begin
        // Validate before apply
        Ok := Guard_ValidateCanImplement(Line."Item No.", CompanyName(), Msg);
        if not Ok then begin
            ResultMsg := Msg;
            exit(false);
        end;

        if not DryRun then begin
            // Update the SKU's Standard Cost
            if not SKU.Get(Line."Location Code", Line."Item No.", Line."Variant Code") then begin
                ResultMsg := StrSubstNo('SKU for Item %1, Location %2, Variant %3 not found.',
                    Line."Item No.", Line."Location Code", Line."Variant Code");
                exit(false);
            end;

            SKU.Validate("Standard Cost", Line."New Standard Cost");
            SKU.Modify(true);

            ResultMsg := StrSubstNo('SKU standard cost for Item %1 (Loc: %2, Var: %3) updated to %4.',
                Line."Item No.", Line."Location Code", Line."Variant Code", Line."New Standard Cost");
        end else begin
            ResultMsg := StrSubstNo('SKU standard cost for Item %1 would be updated to %2 (dry-run).',
                Line."Item No.", Line."New Standard Cost");
        end;

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
        exit(Line.FindFirst());
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
        exit(L.FindFirst());
    end;

    procedure Worksheet_RecalculateLine(var Line: Record "StdCostWkshLine")
    var
        Hdr: Record "StdCostWkshHeader";
    begin
        if not Hdr.Get(Line."Worksheet Name") then
            Error('Worksheet %1 not found.', Line."Worksheet Name");
        if Hdr.Status = Hdr.Status::Implemented then
            Error('Worksheet %1 is implemented and lines cannot be changed.', Hdr.Name);

        // TODO: bring over your line recalc logic
        // Example: Line."New Std. Cost" := CalcSomething(Line);
    end;

}