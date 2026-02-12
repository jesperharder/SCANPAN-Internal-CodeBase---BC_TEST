/// 2026.02             Jesper Harder       104         Snake Game, Added control add-in page and client assets (AL, JS, CSS)
controladdin "SCANPAN Snake Game"
{
    StartupScript = 'src/controladdin/snakegame.js';
    StyleSheets = 'src/controladdin/snakegame.css';

    RequestedHeight = 520;
    RequestedWidth = 800;
    HorizontalStretch = true;
    VerticalStretch = true;

    event ControlReady();
    event ScoreChanged(Score: Integer);
    event GameOver(Score: Integer);

    procedure StartNewGame();
}
