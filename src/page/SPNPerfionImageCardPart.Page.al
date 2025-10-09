page 50075 "SPN Perfion Image CardPart"
{
    PageType = CardPart;
    SourceTable = "SPN Perfion Store";
    Caption = 'Perfion Images';

    layout
    {
        area(content)
        {
            group(Row1)
            {
                field(Image1; Image1) { ApplicationArea = All; ShowCaption = false; }
                field(Image2; Image2) { ApplicationArea = All; ShowCaption = false; }
            }
            group(Row2)
            {
                field(Image3; Image3) { ApplicationArea = All; ShowCaption = false; }
                field(Image4; Image4) { ApplicationArea = All; ShowCaption = false; }
            }
        }
    }
}
