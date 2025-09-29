

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
            group(Filters) // <--- brugerfelter, der virker som filtre
            {
                field(ItemNoFilter; ItemNoFilter)
                {
                    Caption = 'Item No.';
                    ToolTip = 'Specifies the value of the Item No. field.';
                    trigger OnValidate()
                    begin
                        ApplyFilters();
                    end;
                }
                field(GenProdPostingGroupFilter; GenProdPostingGroupFilter)
                {
                    Caption = 'Gen. Prod. Posting Group';
                    TableRelation = "Gen. Product Posting Group".Code;
                    ToolTip = 'Specifies the value of the Gen. Prod. Posting Group field.';
                    trigger OnValidate()
                    begin
                        ApplyFilters();
                    end;
                }
                field(ProdLineCodeFilter; ProdLineCodeFilter)
                {
                    Caption = 'Product Line Code';
                    //TableRelation = "NOTO Item Categories".Code;
                    TableRelation = "NOTO Item Categories".Code WHERE("Category Code" = const("ProductLineCode"));
                    ToolTip = 'Specifies the value of the Product Line Code field.';
                    trigger OnValidate()
                    begin
                        ApplyFilters();
                    end;
                }
              field("Location Filter"; LocationFilter)
              {
                Caption = 'Location Filter';
                  ToolTip = 'Specifies the value of the Location Filter field.';

                  TableRelation = "Location".Code;
                  trigger OnValidate()
                  begin
                      ApplyFilters();
                  end;
              }
            }
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


            part(FIFOEntries; "FIFO Item Inflow Lines")
            {
                SubPageLink = "Item No." = FIELD("No.");
            }
        }
  
    }

trigger OnOpenPage()
begin
    LocationFilter := 'AUNING';
    ItemNoFilter := '';
    GenProdPostingGroupFilter := '';
    ProdLineCodeFilter := '';
    ApplyFilters();
end;

    var
        ItemNoFilter: Code[20];
        GenProdPostingGroupFilter: Code[20];
        ProdLineCodeFilter: Code[20];
        LocationFilter: Code[20];

    local procedure ApplyFilters()
    var
        ItemView: Record Item;
    begin
        ItemView.Reset();
        if LocationFilter <> '' then
            ItemView.SetRange("Location Filter", LocationFilter);
        if ItemNoFilter <> '' then
            ItemView.SetFilter("No.", ItemNoFilter); // supports intervals
        if GenProdPostingGroupFilter <> '' then
            ItemView.SetRange("Gen. Prod. Posting Group", GenProdPostingGroupFilter);
        if ProdLineCodeFilter <> '' then
            ItemView.SetRange("Product Line Code", ProdLineCodeFilter);

        CurrPage.SetTableView(ItemView);
        CurrPage.FIFOEntries.PAGE.SetFilters(LocationFilter);
        CurrPage.Update(false);
    end;

}
