Page 50075 "SPN Perfion Image CardPart"
{
    PageType = CardPart;
    SourceTable = "SPN Perfion Store";
    SourceTableTemporary = true;
    Caption = 'Perfion Images';

    layout
    {
        area(content)
        {
            group(Images)
            {
                ShowCaption = false;
                group(Row1)
                {
                    field(Image1; Image1)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ExtendedDatatype = None;
                        ShowCaption = false;
                    }
                    field(Image2; Image2)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ExtendedDatatype = None;
                        ShowCaption = false;
                    }
                }
                group(Row2)
                {
                    field(Image3; Image3)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ExtendedDatatype = None;
                        ShowCaption = false;
                    }
                    field(Image4; Image4)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ExtendedDatatype = None;
                        ShowCaption = false;
                    }
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields(Image1, Image2, Image3, Image4);
    end;
}