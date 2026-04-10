/// 2026.02             Jesper Harder       104         Snake Game, Added control add-in page and client assets (AL, JS, CSS)
page 50131 "SCANPAN Snake Game"
{
    ApplicationArea = All;
    Caption = 'SCANPAN Snake Game';
    PageType = Card;
    SourceTable = Integer;
    SourceTableTemporary = true;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Game)
            {
                ShowCaption = false;

                usercontrol(Snake; "SCANPAN Snake Game")
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        CurrentScore := 0;
                    end;

                    trigger ScoreChanged(Score: Integer)
                    begin
                        CurrentScore := Score;
                    end;

                    trigger GameOver(Score: Integer)
                    begin
                        CurrentScore := Score;
                        Message('Game over. Final score: %1', Score);
                    end;
                }
            }
            group(Stats)
            {
                Caption = 'Score';
                field(CurrentScore; CurrentScore)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Current Snake game score.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NewGame)
            {
                ApplicationArea = All;
                Caption = 'New Game';
                Image = New;
                ToolTip = 'Start a new Snake game.';

                trigger OnAction()
                begin
                    CurrPage.Snake.StartNewGame();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if Rec.Number = 0 then begin
            Rec.Number := 1;
            Rec.Insert();
        end;
    end;

    var
        CurrentScore: Integer;
}
