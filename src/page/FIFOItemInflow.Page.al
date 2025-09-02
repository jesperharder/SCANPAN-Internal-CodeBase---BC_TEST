

// Hovedside: viser varen og et underafsnit med FIFO-tilgange
page 50071 "FIFO Item Inflow"
{
    PageType = Card;
    SourceTable = Item;
    UsageCategory = Lists;
    ApplicationArea = All;
    
    layout
    {
        area(content)
        {
            group(ItemInfo)
            {
                Editable = false;
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the number of the item.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies what you are selling.';
                }
                field(Inventory; Rec.Inventory)
                {
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of the item that is currently in inventory at all locations.';
                }
            }

            group(Filters) // <--- brugerfelter, der virker som filtre
            {
                field(GenProdPostingGroupFilter; GenProdPostingGroupFilter)
                {
                    Caption = 'Gen. Prod. Posting Group';
                    TableRelation = "Gen. Product Posting Group".Code;
                    ToolTip = 'Specifies the value of the Gen. Prod. Posting Group field.';
                    trigger OnValidate()
                    begin
                        CurrPage.FIFOEntries.PAGE.SetFilters(
                          GenProdPostingGroupFilter, ProdLineCodeFilter);
                          ApplyFilters();
                    end;
                }
                field(ProdLineCodeFilter; ProdLineCodeFilter)
                {
                    Caption = 'Product Line Code';
                    TableRelation = "NOTO Item Categories".Code;
                    ToolTip = 'Specifies the value of the Product Line Code field.';
                    trigger OnValidate()
                    begin
                        CurrPage.FIFOEntries.PAGE.SetFilters(
                          GenProdPostingGroupFilter, ProdLineCodeFilter);
                          ApplyFilters();
                    end;
                }
            }

            part(FIFOEntries; "FIFO Item Inflow Lines")
            {
                SubPageLink = "Item No." = FIELD("No.");
            }
        }
    }

    var
        GenProdPostingGroupFilter: Code[20];
        ProdLineCodeFilter: Code[20];

    local procedure ApplyFilters()
    begin
        CurrPage.FIFOEntries.PAGE.SetFilters(
            GenProdPostingGroupFilter,
            ProdLineCodeFilter);
    end;
}
