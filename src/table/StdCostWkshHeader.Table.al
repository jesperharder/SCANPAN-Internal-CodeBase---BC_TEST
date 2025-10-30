table 50029 "StdCostWkshHeader"
{
    Caption = 'SPN SKU Std. Cost Worksheet';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Name"; Code[20]) { Caption = 'Name'; }
        field(2; "Description"; Text[100]) { Caption = 'Description'; }

        field(3; "Status"; Enum "SPN StdCost Wksh Status")
        {
            Caption = 'Status';

            trigger OnValidate()
            begin
                // Prevent changing status away from Implemented
                if xRec.Status = xRec.Status::Implemented then
                    Error('Cannot change status of an implemented worksheet.');

                // When setting to Implemented, validate required fields
                if Status = Status::Implemented then begin
                    if "Implemented By" = '' then
                        "Implemented By" := UserId();
                    if "Implemented At" = 0DT then
                        "Implemented At" := CurrentDateTime();
                end;
            end;
        }

        field(10; "Created By"; Code[50]) { Caption = 'Created By'; Editable = false; }
        field(11; "Created At"; DateTime) { Caption = 'Created At'; Editable = false; }
        field(12; "Implemented By"; Code[50]) { Caption = 'Implemented By'; Editable = false; }
        field(13; "Implemented At"; DateTime) { Caption = 'Implemented At'; Editable = false; }
    }

    keys { key(PK; "Name") { Clustered = true; } }

    trigger OnModify()
    begin
        // Prevent modification if it was already implemented BEFORE this change
        // Allow the transition FROM Draft TO Implemented
        if (xRec.Status = xRec.Status::Implemented) then
            Error('Worksheet %1 is implemented and cannot be modified.', Rec.Name);
    end;

    trigger OnInsert()
    begin
        if "Name" = '' then
            "Name" := GenAutoName();
        "Created By" := UserId();
        "Created At" := CurrentDateTime();
        // Status defaults to Draft (enum default value)
    end;

    trigger OnDelete()
    var
        Line: Record "StdCostWkshLine";
    begin
        // Block deleting implemented worksheets
        if Status = Status::Implemented then
            Error('Implemented worksheets cannot be deleted.');

        // Also block if contains any implemented lines
        Line.SetRange("Worksheet Name", Rec.Name);
        Line.SetRange(Implemented, true);
        if not Line.IsEmpty() then
            Error('This worksheet contains implemented lines and cannot be deleted.');

        // Delete all remaining (non-implemented) lines
        Line.Reset();
        Line.SetRange("Worksheet Name", Rec.Name);
        Line.DeleteAll(true);
    end;

    local procedure GenAutoName(): Code[20]
    var
        Hdr: Record "StdCostWkshHeader";
        dTxt: Text[8];
        tTxt: Text[6];
        base: Code[20];
        candidate: Code[20];
        i: Integer;
    begin
        // Base = WK-yyyymmdd-hhmmss  (18 chars)
        dTxt := Format(Today, 0, '<Year4><Month,2><Day,2>');
        tTxt := Format(Time, 0, '<Hours24,2><Minutes,2><Seconds,2>');
        base := CopyStr(StrSubstNo('WK-%1-%2', dTxt, tTxt), 1, 20);
        candidate := base;

        // If a record with the same Name exists (same second), add a short suffix
        for i := 0 to 99 do begin
            if (i > 0) then
                candidate := CopyStr(base + '-' + Format(i), 1, 20);
            if not Hdr.Get(candidate) then
                exit(candidate);
        end;

        Error('Unable to generate a unique worksheet name. Please try again.');
    end;
}