table 50031 "SPN Perfion Store"
{
    Caption = 'Perfion Store';
    DataClassification = ToBeClassified;
    TableType = Temporary;
    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
            Editable = true;
        }
        field(2; Image1; Media)
        {
            Caption = 'Image 1';
            DataClassification = CustomerContent;
        }
        field(3; Image2; Media)
        {
            Caption = 'Image 2';
            DataClassification = CustomerContent;
        }
        field(4; Image3; Media)
        {
            Caption = 'Image 3';
            DataClassification = CustomerContent;
        }
        field(5; Image4; Media)
        {
            Caption = 'Image 4';
            DataClassification = CustomerContent;
        }


    }

    keys
    {
        key(PK; "Item No.") { Clustered = true; }
    }
}
