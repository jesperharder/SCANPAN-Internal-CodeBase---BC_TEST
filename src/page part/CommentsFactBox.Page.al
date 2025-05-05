page 50067 "CommentsFactBox"
{
    Caption = 'Campaign Comments';
    PageType = ListPart;
    SourceTable = "Rlshp. Mgt. Comment Line";
    AdditionalSearchTerms = 'Scanpan';

    /// <summary>
    /// 2025.03 - Jesper Harder - 108.1
    /// Campaign Comments in Factbox extension
    /// </summary>

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                Caption = 'General';

                field(Date; Rec.Date)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date of the comment.';
                }

                field(Comment; Rec.Comment)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the comment text.';
                }
            }
        }
    }
}


/*
page 50067 "CommentsFactBox"
///<summary>
/// 2025.03             Jesper Harder       108.1       Campaign Comments in Factbox extension
/// </summary>
{
    PageType = ListPart;
    SourceTable = "Rlshp. Mgt. Comment Line";
    //ApplicationArea = All;
    Caption = 'Campaign Comments';
    AdditionalSearchTerms = 'Scanpan';
    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Date"; Rec."Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Date field.';
                }
                field("Comment"; Rec."Comment")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Comment field.';
                }
            }
        }
    }
}
*/
