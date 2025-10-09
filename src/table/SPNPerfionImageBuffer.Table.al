table 50030 "SPN Perfion Image Buffer"
{
    Caption = 'Perfion Image Buffer';
    DataClassification = ToBeClassified;
    ObsoleteState = Pending; // eller Removed
    ObsoleteReason = 'Replaced by new image storage design with Media fields.';
    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
        }
        field(2; "Image No."; Integer)
        {
            Caption = 'Image No.';
            DataClassification = SystemMetadata;
        }
        field(3; Image; Blob)
        {
            Caption = 'Image';
            Subtype = Bitmap;
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Item No.", "Image No.") { Clustered = true; }
    }
}
