/// <summary>
/// 2025.10  Jesper Harder  116.1
/// </summary>
table 50028 "StdCostWkshLine"
{
    Caption = 'SPN SKU Std. Cost Worksheet Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Worksheet Name"; Code[20])
        {
            Caption = 'Worksheet Name';
            TableRelation = "StdCostWkshHeader".Name;

            trigger OnValidate()
            var
                Hdr: Record "StdCostWkshHeader";
            begin
                // Only validate if we're modifying an existing record
                if "Line No." <> 0 then
                    if "Worksheet Name" <> xRec."Worksheet Name" then begin
                        if not Hdr.Get("Worksheet Name") then
                            Error('Worksheet %1 not found.', "Worksheet Name");
                        if Hdr.Status = Hdr.Status::Implemented then
                            Error('Cannot change to implemented worksheet %1.', "Worksheet Name");
                    end;
            end;
        }

        field(2; "Line No."; Integer) { Caption = 'Line No.'; }

        field(10; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;

            trigger OnValidate()
            begin
                // Clear dependent fields when Item changes
                if "Item No." <> xRec."Item No." then begin
                    "Variant Code" := '';
                    "Current Standard Cost" := 0;
                    "New Standard Cost" := 0;
                end;
            end;
        }

        field(11; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }

        field(12; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }

        field(20; "Current Standard Cost"; Decimal) { Caption = 'Current Standard Cost'; DecimalPlaces = 0 : 5; Editable = false; }
        field(21; "New Standard Cost"; Decimal) { Caption = 'New Standard Cost'; DecimalPlaces = 0 : 5; }
        field(30; "Locked Flag Snapshot"; Boolean) { Caption = 'Locked Flag Snapshot'; Editable = false; }
        field(40; "Note"; Text[100]) { Caption = 'Note'; }
        field(50; "Implemented"; Boolean) { Caption = 'Implemented'; Editable = false; }
        field(51; "Implemented By"; Code[50]) { Caption = 'Implemented By'; Editable = false; }
        field(52; "Implemented At"; DateTime) { Caption = 'Implemented At'; Editable = false; }
    }

    keys
    {
        key(PK; "Worksheet Name", "Line No.") { Clustered = true; }
        key(ItemIdx; "Item No.", "Location Code", "Variant Code") { }
    }

    trigger OnInsert()
    var
        StdCostWkshHeader: Record "StdCostWkshHeader";
        StdCostWkshLine: Record "StdCostWkshLine";
        MaxLineNo: Integer;
    begin
        // Validate worksheet exists and is not implemented
        if "Worksheet Name" <> '' then begin
            if not StdCostWkshHeader.Get("Worksheet Name") then
                Error('Worksheet %1 not found.', "Worksheet Name");
            if StdCostWkshHeader.Status = StdCostWkshHeader.Status::Implemented then
                Error('Worksheet %1 is implemented; lines cannot be inserted.', "Worksheet Name");

            // Ensure manually inserted lines always get the next available number
            StdCostWkshLine.LockTable();
            StdCostWkshLine.SetRange("Worksheet Name", "Worksheet Name");
            if StdCostWkshLine.FindLast() then
                MaxLineNo := StdCostWkshLine."Line No.";

            if "Line No." <= MaxLineNo then
                "Line No." := MaxLineNo + 10000;
        end;
    end;

    trigger OnModify()
    var
        StdCostWkshHeader: Record "StdCostWkshHeader";
    begin
        if Rec.Implemented then
            Error('Implemented lines cannot be modified.');

        if "Worksheet Name" <> '' then begin
            if not StdCostWkshHeader.Get("Worksheet Name") then
                Error('Worksheet %1 not found.', "Worksheet Name");
            if StdCostWkshHeader.Status = StdCostWkshHeader.Status::Implemented then
                Error('Worksheet %1 is implemented; lines cannot be modified.', "Worksheet Name");
        end;
    end;

    trigger OnDelete()
    var
        StdCostWkshHeader: Record "StdCostWkshHeader";
    begin
        if Rec.Implemented then
            Error('Implemented lines cannot be deleted.');

        if "Worksheet Name" <> '' then begin
            if not StdCostWkshHeader.Get("Worksheet Name") then
                Error('Worksheet %1 not found.', "Worksheet Name");
            if StdCostWkshHeader.Status = StdCostWkshHeader.Status::Implemented then
                Error('Worksheet %1 is implemented; lines cannot be deleted.', "Worksheet Name");
        end;
    end;
}